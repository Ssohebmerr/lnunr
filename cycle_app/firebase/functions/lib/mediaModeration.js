// Server-side image moderation for community posts and stories.
//
// The cheap first pass is Google Cloud Vision (SafeSearch + labels + OCR).
// Only visually ambiguous images are sent to Gemini Flash-Lite. Uploaded
// objects stay private to their owner until the submission transaction writes
// a matching Firestore approval document that Storage Rules can verify.

'use strict';

const admin = require('firebase-admin');
const { google } = require('googleapis');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const { evaluateModeration } = require('./moderation');
const { GEMINI_MODERATION_SAFETY_SETTINGS } = require('./gemini');

const VISION_TIMEOUT_MS = 7000;
const GEMINI_VISION_TIMEOUT_MS = 7000;
const LIKELIHOOD = Object.freeze({
  UNKNOWN: 0,
  VERY_UNLIKELY: 1,
  UNLIKELY: 2,
  POSSIBLE: 3,
  LIKELY: 4,
  VERY_LIKELY: 5,
});

const IMAGE_PROMPT = `You moderate images for an adults-only women's health community.
Reject images containing pornography or explicit nudity, sexual exploitation,
sexualized minors, graphic violence/self-harm, hate or threats, illegal sales,
scams, promotional/contact solicitation, or exposed highly sensitive personal data.
Allow ordinary women's-health education, pregnancy/ultrasound images, medication
packaging without sales or dosage instructions, period products, breastfeeding
education without sexualization, and non-graphic medical discussion.
Return ONLY JSON: {"approved":true} or
{"approved":false,"reason":"short reason"}.`;

function withTimeout(request, milliseconds, label) {
  let timer;
  return Promise.race([
    request.finally(() => clearTimeout(timer)),
    new Promise((_, reject) => {
      timer = setTimeout(() => reject(new Error(`${label}_timeout`)), milliseconds);
    }),
  ]);
}

function parseFirebaseMediaUrl(value, communityId, uid) {
  try {
    const url = new URL(value);
    if (url.protocol !== 'https:' ||
        url.hostname !== 'firebasestorage.googleapis.com') return null;

    const parts = url.pathname.split('/').filter(Boolean);
    const bucketIndex = parts.indexOf('b');
    const objectIndex = parts.indexOf('o');
    if (bucketIndex < 0 || objectIndex < 0 || !parts[bucketIndex + 1]) return null;

    const bucket = decodeURIComponent(parts[bucketIndex + 1]);
    const objectPath = decodeURIComponent(parts.slice(objectIndex + 1).join('/'));
    const expectedPrefix = `community_media/${communityId}/`;
    if (!objectPath.startsWith(expectedPrefix)) return null;

    const remainder = objectPath.substring(expectedPrefix.length).split('/');
    if (remainder.length !== 2) return null;
    const ownerUid = remainder[0];
    const fileName = remainder[1];
    if (!ownerUid || (uid && ownerUid !== uid)) return null;
    if (!fileName || fileName.includes('/') || !/^[A-Za-z0-9._-]+$/.test(fileName)) {
      return null;
    }
    return {
      bucket,
      objectPath,
      fileName,
      communityId,
      uid: ownerUid,
      gsUri: `gs://${bucket}/${objectPath}`,
    };
  } catch (_) {
    return null;
  }
}

function approvalRef(db, media) {
  return db.collection('communityMediaApprovals').doc(media.communityId)
    .collection('owners').doc(media.uid)
    .collection('files').doc(media.fileName);
}

function likelihood(value) {
  return LIKELIHOOD[value] ?? 0;
}

function classifyVisionSignals(annotation = {}) {
  const safe = annotation.safeSearchAnnotation || {};
  const scores = {
    adult: likelihood(safe.adult),
    racy: likelihood(safe.racy),
    violence: likelihood(safe.violence),
    medical: likelihood(safe.medical),
  };

  if (scores.adult >= LIKELIHOOD.LIKELY ||
      scores.racy >= LIKELIHOOD.VERY_LIKELY) {
    return { reject: true, reason: 'Explicit or sexual image.', scores };
  }
  if (scores.violence >= LIKELIHOOD.VERY_LIKELY) {
    return { reject: true, reason: 'Graphic violent image.', scores };
  }

  const labels = (annotation.labelAnnotations || [])
    .map((item) => String(item.description || '').toLowerCase());
  const suspiciousLabel = labels.some((label) =>
    /nudity|porn|lingerie|underwear|weapon|gore|blood|wound|violence/.test(label),
  );
  const needsContext = scores.adult >= LIKELIHOOD.POSSIBLE ||
    scores.racy >= LIKELIHOOD.POSSIBLE ||
    scores.violence >= LIKELIHOOD.POSSIBLE || suspiciousLabel;

  const detectedText = String(
    annotation.fullTextAnnotation?.text ||
    annotation.textAnnotations?.[0]?.description || '',
  ).trim().substring(0, 2500);
  return { reject: false, needsContext, detectedText, scores };
}

