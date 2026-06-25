const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const { defineSecret } = require('firebase-functions/params');
const { GoogleGenerativeAI } = require('@google/generative-ai');

admin.initializeApp();

const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');
const PAYPAL_CLIENT_ID = defineSecret('PAYPAL_CLIENT_ID');
const PAYPAL_CLIENT_SECRET = defineSecret('PAYPAL_CLIENT_SECRET');
const GOOGLE_PLAY_SERVICE_ACCOUNT = defineSecret('GOOGLE_PLAY_SERVICE_ACCOUNT');
const ADMIN_BOOTSTRAP_KEY = defineSecret('ADMIN_BOOTSTRAP_KEY');

// ---------------------------------------------------------------------------
// Premium verification helper (server-side check)
// ---------------------------------------------------------------------------
async function verifyPremium(uid) {
  const userDoc = await admin.firestore().collection('users').doc(uid).get();
  if (!userDoc.exists) return false;
  const data = userDoc.data();
  return data?.isPremium === true || data?.premiumExpiry?.toDate() > new Date();
}

// ---------------------------------------------------------------------------
// Gemini AI (Google AI Studio API)
// ---------------------------------------------------------------------------
const GEMINI_SAFETY_SETTINGS = [
  { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
  { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
  { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_ONLY_HIGH' },
  { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
];

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash'];

// ---------------------------------------------------------------------------
// System prompts
// ---------------------------------------------------------------------------
const personality = `
PERSONALITY — you are Lune 🌸:
- A warm, witty, caring friend who knows cycles and wellness — not a cold robot.
- Reply naturally to greetings, feelings, and small talk ("how are you", "I'm happy", "I'm tired", "I'm sad").
- When someone shares mood or fatigue: empathize first, be human, maybe a light gentle joke — then connect to cycle/self-care if it fits.
- Match the user's tone (casual if they're casual, gentle if they're vulnerable).
- Light humor is welcome when appropriate — never crude, never mean.
- Never repeat the same canned disclaimer twice in a row.`;

const medicalSafety = `
MEDICAL SAFETY (strict — this is the ONLY thing to be strict about):
- NEVER diagnose ("you have PCOS", "this is endometriosis", etc.).
- NEVER prescribe medication or give dosages.
- NEVER say "take ibuprofen/paracetamol" — say "speak to your doctor about pain relief options".
- For serious symptoms (very heavy bleeding, severe pain, fever): urge seeing a doctor — briefly, without lecturing.
- For medical conditions: general education only + "see your doctor for a proper check".`;

const offTopic = `
OFF-TOPIC (narrow — do NOT block normal conversation):
- ALWAYS answer: greetings, "how are you", mood (happy/sad/tired/stressed), feelings, venting, friendship chat, self-care, rest, motivation.
- ONLY gently redirect (one warm sentence + offer help) for clearly unrelated topics: politics, elections, coding, crypto, celebrity gossip, homework unrelated to health.
- NEVER respond with a fixed block message like "I only help with cycle topics" when the user is just talking to you humanly.`;

const responseFormat = `
RESPONSE FORMAT:
- ALWAYS begin by responding directly to what the user just wrote (paraphrase or acknowledge their words so they know you read them).
- Write 2–4 complete natural sentences (like texting a supportive friend). Never stop mid-word or mid-sentence.
- Do NOT use bullet points or numbered lists for simple chat messages — write flowing sentences like a real friend texting.
- Add 2–3 short bullet tips ONLY when the user asks for tips, advice, or lists — skip bullets for greetings, mood sharing, or simple questions.
- Total length: about 80–180 words (medium — not one line, not a wall of text).
- Same language as the user (Arabic or English).
- No robotic disclaimers unless medically necessary.`;

const appKnowledge = `
APP FEATURES — you know this app inside out, guide the user through it:
- **Cycle tracking**: log periods (flow/color), symptoms, pain, mood; predicts next period, ovulation, fertile window, and pregnancy chances.
- **Pregnancy mode**: switch goal to "pregnant" for week-by-week tracking, fetal development info, trimester guidance, due date countdown.
- **Wellness hub**: log birth control pills, sanitary products, sex (protected/unprotected), vitals (weight, temp, blood pressure).
- **Education**: articles on cycle phases, nutrition, exercise, reproductive health, FAQs.
- **Self-care / rituals**: daily check-in for water, rest, stretching, mindfulness; streaks and reminders.
- **Community**: join groups by topic (general, fertility, birth control, conditions, support); post, comment, like, save; anonymous nickname; AI moderation; report/block.
- **Goals**: set personal cycle/wellness goals and track progress.
- **Gamification**: earn badges and XP for logging, streaks, community participation.
- **Partner**: connect with a partner to optionally share cycle data.
- **Doctor report**: generate a structured wellness summary for healthcare visits.
- **Premium**: subscription unlocks unlimited AI chat, advanced analysis, cloud backup.
- **Privacy**: all data stays on-device by default; cloud sync and AI are opt-in and encrypted.
- **Settings**: notifications, language (Arabic/English), theme, Gemini API key, community prefs.
- **Profile**: name, nickname, birth year, avatar.
The app uses Arabic and English UI — match the user's language.
${responseFormat}`;

const HEALTH_SYSTEM_PROMPT = `
You are Lune, a warm menstrual cycle wellness companion in a private health app.
${personality}
${medicalSafety}
${offTopic}
TOPICS you shine at (personalize with cycle data when available):
cycle phases, nutrition, gentle exercise, sleep, mood/PMS, hydration, self-care, symptom patterns, reproductive health education, app features.
${appKnowledge}`;

const ANALYZE_SYSTEM_PROMPT = `
You are Lune, a cycle wellness analyst. Warm, direct, supportive.
${personality}
${medicalSafety}
Analyze patterns from the data provided — do not invent data. Give practical wellness insights.
${appKnowledge}`;

const DOCTOR_REPORT_SYSTEM_PROMPT = `
You are Lune, preparing structured wellness visit notes for a healthcare provider.
${medicalSafety}
Be factual, organized, and thorough. Do not chat casually — this is a clinical-style summary.

RESPONSE FORMAT (doctor visit notes):
- Use clear section headings (## or numbered).
- Write 250–450 words with factual bullet points under each section.
- Base EVERYTHING only on the provided data; say "no data logged" where missing.
- End with one short disclaimer line (not a medical diagnosis).
- Same language as the user.`;

const PREGNANT_CHAT_PROMPT = `
You are Lune, a warm prenatal wellness companion. The user is PREGNANT.
${personality}
${medicalSafety}
Focus on gestational week, trimester, rest, nutrition, safe movement, emotional support.
Do NOT discuss ovulation/fertility unless asked. For urgent symptoms, urge contacting their provider.
${appKnowledge}`;

const PREGNANT_ANALYZE_PROMPT = `
You are Lune, a prenatal wellness analyst. The user is PREGNANT.
${personality}
${medicalSafety}
Analyze pregnancy tracking data — never diagnose. Red-flag symptoms → contact provider immediately.
${appKnowledge}`;

// ---------------------------------------------------------------------------
// NEW FEATURE MODE PROMPTS
// ---------------------------------------------------------------------------
const DAILY_BRIEFING_PROMPT = `
You are Lune 🌸, sending a brief daily wellness greeting.

Write ONE short greeting (3–5 sentences, about 50–80 words). Like a caring friend texting good morning.

Include:
- A warm greeting with the cycle day and phase
- One specific actionable tip for TODAY based on the phase (nutrition, energy, mood, or rest)
- One encouraging line

Do NOT use bullets or lists — write as flowing sentences.
Do NOT give medical advice.
Same language as the user. Be warm and concise.`;

const PATTERN_ANALYSIS_PROMPT = `
You are Lune 🌸, a cycle pattern analyst. Warm, supportive, insightful.

The user wants to understand their patterns from historical cycle data provided below.

Rules:
- Point out 2–3 interesting patterns you notice (cycle length trends, recurring symptoms, timing).
- Connect patterns to cycle phases when possible.
- Give ONE practical suggestion per pattern.
- If data is too limited, say so gently and encourage more logging.
- Write 100–150 words. Flowing sentences, no bullet lists.
${medicalSafety}
Same language as the user.`;

const EMERGENCY_PROMPT = `
You are Lune 🌸, responding to someone who may be in pain or distress RIGHT NOW.

Rules:
- Acknowledge their feelings FIRST — empathize, don't lecture.
- Give 2–3 IMMEDIATE, PRACTICAL steps (comfort measures, when to seek help).
- Be calm, warm, and direct. No long paragraphs.
- If symptoms sound severe (heavy bleeding, fainting, extreme pain, fever), URGENTLY recommend contacting a healthcare provider or emergency services.
- Write 60–100 words maximum. Short, clear sentences.
- Same language as the user.
${medicalSafety}`;

const PHASE_NUTRITION_PROMPT = `
You are Lune 🌸, a nutrition-aware cycle companion.

Based on the user's current cycle phase and data provided:
- Suggest 3–4 specific foods or drinks for TODAY that support this phase.
- Explain briefly WHY each helps (one line per item).
- Include one hydration tip.
- Keep it practical and easy to follow.
- Write 80–120 words. Warm, friendly tone. No clinical language.
${medicalSafety}
Same language as the user.`;

const PARTNER_MESSAGE_PROMPT = `
You are Lune 🌸, helping the user communicate with their partner about their cycle/mood/needs.

Rules:
- The user will describe what they want to tell their partner.
- Write a SHORT, warm message they can copy and send (like texting).
- The message should be honest, gentle, and clear about needs.
- 2–4 sentences. Natural language — not formal.
- If the user doesn't specify what to say, write a general "here's how I'm feeling today" message based on their cycle phase.
- Same language as the user.`;

const FERTILITY_INSIGHT_PROMPT = `
You are Lune 🌸, a fertility-aware wellness companion.

The user wants to understand their fertility window and conception-related questions.

Rules:
- Explain the fertile window based on their cycle data (ovulation date, cycle length).
- Give 2-3 practical, evidence-based tips for conception or fertility awareness.
- Be warm, supportive, and educational. Never pressure.
- If cycle data is limited, explain how tracking more helps improve predictions.
- Write 80-130 words. Warm, clear, non-clinical tone.
${medicalSafety}
Same language as the user.`;

const WEIGHT_INSIGHT_PROMPT = `
You are Lune 🌸, a weight-aware wellness companion.

The user wants insights about their weight in relation to their cycle.

Rules:
- Explain how cycle phases affect water retention, appetite, and metabolism.
- Offer 1-2 practical, body-positive tips for each phase.
- Never promote restrictive diets - focus on intuitive eating and phase support.
- If weight data is provided, note gentle trends without diagnosing.
- Write 80-120 words. Warm, body-positive, educational tone.
${medicalSafety}
Same language as the user.`;

const INTIMACY_GUIDANCE_PROMPT = `
You are Lune 🌸, helping the user understand intimacy and libido in relation to their cycle.

Rules:
- Explain how cycle phases can affect libido, energy, and intimacy naturally.
- Offer 1-2 gentle, practical suggestions to connect with their partner based on the phase.
- Keep sex-positive, inclusive, and respectful of all relationship types.
- Never give medical or sexual health prescriptions.
- Write 60-100 words. Warm, respectful, body-positive tone.
${medicalSafety}
Same language as the user.`;

const MOOD_ANALYSIS_PROMPT = `
You are Lune 🌸, an empathetic emotional wellness companion.

The user has written a journal entry or shared their feelings. Analyze gently:

Rules:
- Reflect back the main emotions you sense (1–2 words: tired, anxious, hopeful, etc.).
- Connect to their cycle phase if data is available — "this is common in the [phase] phase."
- Offer ONE small, specific self-care suggestion.
- Validate their feelings — don't minimize or fix.
- Write 60–100 words. Warm, supportive, like a close friend.
${medicalSafety}
Same language as the user.`;

function getSystemPromptForMode(mode, ctx) {
  const isPregnant = ctx && ctx.userGoal === 'pregnant';
  switch (mode) {
    case 'briefing': return DAILY_BRIEFING_PROMPT;
    case 'patterns': return PATTERN_ANALYSIS_PROMPT;
    case 'emergency': return EMERGENCY_PROMPT;
    case 'nutrition': return PHASE_NUTRITION_PROMPT;
    case 'partner': return PARTNER_MESSAGE_PROMPT;
    case 'mood': return MOOD_ANALYSIS_PROMPT;
    case 'fertility': return FERTILITY_INSIGHT_PROMPT;
    case 'weight': return WEIGHT_INSIGHT_PROMPT;
    case 'intimacy': return INTIMACY_GUIDANCE_PROMPT;
    case 'analyze': return isPregnant ? PREGNANT_ANALYZE_PROMPT : ANALYZE_SYSTEM_PROMPT;
    case 'doctor': return DOCTOR_REPORT_SYSTEM_PROMPT;
    default: return isPregnant ? PREGNANT_CHAT_PROMPT : HEALTH_SYSTEM_PROMPT;
  }
}

function getMaxTokensForMode(mode) {
  switch (mode) {
    case 'briefing': return 300;
    case 'patterns': return 600;
    case 'emergency': return 400;
    case 'nutrition': return 500;
    case 'partner': return 300;
    case 'mood': return 400;
    case 'fertility': return 500;
    case 'weight': return 500;
    case 'intimacy': return 400;
    case 'analyze': return 900;
    case 'doctor': return 1200;
    default: return 4000;
  }
}

// ---------------------------------------------------------------------------
// Build context string from cycleContext
// ---------------------------------------------------------------------------
function buildContextString(cycleContext, mode) {
  if (!cycleContext) return 'No cycle data available.';

  const goal = cycleContext.userGoal || 'unknown';
  const parts = [];

  parts.push('User locale: ' + (cycleContext.userLocale || 'ar'));
  parts.push('User goal: ' + goal);

  if (goal === 'pregnant') {
    parts.push('Pregnancy week: ' + (cycleContext.pregnancyWeek || 'unknown'));
    parts.push('Trimester: ' + (cycleContext.trimester || 'unknown'));
    parts.push('Due date: ' + (cycleContext.expectedDueDate || 'unknown'));
    parts.push('Gestational day: ' + (cycleContext.gestationalDay || 'unknown'));
    parts.push('Fetal development: ' + (cycleContext.fetalDevelopmentSnippet || 'unknown'));
    parts.push('Maternal changes: ' + (cycleContext.maternalSnippet || 'unknown'));
    if (cycleContext.pregnancyTracking) {
      parts.push('Pregnancy tracking: ' + JSON.stringify(cycleContext.pregnancyTracking));
    }
  } else {
    parts.push('Cycle length: ' + (cycleContext.cycleLength || 'unknown'));
    parts.push('Period duration: ' + (cycleContext.periodDuration || 'unknown'));
    parts.push('Current phase: ' + (cycleContext.currentPhase || 'unknown'));
    parts.push('Current cycle day: ' + (cycleContext.currentCycleDay || 'unknown'));
    parts.push('Next period: ' + (cycleContext.nextPeriodDate || 'unknown'));
    parts.push('Ovulation: ' + (cycleContext.ovulationDate || 'unknown'));
  }

  parts.push('Today\'s log (home screen): ' + (cycleContext.todayLog || 'nothing yet'));

  if (cycleContext.recentSymptoms) {
    const sym = JSON.stringify(cycleContext.recentSymptoms);
    parts.push('Recent symptoms (30d): ' + sym.substring(0, Math.min(sym.length, 2500)));
  }

  parts.push('Wellness logs: ' + (cycleContext.wellnessLogCount || 0));

  if (cycleContext.wellnessHub && Object.keys(cycleContext.wellnessHub).length > 0) {
    const hub = JSON.stringify(cycleContext.wellnessHub);
    parts.push('Wellness hub (pills, sanitary, vitals — anonymized): ' + hub.substring(0, Math.min(hub.length, 2500)));
  }

  if (cycleContext.summary && Object.keys(cycleContext.summary).length > 0) {
    parts.push('Summary: ' + JSON.stringify(cycleContext.summary));
  }

  if (cycleContext.cycleHistory) {
    parts.push('Cycle history (last 6): ' + JSON.stringify(cycleContext.cycleHistory));
  }

  if (mode === 'patterns' && cycleContext.cycleHistory) {
    parts.push('\n=== PATTERN ANALYSIS: use cycleHistory data above to find trends ===');
  }
  if (mode === 'nutrition') {
    parts.push('\n=== NUTRITION: focus on current phase (' + (cycleContext.currentPhase || 'unknown') + ') ===');
  }
  if (mode === 'partner') {
    parts.push('\n=== PARTNER MESSAGE: write a message the user can send to their partner ===');
  }

  return parts.join('\n');
}

// ---------------------------------------------------------------------------
// Gemini AI caller (Google AI Studio)
// ---------------------------------------------------------------------------
async function callGemini(systemPrompt, userPrompt, maxTokens) {
  const genAI = new GoogleGenerativeAI(GEMINI_API_KEY.value());
  const temperature = (maxTokens || 2000) <= 400 ? 0.6 : 0.78;
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
      if (text && text.trim().length > 0) {
        return text.trim();
      }

      const blockReason = result.response?.promptFeedback?.blockReason;
      if (blockReason) {
        return '⚠️ Content blocked: ' + blockReason + '. Please rephrase your message.';
      }
    } catch (error) {
      lastError = error;
      console.error(`callGemini failed for ${modelName}:`, error);
    }
  }

  if (lastError) {
    console.error('callGemini exhausted model fallbacks:', lastError);
  }

  return 'عذراً، لم أتمكن من توليد رد. حاولي مرة أخرى.';
}

// ---------------------------------------------------------------------------
// Moderate content
// ---------------------------------------------------------------------------
async function moderateContent(text) {
  const moderationPrompt = `You are a content moderator for a women's health community app.
Review the post/comment below. Reject ONLY if it contains:
- Medical prescriptions or specific medication dosages
- Dangerous self-harm/suicide content
- Harassment, hate speech, or threats
- Spam, ads, or promotional links
Allow supportive peer discussion, emotional sharing, personal experiences.
Reply ONLY with JSON: {"approved":true} or {"approved":false,"reason":"short reason"}`;

  try {
    const result = await callGemini(moderationPrompt, text, 100);
    if (result.includes('"approved":true')) return { approved: true };
    if (result.includes('"approved":false')) {
      const match = result.match(/"reason"\s*:\s*"([^"]+)"/);
      return { approved: false, reason: match ? match[1] : 'Content not allowed.' };
    }
    return { approved: true };
  } catch (e) {
    console.error('Moderation error:', e);
    return { approved: true };
  }
}

// ---------------------------------------------------------------------------
// Health chat function (now supports modes)
// ---------------------------------------------------------------------------
exports.chat = onRequest(
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 60 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const message = (req.body?.message || '').trim().substring(0, 2000);
      const cycleContext = req.body?.cycleContext || {};
      const mode = req.body?.mode || 'chat';

      if (!message) { res.status(400).json({ error: 'Message is required.' }); return; }

      await admin.firestore().collection('ai_usage').doc(uid).collection('messages').add({
        message: message.substring(0, 500),
        mode: mode,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      const contextString = buildContextString(cycleContext, mode);
      const userPrompt = mode === 'mood'
        ? `=== USER JOURNAL ENTRY (analyze emotions gently) ===\n${message}\n\nCycle context:\n${contextString}`
        : `=== APP DATA ===\n${contextString}\n\n=== USER MESSAGE ===\n${message}`;

      const systemPrompt = getSystemPromptForMode(mode, cycleContext);
      const maxTokens = getMaxTokensForMode(mode);
      const reply = await callGemini(systemPrompt, userPrompt, maxTokens);

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ reply: reply });
    } catch (error) {
      console.error('Chat error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') { res.status(401).json({ error: 'Token expired.' }); return; }
      res.status(500).json({ reply: 'عذراً، حدث خطأ. حاولي مرة أخرى لاحقاً.' });
    }
  }
);

