import 'dart:convert';

import 'ai_prompt_style.dart';

/// Shared prompt-building logic used by all AI services.
/// Extracted from DirectGeminiService and FirebaseAiService to avoid duplication.
class AiPromptBuilder {
  AiPromptBuilder._();

  static String buildUserPrompt(
    String message,
    Map<String, dynamic> ctx,
    String mode,
  ) {
    // Lightweight modes (partner, intimacy, briefing) get only the basics —
    // saves ~600 tokens per call and keeps the response focused.
    final fullContext = AiPromptStyle.includesFullContext(mode);

    final locale = ctx['userLocale']?.toString() ?? 'ar';
    final contextLines = <String>[
      'User locale: $locale',
      'User goal: ${ctx['userGoal'] ?? 'unknown'}',
      if (ctx['userGoal'] == 'pregnant') ...[
        'Pregnancy week: ${ctx['pregnancyWeek'] ?? 'unknown'}',
        'Trimester: ${ctx['trimester'] ?? 'unknown'}',
        if (fullContext) ...[
          'Due date: ${ctx['expectedDueDate'] ?? 'unknown'}',
          'Gestational day: ${ctx['gestationalDay'] ?? 'unknown'}',
          'Fetal development: ${ctx['fetalDevelopmentSnippet'] ?? 'unknown'}',
          'Maternal changes: ${ctx['maternalSnippet'] ?? 'unknown'}',
          'Pregnancy tracking: ${ctx['pregnancyTracking'] ?? {}}',
        ],
      ] else ...[
        'Cycle length: ${ctx['cycleLength'] ?? 'unknown'}',
        'Period duration: ${ctx['periodDuration'] ?? 'unknown'}',
        'Current phase: ${ctx['currentPhase'] ?? 'unknown'}',
        'Current cycle day: ${ctx['currentCycleDay'] ?? 'unknown'}',
        if (fullContext) ...[
          'Next period: ${ctx['nextPeriodDate'] ?? 'unknown'}',
          'Ovulation: ${ctx['ovulationDate'] ?? 'unknown'}',
        ],
      ],
      if (fullContext) ...[
        'Today\'s log (home screen): ${ctx['todayLog'] ?? 'nothing yet'}',
        'Recent symptoms (30d): ${ctx['recentSymptoms'] ?? {}}',
        'Wellness logs: ${ctx['wellnessLogCount'] ?? 0}',
        'Wellness hub (pills, sanitary, vitals — anonymized): ${_hubSnippet(ctx)}',
        'Summary: ${ctx['summary'] ?? {}}',
        if (ctx['cycleHistory'] != null)
          'Cycle history (last 6): ${ctx['cycleHistory']}',
      ],
    ];

    final header = switch (mode) {
      'briefing' => '=== DAILY BRIEFING REQUEST ===',
      'patterns' => '=== PATTERN ANALYSIS REQUEST ===',
      'emergency' => '=== EMERGENCY — user needs immediate help ===',
      'nutrition' => '=== NUTRITION REQUEST for current phase ===',
      'partner' => '=== PARTNER MESSAGE REQUEST ===',
      'mood' => '=== MOOD JOURNAL ENTRY ===',
      'doctor' => '=== DOCTOR REPORT REQUEST ===',
      'recap' || 'weekly_recap' => '=== WEEKLY RECAP — last 7 days ===',
      'fertility' => '=== FERTILITY INSIGHT REQUEST ===',
      'weight' => '=== WEIGHT INSIGHT REQUEST ===',
      'intimacy' => '=== INTIMACY GUIDANCE REQUEST ===',
      _ => '=== APP DATA (use to personalize — do not dump raw JSON) ===',
    };

    final userHeader = mode == 'mood'
        ? '=== USER JOURNAL ENTRY (analyze emotions gently) ==='
        : '=== USER MESSAGE (answer THIS directly — show you read it) ===';

    return [
      header,
      ...contextLines,
      '',
      userHeader,
      message,
    ].join('\n');
  }

  static String _hubSnippet(Map<String, dynamic> ctx) {
    final hub = ctx['wellnessHub'];
    if (hub is Map && hub.isNotEmpty) {
      final encoded = jsonEncode(hub);
      return encoded.substring(0, encoded.length.clamp(0, 2500));
    }
    return 'none';
  }
}
