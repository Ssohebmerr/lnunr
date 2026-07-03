// ============================================================================
// lib/broadcast.js — push-notification broadcast dispatcher.
// ----------------------------------------------------------------------------
// Shared between:
//   - `endpoints/adminBroadcast.js` — manual admin-triggered broadcasts.
//   - `scheduled/analytics.js` → `processScheduledBroadcasts` — cron
//     processing of scheduled broadcasts.
//
// Centralised here so the audience/segment filtering + FCM multicast
// chunking lives in exactly one place. Behaviour notes:
//   - Token fetch is capped at 2000 per run to keep function memory + FCM
//     batch size predictable.
//   - Multicast is chunked into 500-token batches (the FCM hard limit).
//   - Every successful run writes an `adminBroadcasts` audit row for the
//     admin dashboard.
// ============================================================================

'use strict';

const admin = require('firebase-admin');

const BROADCAST_TOKEN_FETCH_LIMIT = 2000;
const FCM_MULTICAST_CHUNK_SIZE = 500;

/**
 * Send a push broadcast to a slice of users.
 *
 * @param {Object} params
 * @param {string} params.title     Notification title.
 * @param {string} params.body      Notification body.
 * @param {'all'|'premium'|'free'} [params.audience='all']
 *   Free/premium segmentation. Free = "isPremium != true" (catches missing
 *   field and explicit false).
 * @param {string} [params.segment]  Optional: 'new_7d' | 'inactive_14d'.
 * @param {string} [params.country]  Optional: ISO country filter.
 * @param {string} [params.sentBy]   Audit trail — uid or 'system'/'scheduler'.
 * @returns {Promise<{sent: number, failed: number, tokensAttempted: number}>}
 */
async function sendBroadcastInternal({
  title,
  body,
  audience = 'all',
  segment,
  country,
  sentBy = 'system',
}) {
  const db = admin.firestore();

  // Build query based on audience + segment
  let q = db.collection('users');
  if (audience === 'premium') q = q.where('isPremium', '==', true);
  else if (audience === 'free') q = q.where('isPremium', '!=', true);

  if (segment === 'new_7d') {
    const since = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 7 * 86400000));
    q = q.where('createdAt', '>=', since);
  } else if (segment === 'inactive_14d') {
    const cutoff = admin.firestore.Timestamp.fromDate(new Date(Date.now() - 14 * 86400000));
    q = q.where('lastActiveAt', '<', cutoff);
  }
  if (country) q = q.where('country', '==', country);

  // Fetch in batches to handle large collections.
  const snap = await q.limit(BROADCAST_TOKEN_FETCH_LIMIT).get();
  const tokens = snap.docs.map((d) => d.data().fcmToken).filter(Boolean);

  let sent = 0;
  let failed = 0;
  if (tokens.length > 0) {
    for (let i = 0; i < tokens.length; i += FCM_MULTICAST_CHUNK_SIZE) {
      const chunk = tokens.slice(i, i + FCM_MULTICAST_CHUNK_SIZE);
      try {
        const resp = await admin.messaging().sendEachForMulticast({
          notification: { title, body },
          tokens: chunk,
        });
        sent += resp.successCount;
        failed += resp.failureCount;
      } catch (e) {
        failed += chunk.length;
        console.warn('multicast chunk failed:', e.message);
      }
    }
  }

  await db.collection('adminBroadcasts').add({
    title,
    body,
    audience,
    segment: segment || null,
    country: country || null,
    tokensAttempted: tokens.length,
    sent,
    failed,
    sentBy,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { sent, failed, tokensAttempted: tokens.length };
}

module.exports = { sendBroadcastInternal };