// ---------------------------------------------------------------------------
// Cycle analysis function
// ---------------------------------------------------------------------------
exports.analyze = onRequest(
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 60 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const message = (req.body?.message || '').trim().substring(0, 2000);
      const cycleContext = req.body?.cycleContext || {};
      const isDoctorReport = req.body?.doctorReport === true;

      if (!message) { res.status(400).json({ error: 'Message is required.' }); return; }

      await admin.firestore().collection('ai_usage').doc(uid).collection('messages').add({
        message: message.substring(0, 500),
        mode: isDoctorReport ? 'doctor' : 'analyze',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      const goal = cycleContext.userGoal || 'unknown';
      const contextLines = [];
      contextLines.push('User goal: ' + goal);

      if (goal === 'pregnant') {
        contextLines.push('Pregnancy week: ' + (cycleContext.pregnancyWeek || 'unknown'));
        contextLines.push('Trimester: ' + (cycleContext.trimester || 'unknown'));
        contextLines.push('Due date: ' + (cycleContext.expectedDueDate || 'unknown'));
        contextLines.push('Gestational day: ' + (cycleContext.gestationalDay || 'unknown'));
        contextLines.push('Fetal development: ' + (cycleContext.fetalDevelopmentSnippet || 'unknown'));
        contextLines.push('Maternal changes: ' + (cycleContext.maternalSnippet || 'unknown'));
        if (cycleContext.pregnancyTracking) {
          contextLines.push('Pregnancy tracking: ' + JSON.stringify(cycleContext.pregnancyTracking));
        }
      } else {
        contextLines.push('Cycle length: ' + (cycleContext.cycleLength || 'unknown'));
        contextLines.push('Period duration: ' + (cycleContext.periodDuration || 'unknown'));
        contextLines.push('Current phase: ' + (cycleContext.currentPhase || 'unknown'));
        contextLines.push('Current cycle day: ' + (cycleContext.currentCycleDay || 'unknown'));
        contextLines.push('Next period: ' + (cycleContext.nextPeriodDate || 'unknown'));
        contextLines.push('Ovulation: ' + (cycleContext.ovulationDate || 'unknown'));
      }

      contextLines.push('Today\'s log (home screen): ' + (cycleContext.todayLog || 'nothing yet'));

      if (cycleContext.recentSymptoms) {
        const sym = JSON.stringify(cycleContext.recentSymptoms);
        contextLines.push('Recent symptoms (30d): ' + sym.substring(0, Math.min(sym.length, 2500)));
      }

      contextLines.push('Wellness logs: ' + (cycleContext.wellnessLogCount || 0));

      if (cycleContext.wellnessHub && Object.keys(cycleContext.wellnessHub).length > 0) {
        const hub = JSON.stringify(cycleContext.wellnessHub);
        contextLines.push('Wellness hub (pills, sanitary, vitals — anonymized): ' + hub.substring(0, Math.min(hub.length, 2500)));
      }

      if (cycleContext.summary && Object.keys(cycleContext.summary).length > 0) {
        contextLines.push('Summary: ' + JSON.stringify(cycleContext.summary));
      }

      const contextString = contextLines.join('\n');
      const systemPrompt = isDoctorReport ? DOCTOR_REPORT_SYSTEM_PROMPT : ANALYZE_SYSTEM_PROMPT;
      const maxTokens = isDoctorReport ? 1200 : 900;
      const userPrompt = `=== CYCLE / PREGNANCY DATA ===\n${contextString}\n\n${isDoctorReport ? '=== DOCTOR REPORT REQUEST ===' : '=== USER QUESTION (answer THIS directly — show you read it) ==='}\n${message}`;

      const reply = await callGemini(systemPrompt, userPrompt, maxTokens);

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ reply: reply });
    } catch (error) {
      console.error('Analyze error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') { res.status(401).json({ error: 'Token expired.' }); return; }
      res.status(500).json({ reply: 'عذراً، حدث خطأ أثناء التحليل. حاولي مرة أخرى.' });
    }
  }
);

