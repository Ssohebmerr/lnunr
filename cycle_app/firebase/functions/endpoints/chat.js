// ============================================================================
// endpoints/chat.js — POST /chat  (AI chat, premium subscribers only).
// ----------------------------------------------------------------------------
// Request lifecycle (strict server-side paywall — the client is NEVER trusted):
//   1. Verify the Firebase ID token.
//   2. reservePremiumChatSlot(uid): ONE transaction that requires
//      users/{uid}.isPremium == true AND daily_chat_count < 30, then
//      increments the counter. 403 premium_required / 429 daily_limit_reached
//      otherwise — no external API call is ever made for ineligible users.
//   3. Call DeepSeek (fallback Gemini) with a SERVER-clamped token budget.
//      Client-provided maxTokens can only shrink the budget, never grow it.
//   4. On provider failure the reserved slot is rolled back so the user does
//      not lose a message for our outage.
//   5. Token usage + estimated cost are logged to aiUsageDaily for the admin
//      panel budget monitor.
// Keys live in Firebase Secrets (DEEPSEEK_API_KEY + GEMINI_API_KEY).
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { callAiWithFallback } = require('../lib/ai_router');
const {
  QuotaError,
  reservePremiumChatSlot,
  releaseChatSlot,
} = require('../lib/chat_quota');
const { logAiUsage } = require('../lib/ai_usage');
const { getMaxTokensForMode, getSecureSystemPrompt } = require('../lib/prompts');
const { buildContextString } = require('../lib/moderation');
const { handleCors, setCors, bearerToken } = require('../lib/http');

const DEEPSEEK_API_KEY = defineSecret('DEEPSEEK_API_KEY');
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

/**
 * The client may request FEWER tokens (short answers) but never more than the
 * per-mode server ceiling — this is the budget-leak guard.
 */
function clampMaxTokens(clientValue, mode) {
  const ceiling = getMaxTokensForMode(mode);
  const requested = Number(clientValue) || 0;
  if (requested <= 0) return ceiling;
  return Math.min(requested, ceiling);
}

exports.chat = onRequest(
  {
    cors: true,
    secrets: [DEEPSEEK_API_KEY, GEMINI_API_KEY],
    timeoutSeconds: 90,
  },
  async (req, res) => {
    if (handleCors(req, res)) return;

    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const uid = decoded.uid;
      const message = (req.body?.message || '').trim().substring(0, 2000);
      const cycleContext = req.body?.cycleContext || {};
      const mode = req.body?.mode || 'chat';

      if (!message) {
        setCors(res);
        res.status(400).json({ error: 'Message is required.' });
        return;
      }

      // Strict paywall + quota — throws QuotaError before any AI spend.
      const { ref: userRef, remaining } = await reservePremiumChatSlot(uid);

      const clientSystemPrompt = (req.body?.systemPrompt || '').trim();
      const clientTemperature = Number(req.body?.temperature) || 0;

      const contextString = buildContextString(cycleContext, mode);
      const fallbackUserPrompt = mode === 'mood'
        ? `=== USER JOURNAL ENTRY (analyze emotions gently) ===\n${message}\n\nCycle context:\n${contextString}`
        : `=== APP DATA ===\n${contextString}\n\n=== USER MESSAGE ===\n${message}`;

      // Resolve personality from request or parse from clientSystemPrompt for compatibility
      let personality = req.body?.personality || 'friend';
      if (!['friend', 'doctor', 'coach'].includes(personality)) {
        if (clientSystemPrompt.includes('doctor') || clientSystemPrompt.includes('Wellness Expert')) {
          personality = 'doctor';
        } else if (clientSystemPrompt.includes('coach') || clientSystemPrompt.includes('Coach mode')) {
          personality = 'coach';
        } else {
          personality = 'friend';
        }
      }

      const systemPrompt = getSecureSystemPrompt(mode, cycleContext, personality);
      const userPrompt = fallbackUserPrompt;
      const maxTokens = clampMaxTokens(req.body?.maxTokens, mode);

      let aiResult;
      try {
        aiResult = await callAiWithFallback({
          deepseekKey: DEEPSEEK_API_KEY.value(),
          geminiKey: GEMINI_API_KEY.value(),
          systemPrompt,
          userPrompt,
          maxTokens,
          temperature: clientTemperature,
        });
      } catch (aiError) {
        // Providers failed AFTER the slot was reserved — give it back.
        await releaseChatSlot(userRef);
        throw aiError;
      }

      const { reply, provider, usage } = aiResult;

      // Best-effort audit + cost aggregate; never blocks the reply.
      await logAiUsage({
        uid,
        mode,
        provider,
        usage,
        messagePreview: message,
      });

      setCors(res);
      res.json({ reply, provider, dailyRemaining: remaining });
    } catch (error) {
      console.error('Chat error:', error);
      setCors(res);
      if (error instanceof QuotaError) {
        res.status(error.status).json({
          error: error.code,
          message: error.message,
        });
        return;
      }
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({
        error: 'server_error',
        message: 'AI providers failed. Please try again.',
      });
    }
  },
);
