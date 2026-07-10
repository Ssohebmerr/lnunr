// ============================================================================
// lib/red_flags.js — safety net: detects urgent-symptom / crisis language in
// ANY chat message (not just emergency mode) and returns a system-prompt
// escalation block.
// ----------------------------------------------------------------------------
// Two escalation kinds, by priority:
//   'crisis'  — self-harm / suicidal language → crisis-support override.
//   'medical' — heavy bleeding / fainting / severe pain / high fever
//               (or ANY bleeding while pregnant) → urgent-care escalation.
//
// Design notes:
//   - Detection is keyword-based and intentionally biased toward false
//     positives: the worst outcome of a false positive is a warm nudge to
//     see a doctor; the worst outcome of a false negative is much worse.
//   - Arabic matching runs on normalized text (diacritics stripped,
//     أإآ→ا, ة→ه, ى→ي, ؤ→و, ئ→ي) so dialect spellings still hit.
//     Keywords below are written PRE-normalized.
//   - Latin keywords match with word boundaries; apostrophes are stripped
//     from the message first so "can't walk" matches keyword 'cant walk'.
// ============================================================================

'use strict';

/** Self-harm / suicidal ideation — highest priority. */
const CRISIS_KEYWORDS = [
  // Arabic (pre-normalized)
  'انتحار', 'انتحر', 'اذي نفسي', 'اذيت نفسي', 'اوذي نفسي', 'ايذاء نفسي',
  'ما بدي عيش', 'ما عاد بدي عيش', 'مابدي عيش', 'بدي موت', 'نفسي اموت',
  'اموت احسن', 'حابه اموت', 'ابي اموت', 'ودي اموت', 'اتمنى الموت',
  'خلص تعبت من حياتي', 'اكره حياتي وما بدي',
  // English
  'suicide', 'suicidal', 'kill myself', 'killing myself',
  'hurt myself', 'hurting myself', 'harm myself', 'harming myself',
  'cut myself', 'cutting myself', 'self harm', 'self-harm',
  'end my life', 'ending my life', 'end it all', 'want to die', 'wanna die',
  'dont want to live', 'better off dead', 'no reason to live',
];

/** Urgent physical symptoms. */
const MEDICAL_KEYWORDS = [
  // Heavy bleeding (Arabic pre-normalized)
  'نزيف غزير', 'نزيف قوي', 'نزيف كتير', 'نزيف كثير', 'نزيف شديد',
  'النزيف ما بيوقف', 'النزيف ما يوقف', 'ما بيوقف النزيف', 'فوطه كل ساعه',
  'كتل دم كبيره', 'خثرات كبيره', 'قطع دم كبيره',
  // Fainting / consciousness
  'اغمي علي', 'اغمى علي', 'فقدت الوعي', 'غبت عن الوعي', 'بغيب عن الوعي',
  'دوخه شديده', 'دايخه كتير', 'دايخه مره',
  // Severe pain
  'الم فظيع', 'الم شديد جدا', 'الم لا يحتمل', 'الم ما ينحمل', 'اسوا الم',
  'ما بقدر امشي', 'ما اقدر امشي', 'ما بقدر اوقف', 'ما اقدر اوقف',
  'ما بقدر اتحرك', 'ما اقدر اتحرك', 'عم اصرخ من الالم',
  // Fever
  'حراره عاليه', 'حرارتي عاليه', 'سخونه عاليه', 'سخونتي عاليه', 'حمى',
  // English
  'heavy bleeding', 'bleeding heavily', 'bleeding wont stop', 'soaking a pad',
  'soaking through', 'large clots', 'big clots',
  'fainted', 'fainting', 'passed out', 'blacked out', 'losing consciousness',
  'unbearable pain', 'worst pain', 'excruciating', 'severe pain',
  'cant walk', 'cant stand', 'cant move', 'screaming in pain',
  'high fever',
];

/** Pregnant + ANY bleeding is a red flag on its own. */
const PREGNANCY_BLEEDING_KEYWORDS = [
  'نزيف', 'نزفت', 'عم انزف', 'ينزل دم', 'نزل دم', 'تنقيط دم',
  'bleeding', 'bleed', 'spotting', 'blood',
];

const CRISIS_BLOCK = `

=== CRISIS SUPPORT OVERRIDE (HIGHEST PRIORITY — overrides all other style rules) ===
The user's message may indicate self-harm or suicidal thoughts.
- Respond with deep warmth and ZERO judgment. Do NOT lecture, do NOT change the subject, do NOT pivot to cycle advice.
- Take their pain seriously; tell them clearly that their life matters and that this overwhelming feeling can ease with support.
- Gently urge them to reach out RIGHT NOW to someone they trust, and to their local emergency number or a suicide crisis hotline in their country.
- Keep it short, human, and caring — no lists, no disclaimers.
- Stay with them: end by inviting them to keep talking to you right here.`;

