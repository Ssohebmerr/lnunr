// ============================================================================

// endpoints/reprocessModeration.js — re-run AI moderation on stuck content.

// ============================================================================



'use strict';



const { onRequest } = require('firebase-functions/v2/https');

const admin = require('firebase-admin');

const { defineSecret } = require('firebase-functions/params');



const { evaluateModeration } = require('../lib/moderation');

const { verifyCallerIsAdmin } = require('../lib/adminAuth');

const { guardRequest, setCors } = require('../lib/http');



const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

const DEEPSEEK_API_KEY = defineSecret('DEEPSEEK_API_KEY');



async function applyModerationResult(ref, text, kind) {

  const decision = await evaluateModeration({
    deepseekKey: DEEPSEEK_API_KEY.value(),
    geminiKey: GEMINI_API_KEY.value(),
  }, text);



  if (decision.moderationStatus === 'pending_review') {

    console.log(`Still pending after reprocess (${kind}): ${ref.path}`);

    return 'pending';

  }



  if (decision.moderationStatus === 'approved') {

    await ref.update({

      moderationStatus: 'approved',

      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),

      moderationReviewedBy: decision.reviewedBy || 'reprocess_ai',

    });

    return 'approved';

  }



  await ref.update({

    moderationStatus: 'rejected',

    hidden: true,

    moderationReason: decision.reason || 'Content not allowed.',

    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),

    moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),

    moderationReviewedBy: 'reprocess_ai',

  });

  console.log(`Rejected ${kind} ${ref.path}: ${decision.reason}`);

  return 'rejected';

}



exports.reprocessPendingModeration = onRequest(

  { cors: false, secrets: [GEMINI_API_KEY, DEEPSEEK_API_KEY], timeoutSeconds: 120 },

  async (req, res) => {

    if (!(await guardRequest(req, res, { bucket: 'admin', appCheck: 'required' }))) return;



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

      let stillPending = 0;



      for (const docSnap of postsSnap.docs) {

        const text = docSnap.data().text || '';

        const outcome = await applyModerationResult(docSnap.ref, text, 'post');

        postsProcessed += 1;

        if (outcome === 'pending') stillPending += 1;

      }



      for (const docSnap of commentsSnap.docs) {

        const text = docSnap.data().text || '';

        const outcome = await applyModerationResult(docSnap.ref, text, 'comment');

        commentsProcessed += 1;

        if (outcome === 'pending') stillPending += 1;

      }



      setCors(res);

      res.json({ postsProcessed, commentsProcessed, stillPending });

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

