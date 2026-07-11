// ============================================================================
// endpoints/feedback.js — POST /submitFeedback.
// ----------------------------------------------------------------------------
// App submits structured feedback (bug / idea / help / other) with app
// version + platform. Admin panel reads via the `replyToFeedback` action
// in adminApi.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { guardRequest, setCors } = require('../lib/http');

const ALLOWED_FEEDBACK_TYPES = ['bug', 'idea', 'help', 'other'];

exports.submitFeedback = onRequest(
  { cors: true, timeoutSeconds: 20 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'feedback', appCheck: 'required' }))) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }
    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const message = (req.body?.message || '').toString().trim().substring(0, 2000);
      const type = ALLOWED_FEEDBACK_TYPES.includes(req.body?.type) ? req.body.type : 'other';
      const appVersion = (req.body?.appVersion || '').toString().substring(0, 32);
      const platform = (req.body?.platform || '').toString().substring(0, 32);
      if (!message || message.length < 5) {
        setCors(res);
        res.status(400).json({ error: 'الرسالة قصيرة جداً' });
        return;
      }

      await admin.firestore().collection('feedback').add({
        uid,
        email: decoded.email || null,
        type, message, appVersion, platform,
        status: 'new',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      setCors(res);
      res.json({ ok: true });
    } catch (e) {
      console.error('submitFeedback error:', e);
      setCors(res);
      res.status(500).json({ error: 'فشل الإرسال' });
    }
  },
);