const MEDICAL_BLOCK = `

=== URGENT SYMPTOM ESCALATION (high priority) ===
The user's message may describe medically urgent symptoms (heavy bleeding, fainting, severe pain, high fever, or bleeding during pregnancy).
- FIRST: calmly and clearly advise contacting a healthcare provider or emergency services TODAY — before any other advice.
- Then offer 1–2 safe comfort measures while they arrange care (rest, warmth, sips of water).
- Be brief, warm, and direct. Do not diagnose. Do not minimize. Do not bury the urgent advice at the end.`;

/**
 * Normalizes Arabic for tolerant matching (same rules as knowledge.js).
 *
 * @param {string} s
 * @returns {string}
 */
function normalizeArabic(s) {
  return s
    .replace(/[ً-ْـ]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/ؤ/g, 'و')
    .replace(/ئ/g, 'ي');
}

/**
 * Keyword matcher: word boundaries for Latin keywords, substring for Arabic.
 *
 * @param {string} normalizedMessage Lowercased, Arabic-normalized, apostrophe-stripped.
 * @param {string} keyword Pre-normalized keyword.
 * @returns {boolean}
 */
function hits(normalizedMessage, keyword) {
  if (/^[a-z0-9\s-]+$/.test(keyword)) {
    return new RegExp('\\b' + keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b')
      .test(normalizedMessage);
  }
  return normalizedMessage.includes(keyword);
}

/**
 * Scans a user message for crisis / urgent-symptom language.
 *
 * @param {string} message The raw user message.
 * @param {Object} cycleContext The cycle context (`userGoal` is consulted).
 * @returns {?('crisis'|'medical')} The escalation kind, or null.
 */
function detectRedFlags(message, cycleContext) {
  const normalized = normalizeArabic(
    String(message || '').toLowerCase().replace(/['‘’`]/g, ''),
  );
  if (!normalized.trim()) return null;

  for (const kw of CRISIS_KEYWORDS) {
    if (hits(normalized, kw)) return 'crisis';
  }
  for (const kw of MEDICAL_KEYWORDS) {
    if (hits(normalized, kw)) return 'medical';
  }
  if (cycleContext && cycleContext.userGoal === 'pregnant') {
    for (const kw of PREGNANCY_BLEEDING_KEYWORDS) {
      if (hits(normalized, kw)) return 'medical';
    }
  }
  return null;
}

/**
 * The system-prompt block to append for a detected escalation.
 *
 * @param {'crisis'|'medical'} kind
 * @returns {string} A block starting with '\n\n' (or '' for unknown kinds).
 */
function escalationBlockFor(kind) {
  if (kind === 'crisis') return CRISIS_BLOCK;
  if (kind === 'medical') return MEDICAL_BLOCK;
  return '';
}

/**
 * Deterministic first response for high-risk messages. This deliberately does
 * not depend on an AI provider: an outage or an unsafe model response must
 * never delay the first urgent-care instruction.
 */
function emergencyResponseFor(kind, locale = 'ar') {
  const isArabic = String(locale).toLowerCase().startsWith('ar');
  if (kind === 'crisis') {
    return isArabic
      ? 'أنا آسفة أنكِ تمرّين بهذا الآن. أنتِ مهمة ولا يلزم أن تبقي وحدكِ. تواصلي الآن مع شخص تثقين به أو مع خدمات الطوارئ أو خط الدعم النفسي في بلدكِ، وابقَي في مكان آمن. إذا استطعتِ، اكتبي لي: هل يوجد شخص قريب يمكنه البقاء معكِ الآن؟'
      : 'I’m really sorry you are carrying this right now. You matter, and you do not have to be alone. Please contact someone you trust, local emergency services, or a crisis line in your country now, and stay somewhere safe. If you can, tell me: is there someone nearby who can stay with you?';
  }
  if (kind === 'medical') {
    return isArabic
      ? 'الأعراض التي وصفتِها تحتاج تقييماً طبياً عاجلاً اليوم. اتصلي بطبيبتكِ أو بخدمات الطوارئ المحلية الآن، خصوصاً إذا كان النزيف غزيراً أو هناك دوخة، إغماء، ألم شديد، حرارة، أو حمل. إلى أن تصلي للمساعدة: ارتاحي، لا تبقي وحدكِ إن أمكن، وخذي رشفات ماء فقط إذا كنتِ واعية وقادرة على البلع.'
      : 'The symptoms you described need urgent medical assessment today. Contact your clinician or local emergency services now, especially for heavy bleeding, dizziness, fainting, severe pain, fever, or any bleeding during pregnancy. While arranging help: rest, avoid being alone if possible, and take small sips of water only if you are awake and able to swallow.';
  }
  return '';
}

module.exports = {
  detectRedFlags,
  escalationBlockFor,
  emergencyResponseFor,
};
