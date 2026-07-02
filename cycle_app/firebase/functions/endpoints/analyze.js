// ============================================================================
// endpoints/analyze.js — POST /analyze  (cycle / pregnancy analysis).
// ----------------------------------------------------------------------------
// Identical authentication and CORS plumbing to `chat.js` (kept inline so
// each endpoint stays self-contained and easy to reason about).
//
// The `doctor` flag in the body swaps the system prompt to the structured
// doctor-visit format and bumps the output budget. We also still log the
// request into `ai_usage/{uid}/messages` so admin analytics cover all
// AI surfaces.
// ============================================================================

'use strict';

const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');

const { callGemini } = require('../lib/gemini');
const { getSystemPromptForMode, getMaxTokensForMode } = require('../lib/prompts');

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

/**
 * Render the cycle / pregnancy context exactly the same way the on-device
 * chat prompt builder does, so the two surfaces stay aligned.
 */
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
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 60 },
  async (req, res) => {
    if (handleCors(req, res)) return;

    const token = authError(req, res);
    if (!token) return;

    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const uid = decoded.uid;
      const message = (req.body?.message || '').trim().substring(0, 2000);
      const cycleContext = req.body?.cycleContext || {};
      const isDoctorReport = req.body?.doctorReport === true;

      if (!message) {
        setCors(res);
        res.status(400).json({ error: 'Message is required.' });
        return;
      }

      await admin.firestore().collection('ai_usage').doc(uid).collection('messages').add({
        message: message.substring(0, 500),
        mode: isDoctorReport ? 'doctor' : 'analyze',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Prefer the client-built prompt (single source of truth in Dart).
      const clientSystemPrompt = (req.body?.systemPrompt || '').trim();
      const clientUserPrompt = (req.body?.userPrompt || '').trim();
      const clientMaxTokens = Number(req.body?.maxTokens) || 0;
      const clientTemperature = Number(req.body?.temperature) || 0;

      const contextString = buildAnalyzeContext(cycleContext);
      const fallbackSystemPrompt = isDoctorReport
        ? getSystemPromptForMode('doctor', cycleContext)
        : getSystemPromptForMode('analyze', cycleContext);
      const fallbackUserPrompt = `=== CYCLE / PREGNANCY DATA ===\n${contextString}\n\n${isDoctorReport ? '=== DOCTOR REPORT REQUEST ===' : '=== USER QUESTION (answer THIS directly — show you read it) ==='}\n${message}`;

      const systemPrompt = clientSystemPrompt || fallbackSystemPrompt;
      const userPrompt = clientUserPrompt || fallbackUserPrompt;
      const maxTokens = clientMaxTokens || (isDoctorReport ? 1200 : getMaxTokensForMode('analyze'));

      const reply = await callGemini(GEMINI_API_KEY.value(), systemPrompt, userPrompt, maxTokens, clientTemperature);

      setCors(res);
      res.json({ reply });
    } catch (error) {
      console.error('Analyze error:', error);
      setCors(res);
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      setCors(res);
      res.status(500).json({ reply: 'عذراً، حدث خطأ أثناء التحليل. حاولي مرة أخرى.' });
    }
  },
);