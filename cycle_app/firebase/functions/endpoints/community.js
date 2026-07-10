// Server-authoritative community submissions. Client-side validation remains
// for fast feedback, but this endpoint owns the actual post/comment write,
// rate limit, duplicate check, identity fields, and Premium media gate.

'use strict';

const crypto = require('crypto');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const { handleCors, setCors, bearerToken } = require('../lib/http');

const POST_TYPES = new Set([
  'support', 'question', 'tip', 'vent', 'milestone', 'poll',
]);
const DUPLICATE_MS = 5 * 60 * 1000;

class CommunitySubmissionError extends Error {
  constructor(code, status, message) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

function text(value, max) {
  return typeof value === 'string' ? value.trim().substring(0, max) : '';
}

function avatarIndex(value) {
  const number = Number(value);
  return Number.isInteger(number) && number >= 0 && number <= 99 ? number : 0;
}

function contentHash(value) {
  return crypto.createHash('sha256').update(value.toLowerCase()).digest('hex')
    .substring(0, 16);
}

function hourKey(now) {
  return now.toISOString().slice(0, 13);
}

function pollOptions(value) {
  if (!Array.isArray(value)) return null;
  const options = value.map((item) => text(item, 100)).filter(Boolean).slice(0, 4);
  if (options.length < 2) return null;
  const unique = new Set(options.map((item) => item.toLowerCase()));
  return unique.size === options.length ? options : null;
}

function isOwnedMediaUrl(value, communityId, uid) {
  try {
    const decoded = decodeURIComponent(value);
    return decoded.startsWith('https://firebasestorage.googleapis.com/') &&
      decoded.includes(`/o/community_media/${communityId}/${uid}/`);
  } catch (_) {
    return false;
  }
}

async function requireParticipant(db, uid, communityId) {
  const userRef = db.collection('users').doc(uid);
  const membershipRef = db.collection('communities').doc(communityId)
    .collection('members').doc(uid);
  const [userSnap, membershipSnap] = await Promise.all([
    userRef.get(),
    membershipRef.get(),
  ]);
  const user = userSnap.data() || {};
  const birthYear = Number(user.communityBirthYear) || 0;
  const age = new Date().getUTCFullYear() - birthYear;

  if (!userSnap.exists || user.communitySetupComplete !== true ||
      !text(user.communityAlias, 100)) {
    throw new CommunitySubmissionError(
      'community_profile_required', 403, 'Community profile required.',
    );
  }
  if (birthYear <= 0 || age < 18) {
    throw new CommunitySubmissionError('community_minor', 403, 'Adults only.');
  }
  if (user.communityBanned === true) {
    throw new CommunitySubmissionError(
      'community_banned', 403, 'Community participation is unavailable.',
    );
  }
  if (!membershipSnap.exists) {
    throw new CommunitySubmissionError(
      'community_membership_required', 403, 'Join this community first.',
    );
  }
  return user;
}

async function reserveSubmission(db, uid, type, bodyText, limit) {
  const now = new Date();
  const rateRef = db.collection('communityRateLimits').doc(uid);
  const hashRef = db.collection('communityContentHashes')
    .doc(`${uid}_${contentHash(bodyText)}`);

  await db.runTransaction(async (tx) => {
    const [rateSnap, hashSnap] = await Promise.all([
      tx.get(rateRef),
      tx.get(hashRef),
    ]);
    const rate = rateSnap.data() || {};
    const previous = hashSnap.data()?.createdAt?.toDate?.();
    if (previous && now.getTime() - previous.getTime() < DUPLICATE_MS) {
      throw new CommunitySubmissionError(
        'duplicate_content', 429,
        'You recently posted similar content. Please wait before posting again.',
      );
    }

    const sameHour = rate.serverHour === hourKey(now);
    const countKey = type === 'post' ? 'serverPostCount' : 'serverCommentCount';
    const current = sameHour ? (Number(rate[countKey]) || 0) : 0;
    if (current >= limit) {
      throw new CommunitySubmissionError(
        'rate_limited', 429, `Too many ${type}s. Please wait before posting again.`,
      );
    }

    tx.set(rateRef, {
      serverHour: hourKey(now),
      serverPostCount: type === 'post'
        ? current + 1
        : (sameHour ? (Number(rate.serverPostCount) || 0) : 0),
      serverCommentCount: type === 'comment'
        ? current + 1
        : (sameHour ? (Number(rate.serverCommentCount) || 0) : 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.set(hashRef, {
      uid,
      hash: contentHash(bodyText),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });
}

async function submitPost(db, uid, body) {
  const communityId = text(body.communityId, 80);
  const bodyText = text(body.text, 2000);
  const postType = text(body.postType, 20) || 'support';
  if (!communityId || bodyText.length < 3 || !POST_TYPES.has(postType)) {
    throw new CommunitySubmissionError('invalid_post', 400, 'Invalid post.');
  }

  const user = await requireParticipant(db, uid, communityId);
  const anonymous = body.isAnonymous === true;
  const mediaUrl = text(body.mediaUrl, 2000) || null;
  const mediaType = text(body.mediaType, 12) || null;
  if ((mediaUrl || mediaType) &&
      (user.isPremium !== true || !mediaUrl ||
        !['image', 'video'].includes(mediaType) ||
        !isOwnedMediaUrl(mediaUrl, communityId, uid))) {
    throw new CommunitySubmissionError(
      'media_premium_required', 403, 'Premium media is unavailable.',
    );
  }
  const options = postType === 'poll' ? pollOptions(body.pollOptions) : null;
  if (postType === 'poll' && !options) {
    throw new CommunitySubmissionError(
      'invalid_poll', 400, 'A poll needs 2–4 unique options.',
    );
  }

  await reserveSubmission(db, uid, 'post', bodyText, 10);
  const ref = db.collection('communities').doc(communityId).collection('posts').doc();
  await ref.set({
    communityId,
    authorUid: uid,
    authorAlias: anonymous ? 'Anonymous' : text(user.communityAlias, 100),
    text: bodyText,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    commentCount: 0,
    postType,
    communityName: text(body.communityName, 100) || null,
    authorAvatarIndex: anonymous ? 0 : avatarIndex(user.communityAvatarIndex),
    ...(mediaUrl ? { mediaUrl, mediaType } : {}),
    isAnonymous: anonymous,
    authorIsPremium: !anonymous && user.isPremium === true,
    ...(options ? { pollOptions: options } : {}),
    moderationStatus: 'pending_review',
    contentHash: contentHash(bodyText),
  });
  return { id: ref.id, pendingReview: true };
}

async function submitComment(db, uid, body) {
  const communityId = text(body.communityId, 80);
  const postId = text(body.postId, 100);
  const bodyText = text(body.text, 1000);
  if (!communityId || !postId || !bodyText) {
    throw new CommunitySubmissionError('invalid_comment', 400, 'Invalid comment.');
  }

  const user = await requireParticipant(db, uid, communityId);
  const postRef = db.collection('communities').doc(communityId)
    .collection('posts').doc(postId);
  const parentCommentId = text(body.parentCommentId, 100) || null;
  await reserveSubmission(db, uid, 'comment', bodyText, 20);

  const commentRef = postRef.collection('comments').doc();
  await db.runTransaction(async (tx) => {
    const post = await tx.get(postRef);
    if (!post.exists || post.data()?.hidden === true ||
        post.data()?.moderationStatus === 'rejected') {
      throw new CommunitySubmissionError(
        'post_unavailable', 404, 'This post is unavailable.',
      );
    }
    tx.set(commentRef, {
      authorUid: uid,
      authorAlias: text(user.communityAlias, 100),
      text: bodyText,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      authorAvatarIndex: avatarIndex(user.communityAvatarIndex),
      authorIsPremium: user.isPremium === true,
      ...(parentCommentId ? { parentCommentId } : {}),
      moderationStatus: 'pending_review',
    });
    tx.update(postRef, {
      commentCount: (Number(post.data()?.commentCount) || 0) + 1,
    });
  });
  return { id: commentRef.id, pendingReview: true };
}

exports.submitCommunity = onRequest(
  { cors: true, timeoutSeconds: 30 },
  async (req, res) => {
    if (handleCors(req, res)) return;
    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const action = text(req.body?.action, 20);
      let result;
      if (action === 'post') {
        result = await submitPost(admin.firestore(), decoded.uid, req.body || {});
      } else if (action === 'comment') {
        result = await submitComment(admin.firestore(), decoded.uid, req.body || {});
      } else {
        throw new CommunitySubmissionError('invalid_action', 400, 'Invalid action.');
      }
      setCors(res);
      res.json(result);
    } catch (error) {
      console.error('Community submission error:', error);
      setCors(res);
      if (error instanceof CommunitySubmissionError) {
        res.status(error.status).json({ error: error.code, message: error.message });
        return;
      }
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: 'community_submit_failed' });
    }
  },
);
