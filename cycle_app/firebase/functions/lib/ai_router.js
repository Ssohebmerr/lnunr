'use strict';

const { callDeepSeekDetailed, streamDeepSeek } = require('./deepseek');
const { callGeminiDetailed, streamGemini } = require('./gemini');

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
}) {
  if (deepseekKey) {
    try {
      const { text, usage } = await callDeepSeekDetailed(
        deepseekKey,
        systemPrompt,
        userPrompt,
        maxTokens,
        temperature,
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
}) {
  if (deepseekKey) {
    let deepseekEmitted = false;
    try {
      for await (const evt of streamDeepSeek(
        deepseekKey, systemPrompt, userPrompt, maxTokens, temperature,
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
    geminiKey, systemPrompt, userPrompt, maxTokens, temperature,
  )) {
    if (evt.delta) {
      yield { delta: evt.delta };
    } else if (evt.done) {
      yield { done: true, provider: 'gemini', usage: evt.usage };
    }
  }
}

module.exports = {
  callAiWithFallback,
  streamAiWithFallback,
};
