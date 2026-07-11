// ============================================================================
// lib/moderation.js — content moderation + cycle-context string builder.
// ----------------------------------------------------------------------------
// Two distinct responsibilities that both feed into the AI surface:
//
//   - moderateContent(text)
//       Used by community triggers (posts, comments, stories) to decide
//       whether user-generated content is allowed. Returns
//       `{ approved: true }` or `{ approved: false, reason: "..." }`.
//       IMPORTANT: a Gemini outage returns `{ approved: true }` (fail-open)
//       so we don't block legitimate users on transient errors — the onPost
//       / onComment triggers can then re-run via reprocessPendingModeration.
//
//   - buildContextString(cycleContext, mode)
//       Renders the structured cycle context into a flat string the model
//       can read. Mirrors Dart's `AiPromptBuilder.buildUserPrompt` so the
//       two surfaces stay in sync.
// ============================================================================

'use strict';

const { callGemini, GEMINI_MODERATION_SAFETY_SETTINGS } = require('./gemini');

const MODERATION_INSTRUCTION = `You are a content moderator for a women's health community app.
Review the post/comment below. Reject ONLY if it contains:
- Medical prescriptions or specific medication dosages
- Dangerous self-harm/suicide content
- Harassment, hate speech, or threats
- Spam, ads, or promotional links
Allow supportive peer discussion, emotional sharing, personal experiences.
Reply ONLY with JSON: {"approved":true} or {"approved":false,"reason":"short reason"}`;

/**
 * Run moderation on a piece of text via Gemini.
 *
 * @param {string} geminiApiKey Raw key from `defineSecret().value()`.
 * @param {string} text The text to moderate.
 * @returns {Promise<{approved: boolean, reason?: string}>}
 *   Returns `{ approved: true }` on parse failures (fail-open for transient
 *   outages — see header note).
 */
async function moderateContent(geminiApiKey, text) {
  try {
    const result = await callGemini(
      geminiApiKey, MODERATION_INSTRUCTION, text, 100,
      undefined, GEMINI_MODERATION_SAFETY_SETTINGS,
    );
    // Only an EXPLICIT rejection blocks the post. Everything else — an explicit
    // approval, a safety-blocked/empty reply, or unparseable text — passes,
    // because the client-side keyword/link/contact filter already caught the
    // dangerous cases before the text ever reached the model, and reports +
    // auto-hide remain the human safety net.
    if (result.includes('"approved":false')) {
      const match = result.match(/"reason"\s*:\s*"([^"]+)"/);
      return { approved: false, reason: match ? match[1] : 'Content not allowed.' };
    }
    return { approved: true };
  } catch (e) {
    // Fail-OPEN on a transient outage (see header note) — never strand a
    // legitimate post in a review queue nobody drains.
    console.error('Moderation error:', e);
    return { approved: true, failOpen: true };
  }
}

/**
 * Map a moderation result to a Firestore status update.
 * Only an explicit AI rejection blocks the write; everything else is approved
 * (fail-open) so nothing is stranded in a review queue. `pending_review` is now
 * reserved for the reports auto-hide path, not the submit path.
 *
 * @returns {Promise<{
 *   moderationStatus: 'approved'|'rejected',
 *   pendingReview: boolean,
 *   reviewedBy?: string,
 *   reason?: string,
 *   reject?: boolean,
 * }>}
 */
async function evaluateModeration(geminiApiKey, text) {
  if (text.length < 3) {
    return {
      moderationStatus: 'approved',
      pendingReview: false,
      reviewedBy: 'auto_short',
    };
  }

  const result = await moderateContent(geminiApiKey, text);
  if (result.approved) {
    return {
      moderationStatus: 'approved',
      pendingReview: false,
      reviewedBy: result.failOpen ? 'auto_ai_failopen' : 'auto_ai',
    };
  }
  return {
    moderationStatus: 'rejected',
    pendingReview: false,
    reason: result.reason || 'Content not allowed.',
    reject: true,
  };
}

/**
 * Render a structured cycle/pregnancy context into the flat string the model
 * sees. Mirrors `AiPromptBuilder.buildUserPrompt` in the Dart client — keep
 * both in sync when adjusting fields.
 *
 * @param {Object} cycleContext The context object (may be empty).
 * @param {string} mode The active mode (e.g. 'patterns', 'nutrition').
 * @returns {string} The flattened context block.
 */
