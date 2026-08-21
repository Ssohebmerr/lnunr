import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase/cloud_functions_client.dart';

/// Tracks explicit user consent for optional cloud/AI features (Data Safety / GDPR).
class ConsentManager {
  static const _privacyAcceptedKey = 'consent_privacy_policy_v1';
  static const _cloudSyncKey = 'consent_cloud_sync_v1';
  static const _aiKey = 'consent_ai_features_v1';
  static const _ageGroupKey = 'user_age_group';
  static const _communitiesKey = 'consent_communities_v1';

  static Future<bool> hasAcceptedPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyAcceptedKey) ?? false;
  }

  static Future<void> acceptPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyAcceptedKey, true);
  }

  static Future<bool> hasCloudSyncConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cloudSyncKey) ?? false;
  }

  static Future<void> setCloudSyncConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudSyncKey, value);
  }

  static Future<bool> hasAiConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiKey) ?? false;
  }

  static Future<void> setAiConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiKey, value);
    await syncAiEligibility();
  }

  /// Mirrors local AI consent + age-gate group to Firestore via Cloud Functions.
  /// Age/consent fields are protected in rules — clients cannot write them
  /// directly.
  ///
  /// Returns false when no authenticated Firebase session is available or the
  /// write could not be acknowledged. Local tracking remains unaffected.
  static Future<bool> syncAiEligibility() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final response = await CloudFunctionsClient.instance.post(
        '/syncAiEligibility',
        body: {
          'consentGranted': prefs.getBool(_aiKey) ?? false,
          'declaredAgeGroup': prefs.getString(_ageGroupKey) ?? 'unknown',
        },
      );
      if (response.statusCode == 200) return true;
      if (kDebugMode) {
        debugPrint(
          '[ConsentManager] AI eligibility sync failed: ${response.statusCode}',
        );
      }
      return false;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[ConsentManager] AI eligibility sync failed: $error');
      }
      return false;
    }
  }

  static Future<bool> hasCommunitiesConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_communitiesKey) ?? false;
  }

  static Future<void> setCommunitiesConsent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_communitiesKey, value);
  }
}
