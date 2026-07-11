// ============================================================================
// endpoints/adminApi.js — single POST endpoint that powers the admin panel.
// ----------------------------------------------------------------------------
// This is the LARGEST function (~400 lines worth of switch-cases). It is
// kept in a single file because:
//   1. The client only sees ONE endpoint; there's no value in fragmenting it.
//   2. Every action shares the same auth + CORS + error envelope.
//
// Action gating is driven by `ACTION_MIN_ROLE` from `lib/adminAuth.js`:
//   - moderator: read-only / query / count
//   - admin:     write actions + promo codes + broadcasts
//   - owner:     role assignment + admin removal
//
// Per-action behaviour is documented inline in the switch statement below.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { callGemini } = require('../lib/gemini');

const {
  ACTION_MIN_ROLE,
  verifyCallerIsAdmin,
  getCallerRole,
  callerHasRole,
  serializeFirestoreValue,
  serializeDoc,
  applyServerTokens,
  refFromPath,
  collectionFromPath,
  docFromPath,
  MAX_ADMIN_QUERY_LIMIT,
  isBlockedWritePath,
  isAllowedModeratorQueryPath,
  assertWritableAdminPath,
} = require('../lib/adminAuth');

const { guardRequest, setCors } = require('../lib/http');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

// ---------------------------------------------------------------------------
// Query / Count helpers — used by 'query' and 'count' actions.
// ---------------------------------------------------------------------------

async function runAdminQuery(payload, role) {
  const {
    collectionPath,
    collectionGroup,
    filters = [],
    orderBy: orderByField,
    limit: rowLimit = 100,
  } = payload;

  if (role === 'moderator' &&
      !isAllowedModeratorQueryPath(collectionPath, collectionGroup)) {
    throw new Error('Moderators cannot query this collection.');
  }

  let q;
  if (collectionGroup) {
    q = admin.firestore().collectionGroup(collectionGroup);
  } else {
    q = collectionFromPath(collectionPath);
  }

  for (const f of filters) {
    q = q.where(f.field, f.op, f.value);
  }
  if (orderByField?.field) {
    q = q.orderBy(orderByField.field, orderByField.dir || 'asc');
  }
  const cappedLimit = Math.min(
    Math.max(Number(rowLimit) || 100, 1),
    MAX_ADMIN_QUERY_LIMIT,
  );
  q = q.limit(cappedLimit);

  const snap = await q.get();
  return snap.docs.map(serializeDoc);
}

async function runAdminCount(payload, role) {
  const { collectionPath, collectionGroup, filters = [] } = payload;
  if (role === 'moderator' &&
      !isAllowedModeratorQueryPath(collectionPath, collectionGroup)) {
    throw new Error('Moderators cannot count this collection.');
  }
  let q;
  if (collectionGroup) {
    q = admin.firestore().collectionGroup(collectionGroup);
  } else {
    q = collectionFromPath(collectionPath);
  }
  for (const f of filters) {
    q = q.where(f.field, f.op, f.value);
  }
  const snap = await q.count().get();
  return snap.data().count;
}

// ---------------------------------------------------------------------------
// Build the daily analytics snapshot — shared with the cron job in
// `scheduled/analytics.js`. We duplicate the body here (rather than import)
// because the cron function uses `defineSecret`-free env.
// ---------------------------------------------------------------------------

function buildDailySnapshot(db) {
  const now = new Date();
  const dayKey = now.toISOString().slice(0, 10);
  const dayStart = new Date(`${dayKey}T00:00:00Z`);
  const dayPrev = new Date(dayStart.getTime() - 24 * 3600 * 1000);
  const sevenDaysAgo = new Date(dayStart.getTime() - 7 * 24 * 3600 * 1000);

  return {
    dayKey,
    dayStart,
    dayPrev,
    sevenDaysAgo,
    queries: Promise.all([
      db.collection('users').count().get(),
      db.collection('users').where('isPremium', '==', true).count().get(),
      db.collectionGroup('posts').count().get(),
      db.collection('educationArticles').where('published', '==', true).count().get(),
      db.collection('communityReports').where('status', '==', 'pending').count().get(),
      db.collection('users').where('createdAt', '>=', admin.firestore.Timestamp.fromDate(dayPrev)).count().get().catch(() => ({ data: () => ({ count: 0 }) })),
      db.collection('users').where('premiumSince', '>=', dayPrev.toISOString()).count().get().catch(() => ({ data: () => ({ count: 0 }) })),
      db.collection('users').where('createdAt', '>=', admin.firestore.Timestamp.fromDate(sevenDaysAgo)).count().get().catch(() => ({ data: () => ({ count: 0 }) })),
      db.collection('users').where('lastActiveAt', '>=', admin.firestore.Timestamp.fromDate(dayPrev)).count().get().catch(() => ({ data: () => ({ count: 0 }) })),
    ]),
  };
}

