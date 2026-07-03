'use strict';

const admin = require('firebase-admin');

/** Premium users: max AI chat messages per calendar day (server-enforced). */
const DAILY_PREMIUM_CHAT_LIMIT = 10;

class QuotaError extends Error {
  /**
   * @param {'premium_required'|'daily_limit_reached'} code
   * @param {number} status HTTP status
   * @param {string} message
   */
  constructor(code, status, message) {
    super(message);
    this.name = 'QuotaError';
    this.code = code;
    this.status = status;
  }
}

/**
 * Ensures the user is premium and under the daily chat limit.
 * @returns {FirebaseFirestore.DocumentReference} user doc ref for increment
 */
async function assertPremiumChatQuota(uid) {
  const ref = admin.firestore().collection('users').doc(uid);
  const snap = await ref.get();

  if (!snap.exists) {
    throw new QuotaError(
      'premium_required',
      403,
      'Premium subscription required.',
    );
  }

  const data = snap.data() || {};
  if (data.isPremium !== true) {
    throw new QuotaError(
      'premium_required',
      403,
      'Premium subscription required.',
    );
  }

  const count = Number(data.daily_chat_count) || 0;
  if (count >= DAILY_PREMIUM_CHAT_LIMIT) {
    throw new QuotaError(
      'daily_limit_reached',
      429,
      'Daily AI message limit reached.',
    );
  }

  return ref;
}

async function incrementDailyChatCount(userRef) {
  await userRef.update({
    daily_chat_count: admin.firestore.FieldValue.increment(1),
    lastChatAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

module.exports = {
  DAILY_PREMIUM_CHAT_LIMIT,
  QuotaError,
  assertPremiumChatQuota,
  incrementDailyChatCount,
};
