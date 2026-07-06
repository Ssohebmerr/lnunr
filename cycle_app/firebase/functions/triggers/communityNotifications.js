// ============================================================================
// triggers/communityNotifications.js — community activity → inbox + FCM push.
// ----------------------------------------------------------------------------
// The client reads `users/{uid}/communityInbox` (see CommunityInboxItem in
// the app) and shows an unread badge on the community hero header. Nothing
// wrote to that collection before this file existed, so the Activity screen
// was always empty.
//
//   - onCommentApproved   comments/{id} update  pending_review → approved:
//                         notifies the post author (`comment`) and, for
//                         threaded replies, the parent comment author
//                         (`reply`). Fires only after moderation approval so
//                         rejected content never generates a notification.
//   - onPostLiked         likes/{uid} create: notifies the post author
//                         (`like`). Likes are not moderated, so create is
//                         the right hook.
//
// Push body is language-neutral (alias + content preview) because the user's
// UI language is a device-local preference that is not mirrored to Firestore.
// ============================================================================

'use strict';

const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

const PREVIEW_LIMIT = 120;

function preview(text) {
  const t = (text || '').trim().replace(/\s+/g, ' ');
  return t.length > PREVIEW_LIMIT ? `${t.slice(0, PREVIEW_LIMIT)}…` : t;
}

/**
 * Writes an inbox item and (best-effort) sends an FCM push.
 * Never throws — notification failures must not fail the trigger.
 */
async function notify(recipientUid, { type, fromAlias, body, communityId, postId }) {
  const db = admin.firestore();
  try {
    await db
      .collection('users').doc(recipientUid)
      .collection('communityInbox')
      .add({
        type,
        fromAlias,
        preview: body,
        communityId,
        postId,
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (e) {
    console.error(`inbox write failed for ${recipientUid}:`, e);
    return;
  }

  try {
    const userSnap = await db.collection('users').doc(recipientUid).get();
    const token = userSnap.data()?.fcmToken;
    if (!token) return;
    await admin.messaging().send({
      token,
      notification: {
        title: fromAlias,
        body: type === 'like' ? `❤️ ${body}` : body,
      },
      data: { kind: 'community', type, communityId, postId },
    });
  } catch (e) {
    // Invalid/expired tokens are expected — inbox item already delivered.
    console.warn(`push skipped for ${recipientUid}: ${e.message}`);
  }
}

// ---------------------------------------------------------------------------
// onCommentApproved — comment passed moderation → notify post/thread authors.
// ---------------------------------------------------------------------------
exports.onCommentApproved = onDocumentUpdated(
  'communities/{communityId}/posts/{postId}/comments/{commentId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.moderationStatus === 'approved') return; // already notified
    if (after.moderationStatus !== 'approved') return;

    const { communityId, postId } = event.params;
    const commentAuthor = after.authorUid;
    const fromAlias = after.authorAlias || 'Someone';
    const body = preview(after.text);
    const db = admin.firestore();

    const postSnap = await db
      .collection('communities').doc(communityId)
      .collection('posts').doc(postId)
      .get();
    const postAuthor = postSnap.data()?.authorUid;

    const notified = new Set([commentAuthor]);

    // Threaded reply → parent comment author first (more specific signal).
    if (after.parentCommentId) {
      const parentSnap = await db
        .collection('communities').doc(communityId)
        .collection('posts').doc(postId)
        .collection('comments').doc(after.parentCommentId)
        .get();
      const parentAuthor = parentSnap.data()?.authorUid;
      if (parentAuthor && !notified.has(parentAuthor)) {
        notified.add(parentAuthor);
        await notify(parentAuthor, {
          type: 'reply',
          fromAlias,
          body,
          communityId,
          postId,
        });
      }
    }

    if (postAuthor && !notified.has(postAuthor)) {
      await notify(postAuthor, {
        type: 'comment',
        fromAlias,
        body,
        communityId,
        postId,
      });
    }
  },
);

// ---------------------------------------------------------------------------
// onPostLiked — first-class “someone appreciated your post” signal.
// ---------------------------------------------------------------------------
exports.onPostLiked = onDocumentCreated(
  'communities/{communityId}/posts/{postId}/likes/{likeUid}',
  async (event) => {
    const { communityId, postId, likeUid } = event.params;
    const db = admin.firestore();

    const postSnap = await db
      .collection('communities').doc(communityId)
      .collection('posts').doc(postId)
      .get();
    const post = postSnap.data();
    if (!post?.authorUid || post.authorUid === likeUid) return;

    // Liker's alias lives on their membership doc for this community.
    const memberSnap = await db
      .collection('communities').doc(communityId)
      .collection('members').doc(likeUid)
      .get();
    const fromAlias = memberSnap.data()?.alias || 'Someone';

    await notify(post.authorUid, {
      type: 'like',
      fromAlias,
      body: preview(post.text),
      communityId,
      postId,
    });
  },
);
