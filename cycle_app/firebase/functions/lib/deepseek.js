'use strict';

const DEEPSEEK_API_URL = 'https://api.deepseek.com/chat/completions';
const DEEPSEEK_MODEL = 'deepseek-chat';

/**
 * Call DeepSeek Chat Completions API.
 *
 * @param {string} apiKey DeepSeek API key from Firebase Secret.
 * @param {string} systemPrompt
 * @param {string} userPrompt
 * @param {number} [maxTokens=2000]
 * @param {number} [temperature=0.7]
 * @returns {Promise<string>}
 */
async function callDeepSeek(
  apiKey,
  systemPrompt,
  userPrompt,
  maxTokens = 2000,
  temperature = 0.7,
) {
  const key = (apiKey || '').replace(/^\uFEFF/, '').trim();
  if (!key) {
    throw new Error('DEEPSEEK_API_KEY is empty');
  }

  const response = await fetch(DEEPSEEK_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${key}`,
    },
    body: JSON.stringify({
      model: DEEPSEEK_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      max_tokens: maxTokens || 2000,
      temperature: typeof temperature === 'number' && temperature > 0
        ? temperature
        : 0.7,
      stream: false,
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const msg = body?.error?.message || response.statusText || 'DeepSeek error';
    throw new Error(`DeepSeek HTTP ${response.status}: ${msg}`);
  }

  const text = body?.choices?.[0]?.message?.content;
  if (!text || !String(text).trim()) {
    throw new Error('DeepSeek returned empty response');
  }
  return String(text).trim();
}

module.exports = {
  DEEPSEEK_MODEL,
  callDeepSeek,
};
