import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_action_parser.dart';
import 'ai_gateway_exception.dart';
import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';
import 'models/ai_turn.dart';
import '../config/app_secrets.dart';

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
    List<AiTurn> history = const [],
  }) async {
    final effectiveMode = doctorReportMode
        ? 'doctor'
        : (analyzeMode ? 'analyze' : mode);

    final isSignedIn = _auth.currentUser != null;
    debugPrint(
      '[AiGateway] mode=$effectiveMode, signedIn=$isSignedIn, historyLen=${history.length}',
    );

    if (isSignedIn) {
      try {
        final cloud = await _requestFromCloudFunction(
          message: message,
          context: context,
          mode: effectiveMode,
          history: history,
        );
        if (cloud != null &&
            cloud.isNotEmpty &&
            !_isFailedPlaceholderReply(cloud)) {
          final clean = _sanitizeReply(cloud);
          debugPrint('[AiGateway] Cloud Function succeeded (${clean.length} chars)');
          return clean;
        }
        debugPrint('[AiGateway] Cloud Function returned null or failed');
      } on AiGatewayException {
        rethrow;
      }
    }

    if (kDebugMode) {
      debugPrint('[AiGateway] No server reply — debug builds need signed-in user');
    }

    return null;
  }

  /// Server-backed streaming: fetches the full reply from Cloud Functions and
  /// yields it as one chunk (Functions HTTP is non-streaming today).
  Stream<String> stream({
    required String message,
    required Map<String, dynamic> context,
    String mode = 'chat',
    List<AiTurn> history = const [],
  }) async* {
    debugPrint(
      '[AiGateway.stream] mode=$mode, historyLen=${history.length}',
    );

    try {
      final reply = await request(
        message: message,
        context: context,
        mode: mode,
        history: history,
      );
      if (reply != null && reply.isNotEmpty) {
        yield reply;
      }
    } on AiGatewayException {
      rethrow;
    }
  }

  String _sanitizeReply(String reply) => AiActionParser.sanitizeForDisplay(reply);

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

    if (trimmed.length < 120) {
      const apologeticAr = ['لم أتمكن', 'حدث خطأ', 'عذراً،'];
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
    List<AiTurn> history = const [],
  }) async {
    final token = await _auth.currentUser!.getIdToken();
    final endpoint = (mode == 'analyze' || mode == 'doctor')
        ? '$_baseUrl/analyze'
        : '$_baseUrl/chat';
    debugPrint('[AiGateway] Calling $endpoint');

    final isPregnant = context['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt = AiPromptBuilder.buildUserPrompt(message, context, mode);
    final cfg = AiPromptStyle.configForMode(mode);

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'message': message,
        'cycleContext': context,
        'mode': mode,
        'systemPrompt': systemPrompt,
        'userPrompt': userPrompt,
        'maxTokens': cfg.maxTokens,
        'temperature': cfg.temperature,
        if (mode == 'doctor') 'doctorReport': true,
        if (history.isNotEmpty)
          'history': history
              .map((t) => {'role': t.role.name, 'text': t.text})
              .toList(),
      }),
    );

    debugPrint('[AiGateway] Cloud Function status: ${response.statusCode}');

    if (response.body.isNotEmpty) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final errorCode = data['error'] as String?;
      final errorMessage = data['message'] as String?;

      if (errorCode == 'daily_limit_reached') {
        throw AiGatewayException('daily_limit_reached', message: errorMessage);
      }
      if (errorCode == 'premium_required') {
        throw AiGatewayException('premium_required', message: errorMessage);
      }

      final reply = data['reply'] as String?;
      if (errorCode != null) {
        debugPrint('[AiGateway] Cloud Function error: $errorCode');
      }
      if (reply != null) {
        debugPrint(
          '[AiGateway] Cloud Function reply: ${reply.substring(0, reply.length.clamp(0, 100))}',
        );
      }

      if (reply != null &&
          reply.isNotEmpty &&
          !_isFailedPlaceholderReply(reply)) {
        return reply;
      }
    } else {
      debugPrint(
        '[AiGateway] Cloud Function empty body, status: ${response.statusCode}',
      );
    }

    if (response.statusCode == 429) {
      throw const AiGatewayException('daily_limit_reached');
    }
    if (response.statusCode == 403) {
      throw const AiGatewayException('premium_required');
    }

    return null;
  }
}
