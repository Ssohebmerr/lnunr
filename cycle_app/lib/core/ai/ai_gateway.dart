import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';
import 'direct_gemini_service.dart';
import 'firebase_ai_service.dart';
import 'models/ai_turn.dart';
import '../config/app_secrets.dart';

/// Single entry point for AI.
///
/// Resolution order:
/// 1. Direct Gemini API (Google AI Studio key — free, no billing)
/// 2. Cloud Functions (`chat` / `analyze`) — server-side, signed-in users
/// 3. Firebase AI Logic (`firebase_ai` SDK)
class AiGateway {
  AiGateway({
    FirebaseAuth? auth,
    FirebaseAiService? firebaseAi,
    DirectGeminiService? directGemini,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firebaseAi = firebaseAi ?? FirebaseAiService(),
        _directGemini = directGemini ?? DirectGeminiService();

  final FirebaseAuth _auth;
  final FirebaseAiService _firebaseAi;
  final DirectGeminiService _directGemini;

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

    // 1. Direct Gemini API (most reliable path — Google AI Studio key).
    final direct = await _directGemini.generate(
      message: message,
      cycleContext: context,
      mode: effectiveMode,
      history: history,
    );
    if (direct != null && direct.isNotEmpty && !_isFailedPlaceholderReply(direct)) {
      debugPrint('[AiGateway] Direct Gemini succeeded (${direct.length} chars)');
      return direct;
    }
    debugPrint('[AiGateway] Direct Gemini returned null or failed');

    // 2. Cloud Function (signed-in; key on Firebase Secrets)
    if (isSignedIn) {
      final cloud = await _requestFromCloudFunction(
        message: message,
        context: context,
        mode: effectiveMode,
        history: history,
      );
      if (cloud != null && cloud.isNotEmpty && !_isFailedPlaceholderReply(cloud)) {
        debugPrint('[AiGateway] Cloud Function succeeded (${cloud.length} chars)');
        return cloud;
      }
      debugPrint('[AiGateway] Cloud Function returned null or failed');
    }

    // 3. Firebase AI Logic
    final firebaseAi = await _firebaseAi.generate(
      message: message,
      cycleContext: context,
      mode: effectiveMode,
      history: history,
    );
    if (firebaseAi != null && firebaseAi.isNotEmpty && !_isFailedPlaceholderReply(firebaseAi)) {
      debugPrint('[AiGateway] Firebase AI succeeded (${firebaseAi.length} chars)');
      return firebaseAi;
    }

    // All paths failed. Log a diagnostic (debug only) and return null so callers
    // can show their own fallback instead of leaking raw error text to the UI.
    if (kDebugMode) {
      final diagnostic = await _directGemini.testConnection();
      debugPrint('[AiGateway] All AI paths exhausted. Diagnostic: $diagnostic');
    }
    return null;
  }

  /// Streaming entry point. Tries the Direct Gemini stream first; if it
  /// yields nothing (e.g. no API key), falls back to Firebase AI Logic stream.
  /// Cloud Functions HTTP endpoint is non-streaming, so it's not used here.
  Stream<String> stream({
    required String message,
    required Map<String, dynamic> context,
    String mode = 'chat',
    List<AiTurn> history = const [],
  }) async* {
    debugPrint(
      '[AiGateway.stream] mode=$mode, historyLen=${history.length}',
    );

    var yieldedFromDirect = false;
    await for (final chunk in _directGemini.generateStream(
      message: message,
      cycleContext: context,
      mode: mode,
      history: history,
    )) {
      yieldedFromDirect = true;
      yield chunk;
    }
    if (yieldedFromDirect) return;

    debugPrint('[AiGateway.stream] Direct Gemini empty, falling back to Firebase AI');
    await for (final chunk in _firebaseAi.generateStream(
      message: message,
      cycleContext: context,
      mode: mode,
      history: history,
    )) {
      yield chunk;
    }
  }

  /// Detects "this is not a real AI reply — it's a failed/placeholder reply"
  /// so the gateway can fall through to the next provider instead of leaking
  /// error text to the UI.
  ///
  /// Order matters: check the structured signals (bracketed errors, JSON
  /// error payloads) first, then the apologetic placeholders, but ONLY when
  /// the entire reply is short — otherwise a normal Lune response like "آسفة،
  /// لم أتمكن من فهم سؤالك بشكل كامل، ممكن توضحيلي أكثر؟" would be wrongly
  /// discarded.
  bool _isFailedPlaceholderReply(String reply) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) return true;
    final lower = trimmed.toLowerCase();

    // 1. Bracketed error markers produced by DirectGeminiService when every
    //    model fails, e.g. "[gemini-2.5-flash error] {...}".
    if (RegExp(r'^\[[\w\-.]+\s+error\]').hasMatch(lower)) return true;

    // 2. Direct Gemini REST error fields — these are Gemini's own status
    //    strings, not anything a model would write in a helpful reply.
    if (lower.contains('api_key_service_blocked') ||
        lower.contains('permission_denied') ||
        lower.contains('expected oauth') ||
        lower.contains('unauthenticated')) {
      return true;
    }

    // 3. JSON-shaped error payload from the REST API: {"error": {...}}.
    //    Match as a field, not as a stray substring (the old version
    //    matched "error" anywhere — too greedy).
    if (RegExp(r'\{\s*"error"\s*:').hasMatch(lower)) return true;

    // 4. Diagnostic string we emit in debug mode on full failure.
    if (lower.startsWith('ai diagnostic:')) return true;

    // 5. Placeholders from our own DirectGeminiService when the key is
    //    missing or invalid.
    if (lower.contains('not configured') ||
        lower.contains('set gemini api key') ||
        lower.contains('no api key found')) {
      return true;
    }

    // 6. Apologetic placeholder replies — only when the entire reply is the
    //    apology (under 120 chars). A normal Lune response that *mentions*
    //    "لم أتمكن" mid-sentence still passes through.
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
    try {
      final token = await _auth.currentUser!.getIdToken();
      final endpoint = (mode == 'analyze' || mode == 'doctor')
          ? '$_baseUrl/analyze'
          : '$_baseUrl/chat';
      debugPrint('[AiGateway] Calling $endpoint');

      // Single source of truth: build the exact same system/user prompt and
      // generation config the on-device Gemini path uses, and send them to the
      // Cloud Function so the prompt logic never drifts between Dart and JS.
      // `message`/`cycleContext`/`mode` are still sent for backward-compatible
      // fallback on older server deployments.
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
        final reply = data['reply'] as String?;
        final error = data['error'] as String?;

        if (error != null) {
          debugPrint('[AiGateway] Cloud Function error: $error');
        }
        if (reply != null) {
          debugPrint('[AiGateway] Cloud Function reply: ${reply.substring(0, reply.length.clamp(0, 100))}');
        }

        if (reply != null &&
            reply.isNotEmpty &&
            !_isFailedPlaceholderReply(reply)) {
          return reply;
        }
      } else {
        debugPrint('[AiGateway] Cloud Function empty body, status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[AiGateway] Cloud Function exception: $e');
    }
    return null;
  }
}