// ---------------------------------------------------------------------------
// Community moderation function
// ---------------------------------------------------------------------------
exports.moderate = onRequest(
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const text = (req.body?.text || '').trim().substring(0, 1000);

      if (!text) { res.status(400).json({ approved: true }); return; }

      const result = await moderateContent(text);

      res.set('Access-Control-Allow-Origin', '*');
      res.json(result);
    } catch (error) {
      console.error('Moderate error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') { res.status(401).json({ error: 'Token expired.' }); return; }
      res.json({ approved: true });
    }
  }
);

// ---------------------------------------------------------------------------
// Community auto-moderation (Firestore trigger)
// ---------------------------------------------------------------------------
async function moderateFirestoreDoc(collection, docId, text) {
  const result = await moderateContent(text);
  if (!result.approved) {
    await admin.firestore().collection(collection).doc(docId).update({
      moderationStatus: 'rejected',
      moderationReason: result.reason || 'Content not allowed.',
      rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`Rejected ${collection}/${docId}: ${result.reason}`);
  } else {
    // AI approved — auto-approve the content
    await admin.firestore().collection(collection).doc(docId).update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'auto_ai',
    });
    console.log(`Auto-approved ${collection}/${docId}`);
  }
}

// ---------------------------------------------------------------------------
// Auto-delete expired stories (scheduled — runs every hour)
// ---------------------------------------------------------------------------
exports.cleanupExpiredStories = onSchedule(
  { schedule: 'every 1 hours', timeoutSeconds: 120, memory: '256MiB' },
  async (event) => {
    const now = admin.firestore.Timestamp.now();
    const communitiesSnap = await admin.firestore().collection('communities').get();
    let totalDeleted = 0;

    for (const community of communitiesSnap.docs) {
      try {
        const expiredSnap = await community.ref
          .collection('stories')
          .where('expiresAt', '<=', now)
          .limit(100)
          .get();

        if (expiredSnap.empty) continue;

        const batch = admin.firestore().batch();
        expiredSnap.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        totalDeleted += expiredSnap.size;
        console.log(`Cleaned ${expiredSnap.size} expired stories from community ${community.id}`);
      } catch (e) {
        console.error(`Error cleaning stories for community ${community.id}:`, e);
      }
    }

    console.log(`Story cleanup complete. Total deleted: ${totalDeleted}`);
  }
);

