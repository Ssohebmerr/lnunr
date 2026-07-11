// ============================================================================
// endpoints/broadcast.js — POST /adminBroadcast  (admin-triggered push).
// ----------------------------------------------------------------------------
// Thin wrapper around the shared `sendBroadcastInternal` from `lib/broadcast.js`.
// The scheduled cron variant (processScheduledBroadcasts) lives in
// `scheduled/analytics.js` and uses the same helper.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

const { callerHasRole } = require('../lib/adminAuth');
const { sendBroadcastInternal } = require('../lib/broadcast');
const { guardRequest, setCors } = require('../lib/http');

exports.adminBroadcast = onRequest(
  { cors: true, timeoutSeconds: 60 },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'admin', appCheck: 'skip' }))) return;

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      setCors(res);
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      if (!(await callerHasRole(decoded, 'admin'))) {
        setCors(res);
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      const { title, body, audience, segment, country } = req.body || {};
      if (!title || !body) {
        setCors(res);
        res.status(400).json({ error: 'Title and body required.' });
        return;
      }

      const result = await sendBroadcastInternal({
        title, body,
        audience: audience || 'all',
        segment, country,
        sentBy: decoded.uid,
      });

      setCors(res);
      res.json(result);
    } catch (error) {
      console.error('Admin broadcast error:', error);
      setCors(res);
      res.status(500).json({ error: 'Failed to send broadcast.' });
    }
  },
);