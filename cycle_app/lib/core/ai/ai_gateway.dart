import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_gateway_exception.dart';
import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';
import 'models/ai_turn.dart';
import '../config/app_secrets.dart';
import '../premium/premium_activation_service.dart';
import '../../features/user/data/guest_user_service.dart';

/// Single entry point for AI — all keys live on Firebase Functions.
///
/// Resolution order:
/// 1. Cloud Functions (`chat` / `analyze`) — DeepSeek primary, Gemini fallback
/// 2. (debug only) Direct Gemini — local diagnostics with a dev key
class AiGateway {
  AiGateway({
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  static final _baseUrl = AppSecrets.cloudFunctionsUrl;

  Future<String?> request({
    required String message,
    required Map<String, dynamic> context,
    bool analyzeMode = false,
    bool doctorReportMode = false,
    String mode = 'chat',
    String? personality,
    List<AiTurn> history = const [],
  }) async {
    final effectiveMode = doctorReportMode
        ? 'doctor'
        : (analyzeMode ? 'analyze' : mode);

    // Bind Firebase session + server premium to the current UID before AI.
    try {
      await GuestUserService().ensureSession();
      await PremiumActivationService.grantTesterPremium();
    } catch (e) {
      debugPrint('[AiGateway] session/premium prepare failed: $e');
    }

    final user = _auth.currentUser;
    debugPrint(
      '[AiGateway] mode=$effectiveMode, signedIn=${user != null}, '
      'uid=${user?.uid}, historyLen=${history.length}',
    );

    if (user == null) {
      throw const AiGatewayException('auth_required');
    }

    return _requestFromCloudFunction(
      message: message,
      context: context,
      mode: effectiveMode,
      personality: personality,
      history: history,
    );
  }

  /// Server-backed streaming: fetches the full reply from Cloud Functions and
  /// yields it as one chunk (Functions HTTP is non-streaming today).
  Stream<String> stream({
    required String message,
    required Map<String, dynamic> context,
    String mode = 'chat',
    String? personality,
    List<AiTurn> history = const [],
  }) async* {
    debugPrint(
      '[AiGateway.stream] mode=$mode, historyLen=${history.length}',
    );

    final reply = await request(
      message: message,
      context: context,
      mode: mode,
      personality: personality,
      history: history,
    );
    if (reply != null && reply.isNotEmpty) {
      yield reply;
    }
  }

  /// Cycle widget / wellness maps may contain DateTime or custom objects.
  /// Those throw [JsonUnsupportedObjectError] (an Error, not Exception) and
  /// previously aborted the request before it ever reached Cloud Functions.
  static dynamic jsonSafe(dynamic value) {
    if (value == null || value is num || value is String || value is bool) {
      return value;
    }
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((key, dynamic item) {
        out[key.toString()] = jsonSafe(item);
      });
      return out;
    }
    if (value is Iterable) {
      return value.map(jsonSafe).toList();
    }
    return value.toString();
  }

  bool _isFailedPlaceholderReply(String reply) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return true;
    final lower = trimmed.toLowerCase();

    if (RegExp(r'^\[[\w\-.]+\s+error\]').hasMatch(lower)) return true;
    if (lower.contains('api_key_service_blocked') ||
        lower.contains('permission_denied') ||
        lower.contains('expected oauth') ||
        lower.contains('unauthenticated')) {
      return true;
    }
    if (RegExp(r'\{\s*"error"\s*:').hasMatch(lower)) return true;
    if (lower.startsWith('ai diagnostic:')) return true;

    // Only treat short apologetic strings as provider failures — not real replies.
    if (trimmed.length < 80) {
      const apologeticAr = ['لم أتمكن', 'حدث خطأ'];
      if (apologeticAr.any(trimmed.startsWith)) return true;
      if (lower.startsWith('sorry,') ||
          lower.startsWith('i cannot') ||
          lower.startsWith("i can't")) {
        return true;
      }
    }

    return false;
  }