function buildContextString(cycleContext, mode) {
  if (!cycleContext) return 'No cycle data available.';

  const goal = cycleContext.userGoal || 'unknown';
  const parts = [];

  parts.push('User locale: ' + (cycleContext.userLocale || 'ar'));
  parts.push('User goal: ' + goal);

  if (cycleContext.localTimeOfDay) {
    parts.push('Local time of day: ' + cycleContext.localTimeOfDay);
  }

  if (Array.isArray(cycleContext.aiMemory) && cycleContext.aiMemory.length > 0) {
    const facts = cycleContext.aiMemory
      .slice(0, 15)
      .map((f) => String(f).substring(0, 140))
      .join(' | ');
    parts.push('Known about the user (long-term memory): ' + facts.substring(0, 1200));
  }

  if (goal === 'pregnant') {
    parts.push('Pregnancy week: ' + (cycleContext.pregnancyWeek || 'unknown'));
    parts.push('Trimester: ' + (cycleContext.trimester || 'unknown'));
    parts.push('Due date: ' + (cycleContext.expectedDueDate || 'unknown'));
    parts.push('Gestational day: ' + (cycleContext.gestationalDay || 'unknown'));
    parts.push('Fetal development: ' + (cycleContext.fetalDevelopmentSnippet || 'unknown'));
    parts.push('Maternal changes: ' + (cycleContext.maternalSnippet || 'unknown'));
    if (cycleContext.pregnancyTracking) {
      parts.push('Pregnancy tracking: ' + JSON.stringify(cycleContext.pregnancyTracking));
    }
  } else {
    parts.push('Cycle length: ' + (cycleContext.cycleLength || 'unknown'));
    parts.push('Period duration: ' + (cycleContext.periodDuration || 'unknown'));
    parts.push('Current phase: ' + (cycleContext.currentPhase || 'unknown'));
    parts.push('Current cycle day: ' + (cycleContext.currentCycleDay || 'unknown'));
    parts.push('Next period: ' + (cycleContext.nextPeriodDate || 'unknown'));
    parts.push('Ovulation: ' + (cycleContext.ovulationDate || 'unknown'));
  }

  // todayLog is an object (symptoms/mood/water/...) — stringify it, otherwise
  // it reaches the model as the useless literal "[object Object]".
  const todayLog = cycleContext.todayLog && typeof cycleContext.todayLog === 'object'
    ? JSON.stringify(cycleContext.todayLog).substring(0, 1200)
    : (cycleContext.todayLog || 'nothing yet');
  parts.push('Today\'s log (home screen): ' + todayLog);

  if (cycleContext.recentSymptoms) {
    const sym = JSON.stringify(cycleContext.recentSymptoms);
    parts.push('Recent symptoms (30d): ' + sym.substring(0, Math.min(sym.length, 2500)));
  }

  parts.push('Wellness logs: ' + (cycleContext.wellnessLogCount || 0));

  if (cycleContext.wellnessHub && Object.keys(cycleContext.wellnessHub).length > 0) {
    const hub = JSON.stringify(cycleContext.wellnessHub);
    parts.push('Wellness hub (pills, sanitary, vitals — anonymized): ' + hub.substring(0, Math.min(hub.length, 2500)));
  }

  if (cycleContext.summary && Object.keys(cycleContext.summary).length > 0) {
    parts.push('Summary: ' + JSON.stringify(cycleContext.summary));
  }

  if (cycleContext.cycleHistory) {
    parts.push('Cycle history (last 6): ' + JSON.stringify(cycleContext.cycleHistory));
  }

  if (mode === 'patterns' && cycleContext.cycleHistory) {
    parts.push('\n=== PATTERN ANALYSIS: use cycleHistory data above to find trends ===');
  }
  if (mode === 'nutrition') {
    parts.push('\n=== NUTRITION: focus on current phase (' + (cycleContext.currentPhase || 'unknown') + ') ===');
  }
  if (mode === 'partner') {
    parts.push('\n=== PARTNER MESSAGE: write a message the user can send to their partner ===');
  }

  return parts.join('\n');
}

module.exports = {
  moderateContent,
  evaluateModeration,
  buildContextString,
};