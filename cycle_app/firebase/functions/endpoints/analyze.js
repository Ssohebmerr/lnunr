// ============================================================================
// endpoints/analyze.js — POST /analyze  (cycle analysis for premium users).
// Same quota + AI routing as chat.js.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { callAiWithFallback } = require('../lib/ai_router');
const {
  QuotaError,
  requireAiEligibility,
  reservePremiumChatSlot,
  releaseChatSlot,
} = require('../lib/chat_quota');
const { logAiUsage } = require('../lib/ai_usage');
const { getSystemPromptForMode, getMaxTokensForMode, getSecureSystemPrompt } = require('../lib/prompts');
const { guardRequest, setCors, bearerToken } = require('../lib/http');
const { sanitizeCycleContext } = require('../lib/context_sanitize');

const DEEPSEEK_API_KEY = defineSecret('DEEPSEEK_API_KEY');
const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

function buildAnalyzeContext(cycleContext) {
  const goal = cycleContext.userGoal || 'unknown';
  const lines = [];
  lines.push('User goal: ' + goal);

  if (goal === 'pregnant') {
    lines.push('Pregnancy week: ' + (cycleContext.pregnancyWeek || 'unknown'));
    lines.push('Trimester: ' + (cycleContext.trimester || 'unknown'));
    lines.push('Due date: ' + (cycleContext.expectedDueDate || 'unknown'));
    lines.push('Gestational day: ' + (cycleContext.gestationalDay || 'unknown'));
    lines.push('Fetal development: ' + (cycleContext.fetalDevelopmentSnippet || 'unknown'));
    lines.push('Maternal changes: ' + (cycleContext.maternalSnippet || 'unknown'));
    if (cycleContext.pregnancyTracking) {
      lines.push('Pregnancy tracking: ' + JSON.stringify(cycleContext.pregnancyTracking));
    }
  } else {
    lines.push('Cycle length: ' + (cycleContext.cycleLength || 'unknown'));
    lines.push('Period duration: ' + (cycleContext.periodDuration || 'unknown'));
    lines.push('Current phase: ' + (cycleContext.currentPhase || 'unknown'));
    lines.push('Current cycle day: ' + (cycleContext.currentCycleDay || 'unknown'));
    lines.push('Next period: ' + (cycleContext.nextPeriodDate || 'unknown'));
    lines.push('Ovulation: ' + (cycleContext.ovulationDate || 'unknown'));
  }

  lines.push('Today\'s log (home screen): ' + (cycleContext.todayLog || 'nothing yet'));

  if (cycleContext.recentSymptoms) {
    const sym = JSON.stringify(cycleContext.recentSymptoms);
    lines.push('Recent symptoms (30d): ' + sym.substring(0, Math.min(sym.length, 2500)));
  }

  lines.push('Wellness logs: ' + (cycleContext.wellnessLogCount || 0));

  if (cycleContext.wellnessHub && Object.keys(cycleContext.wellnessHub).length > 0) {
    const hub = JSON.stringify(cycleContext.wellnessHub);
    lines.push('Wellness hub (pills, sanitary, vitals — anonymized): ' + hub.substring(0, Math.min(hub.length, 2500)));
  }

  if (cycleContext.summary && Object.keys(cycleContext.summary).length > 0) {
    lines.push('Summary: ' + JSON.stringify(cycleContext.summary));
  }

  return lines.join('\n');
}

exports.analyze = onRequest(
  {
    cors: true,
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
      const isDoctorReport = req.body?.doctorReport === true;

      if (!message) {
        setCors(res);
        res.status(400).json({ error: 'Message is required.' });
        return;
      }

      // Strict paywall + quota — throws QuotaError before any AI spend.
      const { ref: userRef, remaining } = await reservePremiumChatSlot(uid);

      const clientSystemPrompt = (req.body?.systemPrompt || '').trim();
      const clientMaxTokens = Number(req.body?.maxTokens) || 0;
      const clientTemperature = Number(req.body?.temperature) || 0;

      const contextString = buildAnalyzeContext(cycleContext);
      const fallbackSystemPrompt = isDoctorReport
        ? getSystemPromptForMode('doctor', cycleContext)
        : getSecureSystemPrompt('analyze', cycleContext, 'friend');
      const fallbackUserPrompt = `=== CYCLE / PREGNANCY DATA ===\n${contextString}\n\n${isDoctorReport ? '=== DOCTOR REPORT REQUEST ===' : '=== USER QUESTION (answer THIS directly — show you read it) ==='}\n${message}`;

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

      const systemPrompt = isDoctorReport
        ? getSystemPromptForMode('doctor', cycleContext)
        : getSecureSystemPrompt('analyze', cycleContext, personality);
      const userPrompt = fallbackUserPrompt;
      // Client may only shrink the budget — the server ceiling always wins.
      const ceiling = isDoctorReport ? 1200 : getMaxTokensForMode('analyze');
      const maxTokens = clientMaxTokens > 0
        ? Math.min(clientMaxTokens, ceiling)
        : ceiling;

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

      await logAiUsage({
        uid,
        mode: isDoctorReport ? 'doctor' : 'analyze',
        provider,
        usage,
        messageLength: message.length,
      });

      setCors(res);
      res.json({ reply, provider, dailyRemaining: remaining });
    } catch (error) {
      console.error('Analyze error:', error);
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
// redeploy marker 2026-07-10 (shared libs: todayLog JSON fix + adaptive context)
