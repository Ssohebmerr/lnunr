// ============================================================================
// triggers/communityNotifications.js — community activity → inbox + FCM push.
// ----------------------------------------------------------------------------
// The client reads `users/{uid}/communityInbox` (see CommunityInboxItem in
// the app) and shows an unread badge on the community hero header. Nothing
// wrote to that collection before this file existed, so the Activity screen
// was always empty.
//
//   - onCommentPublished  comments/{id} create with status approved: the
//                         common path — most comments pass moderation inline
//                         and are created already approved, so the update
//                         trigger below never fires for them.
//   - onCommentApproved   comments/{id} update  pending_review → approved:
//                         held comments released by moderation. Both comment
//                         triggers share notifyCommentRecipients: post author
//                         (`comment`), parent comment author (`reply`), and
//                         any `mentions` uids (`mention`).
//   - onPostLiked         likes/{uid} create: notifies the post author
//                         (`like`). Likes are not moderated, so create is
//                         the right hook.
//   - onUserFollowed      users/{follower}/following/{followed} create:
//                         notifies the followed user (`follow`).
//
// Push body is language-neutral (alias + content preview) because the user's
// UI language is a device-local preference that is not mirrored to Firestore.
// ============================================================================

'use strict';

const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentDeleted,
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
// Shared comment fan-out: reply → parent author, comment → post author,
// mention → each uid the endpoint validated into `mentions`.
// ---------------------------------------------------------------------------
async function notifyCommentRecipients(comment, communityId, postId) {
  const commentAuthor = comment.authorUid;
  const fromAlias = comment.authorAlias || 'Someone';
  const body = preview(comment.text);
  const db = admin.firestore();

  const postSnap = await db
    .collection('communities').doc(communityId)
    .collection('posts').doc(postId)
    .get();
  const postAuthor = postSnap.data()?.authorUid;

  const notified = new Set([commentAuthor]);

  // Threaded reply → parent comment author first (more specific signal).
  if (comment.parentCommentId) {
    const parentSnap = await db
      .collection('communities').doc(communityId)
      .collection('posts').doc(postId)
      .collection('comments').doc(comment.parentCommentId)
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
    notified.add(postAuthor);
    await notify(postAuthor, {
      type: 'comment',
      fromAlias,
      body,
      communityId,
      postId,
    });
  }

  if (Array.isArray(comment.mentions)) {
    for (const mentionUid of comment.mentions) {
      if (typeof mentionUid !== 'string' || notified.has(mentionUid)) continue;
      notified.add(mentionUid);
      await notify(mentionUid, {
        type: 'mention',
        fromAlias,
        body,
        communityId,
        postId,
      });
    }
  }
}

// ---------------------------------------------------------------------------
// Top-comment preview: the feed's post cards show the latest approved
// top-level comment inline (denormalised onto the post doc) so the feed
// feels alive without N extra reads per card.
// ---------------------------------------------------------------------------
function postRef(communityId, postId) {
  return admin.firestore()
    .collection('communities').doc(communityId)
    .collection('posts').doc(postId);
}

async function setTopComment(communityId, postId, commentId, comment) {
  if (comment.parentCommentId) return; // replies never headline a card
  try {
    await postRef(communityId, postId).update({
      topComment: {
        commentId,
        alias: comment.authorAlias || 'Someone',
        preview: preview(comment.text),
        avatarIndex: comment.authorAvatarIndex || 0,
      },
    });
  } catch (e) {
    console.warn(`topComment update failed for ${postId}: ${e.message}`);
  }
}

// ---------------------------------------------------------------------------
// onCommentPublished — comment created already approved (the common case:
// inline moderation passed, so no pending_review → approved update ever
// fires for it).
// ---------------------------------------------------------------------------
exports.onCommentPublished = onDocumentCreated(
  'communities/{communityId}/posts/{postId}/comments/{commentId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if ((data.moderationStatus || 'approved') !== 'approved') return;

    const { communityId, postId, commentId } = event.params;
    await setTopComment(communityId, postId, commentId, data);
    await notifyCommentRecipients(data, communityId, postId);
  },
);

