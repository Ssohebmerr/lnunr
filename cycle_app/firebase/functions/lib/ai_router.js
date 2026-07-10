'use strict';

const { callDeepSeekDetailed, streamDeepSeek } = require('./deepseek');
const { callGeminiDetailed, streamGemini } = require('./gemini');

/**
 * Validates the client-supplied conversation history into the shape the
 * providers expect: `[{role: 'user'|'model', text}]`, newest-last.
 *
 * - Caps turns and per-turn length (the client cannot inflate our token bill).
 * - Drops empty / malformed entries.
 * - Trims leading model turns — Gemini requires the first turn to be `user`.
 *
 * @param {*} raw `req.body.history` as sent by the app (may be anything).
 * @param {Object} [opts]
 * @param {number} [opts.maxTurns=8]
 * @param {number} [opts.maxChars=800]
 * @returns {Array<{role: 'user'|'model', text: string}>}
 */
function sanitizeHistory(raw, { maxTurns = 8, maxChars = 800 } = {}) {
  if (!Array.isArray(raw)) return [];
  const turns = [];
  for (const item of raw.slice(-maxTurns)) {
    let role = null;
    if (item && item.role === 'user') role = 'user';
    else if (item && (item.role === 'model' || item.role === 'assistant')) role = 'model';
    const text = (item && typeof item.text === 'string')
      ? item.text.trim().substring(0, maxChars)
      : '';
    if (!role || !text) continue;
    turns.push({ role, text });
  }
  while (turns.length > 0 && turns[0].role !== 'user') turns.shift();
  return turns;
}

/**
 * Primary: DeepSeek. Fallback: Google Gemini (AI Studio key on server).
 *
 * @returns {Promise<{reply: string, provider: 'deepseek'|'gemini',
 *   usage: {promptTokens: number, completionTokens: number}}>}
 */
async function callAiWithFallback({
  deepseekKey,
  geminiKey,
  systemPrompt,
  userPrompt,
  maxTokens,
  temperature,
  history = [],
}) {
  if (deepseekKey) {
    try {
      const { text, usage } = await callDeepSeekDetailed(
        deepseekKey,
        systemPrompt,
        userPrompt,
        maxTokens,
        temperature,
        history,
      );
      if (text) {
        return { reply: text, provider: 'deepseek', usage };
      }
    } catch (error) {
      console.error('DeepSeek failed, falling back to Gemini:', error.message || error);
    }
  }

  if (!geminiKey) {
    throw new Error('No AI provider keys configured on server');
  }

  const { text, usage } = await callGeminiDetailed(
    geminiKey,
    systemPrompt,
    userPrompt,
    maxTokens,
    temperature,
    history,
  );
  return { reply: text, provider: 'gemini', usage };
}

/**
 * Streaming router: DeepSeek primary, Gemini fallback.
 *
 * Async generator yielding `{ delta }` text chunks then a final
 * `{ done, provider, usage }`. The fallback to Gemini only happens if DeepSeek
 * fails BEFORE emitting any delta — once tokens have streamed to the caller we
 * are committed to that provider (we can't un-send bytes).
 *
 * @yields {{delta?: string, done?: boolean, provider?: string, usage?: object}}
 */
async function* streamAiWithFallback({
  deepseekKey,
  geminiKey,
  systemPrompt,
  userPrompt,
  maxTokens,
  temperature,
  history = [],
}) {
  if (deepseekKey) {
    let deepseekEmitted = false;
    try {
      for await (const evt of streamDeepSeek(
        deepseekKey, systemPrompt, userPrompt, maxTokens, temperature, history,
      )) {
        if (evt.delta) {
          deepseekEmitted = true;
          yield { delta: evt.delta };
        } else if (evt.done) {
          yield { done: true, provider: 'deepseek', usage: evt.usage };
        }
      }
      return;
    } catch (error) {
      console.error('DeepSeek stream failed:', error.message || error);
      if (deepseekEmitted) {
        // Partial output already sent — cannot safely fall back.
        throw error;
      }
      // else: fall through to Gemini.
    }
  }

  if (!geminiKey) {
    throw new Error('No AI provider keys configured on server');
  }

  for await (const evt of streamGemini(
    geminiKey, systemPrompt, userPrompt, maxTokens, temperature, history,
  )) {
    if (evt.delta) {
      yield { delta: evt.delta };
    } else if (evt.done) {
      yield { done: true, provider: 'gemini', usage: evt.usage };
    }
  }
}

module.exports = {
  sanitizeHistory,
  callAiWithFallback,
  streamAiWithFallback,
};
