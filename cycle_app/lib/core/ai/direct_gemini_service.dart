import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/community/data/moderation_result.dart';
import '../config/app_secrets.dart';
import '../security/secure_storage_service.dart';
import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';

/// Direct Gemini API client — uses Google AI Studio key from secure storage.
/// Works on Spark plan (free), no Firebase billing required.
class DirectGeminiService {
  DirectGeminiService({SecureStorageService? secureStorage})
      : _secure = secureStorage ?? SecureStorageService();

  static const _models = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.5-flash-lite',
  ];
  static const _secureKey = 'gemini_api_key';
  static const _legacyPrefKey = 'gemini_api_key'; // Old SharedPreferences key

  final SecureStorageService _secure;
  String? _cachedKey;

  Future<String?> _getKey() async {
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey;

    // 1. Try secure storage first
    _cachedKey = await _secure.read(_secureKey);
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey;

    // 2. Migrate from SharedPreferences if found (one-time)
    final prefs = await SharedPreferences.getInstance();
    final legacyKey = prefs.getString(_legacyPrefKey);
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await _secure.write(_secureKey, legacyKey);
      await prefs.remove(_legacyPrefKey); // Clean up legacy
      _cachedKey = legacyKey;
      if (kDebugMode) debugPrint('[DirectGemini] Migrated key from SharedPreferences to SecureStorage');
      return _cachedKey;
    }

    // 3. Fallback to AppSecrets (build-time --dart-define or hardcoded)
    if (AppSecrets.geminiApiKey.isNotEmpty) {
      _cachedKey = AppSecrets.geminiApiKey;
      await _secure.write(_secureKey, _cachedKey!);
      if (kDebugMode) debugPrint('[DirectGemini] Using key from AppSecrets');
      return _cachedKey;
    }

    return null;
  }

  Future<void> setKey(String key) async {
    _cachedKey = key.trim();
    await _secure.write(_secureKey, _cachedKey!);
  }

  Future<bool> hasKey() async {
    final key = await _getKey();
    return key != null && key.isNotEmpty;
  }

  /// Test if the API key works by making a direct HTTP request.
  /// Returns a diagnostic message.
  Future<String> testConnection() async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) return 'No API key found';

    // Test with direct HTTP call to Gemini API
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Say hello in one word'}
              ]
            }
          ]
        }),
      );

      if (kDebugMode) {
        debugPrint('[DirectGemini] Test response status: ${response.statusCode}');
        debugPrint('[DirectGemini] Test response body: ${response.body.substring(0, response.body.length.clamp(0, 200))}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return 'SUCCESS: API key works! Response: $text';
      } else if (response.statusCode == 400) {
        return 'ERROR 400: Bad request - key might be invalid format';
      } else if (response.statusCode == 403) {
        return 'ERROR 403: Forbidden - API not enabled or key revoked';
      } else if (response.statusCode == 429) {
        return 'ERROR 429: Rate limit exceeded';
      } else {
        return 'ERROR ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      return 'EXCEPTION: $e';
    }
  }

  Future<String?> generate({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) debugPrint('[DirectGemini] No API key found');
      return null;
    }

    final isPregnant = cycleContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt = AiPromptBuilder.buildUserPrompt(message, cycleContext, mode);

    final maxTokens = switch (mode) {
      'doctor' => 1200,
      'analyze' => 900,
      'briefing' => 300,
      'emergency' => 400,
      'patterns' => 600,
      'nutrition' => 500,
      'partner' => 300,
      'mood' => 400,
      'fertility' => 500,
      'weight' => 500,
      'intimacy' => 400,
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
          text = '$text\n\n... [response truncated]';
        } else if (finish != null &&
            finish != FinishReason.stop &&
            finish != FinishReason.maxTokens) {
          text = '$text\n\n[response stopped: $finish]';
        }

        return text;
      } catch (e) {
        final error = e.toString();
        // Return the error from the last model attempt
        if (modelName == _models.last) {
          return '[$modelName error] $error';
        }
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
      if (kDebugMode) debugPrint('[DirectGemini] moderate failed: $e');
    }
    return null;
  }
}
