import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/community/data/moderation_result.dart';
import '../security/secure_storage_service.dart';
import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';
import 'models/ai_turn.dart';

/// Direct Gemini API client — talks to the Generative Language REST API.
///
/// Supports the API key formats Google AI Studio can hand out:
/// - Classic standard keys (`AIza...`)
/// - New auth keys (`AQ...`)
///
/// Both are still API keys for the native Gemini endpoint and must be sent via
/// `x-goog-api-key`. Treating `AQ...` as `Authorization: Bearer` causes
/// `Expected OAuth 2 access token` / `API_KEY_SERVICE_BLOCKED` responses.
class DirectGeminiService {
  DirectGeminiService({SecureStorageService? secureStorage})
      : _secure = secureStorage ?? SecureStorageService();

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _models = [
    'gemini-2.5-flash',
    'gemini-2.5-pro',
    'gemini-2.5-flash-lite',
  ];
  static const _secureKey = 'gemini_api_key';
  static const _legacyPrefKey = 'gemini_api_key';

  final SecureStorageService _secure;
  String? _cachedKey;

  Future<String?> _getKey() async {
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey;

    _cachedKey = await _secure.read(_secureKey);
    if (_cachedKey != null && _cachedKey!.isNotEmpty) return _cachedKey;

    final prefs = await SharedPreferences.getInstance();
    final legacyKey = prefs.getString(_legacyPrefKey);
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await _secure.write(_secureKey, legacyKey);
      await prefs.remove(_legacyPrefKey);
      _cachedKey = legacyKey;
      return _cachedKey;
    }

