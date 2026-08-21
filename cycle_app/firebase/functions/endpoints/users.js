// ============================================================================
// endpoints/users.js — user lifecycle endpoints.
// ----------------------------------------------------------------------------
// Three endpoints share the same domain (managing `users/{uid}` docs):
//
//   - exports.syncUsersFromAuth       (admin only) — backfill Firestore
//                                       `users/` from Firebase Auth.
//   - exports.bootstrapAdmin          (callable)  — one-time setup of the
//                                       first owner. Gated by a secret
//                                       bootstrap key.
//   - exports.deleteUserAccount       (user)      — GDPR / Play requirement:
//                                       delete all of a user's data and
//                                       their Auth account.
//
// Note: `deleteUserAccount`'s subcollection list must stay in sync with the
// per-user allow-list in `cycle_app/firestore.rules` (the deployed rules
// file, see firebase.json) — otherwise a "delete my data" request will leak
// data the rules permit reading.
// ============================================================================

'use strict';

const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { verifyCallerIsAdmin } = require('../lib/adminAuth');
const { guardRequest, setCors, bearerToken } = require('../lib/http');
const { resolveAiAgeGroup } = require('../lib/ai_eligibility');

const ADMIN_BOOTSTRAP_KEY = defineSecret('ADMIN_BOOTSTRAP_KEY');

// Per-user subcollections covered by deleteUserAccount. Keep in sync with
// `firestore.rules` user subcollection allow-lists.
const USER_SUBCOLLECTIONS_FOR_DELETE = [
  'chats', 'cycle_logs', 'wellness_logs',
  'community_reports', 'community_comments', 'community_likes',
  'backups', 'communityMemberships', 'blockedUsers',
  'savedPosts', 'communityInbox', 'following', 'secure',
];

const DELETE_BATCH_SIZE = 400;

/// Deletes every direct document in a collection in bounded batches. Firestore
/// document deletion does not cascade to subcollections, so callers that own
/// nested data must clear it explicitly before deleting their parent document.
async function deleteDirectDocuments(collectionRef) {
  while (true) {
    const snap = await collectionRef.limit(DELETE_BATCH_SIZE).get();
    if (snap.empty) return;
    const batch = admin.firestore().batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    if (snap.size < DELETE_BATCH_SIZE) return;
  }
}

async function deleteUserChats(db, uid) {
  const chatsRef = db.collection('users').doc(uid).collection('chats');
  const chats = await chatsRef.get();
  for (const chat of chats.docs) {
    await deleteDirectDocuments(chat.ref.collection('messages'));
    await chat.ref.delete();
  }
}

async function deleteAiUsageData(db, uid) {
  const usageRef = db.collection('ai_usage').doc(uid);
  await deleteDirectDocuments(usageRef.collection('messages'));
  await usageRef.delete().catch((error) => {
    if (error.code !== 5) throw error;
  });
}

async function deleteUserAiData(db, uid) {
  const userRef = db.collection('users').doc(uid);
  await Promise.all([
    deleteUserChats(db, uid),
    deleteAiUsageData(db, uid),
  ]);
  await userRef.set({
    aiMemory: admin.firestore.FieldValue.delete(),
    aiConsentGranted: false,
    aiConsentVersion: admin.firestore.FieldValue.delete(),
    aiEligibilityUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}


// ---------------------------------------------------------------------------
// syncUsersFromAuth — backfill users/ from Firebase Auth (admin only).
// ---------------------------------------------------------------------------

exports.syncUsersFromAuth = onRequest(
  { cors: false, timeoutSeconds: 300 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'admin', appCheck: 'required' }))) return;

    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      if (!(await verifyCallerIsAdmin(decoded))) {
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      let synced = 0;
      let nextPageToken;
      do {
        const result = await admin.auth().listUsers(1000, nextPageToken);
        let batch = admin.firestore().batch();
        let ops = 0;

        for (const user of result.users) {
          batch.set(
            admin.firestore().collection('users').doc(user.uid),
            {
              email: user.email || null,
              ...(user.displayName ? { name: user.displayName } : {}),
              authProviders: user.providerData.map((p) => p.providerId).join(','),
              authCreatedAt: user.metadata.creationTime || null,
              authLastSignInAt: user.metadata.lastSignInTime || null,
              syncedFromAuthAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          ops += 1;
          synced += 1;
          if (ops >= 400) {
            await batch.commit();
            batch = admin.firestore().batch();
            ops = 0;
          }
        }

        if (ops > 0) await batch.commit();
        nextPageToken = result.pageToken;
      } while (nextPageToken);

      setCors(res, req);
      res.json({ synced });
    } catch (error) {
      console.error('syncUsersFromAuth error:', error);
      setCors(res, req);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: 'Failed to sync users from Auth.' });
    }
  },
);

// ---------------------------------------------------------------------------
// bootstrapAdmin — one-time setup of the first owner.
// ---------------------------------------------------------------------------

