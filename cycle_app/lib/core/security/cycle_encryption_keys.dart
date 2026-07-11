import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// Generates and stores AES keys in secure storage (Android Keystore / iOS Keychain).
class CycleEncryptionKeys {
  static const _secretKey = 'cycle_secret_key';
  static const _ivKey = 'cycle_iv_key';
  static final _secure = SecureStorageService();
  static Map<String, String>? _cachedKeys;

  /// Loads the AES key/iv used to encrypt the cycle database.
  ///
  /// Keys live in the platform keystore only. A one-time migration reads any
  /// legacy SharedPreferences copy, moves it into secure storage, then deletes
  /// the plaintext backup.
  static Future<Map<String, String>> loadOrCreate() async {
    if (_cachedKeys != null) return Map<String, String>.from(_cachedKeys!);

    final prefs = await SharedPreferences.getInstance();

    // 1. Prefer the secure keystore.
    var secret = await _secure.read(_secretKey);
    var iv = await _secure.read(_ivKey);

    // 2. One-time migration from legacy plaintext prefs backup.
    if (secret == null || iv == null) {
      final backupSecret = prefs.getString(_secretKey);
      final backupIv = prefs.getString(_ivKey);
      if (backupSecret != null && backupIv != null) {
        secret = backupSecret;
        iv = backupIv;
        if (kDebugMode) {
          debugPrint('[CycleEncryptionKeys] Migrating keys from prefs to keystore.');
        }
      }
    }

    // 3. Genuine first run: generate a new key.
    final generated = secret == null || iv == null;
    if (generated) {
      secret = _randomKey(16);
      iv = _randomKey(16);
      if (kDebugMode) {
        debugPrint('[CycleEncryptionKeys] Generated a new encryption key.');
      }
    }

    // 4. Persist in keystore only — never mirror to SharedPreferences.
    await _secure.write(_secretKey, secret);
    await _secure.write(_ivKey, iv);
    await prefs.remove(_secretKey);
    await prefs.remove(_ivKey);

    _cachedKeys = {'secretKey': secret, 'ivKey': iv};
    return Map<String, String>.from(_cachedKeys!);
  }

  static String _randomKey(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, length);
  }

  /// Stable partition id for the on-device encrypted cycle database.
  ///
  /// The local cycle store MUST always use this single id, independent of
  /// Firebase sign-in state. Previously the id switched between `'local_user'`
  /// (onboarding) and a uid-derived hash (after sign-in), which orphaned the
  /// period dates entered during onboarding and made them "disappear" on the
  /// next launch for any signed-in user.
  static const String localCustomerId = 'local_user';

  static String customerIdFromUid(String? uid) {
    if (uid == null || uid.isEmpty) return localCustomerId;
    return sha256.convert(utf8.encode(uid)).toString().substring(0, 16);
  }

  /// Clears the in-process key cache (tests only).
  @visibleForTesting
  static void resetCacheForTest() => _cachedKeys = null;
}
