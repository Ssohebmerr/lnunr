// ============================================================================
// lib/gemini.js — Gemini AI client wrapper used by chat / analyze / moderate.
// ----------------------------------------------------------------------------
// Centralises:
//   - The safety settings applied to every Gemini call.
//   - The ordered fallback list of model names (cheapest, most-reliable first).
//   - `callGemini()` — used by ALL AI-touching endpoints and triggers.
//
// Defensive notes:
//   - We strip BOM / zero-width chars / whitespace from the API key because
//     the Firebase Secret editor occasionally prepends a BOM and that breaks
//     HTTP header parsing with `ByteString` errors.
//   - We honour a caller-provided temperature (single source of truth lives
//     in the Dart `AiPromptStyle.configForMode`). When no temperature is
//     passed we pick a sensible default based on output length.
//   - The model fallback loop short-circuits on the first model that returns
//     non-empty text. Blocked-by-safety and network errors fall through to
//     the next model.
// ============================================================================

'use strict';

const { GoogleGenerativeAI } = require('@google/generative-ai');

const GEMINI_SAFETY_SETTINGS = [
  { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
  { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
  { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
  { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
];

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash'];

/**
 * Run a Gemini call with model fallback and safety settings.
 *
 * @param {string} geminiApiKey Raw key from `defineSecret().value()`.
 * @param {string} systemPrompt The system instruction.
 * @param {string} userPrompt The user-side prompt.
 * @param {number} [maxTokens=2000] Output budget.
 * @param {number} [temperatureOverride] Optional caller-provided temperature.
 * @returns {Promise<{text: string, usage: {promptTokens: number, completionTokens: number}}>}
 *   Model output + token usage (zeros when the SDK omits usageMetadata).
 */
async function callGeminiDetailed(geminiApiKey, systemPrompt, userPrompt, maxTokens = 2000, temperatureOverride) {
  // Defensive cleanup — strip BOM, zero-width chars, whitespace.
  const apiKey = (geminiApiKey || '')
    .replace(/^\uFEFF/, '')
    .replace(/[\u200B-\u200D\u2060]/g, '')
    .trim();
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is empty after cleanup');
  }

  const genAI = new GoogleGenerativeAI(apiKey);

  // Honour the caller-supplied temperature when present; otherwise pick a
  // heuristic based on output size.
  const temperature =
    typeof temperatureOverride === 'number' && temperatureOverride > 0
      ? temperatureOverride
      : (maxTokens <= 400 ? 0.6 : 0.78);

  let lastError = null;
  for (const modelName of GEMINI_MODELS) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelName,
        systemInstruction: systemPrompt,
        generationConfig: {
          maxOutputTokens: maxTokens || 2000,
          temperature,
        },
        safetySettings: GEMINI_SAFETY_SETTINGS,
      });

      const result = await model.generateContent(userPrompt);
      const text = result.response.text();
      const meta = result.response?.usageMetadata || {};
      const usage = {
        promptTokens: Number(meta.promptTokenCount) || 0,
        completionTokens: Number(meta.candidatesTokenCount) || 0,
      };
      if (text && text.trim().length > 0) {
        return { text: text.trim(), usage };
      }

      const blockReason = result.response?.promptFeedback?.blockReason;
      if (blockReason) {
        return {
          text: '⚠️ Content blocked: ' + blockReason + '. Please rephrase your message.',
          usage,
        };
      }
    } catch (error) {
      lastError = error;
      console.error(`callGemini failed for ${modelName}:`, error);
    }
  }

  if (lastError) {
    console.error('callGemini exhausted model fallbacks:', lastError);
    throw lastError;
  }

  throw new Error('Gemini returned empty response from all models');
}

/**
 * Backwards-compatible variant returning only the reply text — used by
 * moderate / adminApi translateText / moderation triggers.
 */
async function callGemini(geminiApiKey, systemPrompt, userPrompt, maxTokens, temperatureOverride) {
  const { text } = await callGeminiDetailed(
    geminiApiKey, systemPrompt, userPrompt, maxTokens, temperatureOverride,
  );
  return text;
}

/**
 * Streaming variant — async generator yielding `{ delta }` text chunks, then a
 * final `{ done, usage }` event. Tries each model in GEMINI_MODELS in order;
 * if a model yields no content before failing, the next is attempted (matching
 * callGeminiDetailed's fallback behaviour).
 *
 * @yields {{delta?: string, done?: boolean, usage?: object}}
 */
async function* streamGemini(geminiApiKey, systemPrompt, userPrompt, maxTokens = 2000, temperatureOverride) {
  const apiKey = (geminiApiKey || '')
    .replace(/^﻿/, '')
    .replace(/[​-‌⁠]/g, '')
    .trim();
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is empty after cleanup');
  }

  const genAI = new GoogleGenerativeAI(apiKey);
  const temperature =
    typeof temperatureOverride === 'number' && temperatureOverride > 0
      ? temperatureOverride
      : (maxTokens <= 400 ? 0.6 : 0.78);

  let lastError = null;
  for (const modelName of GEMINI_MODELS) {
    try {
      const model = genAI.getGenerativeModel({
        model: modelName,
        systemInstruction: systemPrompt,
        generationConfig: { maxOutputTokens: maxTokens || 2000, temperature },
        safetySettings: GEMINI_SAFETY_SETTINGS,
      });

      const result = await model.generateContentStream(userPrompt);
      let emittedAny = false;
      for await (const chunk of result.stream) {
        const t = typeof chunk.text === 'function' ? chunk.text() : '';
        if (t) {
          emittedAny = true;
          yield { delta: t };
        }
      }

      if (!emittedAny) {
        // Try the next model on an empty stream (e.g. safety block).
        lastError = new Error(`Gemini model ${modelName} streamed no content`);
        continue;
      }

      const final = await result.response;
      const meta = final?.usageMetadata || {};
      yield {
        done: true,
        usage: {
          promptTokens: Number(meta.promptTokenCount) || 0,
          completionTokens: Number(meta.candidatesTokenCount) || 0,
        },
      };
      return;
    } catch (error) {
      lastError = error;
      console.error(`streamGemini failed for ${modelName}:`, error.message || error);
    }
  }

  throw lastError || new Error('Gemini streamed empty response from all models');
}

module.exports = {
  GEMINI_SAFETY_SETTINGS,
  GEMINI_MODELS,
  callGemini,
  callGeminiDetailed,
  streamGemini,
};