// ---------------------------------------------------------------------------
// Auto-moderate stories when created (textOverlay content)
// ---------------------------------------------------------------------------
exports.onStoryCreated = onDocumentCreated(
  'communities/{communityId}/stories/{storyId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const text = data.textOverlay || '';
    if (text.length < 3) return;

    const result = await moderateContent(text);
    const communityId = event.params.communityId;
    const storyId = event.params.storyId;
    const docPath = `communities/${communityId}/stories/${storyId}`;

    if (result.approved) {
      console.log(`Story approved: ${docPath}`);
    } else {
      // Delete rejected stories immediately (stories are ephemeral, no point keeping them)
      await event.data.ref.delete();
      console.log(`Rejected & deleted story ${docPath}: ${result.reason}`);
    }
  }
);

// Auto-moderate posts when created with pending_review status
exports.onPostCreated = onDocumentCreated(
  'communities/{communityId}/posts/{postId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.moderationStatus !== 'pending_review') return;

    const text = data.text || '';
    if (text.length < 3) {
      await event.data.ref.update({
        moderationStatus: 'approved',
        moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationReviewedBy: 'auto_short',
      });
      return;
    }

    const result = await moderateContent(text);
    const communityId = event.params.communityId;
    const postId = event.params.postId;
    const docPath = `communities/${communityId}/posts/${postId}`;

    if (result.approved) {
      await event.data.ref.update({
        moderationStatus: 'approved',
        moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationReviewedBy: 'auto_ai',
      });
      console.log(`Auto-approved post ${docPath}`);
    } else {
      await event.data.ref.update({
        moderationStatus: 'rejected',
        hidden: true,
        moderationReason: result.reason || 'Content not allowed.',
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Rejected post ${docPath}: ${result.reason}`);
    }
  }
);

// Auto-moderate comments when created with pending_review status
exports.onCommentCreated = onDocumentCreated(
  'communities/{communityId}/posts/{postId}/comments/{commentId}',
  async (event) => {
    const data = event.data?.data();
    if (!data || data.moderationStatus !== 'pending_review') return;

    const text = data.text || '';
    if (text.length < 3) {
      await event.data.ref.update({
        moderationStatus: 'approved',
        moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationReviewedBy: 'auto_short',
      });
      return;
    }

    const result = await moderateContent(text);

    if (result.approved) {
      await event.data.ref.update({
        moderationStatus: 'approved',
        moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
        moderationReviewedBy: 'auto_ai',
      });
    } else {
      await event.data.ref.update({
        moderationStatus: 'rejected',
        hidden: true,
        moderationReason: result.reason || 'Content not allowed.',
        rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);

async function verifyCallerIsAdmin(decoded) {
  if (decoded.admin === true) return true;
  const adminDoc = await admin.firestore().collection('admins').doc(decoded.uid).get();
  if (adminDoc.exists) return true;
  const userDoc = await admin.firestore().collection('users').doc(decoded.uid).get();
  return userDoc.exists
    && (userDoc.data()?.isAdmin === true || userDoc.data()?.role === 'admin');
}

function serializeFirestoreValue(v) {
  if (v === null || v === undefined) return v;
  if (v instanceof admin.firestore.Timestamp) {
    return { __type: 'timestamp', iso: v.toDate().toISOString() };
  }
  if (Array.isArray(v)) return v.map(serializeFirestoreValue);
  if (typeof v === 'object' && v.constructor === Object) {
    const out = {};
    for (const [k, val] of Object.entries(v)) out[k] = serializeFirestoreValue(val);
    return out;
  }
  return v;
}

function serializeDoc(docSnap) {
  return {
    id: docSnap.id,
    path: docSnap.ref.path,
    ...serializeFirestoreValue(docSnap.data()),
  };
}

function applyServerTokens(data) {
  if (data === null || data === undefined) return data;
  if (data.__serverTimestamp === true) return admin.firestore.FieldValue.serverTimestamp();
  if (data.__delete === true) return admin.firestore.FieldValue.delete();
  if (Array.isArray(data)) return data.map(applyServerTokens);
  if (typeof data === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(data)) out[k] = applyServerTokens(v);
    return out;
  }
  return data;
}

function refFromPath(pathSegments) {
  let ref = admin.firestore();
  for (let i = 0; i < pathSegments.length; i += 1) {
    ref = (i % 2 === 0) ? ref.collection(pathSegments[i]) : ref.doc(pathSegments[i]);
  }
  return ref;
}

function collectionFromPath(pathSegments) {
  if (!pathSegments?.length || pathSegments.length % 2 !== 1) {
    throw new Error('Invalid collection path');
  }
  return refFromPath(pathSegments);
}

function docFromPath(pathSegments) {
  if (!pathSegments?.length || pathSegments.length % 2 !== 0) {
    throw new Error('Invalid document path');
  }
  return refFromPath(pathSegments);
}

async function runAdminQuery(payload) {
  const {
    collectionPath,
    collectionGroup,
    filters = [],
    orderBy: orderByField,
    limit: rowLimit = 100,
  } = payload;

  let q;
  if (collectionGroup) {
    q = admin.firestore().collectionGroup(collectionGroup);
  } else {
    q = collectionFromPath(collectionPath);
  }

  for (const f of filters) {
    q = q.where(f.field, f.op, f.value);
  }
  if (orderByField?.field) {
    q = q.orderBy(orderByField.field, orderByField.dir || 'asc');
  }
  if (rowLimit) q = q.limit(rowLimit);

  const snap = await q.get();
  return snap.docs.map(serializeDoc);
}

async function runAdminCount(payload) {
  const { collectionPath, collectionGroup, filters = [] } = payload;
  let q;
  if (collectionGroup) {
    q = admin.firestore().collectionGroup(collectionGroup);
  } else {
    q = collectionFromPath(collectionPath);
  }
  for (const f of filters) {
    q = q.where(f.field, f.op, f.value);
  }
  const snap = await q.count().get();
  return snap.data().count;
}

// Admin panel API — uses Admin SDK (bypasses client Firestore / App Check).
exports.adminApi = onRequest(
  { cors: true, timeoutSeconds: 120 },
  async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      res.status(204).send('');
      return;
    }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const { action, payload = {} } = req.body || {};

      if (action === 'checkAdmin') {
        const isAdmin = await verifyCallerIsAdmin(decoded);
        res.set('Access-Control-Allow-Origin', '*');
        res.json({ isAdmin });
        return;
      }

      if (action === 'ensureAdmin') {
        const isAdmin = await verifyCallerIsAdmin(decoded);
        if (!isAdmin) {
          res.status(403).json({ error: 'Admin only.' });
          return;
        }
        const email = decoded.email || null;
        const batch = admin.firestore().batch();
        batch.set(admin.firestore().collection('admins').doc(decoded.uid), {
          email,
          role: 'admin',
          isAdmin: true,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        batch.set(admin.firestore().collection('users').doc(decoded.uid), {
          email,
          isAdmin: true,
          role: 'admin',
          lastLoginAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await batch.commit();
        res.set('Access-Control-Allow-Origin', '*');
        res.json({ ok: true });
        return;
      }

      if (!(await verifyCallerIsAdmin(decoded))) {
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      let result;
      switch (action) {
        case 'overview': {
          const [users, premium, posts, pending, articles] = await Promise.all([
            admin.firestore().collection('users').count().get(),
            admin.firestore().collection('users').where('isPremium', '==', true).count().get(),
            admin.firestore().collectionGroup('posts').count().get(),
            admin.firestore().collection('communityReports').where('status', '==', 'pending').count().get(),
            admin.firestore().collection('educationArticles').where('published', '==', true).count().get(),
          ]);
          result = {
            users: users.data().count,
            premium: premium.data().count,
            posts: posts.data().count,
            pending: pending.data().count,
            articles: articles.data().count,
          };
          break;
        }
        case 'query':
          result = { items: await runAdminQuery(payload) };
          break;
        case 'count':
          result = { count: await runAdminCount(payload) };
          break;
        case 'get': {
          const snap = await docFromPath(payload.path).get();
          result = snap.exists
            ? { exists: true, item: serializeDoc(snap) }
            : { exists: false };
          break;
        }
        case 'set':
          await docFromPath(payload.path).set(
            applyServerTokens(payload.data || {}),
            { merge: payload.merge === true },
          );
          result = { ok: true };
          break;
        case 'update':
          await docFromPath(payload.path).update(applyServerTokens(payload.data || {}));
          result = { ok: true };
          break;
        case 'delete':
          await docFromPath(payload.path).delete();
          result = { ok: true };
          break;
        case 'add': {
          const ref = await collectionFromPath(payload.collectionPath).add(
            applyServerTokens(payload.data || {}),
          );
          result = { id: ref.id };
          break;
        }
        default:
          res.status(400).json({ error: `Unknown action: ${action}` });
          return;
      }

      res.set('Access-Control-Allow-Origin', '*');
      res.json(result);
    } catch (error) {
      console.error('adminApi error:', req.body?.action, error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: error.message || 'Admin API failed.' });
    }
  },
);

async function applyModerationResult(ref, text, kind) {
  if (text.length < 3) {
    await ref.update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'reprocess_short',
    });
    return 'approved';
  }

  const result = await moderateContent(text);
  if (result.approved) {
    await ref.update({
      moderationStatus: 'approved',
      moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
      moderationReviewedBy: 'reprocess_ai',
    });
    return 'approved';
  }

  await ref.update({
    moderationStatus: 'rejected',
    hidden: true,
    moderationReason: result.reason || 'Content not allowed.',
    rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderationReviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    moderationReviewedBy: 'reprocess_ai',
  });
  console.log(`Rejected ${kind} ${ref.path}: ${result.reason}`);
  return 'rejected';
}

// Re-run AI moderation on posts/comments stuck in pending_review (admin only).
exports.reprocessPendingModeration = onRequest(
  { cors: true, secrets: [GEMINI_API_KEY], timeoutSeconds: 120 },
  async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      res.status(204).send('');
      return;
    }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      if (!(await verifyCallerIsAdmin(decoded))) {
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      const postsSnap = await admin.firestore()
        .collectionGroup('posts')
        .where('moderationStatus', '==', 'pending_review')
        .limit(40)
        .get();

      const commentsSnap = await admin.firestore()
        .collectionGroup('comments')
        .where('moderationStatus', '==', 'pending_review')
        .limit(40)
        .get();

      let postsProcessed = 0;
      let commentsProcessed = 0;

      for (const docSnap of postsSnap.docs) {
        const text = docSnap.data().text || '';
        await applyModerationResult(docSnap.ref, text, 'post');
        postsProcessed += 1;
      }

      for (const docSnap of commentsSnap.docs) {
        const text = docSnap.data().text || '';
        await applyModerationResult(docSnap.ref, text, 'comment');
        commentsProcessed += 1;
      }

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ postsProcessed, commentsProcessed });
    } catch (error) {
      console.error('reprocessPendingModeration error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: 'Failed to reprocess pending moderation.' });
    }
  }
);

// Sync Firebase Auth accounts into Firestore users/ (admin only).
exports.syncUsersFromAuth = onRequest(
  { cors: true, timeoutSeconds: 300 },
  async (req, res) => {
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Origin', '*');
      res.set('Access-Control-Allow-Methods', 'POST');
      res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
      res.status(204).send('');
      return;
    }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Auth required.' });
      return;
    }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      if (!(await verifyCallerIsAdmin(decoded))) {
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      let synced = 0;
      let nextPageToken;
      do {
        const result = await admin.auth().listUsers(1000, nextPageToken);
        let batch = admin.firestore().batch();
        let ops = 0;

        for (const user of result.users) {
          batch.set(
            admin.firestore().collection('users').doc(user.uid),
            {
              email: user.email || null,
              ...(user.displayName ? { name: user.displayName } : {}),
              authProviders: user.providerData.map((p) => p.providerId).join(','),
              authCreatedAt: user.metadata.creationTime || null,
              authLastSignInAt: user.metadata.lastSignInTime || null,
              syncedFromAuthAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          ops += 1;
          synced += 1;
          if (ops >= 400) {
            await batch.commit();
            batch = admin.firestore().batch();
            ops = 0;
          }
        }

        if (ops > 0) await batch.commit();
        nextPageToken = result.pageToken;
      } while (nextPageToken);

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ synced });
    } catch (error) {
      console.error('syncUsersFromAuth error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') {
        res.status(401).json({ error: 'Token expired.' });
        return;
      }
      res.status(500).json({ error: 'Failed to sync users from Auth.' });
    }
  }
);

// Auto-hide posts with 3+ reports
exports.onReportCreated = onDocumentCreated(
  'communityReports/{reportId}',
  async (event) => {
    const data = event.data?.data();
    if (!data?.postId || !data?.communityId) return;

    const postId = data.postId;
    const communityId = data.communityId;

    // Count reports for this post
    const reports = await admin.firestore()
      .collection('communityReports')
      .where('postId', '==', postId)
      .where('status', '==', 'pending')
      .get();

    if (reports.size >= 3) {
      // Auto-hide and queue for admin review
      await admin.firestore()
        .collection('communities').doc(communityId)
        .collection('posts').doc(postId)
        .update({
          hidden: true,
          moderationStatus: 'pending_review',
          autoHiddenReason: `Auto-hidden: ${reports.size} reports`,
          autoHiddenAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(`Auto-hidden post ${postId} (${reports.size} reports)`);
    }
  }
);

// ---------------------------------------------------------------------------
// Bootstrap admin user (one-time setup)
// ---------------------------------------------------------------------------
exports.bootstrapAdmin = onCall({ secrets: [ADMIN_BOOTSTRAP_KEY] }, async (request) => {
  // Accept both 'key' and 'bootstrapKey' for backward compatibility
  const key = request.data?.key || request.data?.bootstrapKey;
  if (!key || key !== ADMIN_BOOTSTRAP_KEY.value()) {
    throw new HttpsError('permission-denied', 'Invalid bootstrap key.');
  }

  const email = request.data?.email;
  const password = request.data?.password;

  if (!email || !password) {
    throw new HttpsError('invalid-argument', 'Email and password required.');
  }

  let userRecord;
  let isNewUser = false;
  try {
    userRecord = await admin.auth().getUserByEmail(email);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      userRecord = await admin.auth().createUser({ email, password, emailVerified: true });
      isNewUser = true;
    } else {
      throw e;
    }
  }

  // Always update password for existing users too
  if (!isNewUser) {
    await admin.auth().updateUser(userRecord.uid, { password });
  }

  await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });

  // Write to BOTH 'users' and 'admins' collections (app reads from 'admins')
  const batch = admin.firestore().batch();

  batch.set(admin.firestore().collection('users').doc(userRecord.uid), {
    email: email,
    role: 'admin',
    isAdmin: true,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  batch.set(admin.firestore().collection('admins').doc(userRecord.uid), {
    email: email,
    role: 'admin',
    isAdmin: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await batch.commit();

  return { uid: userRecord.uid, email: email, role: 'admin' };
});

// ---------------------------------------------------------------------------
// Delete user account (Google Play requirement)
// ---------------------------------------------------------------------------
exports.deleteUserAccount = onRequest(
  { cors: true, timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;

      // Delete Firestore user data
      const batch = admin.firestore().batch();
      const collections = ['chats', 'cycle_logs', 'wellness_logs', 'community_reports', 'community_comments', 'community_likes'];
      for (const col of collections) {
        try {
          const snap = await admin.firestore().collection('users').doc(uid).collection(col).get();
          snap.docs.forEach(doc => batch.delete(doc.ref));
        } catch (_) {}
      }
      batch.delete(admin.firestore().collection('users').doc(uid));
      await batch.commit();

      // Delete Auth user
      await admin.auth().deleteUser(uid);

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ success: true });
    } catch (error) {
      console.error('Delete account error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      if (error.code === 'auth/id-token-expired') { res.status(401).json({ error: 'Token expired. Please re-authenticate.' }); return; }
      res.status(500).json({ error: 'Failed to delete account.' });
    }
  }
);

// ---------------------------------------------------------------------------
// Verify Google Play purchase
// ---------------------------------------------------------------------------
exports.verifyPlayPurchase = onRequest(
  { cors: true, secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT], timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const { purchaseToken, productId, packageName } = req.body || {};

      if (!purchaseToken || !productId) {
        res.status(400).json({ verified: false, error: 'Missing purchaseToken or productId' });
        return;
      }

      // Verify with Google Play Developer API
      const { google } = require('googleapis');
      const serviceAccount = JSON.parse(GOOGLE_PLAY_SERVICE_ACCOUNT.value());
      const auth = new google.auth.GoogleAuth({
        credentials: serviceAccount,
        scopes: ['https://www.googleapis.com/auth/androidpublisher'],
      });
      const androidPublisher = google.androidpublisher({ version: 'v3', auth });

      const purchase = await androidPublisher.purchases.subscriptions.get({
        packageName: packageName || 'com.lune.app',
        productId: productId,
        token: purchaseToken,
      });

      const isAcknowledged = purchase.data.acknowledgementState === 1;
      const isValid = purchase.data.paymentState === 1 || purchase.data.paymentState === 2;

      if (isValid && !isAcknowledged) {
        await androidPublisher.purchases.subscriptions.acknowledge({
          packageName: packageName || 'com.lune.app',
          productId: productId,
          token: purchaseToken,
          requestBody: { developerPayload: uid },
        });
      }

      if (isValid) {
        await admin.firestore().collection('users').doc(uid).set({
          isPremium: true,
          premiumSource: 'google_play',
          premiumProductId: productId,
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ verified: isValid });
    } catch (error) {
      console.error('Verify Play purchase error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      res.json({ verified: false, error: error.message });
    }
  }
);

// ---------------------------------------------------------------------------
// Create PayPal order
// ---------------------------------------------------------------------------
exports.createPayPalOrder = onRequest(
  { cors: true, secrets: [PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET], timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);

      const clientId = PAYPAL_CLIENT_ID.value();
      const clientSecret = PAYPAL_CLIENT_SECRET.value();
      if (!clientId || !clientSecret || clientId === 'PLACEHOLDER') {
        res.status(500).json({ error: 'PayPal not configured.' });
        return;
      }

      // Get access token
      const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
      const tokenRes = await fetch('https://api-m.paypal.com/v1/oauth2/token', {
        method: 'POST',
        headers: { 'Authorization': `Basic ${basicAuth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'grant_type=client_credentials',
      });
      const tokenData = await tokenRes.json();
      const accessToken = tokenData.access_token;

      // Create order
      const orderRes = await fetch('https://api-m.paypal.com/v2/checkout/orders', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          intent: 'CAPTURE',
          purchase_units: [{
            amount: { currency_code: 'USD', value: '4.99' },
            description: 'Lune Premium - Monthly',
          }],
          application_context: {
            return_url: 'https://lune-7d956.web.app/premium/success/',
            cancel_url: 'https://lune-7d956.web.app/premium/cancel/',
          },
        }),
      });
      const orderData = await orderRes.json();

      const approvalUrl = orderData.links?.find(l => l.rel === 'approve')?.href;
      const orderId = orderData.id;

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ orderId, approvalUrl });
    } catch (error) {
      console.error('Create PayPal order error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      res.status(500).json({ error: 'Failed to create PayPal order.' });
    }
  }
);

