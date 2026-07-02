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
// per-user allow-list in `cycle_app/firebase/firestore.rules` — otherwise a
// "delete my data" request will leak data the rules permit reading.
// ============================================================================

'use strict';

const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { verifyCallerIsAdmin } = require('../lib/adminAuth');

const ADMIN_BOOTSTRAP_KEY = defineSecret('ADMIN_BOOTSTRAP_KEY');

// Per-user subcollections covered by deleteUserAccount.
// Keep in sync with `firestore.rules` user subcollection allow-lists.
const USER_SUBCOLLECTIONS_FOR_DELETE = [
  'chats', 'cycle_logs', 'wellness_logs',
  'community_reports', 'community_comments', 'community_likes',
  'backups', 'communityMemberships', 'blockedUsers',
  'savedPosts', 'communityInbox',
];

// ---------------------------------------------------------------------------
// syncUsersFromAuth — backfill users/ from Firebase Auth (admin only).
// ---------------------------------------------------------------------------

exports.syncUsersFromAuth = onRequest(
  { cors: true, timeoutSeconds: 300 },
  async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      res.status(204).send('');
      return;
    }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
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

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ synced });
    } catch (error) {
      console.error('syncUsersFromAuth error:', error);
      res.set('Access-Control-Allow-Origin', '*');
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
    await admin.auth().updateUser(userRecord.uid, { password });
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
  { cors: true, timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      res.status(204).send('');
      return;
    }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const db = admin.firestore();

      // 1. Delete every known per-user subcollection. This list must stay in
      //    sync with the subcollections referenced in firestore.rules so a
      //    "delete my data" request actually removes everything (Play / GDPR).
      const batch = db.batch();
      for (const col of USER_SUBCOLLECTIONS_FOR_DELETE) {
        try {
          const snap = await db.collection('users').doc(uid).collection(col).get();
          snap.docs.forEach(doc => batch.delete(doc.ref));
        } catch (_) {}
      }
      batch.delete(db.collection('users').doc(uid));
      await batch.commit();

      // 2. Best-effort removal of content this user authored across all
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

      // 3. Delete the Auth user last.
      await admin.auth().deleteUser(uid);

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ success: true });
    } catch (error) {
      console.error('Delete account error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired. Please re-authenticate.' });
        return;
      }
      res.status(500).json({ error: 'Failed to delete account.' });
    }
  },
);