// ============================================================================
// endpoints/chat.js — POST /chat  (AI chat for signed-in premium users).
// Keys live in Firebase Secrets (DEEPSEEK_API_KEY + GEMINI_API_KEY).
// Enforces isPremium + daily_chat_count limit server-side.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { callAiWithFallback } = require('../lib/ai_router');
const {
  DAILY_PREMIUM_CHAT_LIMIT,
  QuotaError,
  assertPremiumChatQuota,
  incrementDailyChatCount,
} = require('../lib/chat_quota');
const { getSystemPromptForMode, getMaxTokensForMode } = require('../lib/prompts');
const { buildContextString } = require('../lib/moderation');

const DEEPSEEK_API_KEY = defineSecret('DEEPSEEK_API_KEY');
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

function handleCors(req, res) {
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.status(204).send('');
    return true;
  }
  return false;
}

function setCors(res) {
  res.set('Access-Control-Allow-Origin', '*');
}

function authError(req, res) {
  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Auth required.' });
    return null;
  }
  return authHeader.split('Bearer ')[1];
}

exports.chat = onRequest(
  {
    cors: true,
    secrets: [DEEPSEEK_API_KEY, GEMINI_API_KEY],
    timeoutSeconds: 90,
  },
  async (req, res) => {
    if (handleCors(req, res)) return;

    const token = authError(req, res);
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

      const userRef = await assertPremiumChatQuota(uid);

      await admin.firestore().collection('ai_usage').doc(uid).collection('messages').add({
        message: message.substring(0, 500),
        mode,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      const clientSystemPrompt = (req.body?.systemPrompt || '').trim();
      const clientUserPrompt = (req.body?.userPrompt || '').trim();
      const clientMaxTokens = Number(req.body?.maxTokens) || 0;
      const clientTemperature = Number(req.body?.temperature) || 0;

      const contextString = buildContextString(cycleContext, mode);
      const fallbackUserPrompt = mode === 'mood'
        ? `=== USER JOURNAL ENTRY (analyze emotions gently) ===\n${message}\n\nCycle context:\n${contextString}`
        : `=== APP DATA ===\n${contextString}\n\n=== USER MESSAGE ===\n${message}`;

      const systemPrompt = clientSystemPrompt || getSystemPromptForMode(mode, cycleContext);
      const userPrompt = clientUserPrompt || fallbackUserPrompt;
      const maxTokens = clientMaxTokens || getMaxTokensForMode(mode);

      const { reply, provider } = await callAiWithFallback({
        deepseekKey: DEEPSEEK_API_KEY.value(),
        geminiKey: GEMINI_API_KEY.value(),
        systemPrompt,
        userPrompt,
        maxTokens,
        temperature: clientTemperature,
      });

      await incrementDailyChatCount(userRef);

      const snap = await userRef.get();
      const used = Number(snap.data()?.daily_chat_count) || 0;
      const remaining = Math.max(0, DAILY_PREMIUM_CHAT_LIMIT - used);

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
      res.status(500).json({ reply: 'عذراً، حدث خطأ. حاولي مرة أخرى لاحقاً.' });
    }
  },
);
