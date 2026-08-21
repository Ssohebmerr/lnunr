// ============================================================================
// endpoints/moderate.js — POST /moderate  (server-side moderation fallback).
// ----------------------------------------------------------------------------
// Most moderation now happens through the on-device Gemini path (see
// `core/ai/direct_gemini_service.dart`). This endpoint exists as a fallback
// when the client cannot reach Gemini directly — e.g. when the user's build
// has no API key and the AI gateway falls back to the Cloud Function path.
//
// Behaviour:
//   - Auth required (any signed-in user — moderation is cheap).
//   - Empty / super-short text is auto-approved (matches the
//     `reprocess_short` behaviour used by Firestore triggers).
//   - On any error we fail-OPEN (`approved: true`) so a transient outage
//     doesn't block legitimate users. The Firestore triggers can then
//     re-run via `reprocessPendingModeration`.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { moderateContent } = require('../lib/moderation');
const { guardRequest, setCors } = require('../lib/http');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const DEEPSEEK_API_KEY = defineSecret('DEEPSEEK_API_KEY');

function hourKey(now) {
  return now.toISOString().slice(0, 13);
}

async function reserveModerateSlot(db, uid) {
  const now = new Date();
  const rateRef = db.collection('communityRateLimits').doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(rateRef);
    const rate = snap.data() || {};
    const sameHour = rate.serverHour === hourKey(now);
    const current = sameHour ? (Number(rate.serverModerateCount) || 0) : 0;
    if (current >= 30) {
      const err = new Error('rate_limited');
      err.code = 'rate_limited';
      throw err;
    }
    tx.set(rateRef, {
      serverHour: hourKey(now),
      serverModerateCount: current + 1,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

exports.moderate = onRequest(
  { cors: false, secrets: [GEMINI_API_KEY, DEEPSEEK_API_KEY], timeoutSeconds: 30 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'community', appCheck: 'required' }))) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      await reserveModerateSlot(admin.firestore(), decoded.uid);
      const text = (req.body?.text || '').trim().substring(0, 1000);

      if (!text) {
        setCors(res);
        res.status(400).json({ approved: true });
        return;
      }

      const result = await moderateContent({
        deepseekKey: DEEPSEEK_API_KEY.value(),
        geminiKey: GEMINI_API_KEY.value(),
      }, text);
      setCors(res);
      res.json(result);
    } catch (error) {
      console.error('Moderate error:', error);
      setCors(res);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      if (error.code === 'rate_limited') {
        res.status(429).json({ approved: false, error: 'rate_limited' });
        return;
      }
      res.json({ approved: false, pendingReview: true, reason: 'Moderation unavailable' });
    }
  },
);