async function annotateWithVision(gsUri) {
  const auth = new google.auth.GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const response = await withTimeout(
    client.request({
      url: 'https://vision.googleapis.com/v1/images:annotate',
      method: 'POST',
      data: {
        requests: [{
          image: { source: { imageUri: gsUri } },
          features: [
            { type: 'SAFE_SEARCH_DETECTION' },
            { type: 'LABEL_DETECTION', maxResults: 12 },
            { type: 'TEXT_DETECTION', maxResults: 5 },
          ],
        }],
      },
    }),
    VISION_TIMEOUT_MS,
    'vision',
  );
  const annotation = response.data?.responses?.[0];
  if (!annotation || annotation.error) {
    throw new Error(annotation?.error?.message || 'vision_empty_response');
  }
  return annotation;
}

function parseGeminiDecision(value) {
  const clean = String(value || '').replace(/```(?:json)?|```/g, '').trim();
  try {
    const parsed = JSON.parse(clean);
    if (parsed.approved === true) return { approved: true };
    if (parsed.approved === false) {
      return {
        approved: false,
        reason: String(parsed.reason || 'Image not allowed.').substring(0, 160),
      };
    }
  } catch (_) {}
  return null;
}

async function classifyAmbiguousImage(geminiApiKey, media, detectedText) {
  const key = String(geminiApiKey || '').trim();
  if (!key) throw new Error('GEMINI_API_KEY is empty');

  const [buffer, metadata] = await Promise.all([
    admin.storage().bucket(media.bucket).file(media.objectPath).download()
      .then(([data]) => data),
    admin.storage().bucket(media.bucket).file(media.objectPath).getMetadata()
      .then(([data]) => data),
  ]);
  const mimeType = metadata.contentType || 'image/jpeg';
  if (!mimeType.startsWith('image/')) throw new Error('unsupported_media_type');

  const genAI = new GoogleGenerativeAI(key);
  let lastError;
  for (const modelName of ['gemini-2.5-flash-lite', 'gemini-2.5-flash']) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelName,
        systemInstruction: IMAGE_PROMPT,
        generationConfig: { maxOutputTokens: 120, temperature: 0.1 },
        safetySettings: GEMINI_MODERATION_SAFETY_SETTINGS,
      });
      const result = await withTimeout(
        model.generateContent([
          { inlineData: { data: buffer.toString('base64'), mimeType } },
          {
            text: detectedText
              ? `OCR text for context:\n${detectedText}`
              : 'Classify this image.',
          },
        ]),
        GEMINI_VISION_TIMEOUT_MS,
        `gemini_vision_${modelName}`,
      );
      const decision = parseGeminiDecision(result.response.text());
      if (decision) return decision;
      lastError = new Error(`${modelName}_unverified`);
    } catch (error) {
      lastError = error;
      console.error(`Visual moderation failed for ${modelName}:`, error);
    }
  }
  throw lastError || new Error('gemini_vision_unavailable');
}

async function moderateCommunityImage(keys, media) {
  // Accept either a `{deepseekKey, geminiKey}` object or a bare Gemini key.
  // OCR text is classified via the DeepSeek-first `evaluateModeration`; the
  // image pixels themselves still need Gemini vision (DeepSeek has no vision).
  const { geminiKey } = typeof keys === 'string' ? { geminiKey: keys } : (keys || {});
  try {
    const annotation = await annotateWithVision(media.gsUri);
    const vision = classifyVisionSignals(annotation);
    if (vision.reject) {
      return { status: 'rejected', reason: vision.reason, scores: vision.scores };
    }

    let textDecision = null;
    if (vision.detectedText.length >= 3) {
      textDecision = await evaluateModeration(keys, vision.detectedText);
      if (textDecision.reject) {
        return {
          status: 'rejected',
          reason: textDecision.reason || 'Text inside image is not allowed.',
          scores: vision.scores,
        };
      }
    }

    if (!vision.needsContext && !textDecision?.pendingReview) {
      return { status: 'approved', provider: 'vision', scores: vision.scores };
    }

    const decision = await classifyAmbiguousImage(
      geminiKey,
      media,
      vision.detectedText,
    );
    if (!decision) throw new Error('gemini_vision_unverified');
    return decision.approved
      ? { status: 'approved', provider: 'vision+gemini', scores: vision.scores }
      : { status: 'rejected', reason: decision.reason, scores: vision.scores };
  } catch (error) {
    console.error(`Image moderation failed for ${media.objectPath}:`, error);
    return { status: 'unavailable', reason: 'Image review temporarily unavailable.' };
  }
}

function approveMedia(batch, db, media, result) {
  batch.set(approvalRef(db, media), {
    approved: true,
    communityId: media.communityId,
    ownerUid: media.uid,
    objectPath: media.objectPath,
    provider: result.provider || 'vision',
    riskScores: result.scores || {},
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function deleteMediaAndApproval(db, media) {
  await Promise.allSettled([
    admin.storage().bucket(media.bucket).file(media.objectPath).delete({ ignoreNotFound: true }),
    approvalRef(db, media).delete(),
  ]);
}

module.exports = {
  parseFirebaseMediaUrl,
  approvalRef,
  classifyVisionSignals,
  moderateCommunityImage,
  approveMedia,
  deleteMediaAndApproval,
};