  Future<String?> _requestFromCloudFunction({
    required String message,
    required Map<String, dynamic> context,
    required String mode,
    String? personality,
    List<AiTurn> history = const [],
  }) async {
    final token = await _auth.currentUser!.getIdToken(true);
    final endpoint = (mode == 'analyze' || mode == 'doctor')
        ? '$_baseUrl/analyze'
        : '$_baseUrl/chat';
    debugPrint('[AiGateway] Calling $endpoint');

    final safeContext =
        Map<String, dynamic>.from(jsonSafe(context) as Map? ?? {});
    final isPregnant = safeContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt =
        AiPromptBuilder.buildUserPrompt(message, safeContext, mode);
    final cfg = AiPromptStyle.configForMode(mode);

    // Keep history small and skip prior error bubbles.
    final safeHistory = history
        .where((t) => t.text.trim().isNotEmpty && !_isFailedPlaceholderReply(t.text))
        .where((t) => !t.text.contains('المساعد مش متاح'))
        .where((t) => !t.text.contains('المساعد غير متاح'))
        .where((t) => !t.text.contains('Firebase AI Logic'))
        .take(8)
        .map((t) => {
              'role': t.role.name,
              'text': t.text.length > 800 ? t.text.substring(0, 800) : t.text,
            })
        .toList();

    final payload = <String, dynamic>{
      'message': message,
      'cycleContext': safeContext,
      'mode': mode,
      if (personality != null && personality.isNotEmpty)
        'personality': personality,
      'systemPrompt': systemPrompt,
      'userPrompt': userPrompt,
      'maxTokens': cfg.maxTokens,
      'temperature': cfg.temperature,
      if (mode == 'doctor') 'doctorReport': true,
      if (safeHistory.isNotEmpty) 'history': safeHistory,
    };

    late final String body;
    try {
      body = jsonEncode(payload);
    } catch (e, st) {
      debugPrint('[AiGateway] jsonEncode failed: $e\n$st');
      // Last resort: minimal payload so AI still works.
      body = jsonEncode({
        'message': message,
        'cycleContext': {
          'userLocale': safeContext['userLocale'] ?? 'ar',
        },
        'mode': mode,
        'maxTokens': 1200,
        'temperature': 0.8,
      });
    }

    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 90));
    } catch (e, st) {
      debugPrint('[AiGateway] Network error: $e\n$st');
      throw const AiGatewayException('network_error');
    }

    debugPrint('[AiGateway] Cloud Function status: ${response.statusCode}');

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
        debugPrint('[AiGateway] Bad JSON: $e body=$preview');
        throw const AiGatewayException('server_error');
      }
    }

    final errorCode = data['error'] as String?;
    final errorMessage = data['message'] as String?;

    if (errorCode == 'daily_limit_reached' || response.statusCode == 429) {
      throw AiGatewayException('daily_limit_reached', message: errorMessage);
    }
    if (errorCode == 'premium_required' || response.statusCode == 403) {
      throw AiGatewayException('premium_required', message: errorMessage);
    }
    if (errorCode == 'profile_required') {
      throw AiGatewayException('profile_required', message: errorMessage);
    }
    if (response.statusCode == 401 ||
        errorCode == 'Auth required.' ||
        errorCode == 'Token expired.') {
      throw const AiGatewayException('auth_required');
    }

    final reply = data['reply'] as String?;
    if (reply != null &&
        reply.isNotEmpty &&
        !_isFailedPlaceholderReply(reply)) {
      debugPrint(
        '[AiGateway] Cloud Function reply: '
        '${reply.substring(0, reply.length.clamp(0, 100))}',
      );
      return reply;
    }

    if (errorCode != null) {
      debugPrint('[AiGateway] Cloud Function error: $errorCode');
    }

    throw AiGatewayException(
      'server_error',
      message: errorMessage ?? errorCode,
    );
  }
}