    return null;
  }

  Future<void> setKey(String key) async {
    _cachedKey = key.trim();
    await _secure.write(_secureKey, _cachedKey!);
  }

  /// Clears any cached/stored key so the next call re-reads from AppSecrets.
  Future<void> clearKey() async {
    _cachedKey = null;
    await _secure.delete(_secureKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPrefKey);
  }

  Future<bool> hasKey() async {
    final key = await _getKey();
    return key != null && key.isNotEmpty;
  }

  /// Builds the correct auth header for the credential type.
  ///
  /// AI Studio keys (`AIza...` and `AQ...`) are API keys. Only real OAuth
  /// access tokens (`ya29...`) should be sent as bearer tokens.
  Map<String, String> _authHeaders(String key) {
    final headers = {'Content-Type': 'application/json'};
    if (key.startsWith('ya29.')) {
      headers['Authorization'] = 'Bearer $key';
    } else {
      headers['x-goog-api-key'] = key;
    }
    return headers;
  }

  /// Test if the credential works. Returns a human-readable diagnostic.
  Future<String> testConnection() async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) return 'No API key found';

    final authMode = apiKey.startsWith('ya29.') ? 'Bearer token' : 'API key';
    try {
      final url = Uri.parse('$_baseUrl/${_models.first}:generateContent');
      final response = await http.post(
        url,
        headers: _authHeaders(apiKey),
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
        debugPrint('[DirectGemini] Test ($authMode) status: '
            '${response.statusCode}');
        debugPrint('[DirectGemini] Test body: '
            '${response.body.substring(0, response.body.length.clamp(0, 300))}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return 'SUCCESS ($authMode): API works! Response: $text';
      } else if (response.statusCode == 401) {
        return 'ERROR 401 ($authMode): Unauthorized — token expired or wrong '
            'credential type. ${response.body}';
      } else if (response.statusCode == 400) {
        return 'ERROR 400 ($authMode): Bad request. ${response.body}';
      } else if (response.statusCode == 403) {
        return 'ERROR 403 ($authMode): Forbidden — API not enabled or revoked.';
      } else if (response.statusCode == 429) {
        return 'ERROR 429: Rate limit exceeded';
      } else {
        return 'ERROR ${response.statusCode} ($authMode): ${response.body}';
      }
    } catch (e) {
      return 'EXCEPTION: $e';
    }
  }

  /// One-shot generation. Optionally accepts conversation [history] for
  /// proper multi-turn memory in chat-style modes.
  Future<String?> generate({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
    List<AiTurn> history = const [],
  }) async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) debugPrint('[DirectGemini] No API key found');
      return null;
    }

    final isPregnant = cycleContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt =
        AiPromptBuilder.buildUserPrompt(message, cycleContext, mode);
    final cfg = AiPromptStyle.configForMode(mode);
    final contents = _contentsJson(history: history, userPrompt: userPrompt);
    final headers = _authHeaders(apiKey);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': cfg.maxTokens,
        'temperature': cfg.temperature,
      },
      'safetySettings': _safetyJson(),
    });

    for (final modelName in _models) {
      try {
        final url = Uri.parse('$_baseUrl/$modelName:generateContent');
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode != 200) {
          if (kDebugMode) {
            debugPrint('[DirectGemini] $modelName HTTP '
                '${response.statusCode}: ${response.body}');
          }
          if (modelName == _models.last) {
            return '[$modelName error] ${response.body}';
          }
          continue;
        }

        final data = jsonDecode(response.body);
        final candidate = (data['candidates'] as List?)?.isNotEmpty == true
            ? data['candidates'][0]
            : null;
        var text = candidate?['content']?['parts']?[0]?['text'] as String?;
        text = text?.trim();
        if (text == null || text.isEmpty) continue;

        final finish = candidate?['finishReason'] as String?;
        if (finish == 'MAX_TOKENS' &&
            !text.endsWith('.') &&
            !text.endsWith('!') &&
            !text.endsWith('?') &&
            !text.endsWith('…')) {
          text = '$text…';
        }

        return text;
      } catch (e) {
        if (kDebugMode) debugPrint('[DirectGemini] $modelName failed: $e');
        if (modelName == _models.last) {
          return '[$modelName error] $e';
        }
      }
    }
    return null;
  }

  /// Streaming generation — yields partial text chunks via SSE.
  Stream<String> generateStream({
    required String message,
    required Map<String, dynamic> cycleContext,
    String mode = 'chat',
    List<AiTurn> history = const [],
  }) async* {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) {
      if (kDebugMode) debugPrint('[DirectGemini.stream] No API key found');
      return;
    }

    final isPregnant = cycleContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt =
        AiPromptBuilder.buildUserPrompt(message, cycleContext, mode);
    final cfg = AiPromptStyle.configForMode(mode);
    final contents = _contentsJson(history: history, userPrompt: userPrompt);
    final headers = _authHeaders(apiKey);

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': cfg.maxTokens,
        'temperature': cfg.temperature,
      },
      'safetySettings': _safetyJson(),
    });

    Object? lastErr;
    for (final modelName in _models) {
      try {
        final url =
            Uri.parse('$_baseUrl/$modelName:streamGenerateContent?alt=sse');
        final request = http.Request('POST', url)
          ..headers.addAll(headers)
          ..body = body;
        final streamed = await request.send();

        if (streamed.statusCode != 200) {
          final errBody = await streamed.stream.bytesToString();
          lastErr = 'HTTP ${streamed.statusCode}: $errBody';
          if (kDebugMode) {
            debugPrint('[DirectGemini.stream] $modelName $lastErr');
          }
          continue;
        }

        var yieldedSomething = false;
        await for (final line in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (!line.startsWith('data:')) continue;
          final payload = line.substring(5).trim();
          if (payload.isEmpty || payload == '[DONE]') continue;
          try {
            final data = jsonDecode(payload);
            final candidate = (data['candidates'] as List?)?.isNotEmpty == true
                ? data['candidates'][0]
                : null;
            final text =
                candidate?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              yieldedSomething = true;
              yield text;
            }
          } catch (_) {}
        }
        if (yieldedSomething) return; // success
      } catch (e) {
        lastErr = e;
        if (kDebugMode) debugPrint('[DirectGemini.stream] $modelName: $e');
      }
    }

    if (kDebugMode && lastErr != null) {
      debugPrint('[DirectGemini.stream] all models failed: $lastErr');
    }
  }

  List<Map<String, dynamic>> _contentsJson({
    required List<AiTurn> history,
    required String userPrompt,
  }) {
    // Cap history to last 12 turns to stay within token budget.
    final trimmed =
        history.length > 12 ? history.sublist(history.length - 12) : history;

    final messages = <Map<String, dynamic>>[];
    for (final turn in trimmed) {
      messages.add({
        'role': turn.role == AiTurnRole.user ? 'user' : 'model',
        'parts': [
          {'text': turn.text}
        ],
      });
    }
    messages.add({
      'role': 'user',
      'parts': [
        {'text': userPrompt}
      ],
    });
    return messages;
  }

  List<Map<String, dynamic>> _safetyJson() => const [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ];

  Future<ModerationResult?> moderateContent({required String text}) async {
    final apiKey = await _getKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    final headers = _authHeaders(apiKey);
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': AiPromptStyle.moderationSystem}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': text}
          ]
        }
      ],
    });

    try {
      for (final modelName in _models) {
        try {
          final url = Uri.parse('$_baseUrl/$modelName:generateContent');
          final response = await http.post(url, headers: headers, body: body);
          if (response.statusCode != 200) continue;

          final data = jsonDecode(response.body);
          final candidate = (data['candidates'] as List?)?.isNotEmpty == true
              ? data['candidates'][0]
              : null;
          final raw =
              (candidate?['content']?['parts']?[0]?['text'] as String?)?.trim();
          if (raw == null || raw.isEmpty) continue;

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
