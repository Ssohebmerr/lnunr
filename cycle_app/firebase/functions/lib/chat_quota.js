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
 * Ensures users/{uid} exists with isPremium=true for the authenticated caller.
 *
 * Admin may have granted premium on a different UID after session changes.
 * Auto-heal binds premium to the UID that is actually calling AI.
 *
 * @returns {FirebaseFirestore.DocumentReference} user doc ref for increment
 */
async function assertPremiumChatQuota(uid) {
  const ref = admin.firestore().collection('users').doc(uid);
  let snap = await ref.get();
  const data = snap.exists ? (snap.data() || {}) : {};

  if (!snap.exists || data.isPremium !== true) {
    await ref.set(
      {
        name: data.name || 'User',
        isPremium: true,
        premiumSource: data.premiumSource || 'auto_chat',
        testerPremiumGranted: true,
        daily_chat_count: Number(data.daily_chat_count) || 0,
        premiumSince: data.premiumSince || new Date().toISOString(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        ...(snap.exists
          ? {}
          : { createdAt: admin.firestore.FieldValue.serverTimestamp() }),
      },
      { merge: true },
    );
    snap = await ref.get();
  }

  const fresh = snap.data() || {};
  const count = Number(fresh.daily_chat_count) || 0;
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
