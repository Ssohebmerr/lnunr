import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'direct_gemini_service.dart';
import 'firebase_ai_service.dart';

/// Single entry point for AI.
///
/// Resolution order:
/// 1. Cloud Functions (`chat` / `analyze`) — server-side, signed-in users
/// 2. Direct Gemini API (Google AI Studio key — free, no billing)
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

  static const _baseUrl =
      'https://us-central1-lune-7d956.cloudfunctions.net';

  Future<String?> request({
    required String message,
    required Map<String, dynamic> context,
    bool analyzeMode = false,
    bool doctorReportMode = false,
    String mode = 'chat',
  }) async {
    final effectiveMode = doctorReportMode
        ? 'doctor'
        : (analyzeMode ? 'analyze' : mode);

    final isSignedIn = _auth.currentUser != null;
    debugPrint('[AiGateway] mode=$effectiveMode, signedIn=$isSignedIn');

    // 1. Cloud Function (signed-in; key on Firebase Secrets)
    if (isSignedIn) {
      final cloud = await _requestFromCloudFunction(
        message: message,
        context: context,
        mode: effectiveMode,
      );
      if (cloud != null && cloud.isNotEmpty) {
        debugPrint('[AiGateway] Cloud Function succeeded (${cloud.length} chars)');
        return cloud;
      }
      debugPrint('[AiGateway] Cloud Function returned null');
    }

    // 2. Direct Gemini API (Google AI Studio key — free, works on Spark plan)
    final direct = await _directGemini.generate(
      message: message,
      cycleContext: context,
      mode: effectiveMode,
    );
    if (direct != null && direct.isNotEmpty) {
      debugPrint('[AiGateway] Direct Gemini succeeded (${direct.length} chars)');
      return direct;
    }
    debugPrint('[AiGateway] Direct Gemini returned null');

    // 3. Firebase AI Logic (requires Firebase AI Logic enabled in console)
    final firebaseAi = await _firebaseAi.generate(
      message: message,
      cycleContext: context,
      mode: effectiveMode,
    );
    if (firebaseAi != null && firebaseAi.isNotEmpty) {
      debugPrint('[AiGateway] Firebase AI succeeded (${firebaseAi.length} chars)');
      return firebaseAi;
    }
    debugPrint('[AiGateway] All AI paths exhausted');

    return null;
  }

  bool _isFailedPlaceholderReply(String reply) {
    final lower = reply.toLowerCase();
    return lower.contains('not configured') ||
        lower.contains('set gemini') ||
        reply.contains('لم أتمكن') ||
        reply.contains('حدث خطأ');
  }

  Future<String?> _requestFromCloudFunction({
    required String message,
    required Map<String, dynamic> context,
    required String mode,
  }) async {
    try {
      final token = await _auth.currentUser!.getIdToken();
      final endpoint = (mode == 'analyze' || mode == 'doctor')
          ? '$_baseUrl/analyze'
          : '$_baseUrl/chat';
      debugPrint('[AiGateway] Calling $endpoint');
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
          if (mode == 'doctor') 'doctorReport': true,
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
