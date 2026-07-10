import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';
import '../../features/sync/data/cloud_sync_service.dart';
import '../../features/user/data/guest_user_service.dart';
import 'premium_activation_result.dart';
import 'premium_status_notifier.dart';

/// Read-only premium status refresh.
///
/// Premium is granted ONLY on the server (Play Billing verification, promo
/// codes, or an admin action). This service never writes entitlement — it
/// binds the Firebase session and reads `users/{uid}.isPremium`, then applies
/// the result to [PremiumStatusNotifier] + local prefs.
class PremiumActivationService {
  PremiumActivationService._();

  /// Avoid re-reading Firestore on every AI message in the same session.
  static DateTime? _lastOkAt;
  static String? _lastOkUid;

  /// Syncs the local premium flag with the server-side source of truth.
  ///
  /// Returns `ok: true` only when Firestore says `isPremium == true` for the
  /// CURRENT uid. Cannot be spoofed locally: the AI endpoints re-verify the
  /// same flag server-side on every request.
  static Future<PremiumActivationResult> refreshPremiumStatus({
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

      final isPremium = await CloudSyncService().fetchPremiumStatus(user.uid);
      await PremiumStatusNotifier.instance.applyRemote(isPremium);

      if (isPremium) {
        _lastOkAt = DateTime.now();
        _lastOkUid = uid;
      }

      return PremiumActivationResult(ok: isPremium);
    } catch (e, st) {
      debugPrint('refreshPremiumStatus error: $e\n$st');
      return const PremiumActivationResult(ok: false);
    }
  }

  /// DEBUG / QA ONLY — grants premium to the current account via the
  /// server's `grantTesterPremium` endpoint.
  ///
  /// Guarded on BOTH ends: this method no-ops outside [kDebugMode], and the
  /// server endpoint returns 403 unless `TESTER_PREMIUM_ENABLED=true` is set
  /// on the deployed Functions. Never reachable from a release build.
  static Future<PremiumActivationResult> activateTesterPremium() async {
    if (!kDebugMode) {
      return const PremiumActivationResult(ok: false);
    }
    try {
      final uid = await GuestUserService().ensureSession();
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return const PremiumActivationResult(ok: false, needsProfile: true);
      }

      final token = await user.getIdToken(true);
      final response = await http
          .post(
            Uri.parse('${AppSecrets.cloudFunctionsUrl}/grantTesterPremium'),
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

      if (response.statusCode == 200 && body['ok'] == true) {
        _lastOkAt = DateTime.now();
        _lastOkUid = uid;
        await PremiumStatusNotifier.instance.applyRemote(true);
        return const PremiumActivationResult(ok: true);
      }

      debugPrint(
        'activateTesterPremium failed: ${response.statusCode} ${response.body}',
      );
      return const PremiumActivationResult(ok: false);
    } catch (e, st) {
      debugPrint('activateTesterPremium error: $e\n$st');
      return const PremiumActivationResult(ok: false);
    }
  }
}
