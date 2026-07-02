// ============================================================================
// endpoints/reprocessModeration.js — re-run AI moderation on stuck content.
// ----------------------------------------------------------------------------
// When the on-device moderation path (Direct Gemini → Firebase AI → Cloud
// Function fallback) fails for a user, posts and comments are left in
// `moderationStatus: 'pending_review'`. Admins can hit this endpoint to
// drain the backlog and either approve or reject each piece.
//
// Why not a Firestore trigger instead?
//   Triggers fire once. This endpoint is manual, idempotent, and lets the
//   admin see exactly how many items were processed.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { moderateContent } = require('../lib/moderation');
const { verifyCallerIsAdmin } = require('../lib/adminAuth');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

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

async function applyModerationResult(ref, text, kind) {
  if (text.length < 3) {
    await ref.update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'reprocess_short',
    });
    return 'approved';
  }

  const result = await moderateContent(GEMINI_API_KEY.value(), text);
  if (result.approved) {
    await ref.update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'reprocess_ai',
    });
    return 'approved';
  }

  await ref.update({
    moderationStatus: 'rejected',
    hidden: true,
    moderationReason: result.reason || 'Content not allowed.',
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderationReviewedBy: 'reprocess_ai',
  });
  console.log(`Rejected ${kind} ${ref.path}: ${result.reason}`);
  return 'rejected';
}

exports.reprocessPendingModeration = onRequest(
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 120 },
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
      if (!(await verifyCallerIsAdmin(decoded))) {
        setCors(res);
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      const postsSnap = await admin.firestore()
        .collectionGroup('posts')
        .where('moderationStatus', '==', 'pending_review')
        .limit(40)
        .get();

      const commentsSnap = await admin.firestore()
        .collectionGroup('comments')
        .where('moderationStatus', '==', 'pending_review')
        .limit(40)
        .get();

      let postsProcessed = 0;
      let commentsProcessed = 0;

      for (const docSnap of postsSnap.docs) {
        const text = docSnap.data().text || '';
        await applyModerationResult(docSnap.ref, text, 'post');
        postsProcessed += 1;
      }

      for (const docSnap of commentsSnap.docs) {
        const text = docSnap.data().text || '';
        await applyModerationResult(docSnap.ref, text, 'comment');
        commentsProcessed += 1;
      }

      setCors(res);
      res.json({ postsProcessed, commentsProcessed });
    } catch (error) {
      console.error('reprocessPendingModeration error:', error);
      setCors(res);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: 'Failed to reprocess pending moderation.' });
    }
  },
);