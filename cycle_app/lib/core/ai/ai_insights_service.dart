import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'doctor_report_builder.dart';
import 'ai_action_parser.dart';
import 'ai_prompt_style.dart';
import '../privacy/consent_manager.dart';
import '../premium/premium_gate.dart';
import 'ai_context_engine.dart';
import 'ai_gateway.dart';
import 'models/ai_insight.dart';
import 'models/doctor_report_enrichment.dart';
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
  }) : _engine = contextEngine,
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
          final insight = AiInsight.fromJson(
            jsonDecode(cached) as Map<String, dynamic>,
            fromCache: true,
          );
          return AiInsight(
            type: insight.type,
            text: AiActionParser.sanitizeForDisplay(insight.text),
            generatedAt: insight.generatedAt,
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

  /// Enriches the printable doctor report with professional clinical sections
  /// derived from on-device data. Returns null when AI consent is off or the
  /// provider is unreachable — the report still renders without these sections.
  Future<DoctorReportEnrichment?> enrichDoctorReport({
    required String languageCode,
    required bool limitedData,
    Map<String, dynamic> clinicalMetrics = const {},
  }) async {
    if (!await ConsentManager.hasAiConsent()) return null;

    HealthSnapshot snapshot = const HealthSnapshot();
    try {
      snapshot = await _engine.buildSnapshot();
    } catch (_) {}

    final language = languageCode == 'ar' ? 'Arabic' : 'English';
    final limitedHint = limitedData
        ? (languageCode == 'ar'
              ? 'البيانات محدودة — أضيفي جملة واحدة احترافية في data_quality_note '
                    'أن التتبع لمدة شهر تقريباً يحسّن دقة التقرير.'
              : 'Data is limited — include one professional sentence in '
                    'data_quality_note that ~one month of daily logging improves accuracy.')
        : 'Omit data_quality_note or set it to null.';

    final isPregnant = snapshot.isPregnancyMode;
    final prompt =
        'Respond in $language with ONLY valid JSON (no markdown fences):\n'
        '{\n'
        '  "clinical_summary": "2-3 concise professional sentences for a physician",\n'
        '  "patterns": ["observed pattern 1", "observed pattern 2"],\n'
        '  "discussion_points": ["question the patient could ask the doctor", "..."],\n'
        '  "data_quality_note": "optional single sentence or null"\n'
        '}\n'
        '${isPregnant ? "Context: prenatal tracking." : "Context: menstrual cycle tracking."}\n'
        'Base every statement on the provided cycleContext and clinicalMetrics '
        '(cycle length range, variability, period duration, average pain, flags). '
        'Reference the actual figures and never invent concerns. The app '
        'renders urgent discussion flags only from its deterministic metrics.\n'
        '$limitedHint\n'
        'Never diagnose or prescribe. Write for a doctor reading a clean visit report.';

    final context = Map<String, dynamic>.from(snapshot.toPromptMap());
    if (clinicalMetrics.isNotEmpty) {
      context['clinicalMetrics'] = clinicalMetrics;
    }
    if (limitedData) {
      context['reportDataLimited'] = true;
    }

    final raw = await _gateway.request(
      message: prompt,
      context: context,
      doctorReportMode: true,
    );

    if (raw == null || raw.trim().isEmpty) return null;
    return _parseEnrichment(
      raw.trim(),
      limitedData: limitedData,
      languageCode: languageCode,
    );
  }

  DoctorReportEnrichment? _parseEnrichment(
    String raw, {
    required bool limitedData,
    required String languageCode,
  }) {
    try {
      var jsonStr = raw;
      final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
      final match = fence.firstMatch(raw);
      if (match != null) jsonStr = match.group(1)!.trim();

      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return _fallbackEnrichment(raw);

      List<String> listOf(dynamic v) {
        if (v is! List) return const [];
        return v
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .take(6)
            .toList();
      }

      final summary = decoded['clinical_summary']?.toString().trim();
      final patterns = listOf(decoded['patterns']);
      final points = listOf(decoded['discussion_points']);
      var note = decoded['data_quality_note']?.toString().trim();
      if (note == null || note.isEmpty || note.toLowerCase() == 'null') {
        note = limitedData
            ? (languageCode == 'ar'
                  ? 'البيانات ما زالت محدودة؛ التتبع اليومي لمدة شهر تقريباً يجعل هذا التقرير أدق.'
                  : 'Data is still limited; about one month of daily logging will make this report more accurate.')
            : null;
      }

      final enrichment = DoctorReportEnrichment(
        clinicalSummary: summary,
        patterns: patterns,
        discussionPoints: points,
        // Clinical flags are rendered only from DoctorReportAnalyzer's
        // deterministic calculations. Do not let a generative response turn
        // an unsupported concern into a medical-looking warning.
        redFlags: const [],
        dataQualityNote: note,
      );
      return enrichment.isEmpty ? null : enrichment;
    } catch (_) {
      return _fallbackEnrichment(raw);
    }
  }

  DoctorReportEnrichment? _fallbackEnrichment(String raw) {
    final text = raw.trim();
    if (text.length < 40) return null;
    return DoctorReportEnrichment(clinicalSummary: text);
  }

  /// One cache slot per type per day per language.
  String _cacheKey(AiInsightType type, String lang) {
    final now = DateTime.now();
    final day =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'ai_insight_${type.name}_${lang}_$day';
  }

  String _prompt(AiInsightType type, HealthSnapshot s, String lang) {
    final language = lang == 'ar' ? 'Arabic' : 'English';
    final base =
        'Respond in $language. Be warm, supportive, and concise. '
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
