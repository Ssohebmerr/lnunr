import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';
import '../privacy/consent_manager.dart';
import '../../features/sync/data/cloud_sync_service.dart';
import '../../features/user/data/guest_user_service.dart';
import 'premium_activation_result.dart';
import 'premium_status_notifier.dart';

/// Server-side premium grants — local prefs alone cannot unlock AI.
class PremiumActivationService {
  PremiumActivationService._();

  static final _baseUrl = AppSecrets.cloudFunctionsUrl;

  /// Avoid hammering grant on every AI message in the same session.
  static DateTime? _lastOkAt;
  static String? _lastOkUid;

  /// Ensures `users/{currentUid}` exists and has `isPremium: true` on the server.
  ///
  /// Does **not** depend on client Firestore writes (rules can block those).
  /// The Cloud Function uses the Admin SDK and creates the profile if missing.
  static Future<PremiumActivationResult> grantTesterPremium({
    bool force = false,
  }) async {
    try {
      final uid = await GuestUserService().ensureSession();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const PremiumActivationResult(ok: false, needsProfile: true);
      }

      if (!force &&
          _lastOkUid == uid &&
          _lastOkAt != null &&
          DateTime.now().difference(_lastOkAt!) < const Duration(minutes: 10)) {
        return const PremiumActivationResult(ok: true);
      }

      final result = await _callGrant(user);
      if (result.ok) {
        _lastOkAt = DateTime.now();
        _lastOkUid = uid;
        await ConsentManager.setAiConsent(true);
        await PremiumStatusNotifier.instance.applyRemote(true);
        unawaited(
          CloudSyncService()
              .fetchPremiumStatus(user.uid)
              .then(PremiumStatusNotifier.instance.applyRemote),
        );
      }

      return result;
    } catch (e, st) {
      debugPrint('grantTesterPremium error: $e\n$st');
      return const PremiumActivationResult(ok: false);
    }
  }

  static Future<PremiumActivationResult> _callGrant(User user) async {
    final token = await user.getIdToken(true);
    final response = await http
        .post(
          Uri.parse('$_baseUrl/grantTesterPremium'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 30));

    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode == 403 && body['error'] == 'profile_required') {
      // Server now auto-creates profiles; treat as retryable failure.
      return const PremiumActivationResult(ok: false, needsProfile: true);
    }

    if (response.statusCode == 400 && body['error'] == 'already_granted') {
      return const PremiumActivationResult(ok: true);
    }

    if (response.statusCode == 200 && body['ok'] == true) {
      return const PremiumActivationResult(ok: true);
    }

    debugPrint(
      'grantTesterPremium failed: ${response.statusCode} ${response.body}',
    );
    return const PremiumActivationResult(ok: false);
  }
}
