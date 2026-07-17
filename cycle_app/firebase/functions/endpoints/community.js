// Server-authoritative community submissions. Client-side validation remains
// for fast feedback, but this endpoint owns the actual post/comment write,
// rate limit, duplicate check, identity fields, and Premium media gate.

'use strict';

const crypto = require('crypto');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

const { guardRequest, setCors, bearerToken } = require('../lib/http');
const { evaluateModeration } = require('../lib/moderation');
const {
  parseFirebaseMediaUrl,
  moderateCommunityImage,
  approveMedia,
  deleteMediaAndApproval,
} = require('../lib/mediaModeration');
const { sanitizePostText, sanitizeCommentText } = require('../lib/text_sanitize');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

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
    const countKey = type === 'post'
      ? 'serverPostCount'
      : type === 'comment'
        ? 'serverCommentCount'
        : 'serverStoryCount';
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
      serverStoryCount: type === 'story'
        ? current + 1
        : (sameHour ? (Number(rate.serverStoryCount) || 0) : 0),
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
  const bodyText = sanitizePostText(body.text);
  const postType = text(body.postType, 20) || 'support';
  if (!communityId || bodyText.length < 3 || !POST_TYPES.has(postType)) {
    throw new CommunitySubmissionError('invalid_post', 400, 'Invalid post.');
  }

  const user = await requireParticipant(db, uid, communityId);
  const anonymous = body.isAnonymous === true;
  const mediaUrl = text(body.mediaUrl, 2000) || null;
  const mediaType = text(body.mediaType, 12) || null;
  // Designed gradient cover for text posts — free feature, fixed catalogue
  // (mirrors PostCoverStyles in the app). Ignored when media is attached.
  const COVER_STYLES = new Set([
    'berry', 'lavender', 'sunset', 'ocean', 'forest', 'blush',
  ]);
  const coverStyleRaw = text(body.coverStyle, 20) || null;
  const coverStyle =
    coverStyleRaw && COVER_STYLES.has(coverStyleRaw) && !mediaUrl
      ? coverStyleRaw
      : null;
  const media = mediaUrl
    ? parseFirebaseMediaUrl(mediaUrl, communityId, uid)
    : null;
  if ((mediaUrl || mediaType) &&
      (user.isPremium !== true || !mediaUrl ||
        mediaType !== 'image' || !media)) {
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

  // The quota transaction and AI review are independent. Running them
  // together removes one full serial network step from every submission
  // while keeping the same server-authoritative checks and fail-safe result.
  const [, moderation, mediaModeration] = await Promise.all([
    reserveSubmission(db, uid, 'post', bodyText, 10),
    evaluateModeration(GEMINI_API_KEY.value(), bodyText),
    media
      ? moderateCommunityImage(GEMINI_API_KEY.value(), media)
      : Promise.resolve(null),
  ]);
  if (moderation.reject) {
    if (media) await deleteMediaAndApproval(db, media);
    throw new CommunitySubmissionError(
      'content_rejected', 400, moderation.reason || 'Content not allowed.',
    );
  }
  if (mediaModeration?.status === 'rejected') {
    await deleteMediaAndApproval(db, media);
    throw new CommunitySubmissionError(
      'content_rejected', 400,
      mediaModeration.reason || 'Image not allowed.',
    );
  }
  if (mediaModeration?.status === 'unavailable') {
    await deleteMediaAndApproval(db, media);
    throw new CommunitySubmissionError(
      'media_review_unavailable', 503,
      'Image safety review is temporarily unavailable. Please try again.',
    );
  }

  const ref = db.collection('communities').doc(communityId).collection('posts').doc();
  const postPayload = {
    communityId,
    authorAlias: anonymous ? 'Anonymous' : text(user.communityAlias, 100),
    text: bodyText,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    commentCount: 0,
    postType,
    communityName: text(body.communityName, 100) || null,
    authorAvatarIndex: anonymous ? 0 : avatarIndex(user.communityAvatarIndex),
    ...(mediaUrl ? {
      mediaUrl,
      mediaType,
      mediaModerationStatus: 'approved',
    } : {}),
    ...(coverStyle ? { coverStyle } : {}),
    isAnonymous: anonymous,
    authorIsPremium: !anonymous && user.isPremium === true,
    ...(options ? { pollOptions: options } : {}),
    moderationStatus: moderation.moderationStatus,
    contentHash: contentHash(bodyText),
  };
  if (moderation.moderationStatus === 'approved') {
    postPayload.moderationReviewedAt = admin.firestore.FieldValue.serverTimestamp();
    postPayload.moderationReviewedBy = moderation.reviewedBy || 'submit_ai';
  }
  if (!anonymous) {
    postPayload.authorUid = uid;
  }
  const batch = db.batch();
  batch.set(ref, postPayload);
  if (media) approveMedia(batch, db, media, mediaModeration);
  if (anonymous) {
    batch.set(
      db.collection('communityPrivateAuth').doc(communityId)
        .collection('posts').doc(ref.id),
      {
        authorUid: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
    );
  }
  try {
    await batch.commit();
  } catch (error) {
    if (media) await deleteMediaAndApproval(db, media);
    throw error;
  }
  return { id: ref.id, pendingReview: moderation.pendingReview };
}

async function submitComment(db, uid, body) {
  const communityId = text(body.communityId, 80);
  const postId = text(body.postId, 100);
  const bodyText = sanitizeCommentText(body.text);
  if (!communityId || !postId || !bodyText) {
    throw new CommunitySubmissionError('invalid_comment', 400, 'Invalid comment.');
  }

  const user = await requireParticipant(db, uid, communityId);
  const postRef = db.collection('communities').doc(communityId)
    .collection('posts').doc(postId);
  const parentCommentId = text(body.parentCommentId, 100) || null;
  // Mentioned member uids (client resolves @alias → uid from the thread's
  // participants). Capped and self-mentions dropped; only used for inbox
  // notifications, never rendered back.
  const mentions = Array.isArray(body.mentions)
    ? [...new Set(body.mentions.filter((m) =>
        typeof m === 'string' && m.length > 0 && m.length <= 128 && m !== uid,
      ))].slice(0, 5)
    : [];
  const [, moderation] = await Promise.all([
    reserveSubmission(db, uid, 'comment', bodyText, 20),
    evaluateModeration(GEMINI_API_KEY.value(), bodyText),
  ]);
  if (moderation.reject) {
    throw new CommunitySubmissionError(
      'content_rejected', 400, moderation.reason || 'Content not allowed.',
    );
  }

  const commentRef = postRef.collection('comments').doc();
  await db.runTransaction(async (tx) => {
    const post = await tx.get(postRef);
    if (!post.exists || post.data()?.hidden === true ||
        post.data()?.moderationStatus === 'rejected') {
      throw new CommunitySubmissionError(
        'post_unavailable', 404, 'This post is unavailable.',
      );
    }
    const commentPayload = {
      authorUid: uid,
      authorAlias: text(user.communityAlias, 100),
      text: bodyText,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      authorAvatarIndex: avatarIndex(user.communityAvatarIndex),
      authorIsPremium: user.isPremium === true,
      likeCount: 0,
      ...(parentCommentId ? { parentCommentId } : {}),
      ...(mentions.length ? { mentions } : {}),
      moderationStatus: moderation.moderationStatus,
    };
    if (moderation.moderationStatus === 'approved') {
      commentPayload.moderationReviewedAt = admin.firestore.FieldValue.serverTimestamp();
      commentPayload.moderationReviewedBy = moderation.reviewedBy || 'submit_ai';
    }
    tx.set(commentRef, commentPayload);
    tx.update(postRef, {
      commentCount: (Number(post.data()?.commentCount) || 0) + 1,
    });
  });
  return { id: commentRef.id, pendingReview: moderation.pendingReview };
}

async function submitStory(db, uid, body) {
  const communityId = text(body.communityId, 80);
  if (!communityId) {
    throw new CommunitySubmissionError('invalid_story', 400, 'Invalid story.');
  }

  const user = await requireParticipant(db, uid, communityId);
  const mediaType = text(body.mediaType, 12) || 'text';
  const mediaUrl = text(body.mediaUrl, 2000) || '';
  const textOverlay = text(body.textOverlay, 500) || null;
  const backgroundColor = text(body.backgroundColor, 40) || null;

  const media = mediaType === 'image'
    ? parseFirebaseMediaUrl(mediaUrl, communityId, uid)
    : null;
  if (mediaType === 'image') {
    if (user.isPremium !== true || !mediaUrl || !media) {
      throw new CommunitySubmissionError(
        'media_premium_required', 403, 'Story media is unavailable.',
      );
    }
  } else if (mediaType !== 'text' || mediaUrl) {
    throw new CommunitySubmissionError('invalid_story', 400, 'Invalid story media.');
  }

  const fingerprint = mediaUrl || textOverlay || 'text-story';
  const [, textModeration, mediaModeration] = await Promise.all([
    reserveSubmission(db, uid, 'story', fingerprint, 5),
    evaluateModeration(GEMINI_API_KEY.value(), textOverlay || ''),
    media
      ? moderateCommunityImage(GEMINI_API_KEY.value(), media)
      : Promise.resolve(null),
  ]);
  if (textModeration.reject || mediaModeration?.status === 'rejected') {
    if (media) await deleteMediaAndApproval(db, media);
    throw new CommunitySubmissionError(
      'content_rejected', 400,
      textModeration.reject
        ? (textModeration.reason || 'Story text not allowed.')
        : (mediaModeration.reason || 'Image not allowed.'),
    );
  }
  if (textModeration.pendingReview || mediaModeration?.status === 'unavailable') {
    if (media) await deleteMediaAndApproval(db, media);
    throw new CommunitySubmissionError(
      'media_review_unavailable', 503,
      'Safety review is temporarily unavailable. Please try again.',
    );
  }

  const ref = db.collection('communities').doc(communityId).collection('stories').doc();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
  const batch = db.batch();
  batch.set(ref, {
    communityId,
    authorUid: uid,
    authorAlias: text(user.communityAlias, 100),
    mediaUrl,
    mediaType,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    authorAvatarIndex: avatarIndex(user.communityAvatarIndex),
    ...(textOverlay ? { textOverlay } : {}),
    ...(backgroundColor ? { backgroundColor } : {}),
    viewCount: 0,
    moderationStatus: 'approved',
    moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderationReviewedBy: media ? (mediaModeration.provider || 'vision') :
      (textModeration.reviewedBy || 'auto_short'),
  });
  if (media) approveMedia(batch, db, media, mediaModeration);
  try {
    await batch.commit();
  } catch (error) {
    if (media) await deleteMediaAndApproval(db, media);
    throw error;
  }
  return { id: ref.id };
}

exports.submitCommunity = onRequest(
  {
    cors: true,
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 45,
    memory: '512MiB',
  },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'community', appCheck: 'required' }))) return;
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
      } else if (action === 'story') {
        result = await submitStory(admin.firestore(), decoded.uid, req.body || {});
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
