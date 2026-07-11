import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../security/secure_storage_service.dart';

class UserPrefs {
  static const _uidKey = 'uid';
  static const _onboardingKey = 'onboarding_done';
  static const _premiumKey = 'is_premium';
  static const _profileNameKey = 'profile_name';
  static const _profileUsernameKey = 'profile_username';
  static const _profileGoalKey = 'profile_goal';
  static const _profileBirthDateKey = 'profile_birth_date';
  static const _postpartumStartKey = 'postpartum_start_date';
  static const _deviceUserIdKey = 'device_user_id';
  static const avatarIndexKey = 'profile_avatar_index';
  static const _stealthEnabledKey = 'stealth_mode_enabled';
  static const _stealthPinKey = 'stealth_mode_pin';
  static const _stealthPinHashKey = 'stealth_pin_hash';
  static const _stealthPinSaltKey = 'stealth_pin_salt';
  static final _secure = SecureStorageService();
  static String? _stealthPinHashMem;
  static String? _stealthPinSaltMem;

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

  static Future<String?> getProfileUsername() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_profileUsernameKey);
  }

  static Future<void> setProfileUsername(String username) async {
    final p = await SharedPreferences.getInstance();
    if (username.trim().isEmpty) {
      await p.remove(_profileUsernameKey);
    } else {
      await p.setString(_profileUsernameKey, username.trim());
    }
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

  /// Baby's birth date — anchors postpartum recovery week/milestones.
  static Future<void> setPostpartumStartDate(DateTime date) async {
    final p = await SharedPreferences.getInstance();
    final d = DateTime(date.year, date.month, date.day);
    await p.setString(_postpartumStartKey, d.toIso8601String());
  }

  static Future<DateTime?> getPostpartumStartDate() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_postpartumStartKey);
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

  /// Cryptographically random, URL-safe device id (128 bits of entropy).
  /// Stored once in SharedPreferences and reused for the device's lifetime.
  static String _generateDeviceId() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    final token = base64Url.encode(bytes).replaceAll('=', '');
    return 'lune_$token';
  }

  static Future<bool> isStealthModeEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_stealthEnabledKey) ?? false;
  }

  static Future<void> setStealthModeEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_stealthEnabledKey, value);
  }

  static Future<bool> hasStealthPin() async {
    await _migrateStealthPinFromPrefsIfNeeded();
    final hash = await _secure.read(_stealthPinHashKey) ?? _stealthPinHashMem;
    return hash != null && hash.isNotEmpty;
  }

  /// @deprecated Use [stealthPinMatchesBuffer] — PIN is stored as a hash only.
  static Future<String?> getStealthModePin() async {
    if (!await hasStealthPin()) return null;
    return null;
  }

  static Future<void> setStealthModePin(String pin) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_stealthPinKey);
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    _stealthPinSaltMem = salt;
    _stealthPinHashMem = hash;
    await _secure.write(_stealthPinSaltKey, salt);
    await _secure.write(_stealthPinHashKey, hash);
  }

  /// True when [buffer] ends with the configured stealth PIN digits.
  static Future<bool> stealthPinMatchesBuffer(String buffer) async {
    if (buffer.isEmpty) return false;
    await _migrateStealthPinFromPrefsIfNeeded();
    final salt = await _secure.read(_stealthPinSaltKey) ?? _stealthPinSaltMem;
    final hash = await _secure.read(_stealthPinHashKey) ?? _stealthPinHashMem;
    if (salt == null || hash == null) return false;
    for (var len = 4; len <= 8 && len <= buffer.length; len++) {
      final candidate = buffer.substring(buffer.length - len);
      if (_hashPin(candidate, salt) == hash) return true;
    }
    return false;
  }

  static Future<void> _migrateStealthPinFromPrefsIfNeeded() async {
    final p = await SharedPreferences.getInstance();
    final legacy = p.getString(_stealthPinKey);
    if (legacy == null || legacy.isEmpty) return;
    final existing = await _secure.read(_stealthPinHashKey);
    if (existing == null || existing.isEmpty) {
      await setStealthModePin(legacy);
    }
    await p.remove(_stealthPinKey);
  }

  static String _randomSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  static bool _sessionUnlocked = false;

  static bool isSessionUnlocked() => _sessionUnlocked;

  static void setSessionUnlocked(bool value) {
    _sessionUnlocked = value;
  }

  /// Clears in-process stealth PIN cache (tests only).
  @visibleForTesting
  static void resetStealthCacheForTest() {
    _stealthPinHashMem = null;
    _stealthPinSaltMem = null;
  }
}
