// ============================================================================
// triggers/moderationTriggers.js — Firestore triggers for content moderation.
// ----------------------------------------------------------------------------
// Backup path when submitCommunity could not auto-approve (AI outage).
// Primary moderation runs synchronously in endpoints/community.js.
// ============================================================================

'use strict';

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { evaluateModeration } = require('../lib/moderation');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

async function applyResult(ref, text, isStory = false) {
  try {
    const decision = await evaluateModeration(GEMINI_API_KEY.value(), text);

    if (isStory) {
      if (decision.reject) {
        await ref.delete();
        console.log(`Rejected & deleted story: ${decision.reason}`);
      } else {
        console.log(`Story approved: ${ref.path}`);
      }
      return;
    }

    if (decision.moderationStatus === 'pending_review') {
      console.log(`Keeping pending review: ${ref.path}`);
      return;
    }

    if (decision.moderationStatus === 'approved') {
      await ref.update({
        moderationStatus: 'approved',
        moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationReviewedBy: decision.reviewedBy || 'auto_ai',
      });
      console.log(`Auto-approved: ${ref.path}`);
      return;
    }

    await ref.update({
      moderationStatus: 'rejected',
      hidden: true,
      moderationReason: decision.reason || 'Content not allowed.',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'auto_ai',
    });
    console.log(`Rejected: ${ref.path}: ${decision.reason}`);
  } catch (error) {
    console.error(`Moderation trigger failed for ${ref.path}:`, error);
  }
}

exports.onStoryCreated = onDocumentCreated(
  {
    document: 'communities/{communityId}/stories/{storyId}',
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const text = data.textOverlay || '';
    if (text.length < 3) return;

    await applyResult(event.data.ref, text, /* isStory */ true);
  },
);

exports.onPostCreated = onDocumentCreated(
  {
    document: 'communities/{communityId}/posts/{postId}',
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.moderationStatus !== 'pending_review') return;

    await applyResult(event.data.ref, data.text || '', /* isStory */ false);
  },
);

exports.onCommentCreated = onDocumentCreated(
  {
    document: 'communities/{communityId}/posts/{postId}/comments/{commentId}',
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const data = event.data?.data();
    if (!data || data.moderationStatus !== 'pending_review') return;

    await applyResult(event.data.ref, data.text || '', /* isStory */ false);
  },
);

exports.onReportCreated = onDocumentCreated(
  'communityReports/{reportId}',
  async (event) => {
    const data = event.data?.data();
    if (!data?.postId || !data?.communityId) return;

    const reports = await admin.firestore()
      .collection('communityReports')
      .where('communityId', '==', data.communityId)
      .where('postId', '==', data.postId)
      .get();

    const sameTarget = reports.docs.filter((doc) => {
      const report = doc.data();
      return report.status === 'pending' &&
        (report.commentId || null) === (data.commentId || null);
    });
    const uniqueReporters = new Set(
      sameTarget.map((doc) => doc.data().reporterUid).filter(Boolean),
    );

    if (uniqueReporters.size >= 3) {
      const postRef = admin.firestore()
        .collection('communities').doc(data.communityId)
        .collection('posts').doc(data.postId);
      const targetRef = data.commentId
        ? postRef.collection('comments').doc(data.commentId)
        : postRef;
      await targetRef
        .update({
          hidden: true,
          moderationStatus: 'pending_review',
          autoHiddenReason: `Auto-hidden: ${uniqueReporters.size} unique reports`,
          autoHiddenAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(
        `Auto-hidden ${data.commentId ? 'comment' : 'post'} ` +
        `${data.commentId || data.postId} (${uniqueReporters.size} reports)`,
      );
    }
  },
);
