// ============================================================================
// lib/ai_memory.js — long-term user memory for Lune's AI chat.
// ----------------------------------------------------------------------------
// The model is instructed (prompts.js actionTagsRule) to emit
//   [[remember:<short stable fact>]]
// when the user states a lasting fact or preference ("my name is Sara",
// "I prefer nutrition tips over emotional ones"). After each reply we extract
// those tags, merge them into users/{uid}.aiMemory (deduped, capped), and the
// next requests inject the list back into the prompt context — so Lune
// remembers the user across sessions, far beyond the 8-turn history window.
//
// The client is untouched: AiActionParser.sanitizeForDisplay strips ALL
// [[...]] blocks from the visible reply, and unknown tag keys are ignored by
// the action-button mapper.
// ============================================================================

'use strict';

const admin = require('firebase-admin');

/** Hard cap on stored facts — newest facts win when the list overflows. */
const MAX_FACTS = 15;
/** Per-fact length cap (chars). */
const MAX_FACT_LENGTH = 140;
/** Max facts accepted from a single reply. */
const MAX_FACTS_PER_REPLY = 3;

const REMEMBER_TAG_SOURCE = String.raw`\[\[remember:([^\]|]{2,200})(?:\|[^\]]*)?\]\]`;

/**
 * Pulls `[[remember:...]]` facts out of a model reply.
 *
 * @param {string} text The full reply text (may contain other action tags).
 * @returns {string[]} Extracted facts, trimmed and length-capped.
 */
function extractRememberFacts(text) {
  if (!text) return [];
  const facts = [];
  const re = new RegExp(REMEMBER_TAG_SOURCE, 'gi');
  let match;
  while ((match = re.exec(text)) !== null) {
    const fact = match[1].trim().substring(0, MAX_FACT_LENGTH);
    if (fact) facts.push(fact);
    if (facts.length >= MAX_FACTS_PER_REPLY) break;
  }
  return facts;
}

/**
 * Merges new facts into users/{uid}.aiMemory — deduped case-insensitively,
 * capped at MAX_FACTS (oldest dropped first). Best-effort: a failure here
 * must never break the chat reply.
 *
 * @param {string} uid
 * @param {string[]} newFacts
 * @returns {Promise<void>}
 */
async function saveUserFacts(uid, newFacts) {
  if (!Array.isArray(newFacts) || newFacts.length === 0) return;
  try {
    const ref = admin.firestore().collection('users').doc(uid);
    await admin.firestore().runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) return;
      const existing = Array.isArray(snap.data().aiMemory)
        ? snap.data().aiMemory.map(String)
        : [];
      const merged = [...existing];
      for (const fact of newFacts) {
        const isDup = merged.some(
          (f) => f.toLowerCase() === fact.toLowerCase(),
        );
        if (!isDup) merged.push(fact);
      }
      tx.update(ref, { aiMemory: merged.slice(-MAX_FACTS) });
    });
  } catch (error) {
    console.warn('saveUserFacts failed (non-fatal):', error.message || error);
  }
}

module.exports = {
  MAX_FACTS,
  extractRememberFacts,
  saveUserFacts,
};