// ---------------------------------------------------------------------------
// onCommentDeleted — if the deleted comment was the card preview, promote the
// latest remaining approved top-level comment (or clear the preview).
// ---------------------------------------------------------------------------
exports.onCommentDeleted = onDocumentDeleted(
  'communities/{communityId}/posts/{postId}/comments/{commentId}',
  async (event) => {
    const { communityId, postId, commentId } = event.params;
    const ref = postRef(communityId, postId);

    try {
      const postSnap = await ref.get();
      if (!postSnap.exists) return;
      if (postSnap.data()?.topComment?.commentId !== commentId) return;

      const remaining = await ref.collection('comments')
        .orderBy('createdAt', 'desc')
        .limit(25)
        .get();
      const next = remaining.docs.find((d) => {
        const c = d.data();
        return !c.parentCommentId
          && (c.moderationStatus || 'approved') === 'approved'
          && c.hidden !== true;
      });

      if (next) {
        await setTopComment(communityId, postId, next.id, next.data());
      } else {
        await ref.update({
          topComment: admin.firestore.FieldValue.delete(),
        });
      }
    } catch (e) {
      console.warn(`topComment cleanup failed for ${postId}: ${e.message}`);
    }
  },
);

// ---------------------------------------------------------------------------
// onCommentApproved — held comment passed moderation → notify recipients.
// ---------------------------------------------------------------------------
exports.onCommentApproved = onDocumentUpdated(
  'communities/{communityId}/posts/{postId}/comments/{commentId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    // Created-approved (or legacy status-less) comments were already
    // notified by onCommentPublished — only a real pending_review →
    // approved release should notify here.
    if ((before.moderationStatus || 'approved') === 'approved') return;
    if (after.moderationStatus !== 'approved') return;

    const { communityId, postId, commentId } = event.params;
    await setTopComment(communityId, postId, commentId, after);
    await notifyCommentRecipients(after, communityId, postId);
  },
);

// ---------------------------------------------------------------------------
// onUserFollowed — someone added a member to their following list.
// ---------------------------------------------------------------------------
exports.onUserFollowed = onDocumentCreated(
  'users/{followerUid}/following/{followedUid}',
  async (event) => {
    const { followerUid, followedUid } = event.params;
    if (followerUid === followedUid) return;

    const db = admin.firestore();
    const followerSnap = await db.collection('users').doc(followerUid).get();
    const fromAlias = followerSnap.data()?.communityAlias || 'Someone';

    await notify(followedUid, {
      type: 'follow',
      fromAlias,
      body: '',
      communityId: '',
      postId: '',
    });
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

// ---------------------------------------------------------------------------
// Comment-like aggregates — keeps "most liked" sorting to one comment query
// instead of one count request per comment. Transactions make rapid likes and
// unlikes safe, while existing comments are initialized on their next change.
// ---------------------------------------------------------------------------
async function adjustCommentLikeCount(event, delta) {
  const { communityId, postId, commentId } = event.params;
  const ref = admin.firestore()
    .collection('communities').doc(communityId)
    .collection('posts').doc(postId)
    .collection('comments').doc(commentId);

  let legacy = false;
  await admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    if (!Number.isFinite(snap.data()?.likeCount)) {
      legacy = true;
      return;
    }
    const current = Number(snap.data()?.likeCount) || 0;
    tx.update(ref, { likeCount: Math.max(0, current + delta) });
  });
  if (legacy) {
    const aggregate = await ref.collection('likes').count().get();
    await ref.update({ likeCount: aggregate.data().count || 0 });
  }
}

exports.onCommentLiked = onDocumentCreated(
  'communities/{communityId}/posts/{postId}/comments/{commentId}/likes/{likeUid}',
  (event) => adjustCommentLikeCount(event, 1),
);

exports.onCommentUnliked = onDocumentDeleted(
  'communities/{communityId}/posts/{postId}/comments/{commentId}/likes/{likeUid}',
  (event) => adjustCommentLikeCount(event, -1),
);