// ---------------------------------------------------------------------------
// Capture PayPal order
// ---------------------------------------------------------------------------
exports.capturePayPalOrder = onRequest(
  { cors: true, secrets: [PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET], timeoutSeconds: 30 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      const uid = decoded.uid;
      const orderId = req.body?.orderId;
      if (!orderId) { res.status(400).json({ error: 'Missing orderId.' }); return; }

      const clientId = PAYPAL_CLIENT_ID.value();
      const clientSecret = PAYPAL_CLIENT_SECRET.value();

      // Get access token
      const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');
      const tokenRes = await fetch('https://api-m.paypal.com/v1/oauth2/token', {
        method: 'POST',
        headers: { 'Authorization': `Basic ${basicAuth}`, 'Content-Type': 'application/x-www-form-urlencoded' },
        body: 'grant_type=client_credentials',
      });
      const tokenData = await tokenRes.json();
      const accessToken = tokenData.access_token;

      // Capture order
      const captureRes = await fetch(`https://api-m.paypal.com/v2/checkout/orders/${orderId}/capture`, {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
      });
      const captureData = await captureRes.json();

      if (captureData.status === 'COMPLETED') {
        await admin.firestore().collection('users').doc(uid).set({
          isPremium: true,
          premiumSource: 'paypal',
          premiumOrderId: orderId,
          premiumUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      }

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ status: captureData.status });
    } catch (error) {
      console.error('Capture PayPal order error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      res.status(500).json({ error: 'Failed to capture PayPal order.' });
    }
  }
);

