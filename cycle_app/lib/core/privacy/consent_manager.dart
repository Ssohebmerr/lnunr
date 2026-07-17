import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Mirrors the user's local AI consent and self-declared age group to their
  /// private Firestore profile so Cloud Functions can enforce the same gate.
  ///
  /// Returns false when no authenticated Firebase session is available or the
  /// write could not be acknowledged. Local tracking remains unaffected.
  static Future<bool> syncAiEligibility() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final prefs = await SharedPreferences.getInstance();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'aiConsentGranted': prefs.getBool(_aiKey) ?? false,
        'aiConsentVersion': 1,
        'aiAgeGroup': prefs.getString(_ageGroupKey) ?? 'unknown',
        'aiEligibilityUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
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
