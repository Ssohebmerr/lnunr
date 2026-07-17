import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../age/age_gate.dart';
import '../privacy/consent_manager.dart';
import 'ai_gateway_exception.dart';
import 'ai_prompt_builder.dart';
import 'ai_prompt_style.dart';
import 'models/ai_turn.dart';
import '../firebase/cloud_functions_client.dart';
import '../../features/user/data/guest_user_service.dart';

void _aiLog(String message) {
  if (kDebugMode) debugPrint(message);
}

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

  /// Lazy so constructing an [AiGateway] never touches Firebase before it is
  /// initialized (and so the auth guard runs before the client is resolved).
  CloudFunctionsClient get _functions => CloudFunctionsClient.instance;

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

    // Bind the Firebase session to the current UID before AI. Entitlement is
    // enforced server-side; the client never grants itself premium.
    try {
      await GuestUserService().ensureSession();
    } catch (e) {
  _aiLog('[AiGateway] session prepare failed: $e');
    }

    final user = _auth.currentUser;
_aiLog(
      '[AiGateway] mode=$effectiveMode, signedIn=${user != null}, '
      'uid=${user?.uid}, historyLen=${history.length}',
    );

    if (user == null) {
      throw const AiGatewayException('auth_required');
    }

    await _assertAiEligibility();
    await ConsentManager.syncAiEligibility();

    return _requestFromCloudFunction(
      message: message,
      context: context,
      mode: effectiveMode,
      personality: personality,
      history: history,
    );
  }

  /// Server-backed streaming — yields the reply token-by-token as it is
  /// generated. Chat modes stream from `/chat`; analyze/doctor reports come
  /// back as a single chunk (that endpoint is one-shot by design).
  Stream<String> stream({
    required String message,
    required Map<String, dynamic> context,
    String mode = 'chat',
    String? personality,
    List<AiTurn> history = const [],
  }) async* {
_aiLog('[AiGateway.stream] mode=$mode, historyLen=${history.length}');

    // Bind the Firebase session before AI (entitlement is server-enforced).
    try {
      await GuestUserService().ensureSession();
    } catch (e) {
  _aiLog('[AiGateway.stream] session prepare failed: $e');
    }
    if (_auth.currentUser == null) {
      throw const AiGatewayException('auth_required');
    }

    await _assertAiEligibility();
    await ConsentManager.syncAiEligibility();

    // Reports are generated in one pass — no partial rendering benefit.
    if (mode == 'analyze' || mode == 'doctor') {
      final reply = await _requestFromCloudFunction(
        message: message,
        context: context,
        mode: mode,
        personality: personality,
        history: history,
      );
      if (reply != null && reply.isNotEmpty) yield reply;
      return;
    }

    yield* _streamFromCloudFunction(
      message: message,
      context: context,
      mode: mode,
      personality: personality,
      history: history,
    );
  }

  /// Fail closed before any health context leaves the device. The same state
  /// is mirrored to Firestore and checked again by Cloud Functions.
  Future<void> _assertAiEligibility() async {
    if (await blocksAiByAgeGate()) {
      throw const AiGatewayException('adult_required');
    }
    if (!await ConsentManager.hasAiConsent()) {
      throw const AiGatewayException('consent_required');
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
    final path = (mode == 'analyze' || mode == 'doctor') ? '/analyze' : '/chat';
_aiLog('[AiGateway] Calling $path');

    final safeContext =
        Map<String, dynamic>.from(jsonSafe(context) as Map? ?? {});
    final payload = _buildPayloadMap(
      message: message,
      safeContext: safeContext,
      mode: mode,
      personality: personality,
      history: history,
    );

    late final http.Response response;
    try {
      response = await _functions.post(
        path,
        body: payload,
        timeout: const Duration(seconds: 90),
      );
    } catch (e, st) {
  _aiLog('[AiGateway] Network error: $e\n$st');
      throw const AiGatewayException('network_error');
    }

_aiLog('[AiGateway] Cloud Function status: ${response.statusCode}');

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final preview = response.body.length > 200
            ? response.body.substring(0, 200)
            : response.body;
    _aiLog('[AiGateway] Bad JSON: $e body=$preview');
        throw const AiGatewayException('server_error');
      }
    }

    final errorCode = data['error'] as String?;
    final errorMessage = data['message'] as String?;

    if (errorCode == 'daily_limit_reached' || response.statusCode == 429) {
      throw AiGatewayException('daily_limit_reached', message: errorMessage);
    }
    if (errorCode == 'adult_required') {
      throw AiGatewayException('adult_required', message: errorMessage);
    }
    if (errorCode == 'consent_required') {
      throw AiGatewayException('consent_required', message: errorMessage);
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
  _aiLog(
        '[AiGateway] Cloud Function reply: '
        '${reply.substring(0, reply.length.clamp(0, 100))}',
      );
      return reply;
    }

    if (errorCode != null) {
  _aiLog('[AiGateway] Cloud Function error: $errorCode');
    }

    throw AiGatewayException(
      'server_error',
      message: errorMessage ?? errorCode,
    );
  }

  /// Builds the request body sent to the `/chat` (or `/analyze`) endpoint.
  /// Shared by the one-shot and streaming request paths.
  Map<String, dynamic> _buildPayloadMap({
    required String message,
    required Map<String, dynamic> safeContext,
    required String mode,
    String? personality,
    List<AiTurn> history = const [],
  }) {
    final isPregnant = safeContext['userGoal'] == 'pregnant';
    final systemPrompt = AiPromptStyle.forMode(mode, isPregnant: isPregnant);
    final userPrompt =
        AiPromptBuilder.buildUserPrompt(message, safeContext, mode);
    final cfg = AiPromptStyle.configForMode(mode);

    // Keep history small and skip prior error bubbles (old + new wording).
    final filteredHistory = history
        .where((t) => t.text.trim().isNotEmpty && !_isFailedPlaceholderReply(t.text))
        .where((t) => !t.text.contains('المساعد مش متاح'))
        .where((t) => !t.text.contains('المساعد غير متاح'))
        .where((t) => !t.text.contains('المساعدة الذكية غير متاحة'))
        .where((t) => !t.text.contains('Firebase AI Logic'))
        .toList();
    // Keep the MOST RECENT 8 turns (take(8) would keep the oldest ones).
    final recentHistory = filteredHistory.length > 8
        ? filteredHistory.sublist(filteredHistory.length - 8)
        : filteredHistory;
    final safeHistory = recentHistory
        .map((t) => {
              'role': t.role.name,
              'text': t.text.length > 800 ? t.text.substring(0, 800) : t.text,
            })
        .toList();

    return <String, dynamic>{
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
  }

  /// Real token-by-token streaming from the `/chat` endpoint. Yields text
  /// deltas as they arrive over the chunked HTTP response.
  ///
  /// Pre-stream errors (auth / quota / premium) arrive as a non-200 JSON body
  /// and are mapped to the same [AiGatewayException]s as the one-shot path.
  Stream<String> _streamFromCloudFunction({
    required String message,
    required Map<String, dynamic> context,
    required String mode,
    String? personality,
    List<AiTurn> history = const [],
  }) async* {
    final path = '/chat';
    final safeContext =
        Map<String, dynamic>.from(jsonSafe(context) as Map? ?? {});
    final payload = _buildPayloadMap(
      message: message,
      safeContext: safeContext,
      mode: mode,
      personality: personality,
      history: history,
    )..['stream'] = true;

    String body;
    try {
      body = jsonEncode(payload);
    } catch (_) {
      body = jsonEncode({
        'message': message,
        'cycleContext': {'userLocale': safeContext['userLocale'] ?? 'ar'},
        'mode': mode,
        'stream': true,
      });
    }

    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('${CloudFunctionsClient.baseUrl}$path'))
        ..body = body;

      final http.StreamedResponse response;
      try {
        response = await CloudFunctionsClient.instance.send(
          request,
          timeout: const Duration(seconds: 90),
        );
      } catch (e, st) {
    _aiLog('[AiGateway.stream] network error: $e\n$st');
        throw const AiGatewayException('network_error');
      }

  _aiLog('[AiGateway.stream] status: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errBody = await response.stream.bytesToString();
        _throwForErrorResponse(response.statusCode, errBody);
      }

      // Safety net for the deploy transition: if the server hasn't been
      // updated to stream yet it answers with a single JSON body
      // (`application/json`). Detect that and yield the reply once, so the
      // chat works whether or not the streaming Functions are deployed.
      final contentType =
          (response.headers['content-type'] ?? '').toLowerCase();
      if (contentType.contains('application/json')) {
        final fullBody = await response.stream.bytesToString();
        Map<String, dynamic> data = {};
        if (fullBody.isNotEmpty) {
          try {
            data = jsonDecode(fullBody) as Map<String, dynamic>;
          } catch (_) {/* fall through to error */}
        }
        final reply = data['reply'] as String?;
        if (reply != null &&
            reply.isNotEmpty &&
            !_isFailedPlaceholderReply(reply)) {
          yield reply;
          return;
        }
        throw AiGatewayException(
          'server_error',
          message: (data['message'] ?? data['error']) as String?,
        );
      }

      // 200 text stream → yield UTF-8 decoded deltas (handles multi-byte splits).
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        if (chunk.isNotEmpty) yield chunk;
      }
    } finally {
      client.close();
    }
  }

  /// Maps a non-200 response body to the matching [AiGatewayException].
  /// Mirrors the error handling of the one-shot path.
  Never _throwForErrorResponse(int statusCode, String body) {
    Map<String, dynamic> data = {};
    if (body.isNotEmpty) {
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {/* non-JSON error body */}
    }
    final errorCode = data['error'] as String?;
    final errorMessage = data['message'] as String?;

    if (errorCode == 'daily_limit_reached' || statusCode == 429) {
      throw AiGatewayException('daily_limit_reached', message: errorMessage);
    }
    if (errorCode == 'adult_required') {
      throw AiGatewayException('adult_required', message: errorMessage);
    }
    if (errorCode == 'consent_required') {
      throw AiGatewayException('consent_required', message: errorMessage);
    }
    if (errorCode == 'premium_required' || statusCode == 403) {
      throw AiGatewayException('premium_required', message: errorMessage);
    }
    if (errorCode == 'profile_required') {
      throw AiGatewayException('profile_required', message: errorMessage);
    }
    if (statusCode == 401 ||
        errorCode == 'Auth required.' ||
        errorCode == 'Token expired.') {
      throw const AiGatewayException('auth_required');
    }
    throw AiGatewayException('server_error', message: errorMessage ?? errorCode);
  }
}
