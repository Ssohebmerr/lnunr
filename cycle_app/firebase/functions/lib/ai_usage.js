// ============================================================================
// lib/ai_usage.js — per-request AI usage logging + daily cost aggregates.
// ----------------------------------------------------------------------------
// Two write targets per AI request (both best-effort — a logging failure must
// never fail the user's chat request):
//
//   1. ai_usage/{uid}/messages/{auto}   privacy-safe per-user usage trail
//      (mode, provider, token counts, and character count only). Powers the
//      admin `aiUsageStats` action without retaining health-chat content.
//
//   2. aiUsageDaily/{YYYY-MM-DD}        ONE document per day with atomic
//      increments. Powers the admin `aiCostStats` action without scanning
//      any subcollections — O(days) reads instead of O(users × messages).
//
// Cost rates are ESTIMATES for budget alerting only (USD per 1M tokens).
// Update the constants when provider pricing changes; historical documents
// store raw token counts, so re-pricing old days is always possible.
// ============================================================================

'use strict';

const admin = require('firebase-admin');

/** USD per 1,000,000 tokens — estimation only, keep in sync with pricing pages. */
const COST_PER_MILLION_TOKENS_USD = {
  deepseek: { prompt: 0.27, completion: 1.10 },
  gemini: { prompt: 0.30, completion: 2.50 },
};

/**
 * Estimated USD cost of one request (returns 0 for unknown providers).
 */
function estimateCostUsd(provider, usage) {
  const rates = COST_PER_MILLION_TOKENS_USD[provider];
  if (!rates || !usage) return 0;
  const prompt = (Number(usage.promptTokens) || 0) * rates.prompt;
  const completion = (Number(usage.completionTokens) || 0) * rates.completion;
  return (prompt + completion) / 1e6;
}

/** UTC day key, e.g. '2026-07-04' — matches analyticsDaily doc ids. */
function utcDayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

/**
 * Records one completed AI request. Never throws.
 *
 * @param {object} p
 * @param {string} p.uid Authenticated caller uid.
 * @param {string} p.mode Chat mode ('chat' | 'analyze' | 'doctor' | ...).
 * @param {string} p.provider 'deepseek' | 'gemini'.
 * @param {{promptTokens: number, completionTokens: number}} p.usage
 * @param {number} p.messageLength User-message length, never its text.
 */
async function logAiUsage({ uid, mode, provider, usage, messageLength = 0 }) {
  const db = admin.firestore();
  const promptTokens = Number(usage?.promptTokens) || 0;
  const completionTokens = Number(usage?.completionTokens) || 0;
  const costUsd = estimateCostUsd(provider, usage);

  try {
    await Promise.all([
      // 1. Per-user audit trail.
      db.collection('ai_usage').doc(uid).collection('messages').add({
        // Do not persist a preview or a hash of the message. Cycle and health
        // chat can contain highly sensitive information, while usage analytics
        // only needs the metadata below.
        messageChars: Math.max(0, Math.min(Number(messageLength) || 0, 2000)),
        mode,
        provider,
        promptTokens,
        completionTokens,
        costUsd,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      }),
      // 2. Daily aggregate (atomic nested increments on one doc).
      //    NOTE: nested maps + merge:true (NOT dotted keys — set() treats
      //    dotted keys as literal field names, unlike update()).
      db.collection('aiUsageDaily').doc(utcDayKey()).set({
        date: utcDayKey(),
        requests: admin.firestore.FieldValue.increment(1),
        promptTokens: admin.firestore.FieldValue.increment(promptTokens),
        completionTokens: admin.firestore.FieldValue.increment(completionTokens),
        estimatedCostUsd: admin.firestore.FieldValue.increment(costUsd),
        byProvider: {
          [provider]: {
            requests: admin.firestore.FieldValue.increment(1),
            promptTokens: admin.firestore.FieldValue.increment(promptTokens),
            completionTokens: admin.firestore.FieldValue.increment(completionTokens),
          },
        },
        byMode: {
          [mode]: admin.firestore.FieldValue.increment(1),
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true }),
    ]);
  } catch (error) {
    console.warn('logAiUsage failed (non-fatal):', error.message);
  }
}

module.exports = {
  COST_PER_MILLION_TOKENS_USD,
  estimateCostUsd,
  utcDayKey,
  logAiUsage,
};
