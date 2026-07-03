'use strict';

const { callDeepSeek } = require('./deepseek');
const { callGemini } = require('./gemini');

/**
 * Primary: DeepSeek. Fallback: Google Gemini (AI Studio key on server).
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
      const reply = await callDeepSeek(
        deepseekKey,
        systemPrompt,
        userPrompt,
        maxTokens,
        temperature,
      );
      if (reply) {
        return { reply, provider: 'deepseek' };
      }
    } catch (error) {
      console.error('DeepSeek failed, falling back to Gemini:', error.message || error);
    }
  }

  if (!geminiKey) {
    throw new Error('No AI provider keys configured on server');
  }

  const reply = await callGemini(
    geminiKey,
    systemPrompt,
    userPrompt,
    maxTokens,
    temperature,
  );
  return { reply, provider: 'gemini' };
}

module.exports = {
  callAiWithFallback,
};