exports.bootstrapAdmin = onCall({ secrets: [ADMIN_BOOTSTRAP_KEY] }, async (request) => {
  // Accept both 'key' and 'bootstrapKey' for backward compatibility.
  const key = request.data?.key || request.data?.bootstrapKey;
  if (!key || key !== ADMIN_BOOTSTRAP_KEY.value()) {
    throw new HttpsError('permission-denied', 'Invalid bootstrap key.');
  }

  const email = request.data?.email;
  const password = request.data?.password;

  if (!email || !password) {
    throw new HttpsError('invalid-argument', 'Email and password required.');
  }

  const existingAdmins = await admin.firestore().collection('admins').limit(1).get();
  if (!existingAdmins.empty) {
    throw new HttpsError(
      'failed-precondition',
      'Bootstrap already completed. Use the admin panel to add admins.',
    );
  }

  let userRecord;
  let isNewUser = false;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      userRecord = await admin.auth().createUser({ email, password, emailVerified: true });
      isNewUser = true;
    } else {
      throw e;
    }
  }

  if (!isNewUser) {
    throw new HttpsError(
      'already-exists',
      'Email already registered. Bootstrap only creates a new owner account.',
    );
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });

  // Write to BOTH 'users' and 'admins' collections (app reads from 'admins').
  const batch = admin.firestore().batch();

  batch.set(admin.firestore().collection('users').doc(userRecord.uid), {
    email: email,
    role: 'admin',
    isAdmin: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  batch.set(admin.firestore().collection('admins').doc(userRecord.uid), {
    email: email,
    role: 'admin',
    isAdmin: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await batch.commit();

  return { uid: userRecord.uid, email: email, role: 'admin' };
});

// ---------------------------------------------------------------------------
// deleteUserAccount — GDPR / Play requirement.
// ---------------------------------------------------------------------------

exports.deleteUserAccount = onRequest(
  { cors: false, timeoutSeconds: 120 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'auth_heavy', appCheck: 'required' }))) return;
    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const uid = decoded.uid;
      const db = admin.firestore();
      const userRef = db.collection('users').doc(uid);

      // 1. Remove AI data first. Chats contain a nested `messages`
      //    collection and audit data is deliberately outside users/{uid}.
      await deleteUserAiData(db, uid);

      // 2. Delete every other known direct user subcollection in batches.
      for (const col of USER_SUBCOLLECTIONS_FOR_DELETE) {
        if (col === 'chats') continue;
        await deleteDirectDocuments(userRef.collection(col));
      }
      await userRef.delete();

      // 3. Best-effort removal of content this user authored across all
      //    communities (posts, comments, stories) via collection-group queries.
      for (const group of ['posts', 'comments', 'stories']) {
        try {
          let authored = await db.collectionGroup(group)
            .where('authorUid', '==', uid)
            .limit(400)
            .get();
          while (!authored.empty) {
            const b = db.batch();
            authored.docs.forEach(doc => b.delete(doc.ref));
            await b.commit();
            if (authored.size < 400) break;
            authored = await db.collectionGroup(group)
              .where('authorUid', '==', uid)
              .limit(400)
              .get();
          }
        } catch (e) {
          console.error(`deleteUserAccount: ${group} cleanup failed:`, e);
        }
      }

      // 4. Delete the Auth user last.
      await admin.auth().deleteUser(uid);

      setCors(res, req);
      res.json({ success: true });
    } catch (error) {
      console.error('Delete account error:', error);
      setCors(res, req);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired. Please re-authenticate.' });
        return;
      }
      res.status(500).json({ error: 'Failed to delete account.' });
    }
  },
);

// ---------------------------------------------------------------------------
// purgeAiData — revoke optional AI consent without deleting the account.
// Clears chat history, long-term AI memory, and metadata-only usage records.
// ---------------------------------------------------------------------------

exports.purgeAiData = onRequest(
  { cors: false, timeoutSeconds: 120 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'auth_heavy', appCheck: 'required' }))) return;
    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      await deleteUserAiData(admin.firestore(), decoded.uid);
      setCors(res, req);
      res.json({ success: true });
    } catch (error) {
      console.error('Purge AI data error:', error);
      setCors(res, req);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired. Please re-authenticate.' });
        return;
      }
      res.status(500).json({ error: 'Failed to purge AI data.' });
    }
  },
);

// ---------------------------------------------------------------------------
// syncAiEligibility — trusted write of age/consent fields (Admin SDK).
// Client Firestore writes to these fields are denied by rules.
// ---------------------------------------------------------------------------

exports.syncAiEligibility = onRequest(
  { cors: false, timeoutSeconds: 30 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'auth_heavy', appCheck: 'required' }))) return;
    if (req.method !== 'POST') {
      setCors(res, req);
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const consentGranted = req.body?.consentGranted === true;
      const declaredAgeGroup =
        typeof req.body?.declaredAgeGroup === 'string'
          ? req.body.declaredAgeGroup
          : undefined;

      const userRef = admin.firestore().collection('users').doc(decoded.uid);
      const snap = await userRef.get();
      const existing = snap.exists ? (snap.data() || {}) : {};
      const aiAgeGroup = resolveAiAgeGroup(existing, declaredAgeGroup);

      await userRef.set({
        aiConsentGranted: consentGranted,
        aiConsentVersion: 1,
        aiAgeGroup,
        aiEligibilityUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      setCors(res, req);
      res.json({ success: true, aiAgeGroup, aiConsentGranted: consentGranted });
    } catch (error) {
      console.error('syncAiEligibility error:', error);
      setCors(res, req);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired. Please re-authenticate.' });
        return;
      }
      res.status(500).json({ error: 'Failed to sync AI eligibility.' });
    }
  },
);