// ---------------------------------------------------------------------------
// Admin broadcast — send push notification to all users
// ---------------------------------------------------------------------------
exports.adminBroadcast = onRequest(
  { cors: true, timeoutSeconds: 60 },
  async (req, res) => {
    if (req.method === 'OPTIONS') { res.set('Access-Control-Allow-Origin', '*'); res.set('Access-Control-Allow-Methods', 'POST'); res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type'); res.status(204).send(''); return; }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) { res.status(401).json({ error: 'Auth required.' }); return; }

    try {
      const decoded = await admin.auth().verifyIdToken(authHeader.split('Bearer ')[1]);
      if (!(await verifyCallerIsAdmin(decoded))) {
        res.status(403).json({ error: 'Admin only.' });
        return;
      }

      const { title, body, audience } = req.body || {};
      if (!title || !body) { res.status(400).json({ error: 'Title and body required.' }); return; }

      // Get FCM tokens
      const usersSnap = await admin.firestore().collection('users').where('fcmToken', '!=', null).get();
      const tokens = usersSnap.docs.map(d => d.data().fcmToken).filter(Boolean);

      let sent = 0, failed = 0;
      if (tokens.length > 0) {
        const message = {
          notification: { title, body },
          tokens: tokens.slice(0, 500), // FCM limit
        };
        const response = await admin.messaging().sendEachForMulticast(message);
        sent = response.successCount;
        failed = response.failureCount;
      }

      // Log broadcast
      await admin.firestore().collection('adminBroadcasts').add({
        title, body, audience: audience || 'all',
        tokensAttempted: tokens.length, sent, failed,
        sentBy: decoded.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      res.set('Access-Control-Allow-Origin', '*');
      res.json({ sent, failed, tokensAttempted: tokens.length });
    } catch (error) {
      console.error('Admin broadcast error:', error);
      res.set('Access-Control-Allow-Origin', '*');
      res.status(500).json({ error: 'Failed to send broadcast.' });
    }
  }
);

// ---------------------------------------------------------------------------
// Placeholder for PayPal config (not used — manual link for now)
// ---------------------------------------------------------------------------
exports.getPaypalConfig = onRequest({ cors: true }, async (req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.json({ clientId: 'PLACEHOLDER', environment: 'sandbox' });
});

// ---------------------------------------------------------------------------
// Google Play (not used — manual link for now)
// ---------------------------------------------------------------------------
exports.googlePlayWebhook = onRequest({ cors: true, secrets: [GOOGLE_PLAY_SERVICE_ACCOUNT] }, async (req, res) => {
  console.log('Google Play webhook:', JSON.stringify(req.body));
  res.status(200).json({ ok: true });
});

// ---------------------------------------------------------------------------
// Scheduled: Clean up expired stories (runs every hour)
// ---------------------------------------------------------------------------
exports.cleanupExpiredStories = onSchedule('every 60 minutes', async () => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  // Query across all communities for expired stories.
  const snap = await db.collectionGroup('stories')
    .where('expiresAt', '<=', now)
    .limit(300)
    .get();

  if (snap.empty) {
    console.log('cleanupExpiredStories: no expired stories found.');
    return;
  }

  const batch = db.batch();
  snap.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();

  console.log(`cleanupExpiredStories: deleted ${snap.docs.length} expired stories.`);
});
