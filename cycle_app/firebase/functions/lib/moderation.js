// ============================================================================
// lib/moderation.js — content moderation + cycle-context string builder.
// ----------------------------------------------------------------------------
// Two distinct responsibilities that both feed into the AI surface:
//
//   - moderateContent(text)
//       Used by community triggers (posts, comments, stories) to decide
//       whether user-generated content is allowed. Returns
//       `{ approved: true }` or `{ approved: false, reason: "..." }`.
//       A Gemini outage returns `pendingReview` (fail-closed): unchecked UGC
//       stays private to its author until a retry or human review resolves it.
//
//   - buildContextString(cycleContext, mode)
//       Renders the structured cycle context into a flat string the model
//       can read. Mirrors Dart's `AiPromptBuilder.buildUserPrompt` so the
//       two surfaces stay in sync.
// ============================================================================

'use strict';

const { callGemini, GEMINI_MODERATION_SAFETY_SETTINGS } = require('./gemini');

const MODERATION_TIMEOUT_MS = 4500;

const MODERATION_INSTRUCTION = `You are a content moderator for a women's health community app.
Review the post/comment below. Reject ONLY if it contains:
- Medical prescriptions or specific medication dosages
- Dangerous self-harm/suicide content
- Harassment, hate speech, or threats
- Child sexual abuse/exploitation, grooming, or sexualization of minors
- Sexual exploitation or non-consensual intimate content
- Personal contact solicitation, scams, illegal sales, spam, or promotional links
Allow supportive peer discussion, emotional sharing, personal experiences.
Reply ONLY with JSON: {"approved":true} or {"approved":false,"reason":"short reason"}`;

async function withModerationTimeout(request) {
  let timer;
  try {
    return await Promise.race([
      request,
      new Promise((_, reject) => {
        timer = setTimeout(
          () => reject(new Error('moderation_timeout')),
          MODERATION_TIMEOUT_MS,
        );
      }),
    ]);
  } finally {
    if (timer) clearTimeout(timer);
  }
}

/**
 * Run moderation on a piece of text via Gemini.
 *
 * @param {string} geminiApiKey Raw key from `defineSecret().value()`.
 * @param {string} text The text to moderate.
 * @returns {Promise<{approved: boolean, reason?: string}>}
 *   Returns `pendingReview` on parse failures or transient outages.
 */
async function moderateContent(geminiApiKey, text) {
  try {
    const result = await withModerationTimeout(
      callGemini(
        geminiApiKey, MODERATION_INSTRUCTION, text, 100,
        undefined, GEMINI_MODERATION_SAFETY_SETTINGS,
      ),
    );
    if (result.includes('"approved":false')) {
      const match = result.match(/"reason"\s*:\s*"([^"]+)"/);
      return { approved: false, reason: match ? match[1] : 'Content not allowed.' };
    }
    if (result.includes('"approved":true')) return { approved: true };
    return {
      approved: false,
      pendingReview: true,
      reason: 'Moderation response could not be verified.',
    };
  } catch (e) {
    // Fail closed to the private review queue. The author still sees the
    // optimistic/pending item, while other members never receive unchecked
    // content. Scheduled moderation and the admin queue resolve it later.
    console.error('Moderation error:', e);
    return {
      approved: false,
      pendingReview: true,
      reason: 'Moderation temporarily unavailable.',
    };
  }
}

/**
 * Map a moderation result to a Firestore status update.
 * Explicit approval publishes, explicit rejection blocks, and an unavailable
 * or unverifiable classifier result is held in `pending_review`.
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
  if (result.pendingReview) {
    return {
      moderationStatus: 'pending_review',
      pendingReview: true,
      reason: result.reason,
    };
  }
  if (result.approved) {
    return {
      moderationStatus: 'approved',
      pendingReview: false,
      reviewedBy: 'auto_ai',
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
    parts.push('Cycle regularity: ' + (cycleContext.cycleRegularity || 'unknown'));
    if (cycleContext.cycleHistory && cycleContext.cycleHistory.ovulationCalibrated) {
      parts.push('Ovulation timing is calibrated from user ovulation/LH logs — treat ovulation date as more reliable than generic estimates.');
    }
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
    const window = cycleContext.cycleHistory.predictionWindowDays;
    if (window != null) {
      parts.push(
        'Prediction uncertainty: ±' + window + ' days around next period/ovulation dates. ' +
        'When irregular, explain that dates are estimates and encourage logging each period to improve accuracy.',
      );
    }
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