// ---------------------------------------------------------------------------
// Public function
// ---------------------------------------------------------------------------

exports.adminApi = onRequest(
  { cors: true, timeoutSeconds: 120, secrets: [GEMINI_API_KEY] },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'admin', appCheck: 'skip' }))) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const { action, payload = {} } = req.body || {};

      if (action === 'checkAdmin') {
        const isAdmin = await verifyCallerIsAdmin(decoded);
        const role = isAdmin ? await getCallerRole(decoded) : null;
        setCors(res);
        res.json({ isAdmin, role });
        return;
      }

      if (action === 'ensureAdmin') {
        const isAdmin = await verifyCallerIsAdmin(decoded);
        if (!isAdmin) {
          setCors(res);
          res.status(403).json({ error: 'Admin only.' });
          return;
        }
        const email = decoded.email || null;
        // preserve existing role if any (don't downgrade owner to admin on every login)
        const existingAdminDoc = await admin.firestore().collection('admins').doc(decoded.uid).get();
        const existingRole = existingAdminDoc.exists ? existingAdminDoc.data()?.role : null;
        const role = existingRole || 'admin';
        const batch = admin.firestore().batch();
        batch.set(admin.firestore().collection('admins').doc(decoded.uid), {
          email,
          role,
          isAdmin: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        batch.set(admin.firestore().collection('users').doc(decoded.uid), {
          email,
          isAdmin: true,
          role,
          lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await batch.commit();
        setCors(res);
        res.json({ ok: true, role });
        return;
      }

      // For all other actions: check role gating
      const minRole = ACTION_MIN_ROLE[action] || 'admin';
      if (!(await callerHasRole(decoded, minRole))) {
        setCors(res);
        res.status(403).json({ error: `Requires ${minRole} role.` });
        return;
      }
      const callerRole = await getCallerRole(decoded);

      let result;
      switch (action) {
        case 'overview': {
          const [users, premium, posts, pendingReports, articles, pendingPosts, pendingComments] =
            await Promise.all([
            admin.firestore().collection('users').count().get(),
            admin.firestore().collection('users').where('isPremium', '==', true).count().get(),
            admin.firestore().collectionGroup('posts').count().get(),
            admin.firestore().collection('communityReports').where('status', '==', 'pending').count().get(),
            admin.firestore().collection('educationArticles').where('published', '==', true).count().get(),
            admin.firestore().collectionGroup('posts')
              .where('moderationStatus', '==', 'pending_review').count().get(),
            admin.firestore().collectionGroup('comments')
              .where('moderationStatus', '==', 'pending_review').count().get(),
          ]);
          const moderationPending =
            pendingPosts.data().count + pendingComments.data().count;
          result = {
            users: users.data().count,
            premium: premium.data().count,
            posts: posts.data().count,
            pending: pendingReports.data().count,
            moderationPending,
            articles: articles.data().count,
          };
          break;
        }
        case 'query':
          result = { items: await runAdminQuery(payload, callerRole) };
          break;
        case 'count':
          result = { count: await runAdminCount(payload, callerRole) };
          break;
        case 'get': {
          const segments = Array.isArray(payload.path)
            ? payload.path
            : String(payload.path || '').split('/').filter(Boolean);
          if (callerRole === 'moderator' &&
              (segments.length === 0 ||
                  !isAllowedModeratorQueryPath(segments[0], null))) {
            throw new Error('Moderators cannot read this document.');
          }
          const snap = await docFromPath(segments).get();
          result = snap.exists
            ? { exists: true, item: serializeDoc(snap) }
            : { exists: false };
          break;
        }
        case 'set':
          assertWritableAdminPath(payload.path, callerRole);
          await docFromPath(payload.path).set(
            applyServerTokens(payload.data || {}),
            { merge: payload.merge === true },
          );
          result = { ok: true };
          break;
        case 'update':
          assertWritableAdminPath(payload.path, callerRole);
          await docFromPath(payload.path).update(applyServerTokens(payload.data || {}));
          result = { ok: true };
          break;
        case 'delete':
          assertWritableAdminPath(payload.path, callerRole);
          await docFromPath(payload.path).delete();
          result = { ok: true };
          break;
        case 'add': {
          if (isBlockedWritePath(payload.collectionPath)) {
            throw new Error('Writes to this collection are not permitted.');
          }
          const ref = await collectionFromPath(payload.collectionPath).add(
            applyServerTokens(payload.data || {}),
          );
          result = { id: ref.id };
          break;
        }

        // ============== NEW ADMIN EXTENSIONS ==============
        case 'setUserPremium': {
          // Manual premium override — the ONLY sanctioned client-triggerable
          // path besides Play Billing / promo codes. Admin-gated + audited.
          const uid = (payload.uid || '').toString().trim();
          const isPremium = payload.isPremium === true;
          if (!uid) throw new Error('uid مطلوب');

          const userRef = admin.firestore().collection('users').doc(uid);
          const snap = await userRef.get();
          if (!snap.exists) throw new Error('المستخدم غير موجود');

          await userRef.set({
            isPremium,
            premiumSource: isPremium ? 'admin_grant' : admin.firestore.FieldValue.delete(),
            premiumSince: isPremium
              ? (snap.data()?.premiumSince || new Date().toISOString())
              : admin.firestore.FieldValue.delete(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          // Audit trail — who flipped whom, when, in which direction.
          await admin.firestore().collection('adminActivityLog').add({
            action: 'setUserPremium',
            targetUid: uid,
            isPremium,
            performedBy: decoded.uid,
            performedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          result = { ok: true, uid, isPremium };
          break;
        }
        case 'aiCostStats': {
          // Budget monitor — reads O(days) aggregate docs written by
          // lib/ai_usage.js on every AI request. No subcollection scans.
          const days = Math.min(Math.max(parseInt(payload.days, 10) || 30, 1), 90);
          const since = new Date();
          since.setUTCDate(since.getUTCDate() - days);
          const sinceKey = since.toISOString().slice(0, 10);
          const snap = await admin.firestore()
            .collection('aiUsageDaily')
            .where(admin.firestore.FieldPath.documentId(), '>=', sinceKey)
            .orderBy(admin.firestore.FieldPath.documentId(), 'asc')
            .limit(days)
            .get();

          const daysOut = snap.docs.map(serializeDoc);
          const totals = daysOut.reduce((acc, d) => ({
            requests: acc.requests + (Number(d.requests) || 0),
            promptTokens: acc.promptTokens + (Number(d.promptTokens) || 0),
            completionTokens: acc.completionTokens + (Number(d.completionTokens) || 0),
            estimatedCostUsd: acc.estimatedCostUsd + (Number(d.estimatedCostUsd) || 0),
          }), { requests: 0, promptTokens: 0, completionTokens: 0, estimatedCostUsd: 0 });

          result = { days: daysOut, totals };
          break;
        }
        case 'analyticsHistory': {
          const days = Math.min(Math.max(parseInt(payload.days, 10) || 30, 7), 90);
          const since = new Date();
          since.setUTCDate(since.getUTCDate() - days);
          const sinceKey = since.toISOString().slice(0, 10);
          const snap = await admin.firestore()
            .collection('analyticsDaily')
            .where(admin.firestore.FieldPath.documentId(), '>=', sinceKey)
            .orderBy(admin.firestore.FieldPath.documentId(), 'asc')
            .limit(days)
            .get();
          result = { items: snap.docs.map(serializeDoc) };
          break;
        }
        case 'aiUsageStats': {
          const days = Math.min(Math.max(parseInt(payload.days, 10) || 7, 1), 30);
          const since = new Date(Date.now() - days * 24 * 60 * 60 * 1000);
          const usersSnap = await admin.firestore().collection('ai_usage').limit(500).get();
          const byDay = {};
          const byMode = {};
          const byUser = {};
          for (const userDoc of usersSnap.docs) {
            const msgs = await userDoc.ref.collection('messages')
              .where('timestamp', '>=', since).limit(1000).get();
            byUser[userDoc.id] = (byUser[userDoc.id] || 0) + msgs.size;
            msgs.docs.forEach((m) => {
              const data = m.data();
              const day = data.timestamp?.toDate?.()?.toISOString().slice(0, 10) || 'unknown';
              byDay[day] = (byDay[day] || 0) + 1;
              const mode = data.mode || 'chat';
              byMode[mode] = (byMode[mode] || 0) + 1;
            });
          }
          const total = Object.values(byDay).reduce((a, b) => a + b, 0);
          const topUsers = Object.entries(byUser)
            .sort((a, b) => b[1] - a[1]).slice(0, 10)
            .map(([uid, count]) => ({ uid, count }));
          result = { total, byDay, byMode, topUsers };
          break;
        }
        case 'createPromoCode': {
          const codeRaw = (payload.code || '').toString().trim().toUpperCase();
          const code = codeRaw.replace(/[^A-Z0-9_-]/g, '');
          if (!code || code.length < 3) { throw new Error('الكود قصير جداً (3 أحرف على الأقل)'); }
          const days = Math.min(Math.max(parseInt(payload.days, 10) || 7, 1), 365);
          const maxUses = Math.max(parseInt(payload.maxUses, 10) || 100, 1);
          const expiresAt = payload.expiresAt ? new Date(payload.expiresAt) : null;
          await admin.firestore().collection('promoCodes').doc(code).set({
            code,
            type: 'premium_days',
            days,
            maxUses,
            usedCount: 0,
            active: true,
            expiresAt: expiresAt ? admin.firestore.Timestamp.fromDate(expiresAt) : null,
            note: (payload.note || '').toString().substring(0, 120),
            createdBy: decoded.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          result = { code };
          break;
        }
        case 'revokePromoCode': {
          const code = (payload.code || '').toString().trim().toUpperCase();
          if (!code) throw new Error('الكود مطلوب');
          await admin.firestore().collection('promoCodes').doc(code).update({
            active: false,
            revokedAt: admin.firestore.FieldValue.serverTimestamp(),
            revokedBy: decoded.uid,
          });
          result = { ok: true };
          break;
        }
        case 'segmentPreview': {
          const seg = payload.segment || 'all';
          let q = admin.firestore().collection('users');
          if (seg === 'premium') q = q.where('isPremium', '==', true);
          else if (seg === 'free') q = q.where('isPremium', '!=', true);
          else if (seg === 'new_7d') {
            const since = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 86400000));
            q = q.where('createdAt', '>=', since);
          } else if (seg === 'inactive_14d') {
            const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14 * 86400000));
            q = q.where('lastActiveAt', '<', cutoff);
          } else if (seg === 'expired_premium') {
            q = q.where('isPremium', '==', false).where('premiumSince', '!=', null);
          }
          if (payload.country) q = q.where('country', '==', payload.country);
          try {
            const cnt = await q.count().get();
            result = { count: cnt.data().count };
          } catch (e) {
            const snap = await q.limit(500).get();
            result = { count: snap.size, approximate: true };
          }
          break;
        }
        case 'scheduleBroadcast': {
          const title = (payload.title || '').toString().trim().substring(0, 80);
          const body = (payload.body || '').toString().trim().substring(0, 300);
          const audience = ['all', 'premium', 'free'].includes(payload.audience) ? payload.audience : 'all';
          if (!title || !body) throw new Error('العنوان والنص مطلوبان');
          if (!payload.scheduledFor) throw new Error('وقت الإرسال مطلوب');
          const when = new Date(payload.scheduledFor);
          if (Number.isNaN(when.getTime())) throw new Error('وقت غير صالح');
          if (when.getTime() < Date.now() - 60000) throw new Error('الوقت في الماضي');
          const ref = await admin.firestore().collection('scheduledBroadcasts').add({
            title, body, audience,
            scheduledFor: admin.firestore.Timestamp.fromDate(when),
            sent: false,
            createdBy: decoded.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          result = { id: ref.id };
          break;
        }
        case 'cancelScheduledBroadcast': {
          const id = payload.id;
          if (!id) throw new Error('id مطلوب');
          await admin.firestore().collection('scheduledBroadcasts').doc(id).delete();
          result = { ok: true };
          break;
        }
        case 'setAdminRole': {
          const uid = (payload.uid || '').toString();
          const role = payload.role;
          if (!uid) throw new Error('uid مطلوب');
          if (!['owner', 'admin', 'moderator'].includes(role)) throw new Error('role غير صالح');
          await admin.firestore().collection('admins').doc(uid).set({
            role,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedBy: decoded.uid,
            isAdmin: true,
          }, { merge: true });
          await admin.firestore().collection('users').doc(uid).set({
            isAdmin: true, role,
          }, { merge: true });
          result = { ok: true };
          break;
        }
        case 'removeAdmin': {
          const uid = (payload.uid || '').toString();
          if (!uid) throw new Error('uid مطلوب');
          if (uid === decoded.uid) throw new Error('لا يمكنكِ إزالة نفسكِ');
          await admin.firestore().collection('admins').doc(uid).delete();
          await admin.firestore().collection('users').doc(uid).set({
            isAdmin: false, role: admin.firestore.FieldValue.delete(),
          }, { merge: true });
          result = { ok: true };
          break;
        }
        case 'replyToFeedback': {
          const id = (payload.id || '').toString();
          const reply = (payload.reply || '').toString().trim().substring(0, 1000);
          if (!id || !reply) throw new Error('id و reply مطلوبان');
          const ref = admin.firestore().collection('feedback').doc(id);
          const snap = await ref.get();
          if (!snap.exists) throw new Error('الملاحظة غير موجودة');
          const fb = snap.data();
          await ref.update({
            reply,
            status: 'replied',
            repliedAt: admin.firestore.FieldValue.serverTimestamp(),
            repliedBy: decoded.uid,
          });
          // try to push to user
          if (fb.uid) {
            const userSnap = await admin.firestore().collection('users').doc(fb.uid).get();
            const token = userSnap.data()?.fcmToken;
            if (token) {
              try {
                await admin.messaging().send({
                  token,
                  notification: {
                    title: 'رد من فريق Lune 💜',
                    body: reply.substring(0, 100),
                  },
                  data: { type: 'feedback_reply', feedbackId: id },
                });
              } catch (e) {
                console.warn('feedback push failed:', e.message);
              }
            }
          }
          result = { ok: true };
          break;
        }
        case 'runSnapshotNow': {
          const db = admin.firestore();
          const { dayKey, queries } = buildDailySnapshot(db);
          const [users, premium, posts, articles, pending, newToday, newPremiumToday, signups7d, dauApprox] = await queries;
          const snapshot = {
            date: dayKey,
            users: users.data().count,
            premium: premium.data().count,
            posts: posts.data().count,
            articles: articles.data().count,
            pendingReports: pending.data().count,
            newUsersToday: newToday.data().count,
            newPremiumToday: newPremiumToday.data().count,
            newUsers7d: signups7d.data().count,
            dau: dauApprox.data().count,
            triggeredBy: decoded.uid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          await db.collection('analyticsDaily').doc(dayKey).set(snapshot, { merge: true });
          result = snapshot;
          break;
        }
        case 'translateText': {
          const text = (payload.text || '').toString().substring(0, 4000);
          const target = payload.target === 'en' ? 'English' : 'Arabic';
          if (!text.trim()) throw new Error('النص مطلوب');
          const sys = `You are a professional translator. Translate the user's text to ${target}.
- Preserve meaning, tone, and formatting (line breaks, punctuation).
- Output ONLY the translation. No explanations, no quotes around it.`;
          try {
            const translated = await callGemini(GEMINI_API_KEY.value(), sys, text, 1500);
            result = { translated };
          } catch (e) {
            throw new Error('فشلت الترجمة: ' + (e.message || e));
          }
          break;
        }
        default:
          setCors(res);
          res.status(400).json({ error: `Unknown action: ${action}` });
          return;
      }

      setCors(res);
      res.json(result);
    } catch (error) {
      console.error('adminApi error:', req.body?.action, error);
      setCors(res);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: error.message || 'Admin API failed.' });
    }
  },
);