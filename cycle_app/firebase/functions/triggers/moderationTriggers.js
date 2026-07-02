// ============================================================================
// triggers/moderationTriggers.js — Firestore triggers for content moderation.
// ----------------------------------------------------------------------------
// Four triggers kept in one file because they share helpers (moderation
// decision, post-rejection update). Each handles a different collection:
//
//   - onStoryCreated     stories/{id}    ephemeral content (24h), rejected
//                                       stories are deleted outright
//   - onPostCreated      posts/{id}       status: pending_review → approved/rejected
//   - onCommentCreated   comments/{id}    same flow as posts
//   - onReportCreated    communityReports/{id}
//                                       if 3+ reports target a post, hide it
//                                       and re-queue for moderation
//
// WHY kept together (instead of one file per trigger):
//   Each trigger is short (~30 lines) and they share the same helper
//   `applyModerationResult`-equivalent logic inline. Splitting them out
//   would create four near-duplicate files with no shared state.
// ============================================================================

'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { moderateContent } = require('../lib/moderation');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

// ---------------------------------------------------------------------------
// Helper — update a community doc with an approved/rejected result.
// ---------------------------------------------------------------------------
async function applyResult(ref, text, isStory = false) {
  const result = await moderateContent(GEMINI_API_KEY.value(), text);
  const communityId = ref.parent.parent?.id;
  const postId = ref.parent.id;
  const docPath = `${communityId ? communityId + '/' : ''}${ref.parent.parent ? ref.parent.parent.id + '/' : ''}${ref.id}`;

  if (isStory) {
    // Stories are ephemeral — reject by deleting outright.
    if (!result.approved) {
      await ref.delete();
      console.log(`Rejected & deleted story: ${result.reason}`);
    } else {
      console.log(`Story approved: ${docPath}`);
    }
    return;
  }

  if (text.length < 3) {
    await ref.update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'auto_short',
    });
    return;
  }

  if (result.approved) {
    await ref.update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'auto_ai',
    });
    console.log(`Auto-approved post ${docPath}`);
  } else {
    await ref.update({
      moderationStatus: 'rejected',
      hidden: true,
      moderationReason: result.reason || 'Content not allowed.',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Rejected post ${docPath}: ${result.reason}`);
  }
}

// ---------------------------------------------------------------------------
// onStoryCreated — ephemeral stories.
// ---------------------------------------------------------------------------
exports.onStoryCreated = onDocumentCreated(
  'communities/{communityId}/stories/{storyId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const text = data.textOverlay || '';
    if (text.length < 3) return;

    await applyResult(event.data.ref, text, /* isStory */ true);
  },
);

// ---------------------------------------------------------------------------
// onPostCreated — community posts (pending_review → approved/rejected).
// ---------------------------------------------------------------------------
exports.onPostCreated = onDocumentCreated(
  'communities/{communityId}/posts/{postId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.moderationStatus !== 'pending_review') return;

    await applyResult(event.data.ref, data.text || '', /* isStory */ false);
  },
);

// ---------------------------------------------------------------------------
// onCommentCreated — comments go through the same flow.
// ---------------------------------------------------------------------------
exports.onCommentCreated = onDocumentCreated(
  'communities/{communityId}/posts/{postId}/comments/{commentId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.moderationStatus !== 'pending_review') return;

    await applyResult(event.data.ref, data.text || '', /* isStory */ false);
  },
);

// ---------------------------------------------------------------------------
// onReportCreated — auto-hide posts with 3+ pending reports.
// ---------------------------------------------------------------------------
exports.onReportCreated = onDocumentCreated(
  'communityReports/{reportId}',
  async (event) => {
    const data = event.data?.data();
    if (!data?.postId || !data?.communityId) return;

    const reports = await admin.firestore()
      .collection('communityReports')
      .where('postId', '==', data.postId)
      .where('status', '==', 'pending')
      .get();

    if (reports.size >= 3) {
      await admin.firestore()
        .collection('communities').doc(data.communityId)
        .collection('posts').doc(data.postId)
        .update({
          hidden: true,
          moderationStatus: 'pending_review',
          autoHiddenReason: `Auto-hidden: ${reports.size} reports`,
          autoHiddenAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(`Auto-hidden post ${data.postId} (${reports.size} reports)`);
    }
  },
);