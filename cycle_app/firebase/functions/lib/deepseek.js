'use strict';

const DEEPSEEK_API_URL = 'https://api.deepseek.com/chat/completions';
/** Cheapest general chat model — avoid deepseek-reasoner (costlier). */
const DEEPSEEK_MODEL = 'deepseek-chat';
const DEEPSEEK_DEFAULT_TEMPERATURE = 0.88;

/**
 * Call DeepSeek Chat Completions API and return text + token usage.
 *
 * @param {string} apiKey DeepSeek API key from Firebase Secret.
 * @param {string} systemPrompt
 * @param {string} userPrompt
 * @param {number} [maxTokens=2000]
 * @param {number} [temperature=0.7]
 * @returns {Promise<{text: string, usage: {promptTokens: number, completionTokens: number}}>}
 */
async function callDeepSeekDetailed(
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
        : DEEPSEEK_DEFAULT_TEMPERATURE,
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

  return {
    text: String(text).trim(),
    usage: {
      promptTokens: Number(body?.usage?.prompt_tokens) || 0,
      completionTokens: Number(body?.usage?.completion_tokens) || 0,
    },
  };
}

/**
 * Backwards-compatible variant returning only the reply text
 * (used by scripts/verify_providers.js).
 */
async function callDeepSeek(apiKey, systemPrompt, userPrompt, maxTokens, temperature) {
  const { text } = await callDeepSeekDetailed(
    apiKey, systemPrompt, userPrompt, maxTokens, temperature,
  );
  return text;
}

/**
 * Streaming variant — an async generator that yields incremental text deltas
 * (`{ delta }`) as they arrive over SSE, then a final `{ done, usage }` event.
 *
 * DeepSeek streams Server-Sent Events: lines of `data: {json}` terminated by a
 * blank line, ending with `data: [DONE]`. We buffer partial lines across chunk
 * boundaries so multi-byte characters and split frames are handled correctly.
 *
 * @param {string} apiKey
 * @param {string} systemPrompt
 * @param {string} userPrompt
 * @param {number} [maxTokens=2000]
 * @param {number} [temperature=0.7]
 * @yields {{delta?: string, done?: boolean, usage?: object}}
 */
async function* streamDeepSeek(
  apiKey,
  systemPrompt,
  userPrompt,
  maxTokens = 2000,
  temperature = 0.7,
) {
  const key = (apiKey || '').replace(/^﻿/, '').trim();
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
        : DEEPSEEK_DEFAULT_TEMPERATURE,
      stream: true,
      stream_options: { include_usage: true },
    }),
  });

  if (!response.ok || !response.body) {
    let msg = response.statusText || 'DeepSeek error';
    try {
      const errBody = await response.json();
      msg = errBody?.error?.message || msg;
    } catch (_) { /* body may not be JSON on stream errors */ }
    throw new Error(`DeepSeek HTTP ${response.status}: ${msg}`);
  }

  const decoder = new TextDecoder('utf-8');
  let buffer = '';
  let completionTokens = 0;
  let promptTokens = 0;
  let emittedAny = false;

  for await (const chunk of response.body) {
    buffer += decoder.decode(chunk, { stream: true });

    // Process complete SSE lines; keep the trailing partial line in `buffer`.
    let newlineIndex;
    while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
      const line = buffer.slice(0, newlineIndex).trim();
      buffer = buffer.slice(newlineIndex + 1);
      if (!line.startsWith('data:')) continue;

      const payload = line.slice(5).trim();
      if (payload === '[DONE]') continue;

      let json;
      try {
        json = JSON.parse(payload);
      } catch (_) {
        continue; // skip malformed frame
      }

      const delta = json?.choices?.[0]?.delta?.content;
      if (delta) {
        emittedAny = true;
        yield { delta };
      }
      if (json?.usage) {
        promptTokens = Number(json.usage.prompt_tokens) || promptTokens;
        completionTokens = Number(json.usage.completion_tokens) || completionTokens;
      }
    }
  }

  if (!emittedAny) {
    throw new Error('DeepSeek stream produced no content');
  }

  yield { done: true, usage: { promptTokens, completionTokens } };
}

module.exports = {
  DEEPSEEK_MODEL,
  callDeepSeek,
  callDeepSeekDetailed,
  streamDeepSeek,
};
