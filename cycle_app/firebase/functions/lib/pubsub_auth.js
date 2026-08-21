'use strict';

const { OAuth2Client } = require('google-auth-library');

const DEFAULT_AUDIENCE =
  process.env.PLAY_WEBHOOK_AUDIENCE ||
  'https://us-central1-lune-7d956.cloudfunctions.net/googlePlayWebhook';

/**
 * Verifies the OIDC Bearer token that Pub/Sub attaches to push deliveries.
 * Rejects unauthenticated callers so the RTDN endpoint cannot be probed.
 *
 * @param {import('express').Request} req
 * @returns {Promise<boolean>}
 */
async function verifyPubSubOidc(req) {
  const authHeader = req.get('Authorization') || '';
  if (!authHeader.startsWith('Bearer ')) {
    return false;
  }
  const token = authHeader.slice('Bearer '.length).trim();
  if (!token) return false;

  try {
    const client = new OAuth2Client();
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: DEFAULT_AUDIENCE,
    });
    const payload = ticket.getPayload();
    if (!payload) return false;
    // Pub/Sub push tokens are issued for Google service accounts.
    const email = payload.email || '';
    const emailVerified = payload.email_verified === true;
    return emailVerified && email.endsWith('.gserviceaccount.com');
  } catch (error) {
    console.warn('pubsub_oidc_invalid', { message: error.message });
    return false;
  }
}

module.exports = {
  verifyPubSubOidc,
  DEFAULT_AUDIENCE,
};
