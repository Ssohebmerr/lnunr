// ============================================================================
// endpoints/subscriptions.js — Google Play billing + promo code redemption.
// ----------------------------------------------------------------------------
// Four endpoints share the subscription domain:
//
//   - exports.verifyPlayPurchase    (user)   — called from Dart after a
//                                             Play Billing purchase to mark
//                                             the user as Premium on our
//                                             side. Server-side verification
//                                             via service account.
//   - exports.redeemPromoCode       (user)   — atomic transaction that
//                                             applies promo-code premium
//                                             days and prevents re-use.
//   - exports.googlePlayWebhook     (Pub/Sub) — Real-Time Developer
//                                             Notifications for renewals /
//                                             cancellations / refunds.
//   - exports.syncExpiredPlayPremium (cron)  — safety net: revoke Play
//                                             premium after stored expiry
//                                             in case RTDN missed an event.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const playBilling = require('../play_billing');

const GOOGLE_PLAY_SERVICE_ACCOUNT = defineSecret('GOOGLE_PLAY_SERVICE_ACCOUNT');

function handleCors(req, res) {
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.status(204).send('');
    return true;
  }
  return false;
}

function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
}

// ---------------------------------------------------------------------------
// verifyPlayPurchase — Dart calls this right after a successful purchase.
// ---------------------------------------------------------------------------

exports.verifyPlayPurchase = onRequest(
  { cors: true, secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT], timeoutSeconds: 30 },
  async (req, res) => {
    if (handleCors(req, res)) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const { purchaseToken, productId, packageName } = req.body || {};

      if (!purchaseToken || !productId) {
        setCors(res);
        res.status(400).json({ verified: false, error: 'Missing purchaseToken or productId' });
        return;
      }

      if (!playBilling.PREMIUM_PRODUCT_IDS.has(productId)) {
        setCors(res);
        res.status(400).json({ verified: false, error: 'Unknown productId' });
        return;
      }

      const androidPublisher = playBilling.getAndroidPublisher(
        GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
      );
      const result = await playBilling.processPlaySubscription(
        admin.firestore(),
        androidPublisher,
        { uid, productId, token: purchaseToken, packageName },
      );

      setCors(res);
      res.json({
        verified: result.entitled === true,
        entitled: result.entitled === true,
        expiryMillis: result.expiryMillis ?? null,
      });
    } catch (error) {
      console.error('Verify Play purchase error:', error);
      setCors(res);
      res.status(500).json({ verified: false, error: error.message });
    }
  },
);

// ---------------------------------------------------------------------------
// redeemPromoCode — atomic transaction (single use per user).
// ---------------------------------------------------------------------------

exports.redeemPromoCode = onRequest(
  { cors: true, timeoutSeconds: 30 },
  async (req, res) => {
    if (handleCors(req, res)) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }
    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const code = (req.body?.code || '').toString().trim().toUpperCase();
      if (!code) {
        setCors(res);
        res.status(400).json({ error: 'الكود مطلوب' });
        return;
      }

      const db = admin.firestore();
      const codeRef = db.collection('promoCodes').doc(code);
      const redemptionRef = db.collection('promoCodes').doc(code).collection('redemptions').doc(uid);

      const result = await db.runTransaction(async (tx) => {
        const codeSnap = await tx.get(codeRef);
        if (!codeSnap.exists) throw new Error('الكود غير موجود');
        const c = codeSnap.data();
        if (c.active === false) throw new Error('الكود مُلغى');
        if (c.expiresAt && c.expiresAt.toDate().getTime() < Date.now()) throw new Error('الكود منتهي الصلاحية');
        if ((c.usedCount || 0) >= (c.maxUses || 0)) throw new Error('الكود استُهلك بالكامل');

        const exist = await tx.get(redemptionRef);
        if (exist.exists) throw new Error('استخدمتِ هذا الكود مسبقاً');

        const days = c.days || 7;
        const userRef = db.collection('users').doc(uid);
        const userSnap = await tx.get(userRef);
        const u = userSnap.data() || {};
        const now = new Date();
        const currentExpiry = u.premiumExpiry?.toDate?.() || (u.isPremium ? null : now);
        const base = currentExpiry && currentExpiry.getTime() > now.getTime() ? currentExpiry : now;
        const newExpiry = new Date(base.getTime() + days * 24 * 3600 * 1000);

        tx.update(codeRef, {
          usedCount: admin.firestore.FieldValue.increment(1),
        });
        tx.set(redemptionRef, {
          uid,
          redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        tx.set(userRef, {
          isPremium: true,
          premiumSince: u.premiumSince || new Date().toISOString(),
          premiumExpiry: admin.firestore.Timestamp.fromDate(newExpiry),
          premiumSource: 'promo',
          lastPromoCode: code,
        }, { merge: true });

        return { days, newExpiry: newExpiry.toISOString() };
      });

      setCors(res);
      res.json({ ok: true, ...result });
    } catch (e) {
      console.error('redeemPromoCode error:', e);
      setCors(res);
      res.status(400).json({ error: e.message || 'فشل استخدام الكود' });
    }
  },
);

// ---------------------------------------------------------------------------
// googlePlayWebhook — Real-Time Developer Notifications from Pub/Sub.
// Configure in Play Console → Monetize → Monetization setup → RTDN topic,
// then create a Pub/Sub push subscription to this function URL.
// ---------------------------------------------------------------------------

exports.googlePlayWebhook = onRequest(
  { cors: false, secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT], timeoutSeconds: 60 },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    try {
      const envelope = playBilling.decodePubSubBody(req.body);
      if (!envelope) {
        console.warn('googlePlayWebhook: unrecognised body');
        res.status(400).json({ ok: false, error: 'Invalid Pub/Sub payload' });
        return;
      }

      const androidPublisher = playBilling.getAndroidPublisher(
        GOOGLE_PLAY_SERVICE_ACCOUNT.value(),
      );
      const result = await playBilling.handleRtdnMessage(
        admin.firestore(),
        androidPublisher,
        envelope,
      );

      // Pub/Sub expects 2xx so the message is not retried forever.
      res.status(200).json(result);
    } catch (error) {
      console.error('googlePlayWebhook error:', error);
      res.status(500).json({ ok: false, error: error.message });
    }
  },
);

// ---------------------------------------------------------------------------
// syncExpiredPlayPremium — safety net (renewals normally update expiry via RTDN).
// ---------------------------------------------------------------------------

exports.syncExpiredPlayPremium = onSchedule(
  { schedule: 'every 24 hours', secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT], timeZone: 'UTC' },
  async () => {
    const result = await playBilling.revokeExpiredPlayPremium(admin.firestore());
    console.log('syncExpiredPlayPremium:', result);
  },
);