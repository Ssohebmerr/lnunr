// ============================================================================
// endpoints/chat.js — POST /chat  (AI chat, premium subscribers only).
// ----------------------------------------------------------------------------
// Request lifecycle (strict server-side paywall — the client is NEVER trusted):
//   1. Verify the Firebase ID token.
//   2. Require adult age + explicit AI consent before evaluating content.
//   3. reservePremiumChatSlot(uid): ONE transaction that requires
//      users/{uid}.isPremium == true AND daily_chat_count < 30, then
//      increments the counter. 403 premium_required / 429 daily_limit_reached
//      otherwise — no external API call is ever made for ineligible users.
//   4. Call DeepSeek (fallback Gemini) with a SERVER-clamped token budget.
//      Client-provided maxTokens can only shrink the budget, never grow it.
//   5. On provider failure the reserved slot is rolled back so the user does
//      not lose a message for our outage.
//   6. Token usage + estimated cost are logged to aiUsageDaily for the admin
//      panel budget monitor.
// Keys live in Firebase Secrets (DEEPSEEK_API_KEY + GEMINI_API_KEY).
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const {
  callAiWithFallback,
  streamAiWithFallback,
  sanitizeHistory,
} = require('../lib/ai_router');
const { buildKnowledgeBlock } = require('../lib/knowledge');
const { detectRedFlags, emergencyResponseFor } = require('../lib/red_flags');
const { extractRememberFacts, saveUserFacts } = require('../lib/ai_memory');
const {
  QuotaError,
  requireAiEligibility,
  reservePremiumChatSlot,
  releaseChatSlot,
} = require('../lib/chat_quota');
const { logAiUsage } = require('../lib/ai_usage');
const { getMaxTokensForMode, getSecureSystemPrompt } = require('../lib/prompts');
const { buildContextString } = require('../lib/moderation');
const { sanitizeCycleContext } = require('../lib/context_sanitize');
const { guardRequest, setCors, bearerToken } = require('../lib/http');

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
    cors: false,
    secrets: [DEEPSEEK_API_KEY, GEMINI_API_KEY],
    timeoutSeconds: 90,
  },
  async (req, res) => {
    if (!(await guardRequest(req, res, { bucket: 'ai', appCheck: 'required' }))) return;

    const token = bearerToken(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const uid = decoded.uid;
      await requireAiEligibility(uid);

      const message = (req.body?.message || '').trim().substring(0, 2000);
      const cycleContext = sanitizeCycleContext(req.body?.cycleContext);
      const mode = req.body?.mode || 'chat';

      if (!message) {
        setCors(res);
        res.status(400).json({ error: 'Message is required.' });
        return;
      }

      // High-risk language receives an immediate, deterministic response.
      // This is intentionally before entitlement/quota/provider calls so an
      // outage, a quota limit, or a non-premium account never delays safety
      // guidance. Doctor reports are generated from a canned request rather
      // than a live symptom conversation, so they keep their normal flow.
      const redFlag = mode === 'doctor'
        ? null
        : detectRedFlags(message, cycleContext);
      if (redFlag) {
        setCors(res);
        res.json({
          reply: emergencyResponseFor(redFlag, cycleContext.userLocale),
          safetyEscalation: redFlag,
        });
        return;
      }

      // Strict paywall + quota — throws QuotaError before any AI spend.
      // The same transaction read piggybacks the user's long-term AI memory.
      const { ref: userRef, remaining, aiMemory } =
        await reservePremiumChatSlot(uid);

      // Server-truth memory injection: whatever the client sent under
      // aiMemory is overwritten with the Firestore-stored facts.
      cycleContext.aiMemory = aiMemory;

      const clientSystemPrompt = (req.body?.systemPrompt || '').trim();
      const clientTemperature = Number(req.body?.temperature) || 0;

      // Multi-turn memory: prior conversation turns sent by the app,
      // validated + capped server-side (see sanitizeHistory).
      const history = sanitizeHistory(req.body?.history);

      // RAG-lite: curated wellness notes matched to this message (may be '').
      const knowledgeBlock = buildKnowledgeBlock(message, cycleContext, mode);

      const contextString = buildContextString(cycleContext, mode);
      const fallbackUserPrompt = mode === 'mood'
        ? `=== USER JOURNAL ENTRY (analyze emotions gently) ===\n${message}\n\nCycle context:\n${contextString}${knowledgeBlock}`
        : `=== APP DATA ===\n${contextString}${knowledgeBlock}\n\n=== USER MESSAGE ===\n${message}`;

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

      let systemPrompt = getSecureSystemPrompt(mode, cycleContext, personality);

      const userPrompt = fallbackUserPrompt;
      const maxTokens = clampMaxTokens(req.body?.maxTokens, mode);
      const aiArgs = {
        deepseekKey: DEEPSEEK_API_KEY.value(),
        geminiKey: GEMINI_API_KEY.value(),
        systemPrompt,
        userPrompt,
        maxTokens,
        temperature: clientTemperature,
        history,
      };

      // ── Streaming path (opt-in via `stream: true`) ──────────────────────
      // Text deltas are written to the response as they arrive, so the app
      // renders the reply token-by-token. Errors BEFORE the first byte still
      // return a clean JSON error + release the slot; once bytes are on the
      // wire we are committed to a 200 and end gracefully on failure.
      if (req.body?.stream === true) {
        let started = false;
        let fullText = '';
        let provider = null;
        let usage = { promptTokens: 0, completionTokens: 0 };

        try {
          for await (const evt of streamAiWithFallback(aiArgs)) {
            if (evt.delta) {
              if (!started) {
                started = true;
                setCors(res);
                res.setHeader('Content-Type', 'text/plain; charset=utf-8');
                res.setHeader('Cache-Control', 'no-cache, no-transform');
                res.setHeader('X-Accel-Buffering', 'no');
                res.setHeader('X-Daily-Remaining', String(remaining));
                if (typeof res.flushHeaders === 'function') res.flushHeaders();
              }
              fullText += evt.delta;
              res.write(evt.delta);
              if (typeof res.flush === 'function') res.flush();
            } else if (evt.done) {
              provider = evt.provider;
              usage = evt.usage || usage;
            }
          }
        } catch (streamErr) {
          if (!started) {
            await releaseChatSlot(userRef);
            setCors(res);
            res.status(500).json({
              error: 'server_error',
              message: 'AI providers failed. Please try again.',
            });
            return;
          }
          // Partial reply already streamed — log and end without an error body.
          console.error('Chat stream error after first byte:', streamErr);
        }

        if (!started) {
          await releaseChatSlot(userRef);
          setCors(res);
          res.status(500).json({
            error: 'server_error',
            message: 'AI providers failed. Please try again.',
          });
          return;
        }

        await logAiUsage({
          uid,
          mode,
          provider: provider || 'unknown',
          usage,
          messageLength: message.length,
        });
        // Long-term memory: persist any [[remember:...]] facts the model
        // emitted in this reply (best-effort, never blocks the response).
        await saveUserFacts(uid, extractRememberFacts(fullText));
        res.end();
        return;
      }

      // ── Non-streaming path (JSON, backward compatible) ──────────────────
      let aiResult;
      try {
        aiResult = await callAiWithFallback(aiArgs);
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
        messageLength: message.length,
      });

      // Long-term memory: persist any [[remember:...]] facts (best-effort).
      await saveUserFacts(uid, extractRememberFacts(reply));

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
