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
const { handleCors, setCors } = require('../lib/http');

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

exports.moderate = onRequest(
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 30 },
  async (req, res) => {
    if (handleCors(req, res)) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const text = (req.body?.text || '').trim().substring(0, 1000);

      if (!text) {
        setCors(res);
        res.status(400).json({ approved: true });
        return;
      }

      const result = await moderateContent(GEMINI_API_KEY.value(), text);
      setCors(res);
      res.json(result);
    } catch (error) {
      console.error('Moderate error:', error);
      setCors(res);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.json({ approved: true });
    }
  },
);