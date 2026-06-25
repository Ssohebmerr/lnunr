import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/community/data/moderation_result.dart';
import 'ai_prompt_style.dart';

/// Direct Gemini API client — uses Google AI Studio key from SharedPreferences.
/// Works on Spark plan (free), no Firebase billing required.
class DirectGeminiService {
  static const _models = ['gemini-2.5-flash', 'gemini-2.0-flash'];
  static const _prefKey = 'gemini_api_key';

  String? _cachedKey;

  Future<String?> _getKey() async {
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey;
    final prefs = await SharedPreferences.getInstance();
    _cachedKey = prefs.getString(_prefKey);
    return _cachedKey;
  }

  Future<void> setKey(String key) async {
    _cachedKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _cachedKey!);
  }

  Future<bool> hasKey() async {
    final key = await _getKey();
    return key != null && key.isNotEmpty;
  }

  Future<String?> generate({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final isPregnant = cycleContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt = _buildUserPrompt(message, cycleContext, mode);

    final maxTokens = switch (mode) {
      'doctor' => 1200,
      'analyze' => 900,
      'briefing' => 300,
      'emergency' => 400,
      'patterns' => 600,
      'nutrition' => 500,
      'partner' => 300,
      'mood' => 400,
      _ => 4000,
    };

    final temperature = mode == 'emergency' ? 0.6 : 0.78;

    for (final modelName in _models) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.system(systemPrompt),
          generationConfig: GenerationConfig(
            maxOutputTokens: maxTokens,
            temperature: temperature,
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
          ],
        );

        final response = await model.generateContent([Content.text(userPrompt)]);
        var text = response.text?.trim();
        if (text == null || text.isEmpty) continue;

        final finish = response.candidates.isNotEmpty
            ? response.candidates.first.finishReason
            : null;
        if (finish == FinishReason.maxTokens) {
          text = '$text\n\n… [اكتمل الحد الأقصى للرد]';
        } else if (finish != null &&
            finish != FinishReason.stop &&
            finish != FinishReason.maxTokens) {
          text = '$text\n\n[توقف الرد: $finish]';
        }

        debugPrint('[DirectGemini] $modelName succeeded (${text.length} chars)');
        return text;
      } catch (e) {
        debugPrint('[DirectGemini] $modelName failed: $e');
      }
    }
    return null;
  }

  Future<ModerationResult?> moderateContent({required String text}) async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      const instruction =
          'You are a content moderator for a women\'s health community app. '
          'Review the post/comment. Reject if it contains: medical prescriptions, '
          'dangerous advice, harassment, hate speech, spam, links, or self-harm. '
          'Allow supportive peer discussion. Reply ONLY with JSON: '
          '{"approved":true} or {"approved":false,"reason":"short reason"}.';

      for (final modelName in _models) {
        try {
          final model = GenerativeModel(
            model: modelName,
            apiKey: apiKey,
            systemInstruction: Content.system(instruction),
          );
          final response = await model.generateContent([Content.text(text)]);
          final raw = response.text?.trim();
          if (raw == null || raw.isEmpty) continue;

          final lower = raw.toLowerCase();
          if (lower.contains('"approved":true') || lower.contains('"approved": true')) {
            return const ModerationResult(approved: true);
          }
          if (lower.contains('"approved":false') || lower.contains('"approved": false')) {
            final reasonMatch = RegExp(r'"reason"\s*:\s*"([^"]+)"').firstMatch(raw);
            return ModerationResult(
              approved: false,
              reason: reasonMatch?.group(1) ?? 'Content not allowed.',
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[DirectGemini] moderate failed: $e');
    }
    return null;
  }

  String _buildUserPrompt(String message, Map<String, dynamic> ctx, String mode) {
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
      'Today\'s log: ${ctx['todayLog'] ?? 'nothing yet'}',
      'Recent symptoms (30d): ${ctx['recentSymptoms'] ?? {}}',
      'Wellness logs: ${ctx['wellnessLogCount'] ?? 0}',
      'Wellness hub: $hubText',
      'Summary: ${ctx['summary'] ?? {}}',
      if (ctx['cycleHistory'] != null)
        'Cycle history (last 6): ${ctx['cycleHistory']}',
    ];

    final header = switch (mode) {
      'briefing' => '=== DAILY BRIEFING REQUEST ===',
      'patterns' => '=== PATTERN ANALYSIS REQUEST ===',
      'emergency' => '=== EMERGENCY ===',
      'nutrition' => '=== NUTRITION REQUEST ===',
      'partner' => '=== PARTNER MESSAGE REQUEST ===',
      'mood' => '=== MOOD JOURNAL ENTRY ===',
      'doctor' => '=== DOCTOR REPORT REQUEST ===',
      _ => '=== APP DATA (use to personalize) ===',
    };

    final userHeader = mode == 'mood'
        ? '=== USER JOURNAL ENTRY (analyze emotions gently) ==='
        : '=== USER MESSAGE (answer THIS directly) ===';

    return [
      header,
      ...contextLines,
      '',
      userHeader,
      message,
    ].join('\n');
  }
}
