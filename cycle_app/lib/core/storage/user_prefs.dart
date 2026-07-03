import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static const _uidKey = 'uid';
  static const _onboardingKey = 'onboarding_done';
  static const _premiumKey = 'is_premium';
  static const _profileNameKey = 'profile_name';
  static const _profileGoalKey = 'profile_goal';
  static const _profileBirthDateKey = 'profile_birth_date';
  static const _deviceUserIdKey = 'device_user_id';
  static const avatarIndexKey = 'profile_avatar_index';
  static const _stealthEnabledKey = 'stealth_mode_enabled';
  static const _stealthPinKey = 'stealth_mode_pin';

  /// Fixed uid for offline AI chat (stored on device only).
  static const localChatUid = 'local_guest';

  static Future<void> saveUid(String uid) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_uidKey, uid);
  }

  static Future<String?> getUid() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_uidKey);
  }

  static Future<void> clearUid() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_uidKey);
  }

  static Future<bool> isOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_onboardingKey, true);
  }

  static Future<void> clearOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_onboardingKey);
  }

  static Future<bool> isPremium() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_premiumKey) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_premiumKey, value);
  }

  static Future<void> setProfile({required String name, required String goal}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_profileNameKey, name);
    await p.setString(_profileGoalKey, goal);
  }

  static Future<String?> getProfileName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_profileNameKey);
  }

  static Future<String?> getProfileGoal() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_profileGoalKey);
  }

  static Future<void> setProfileBirthDate(DateTime date) async {
    final p = await SharedPreferences.getInstance();
    final d = DateTime(date.year, date.month, date.day);
    await p.setString(_profileBirthDateKey, d.toIso8601String());
  }

  static Future<DateTime?> getProfileBirthDate() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_profileBirthDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<String> getOrCreateDeviceId() async {
    final p = await SharedPreferences.getInstance();
    final existing = p.getString(_deviceUserIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _generateDeviceId();
    await p.setString(_deviceUserIdKey, id);
    return id;
  }

  static String _generateDeviceId() {
    final ms = DateTime.now().microsecondsSinceEpoch;
    final rand = ms.hashCode ^ Object().hashCode;
    return 'lune_${ms.toRadixString(36)}_${rand.toRadixString(36)}';
  }

  static Future<bool> isStealthModeEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_stealthEnabledKey) ?? false;
  }

  static Future<void> setStealthModeEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_stealthEnabledKey, value);
  }

  static Future<String?> getStealthModePin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_stealthPinKey);
  }

  static Future<void> setStealthModePin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_stealthPinKey, pin);
  }

  static bool _sessionUnlocked = false;

  static bool isSessionUnlocked() => _sessionUnlocked;

  static void setSessionUnlocked(bool value) {
    _sessionUnlocked = value;
  }
}
