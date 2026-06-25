import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'doctor_report_builder.dart';
import 'ai_prompt_style.dart';
import '../privacy/consent_manager.dart';
import '../premium/premium_gate.dart';
import 'ai_context_engine.dart';
import 'ai_gateway.dart';
import 'models/ai_insight.dart';
import 'models/health_snapshot.dart';

/// Generates typed AI insights for any screen in the app.
///
/// - Builds context through [AiContextEngine] (never ad-hoc maps).
/// - Talks to Gemini through [AiGateway] (cloud first, local key fallback).
/// - Caches one insight per type per day, so opening a screen twice never
///   costs a second API call.
class AiInsightsService {
  AiInsightsService({
    required AiContextEngine contextEngine,
    required AiGateway gateway,
  })  : _engine = contextEngine,
        _gateway = gateway;

  final AiContextEngine _engine;
  final AiGateway _gateway;

  /// Returns the insight for [type], from today's cache when available.
  /// Returns null when AI consent is missing or no AI provider is reachable.
  Future<AiInsight?> getInsight(
    AiInsightType type, {
    String languageCode = 'en',
    bool forceRefresh = false,
  }) async {
    if (!await ConsentManager.hasAiConsent()) return null;
    if (!await PremiumGate.hasPremium()) return null;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _cacheKey(type, languageCode);

    if (!forceRefresh) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          return AiInsight.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
            fromCache: true,
          );
        } catch (_) {}
      }
    }

    final snapshot = await _engine.buildSnapshot();
    if (snapshot.isEmpty) return null;

    final reply = await _gateway.request(
      message: _prompt(type, snapshot, languageCode),
      context: snapshot.toPromptMap(),
    );
    if (reply == null || reply.trim().isEmpty) return null;

    final insight = AiInsight(
      type: type,
      text: reply.trim(),
      generatedAt: DateTime.now(),
    );
    await prefs.setString(cacheKey, jsonEncode(insight.toJson()));
    return insight;
  }

  /// Generates a structured, shareable report for a healthcare visit.
  /// Always fresh (no daily cache) — the user generates it on demand.
  Future<String?> generateDoctorReport({String languageCode = 'en'}) async {
    if (!await ConsentManager.hasAiConsent()) return null;

    final hasPremium = await PremiumGate.hasPremium();
    if (!hasPremium) {
      final remaining = await PremiumGate.remainingFreeReports();
      if (remaining <= 0) return null;
    }

    final snapshot = await _engine.buildSnapshot();
    if (snapshot.isEmpty) return null;

    final localReport = DoctorReportBuilder.build(
      snapshot,
      languageCode: languageCode,
    );

    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final isPregnant = snapshot.isPregnancyMode;
    final prompt = isPregnant
        ? 'Respond in $language.\n'
            'Add AI-enhanced prenatal visit notes BELOW the data provided. '
            'Sections: fetal development focus, maternal symptoms patterns, '
            'pain summary, suggested questions for OB/midwife. '
            'Do not repeat cycle stats already in the user data — add insight only.'
        : 'Respond in $language.\n'
            'Add AI-enhanced visit notes BELOW the data provided. '
            'Sections: symptom pattern analysis, pain trends, irregularities '
            'worth discussing, suggested questions for the doctor. '
            'Do not repeat raw stats — add interpretation only.';

    final aiNotes = await _gateway.request(
      message: prompt,
      context: snapshot.toPromptMap(),
      doctorReportMode: true,
    );

    if (aiNotes != null && aiNotes.trim().length > 60) {
      final header = languageCode == 'ar'
          ? '\n\n── ملاحظات إضافية (ذكاء اصطناعي) ──\n'
          : '\n\n── Additional notes (AI) ──\n';
      return '$localReport$header${aiNotes.trim()}';
    }
    return localReport;
  }

  /// One cache slot per type per day per language.
  String _cacheKey(AiInsightType type, String lang) {
    final now = DateTime.now();
    final day = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'ai_insight_${type.name}_${lang}_$day';
  }

  String _prompt(AiInsightType type, HealthSnapshot s, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    final base = 'Respond in $language. Be warm, supportive, and concise. '
        'Never diagnose or prescribe. Speak directly to the user ("you"). '
        '${AiPromptStyle.responseFormat}';

    switch (type) {
      case AiInsightType.prenatalTip:
        return '$base\n'
            'I am pregnant (week ${s.pregnancyWeek ?? '?'}, trimester '
            '${s.trimester ?? '?'}, due ${s.expectedDueDate ?? 'unknown'}). '
            'Fetal development: ${s.fetalDevelopmentSnippet ?? 'unknown'}. '
            'Tracking today: ${s.pregnancyTracking}. '
            'Give me one practical prenatal wellness tip for today — nutrition, '
            'rest, movement, kicks, or emotional support. Do not mention ovulation.';
      case AiInsightType.dailyTip:
        if (s.isPregnancyMode) {
          return '$base\n'
              'I am pregnant (week ${s.pregnancyWeek ?? '?'}). Give me today\'s '
              'personalized prenatal tip — nutrition, rest, or gentle activity.';
        }
        return '$base\n'
            'Based on my current cycle phase (${s.currentPhase ?? 'unknown'}, '
            'day ${s.currentCycleDay ?? '?'}), give me today\'s personalized tip '
            'covering one of: nutrition, mood, or gentle activity. '
            'Make it specific to this phase, not generic.';
      case AiInsightType.moodInsight:
        if (s.isPregnancyMode) {
          return '$base\n'
              'I am pregnant (week ${s.pregnancyWeek ?? '?'}). Hormones in '
              'pregnancy affect mood. Given my recent symptoms, explain how I '
              'might feel today and one gentle way to feel better.';
        }
        return '$base\n'
            'Act as an emotionally intelligent companion. Given my recent '
            'symptoms and cycle phase, explain how my hormones may be '
            'affecting my mood right now, and give one practical way to '
            'feel better today.';
      case AiInsightType.cycleHealth:
        return '$base\n'
            'Review my cycle regularity (${s.cycleRegularity ?? 'unknown'}), '
            'average pain level (${s.averagePainLevel ?? 'no data'}), and '
            'recent symptoms. Tell me what looks healthy, and what is worth '
            'gently keeping an eye on. If something clearly deviates from '
            'typical patterns, suggest mentioning it to a doctor.';
      case AiInsightType.weeklySummary:
        return '$base\n'
            'Summarize my last 30 days of wellness logs '
            '(${s.wellnessLogCount} entries, symptoms: ${s.recentSymptoms}). '
            'Also consider my Wellness Hub data (pills adherence, sanitary '
            'usage, daily vitals) when relevant: ${s.wellnessHub}. '
            'Celebrate what I did well and suggest one focus for next week.';
      case AiInsightType.conceiveTip:
        return '$base\n'
            'My goal is TRYING TO CONCEIVE. Cycle phase: ${s.currentPhase ?? 'unknown'}, '
            'day ${s.currentCycleDay ?? '?'}, ovulation: ${s.ovulationDate ?? 'unknown'}, '
            'fertility: ${s.pregnancyChances ?? 'unknown'}. '
            'Give one practical fertility tip for today — timing, nutrition, rest, or tracking. '
            'Never diagnose infertility.';
      case AiInsightType.avoidTip:
        return '$base\n'
            'My goal is AVOIDING PREGNANCY. Cycle phase: ${s.currentPhase ?? 'unknown'}, '
            'day ${s.currentCycleDay ?? '?'}, ovulation: ${s.ovulationDate ?? 'unknown'}. '
            'Give one practical tip about fertile-day awareness and consistent contraception. '
            'Do not prescribe specific medications.';
      case AiInsightType.wellnessTip:
        return '$base\n'
            'My goal is GENERAL CYCLE WELLNESS. Phase: ${s.currentPhase ?? 'unknown'}, '
            'regularity: ${s.cycleRegularity ?? 'unknown'}. '
            'Give one holistic wellness tip for today — sleep, nutrition, movement, or mood.';
    }
  }
}
