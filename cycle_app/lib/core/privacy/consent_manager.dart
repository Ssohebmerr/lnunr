import 'package:shared_preferences/shared_preferences.dart';

/// Tracks explicit user consent for optional cloud/AI features (Data Safety / GDPR).
class ConsentManager {
  static const _privacyAcceptedKey = 'consent_privacy_policy_v1';
  static const _cloudSyncKey = 'consent_cloud_sync_v1';
  static const _aiKey = 'consent_ai_features_v1';
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
