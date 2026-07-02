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

  /// Loads the AES key/iv used to encrypt the cycle database.
  ///
  /// The key is kept in BOTH the platform keystore and a private
  /// SharedPreferences backup. Losing this key makes every saved period date
  /// unreadable, so resilience is prioritised: a fresh key is only generated
  /// when neither store has one (true first run). This guards against the
  /// known Android case where the keystore entry is wiped by an OS update or
  /// backup restore, which previously caused all cycle data to "disappear"
  /// after the app was closed.
  static Future<Map<String, String>> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Prefer the secure keystore.
    var secret = await _secure.read(_secretKey);
    var iv = await _secure.read(_ivKey);

    // 2. Fall back to the prefs backup as an atomic pair (never mix sources,
    //    or we'd combine a secret with the wrong iv and corrupt decryption).
    if (secret == null || iv == null) {
      final backupSecret = prefs.getString(_secretKey);
      final backupIv = prefs.getString(_ivKey);
      if (backupSecret != null && backupIv != null) {
        secret = backupSecret;
        iv = backupIv;
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

    // 4. Mirror into both stores so a future keystore failure can recover.
    await _secure.write(_secretKey, secret);
    await _secure.write(_ivKey, iv);
    await prefs.setString(_secretKey, secret);
    await prefs.setString(_ivKey, iv);

    return {'secretKey': secret, 'ivKey': iv};
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
}
