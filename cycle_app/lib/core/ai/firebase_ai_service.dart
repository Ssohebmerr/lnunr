import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../features/community/data/moderation_result.dart';
import 'ai_prompt_style.dart';

/// Firebase AI Logic service — primary AI provider for the app.
///
/// Uses Firebase AI Logic SDK to access Gemini models directly from the
/// client with built-in security (App Check) and no backend required.
///
/// Resolution order in AiGateway:
/// 1. Firebase AI Logic (this service) — direct, secure, no server
/// 2. Cloud Function (Firebase) — requires signed-in user
/// 3. Direct Gemini API (legacy fallback)
class FirebaseAiService {
  static const _modelNames = ['gemini-2.5-flash', 'gemini-2.0-flash'];

  GenerativeModel? _moderationModel;

  GenerativeModel _getModel({
    required String modelName,
    required String systemPrompt,
    int? maxTokens,
    double? temperature,
  }) {
    return FirebaseAI.googleAI().generativeModel(
      model: modelName,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        maxOutputTokens: maxTokens ?? 2000,
        temperature: temperature ?? 0.78,
      ),
      safetySettings: [
        SafetySetting(
          HarmCategory.harassment,
          HarmBlockThreshold.medium,
          null,
        ),
        SafetySetting(
          HarmCategory.hateSpeech,
          HarmBlockThreshold.medium,
          null,
        ),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.high,
          null,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.medium,
          null,
        ),
      ],
    );
  }

  /// Generate a response using Firebase AI Logic.
  ///
  /// Returns null if the request fails — callers should fall back to
  /// Cloud Functions or direct Gemini API.
  Future<String?> generate({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
  }) async {
    try {
      final effectiveMode = mode;
      final isPregnant = cycleContext['userGoal'] == 'pregnant';
      final systemPrompt = AiPromptStyle.forMode(
        effectiveMode,
        isPregnant: isPregnant,
      );

      final maxTokens = switch (effectiveMode) {
        'doctor' => 1200,
        'analyze' => 900,
        'briefing' => 300,
        'emergency' => 400,
        'patterns' => 600,
        'nutrition' => 500,
        'partner' => 300,
        'mood' => 400,
        _ => 2000,
      };

      final temperature = effectiveMode == 'emergency' ? 0.6 : 0.78;

      final userPrompt = _buildUserPrompt(message, cycleContext, effectiveMode);

      for (final modelName in _modelNames) {
        try {
          final model = _getModel(
            modelName: modelName,
            systemPrompt: systemPrompt,
            maxTokens: maxTokens,
            temperature: temperature,
          );

          final response = await model.generateContent([Content.text(userPrompt)]);

          var text = response.text?.trim();
          if (text == null || text.isEmpty) continue;

          final finish = response.candidates.isNotEmpty
              ? response.candidates.first.finishReason
              : null;
          if (finish == FinishReason.maxTokens &&
              !text.endsWith('.') &&
              !text.endsWith('!') &&
              !text.endsWith('?') &&
              !text.endsWith('…')) {
            text = '$text…';
          }

          return text;
        } catch (e) {
          debugPrint('[FirebaseAiService] $modelName failed: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('[FirebaseAiService] generate failed: $e');
      return null;
    }
  }

  /// Moderate community content using Firebase AI Logic.
  Future<ModerationResult?> moderateContent({required String text}) async {
    try {
      _moderationModel ??= FirebaseAI.googleAI().generativeModel(
        model: _modelNames.first,
        systemInstruction: Content.system(
          'You are a content moderator for a women\'s health community app. '
          'Review the post/comment. Reject if it contains: medical prescriptions, '
          'dangerous advice, harassment, hate speech, spam, links, or self-harm. '
          'Allow supportive peer discussion. Reply ONLY with JSON: '
          '{"approved":true} or {"approved":false,"reason":"short reason"}.',
        ),
      );

      final response = await _moderationModel!.generateContent([
        Content.text(text),
      ]);
      final raw = response.text?.trim();
      if (raw == null || raw.isEmpty) return null;

      final lower = raw.toLowerCase();
      if (lower.contains('"approved":true') ||
          lower.contains('"approved": true')) {
        return const ModerationResult(approved: true);
      }
      if (lower.contains('"approved":false') ||
          lower.contains('"approved": false')) {
        final reasonMatch =
            RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(raw);
        return ModerationResult(
          approved: false,
          reason: reasonMatch?.group(1) ??
              'Content not allowed in this community.',
        );
      }
    } catch (e) {
      debugPrint('[FirebaseAiService] moderate failed: $e');
    }
    return null;
  }

  String _buildUserPrompt(
    String message,
    Map<String, dynamic> ctx,
    String mode,
  ) {
    final hub = ctx['wellnessHub'];
    String hubText = 'none';
    if (hub is Map && hub.isNotEmpty) {
      final encoded = jsonEncode(hub);
      hubText = encoded.substring(0, encoded.length.clamp(0, 2500));
    }

    final locale = ctx['userLocale']?.toString() ?? 'ar';
    final contextLines = <String>[
      'User locale: $locale',
      'User goal: ${ctx['userGoal'] ?? 'unknown'}',
      if (ctx['userGoal'] == 'pregnant') ...[
        'Pregnancy week: ${ctx['pregnancyWeek'] ?? 'unknown'}',
        'Trimester: ${ctx['trimester'] ?? 'unknown'}',
        'Due date: ${ctx['expectedDueDate'] ?? 'unknown'}',
        'Gestational day: ${ctx['gestationalDay'] ?? 'unknown'}',
        'Fetal development: ${ctx['fetalDevelopmentSnippet'] ?? 'unknown'}',
        'Maternal changes: ${ctx['maternalSnippet'] ?? 'unknown'}',
        'Pregnancy tracking: ${ctx['pregnancyTracking'] ?? {}}',
      ] else ...[
        'Cycle length: ${ctx['cycleLength'] ?? 'unknown'}',
        'Period duration: ${ctx['periodDuration'] ?? 'unknown'}',
        'Current phase: ${ctx['currentPhase'] ?? 'unknown'}',
        'Current cycle day: ${ctx['currentCycleDay'] ?? 'unknown'}',
        'Next period: ${ctx['nextPeriodDate'] ?? 'unknown'}',
        'Ovulation: ${ctx['ovulationDate'] ?? 'unknown'}',
      ],
      'Today\'s log (home screen): ${ctx['todayLog'] ?? 'nothing yet'}',
      'Recent symptoms (30d): ${ctx['recentSymptoms'] ?? {}}',
      'Wellness logs: ${ctx['wellnessLogCount'] ?? 0}',
      'Wellness hub (pills, sanitary, vitals — anonymized): $hubText',
      'Summary: ${ctx['summary'] ?? {}}',
      if (ctx['cycleHistory'] != null)
        'Cycle history (last 6): ${ctx['cycleHistory']}',
    ];

    final header = switch (mode) {
      'briefing' => '=== DAILY BRIEFING REQUEST ===',
      'patterns' => '=== PATTERN ANALYSIS REQUEST ===',
      'emergency' => '=== EMERGENCY — user needs immediate help ===',
      'nutrition' => '=== NUTRITION REQUEST for current phase ===',
      'partner' => '=== PARTNER MESSAGE REQUEST ===',
      'mood' => '=== MOOD JOURNAL ENTRY ===',
      'doctor' => '=== DOCTOR REPORT REQUEST ===',
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
}
