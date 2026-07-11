// ============================================================================
// scheduled/drainModeration.js — autonomous AI moderation janitor.
// ----------------------------------------------------------------------------
// Runs the AI moderator over anything still sitting in `pending_review` and
// resolves it WITHOUT a human in the loop. This is what lets the community
// scale without a moderation team: the submit path already auto-decides every
// new post, and this job mops up the only remaining `pending_review` sources —
//   1. the one-time backlog left by the old (pre-fix) stranding bug, and
//   2. posts auto-hidden after 3+ user reports (see onReportCreated).
//
// `evaluateModeration` never returns `pending_review` anymore, so every item
// is resolved in a single pass (approved+unhidden, or rejected+hidden). A
// transient Gemini outage just leaves the item for the next run (fail-open on
// submit already published it, so nothing is user-visibly stuck).
// ============================================================================

'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { evaluateModeration } = require('../lib/moderation');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

// Bound the work per run so a large backlog can't blow the timeout or the bill;
// leftovers roll to the next tick.
const BATCH_LIMIT = 40;

async function resolveOne(ref, text, kind) {
  try {
    const decision = await evaluateModeration(GEMINI_API_KEY.value(), text || '');
    if (decision.moderationStatus === 'approved') {
      await ref.update({
        moderationStatus: 'approved',
        hidden: false,
        moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationReviewedBy: decision.reviewedBy || 'auto_ai_drain',
      });
      return 'approved';
    }
    await ref.update({
      moderationStatus: 'rejected',
      hidden: true,
      moderationReason: decision.reason || 'Content not allowed.',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'auto_ai_drain',
    });
    return 'rejected';
  } catch (e) {
    // Leave it pending; the next scheduled run retries.
    console.error(`drainModeration ${kind} ${ref.path} failed:`, e);
    return 'error';
  }
}

exports.drainPendingModeration = onSchedule(
  {
    schedule: 'every 30 minutes',
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 300,
    memory: '256MiB',
  },
  async () => {
    const db = admin.firestore();
    const [postsSnap, commentsSnap] = await Promise.all([
      db.collectionGroup('posts')
        .where('moderationStatus', '==', 'pending_review')
        .limit(BATCH_LIMIT)
        .get(),
      db.collectionGroup('comments')
        .where('moderationStatus', '==', 'pending_review')
        .limit(BATCH_LIMIT)
        .get(),
    ]);

    const tally = { approved: 0, rejected: 0, error: 0 };
    for (const doc of postsSnap.docs) {
      const outcome = await resolveOne(doc.ref, doc.data().text, 'post');
      tally[outcome] += 1;
    }
    for (const doc of commentsSnap.docs) {
      const outcome = await resolveOne(doc.ref, doc.data().text, 'comment');
      tally[outcome] += 1;
    }

    console.log(
      `drainPendingModeration: posts=${postsSnap.size} comments=${commentsSnap.size} ` +
      `→ approved=${tally.approved} rejected=${tally.rejected} errors=${tally.error}`,
    );
  },
);
