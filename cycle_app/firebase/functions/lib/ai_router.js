'use strict';

const { callDeepSeekDetailed } = require('./deepseek');
const { callGeminiDetailed } = require('./gemini');

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

module.exports = {
  callAiWithFallback,
};
