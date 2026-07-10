// ============================================================================
// lib/chat_quota.js — strict server-side paywall gate for AI endpoints.
// ----------------------------------------------------------------------------
// Security contract (enforced HERE, never trusted from the client):
//   1. users/{uid} MUST exist and carry `isPremium == true`, otherwise the
//      request is rejected with 403 `premium_required`. The server NEVER
//      grants premium as a side effect of calling AI.
//   2. `daily_chat_count` MUST be below DAILY_PREMIUM_CHAT_LIMIT. The check
//      and the increment happen inside ONE Firestore transaction so parallel
//      requests cannot race past the limit.
//   3. The slot is reserved BEFORE the external AI call (DeepSeek/Gemini).
//      If every provider fails, callers roll the reservation back with
//      `releaseChatSlot()` so users are not billed a message for our failure.
// ============================================================================

'use strict';

const admin = require('firebase-admin');

/** Premium users: max AI chat messages per calendar day (server-enforced). */
const DAILY_PREMIUM_CHAT_LIMIT = 30;

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
 * Atomically verifies premium entitlement and reserves one daily chat slot.
 *
 * @param {string} uid Authenticated Firebase uid (from a verified ID token).
 * @returns {Promise<{ref: FirebaseFirestore.DocumentReference,
 *   remaining: number, aiMemory: string[]}>}
 *   `remaining` = slots left AFTER this reservation (for the client counter).
 *   `aiMemory` = long-term facts stored by lib/ai_memory.js (piggybacked on
 *   this transaction's read so the chat endpoint needs no extra Firestore hit).
 * @throws {QuotaError} 403 premium_required | 429 daily_limit_reached
 */
async function reservePremiumChatSlot(uid) {
  const db = admin.firestore();
  const ref = db.collection('users').doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? (snap.data() || {}) : {};

    if (!snap.exists || data.isPremium !== true) {
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

    tx.update(ref, {
      daily_chat_count: count + 1,
      lastChatAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      remaining: DAILY_PREMIUM_CHAT_LIMIT - (count + 1),
      aiMemory: Array.isArray(data.aiMemory) ? data.aiMemory.map(String) : [],
    };
  });

  return { ref, remaining: result.remaining, aiMemory: result.aiMemory };
}

/**
 * Returns a reserved slot when the AI call failed after reservation.
 * Best effort — a failure to release only costs the user one slot, it never
 * lets them exceed the limit.
 */
async function releaseChatSlot(ref) {
  try {
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const count = Number(snap.data()?.daily_chat_count) || 0;
      if (count > 0) {
        tx.update(ref, { daily_chat_count: count - 1 });
      }
    });
  } catch (error) {
    console.warn('releaseChatSlot failed (slot lost, limit still safe):', error.message);
  }
}

module.exports = {
  DAILY_PREMIUM_CHAT_LIMIT,
  QuotaError,
  reservePremiumChatSlot,
  releaseChatSlot,
};
