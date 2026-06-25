import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'secure_storage_service.dart';

/// Generates and stores AES keys in secure storage (Android Keystore / iOS Keychain).
class CycleEncryptionKeys {
  static const _secretKey = 'cycle_secret_key';
  static const _ivKey = 'cycle_iv_key';
  static final _secure = SecureStorageService();

  static Future<Map<String, String>> loadOrCreate() async {
    var secret = await _secure.read(_secretKey);
    var iv = await _secure.read(_ivKey);

    if (secret == null || iv == null) {
      final prefs = await SharedPreferences.getInstance();
      secret ??= prefs.getString(_secretKey);
      iv ??= prefs.getString(_ivKey);

      if (secret == null || iv == null) {
        secret = _randomKey(16);
        iv = _randomKey(16);
      }

      await _secure.write(_secretKey, secret);
      await _secure.write(_ivKey, iv);
      await prefs.remove(_secretKey);
      await prefs.remove(_ivKey);
    }

    return {'secretKey': secret, 'ivKey': iv};
  }

  static String _randomKey(int length) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes).substring(0, length);
  }

  static String customerIdFromUid(String? uid) {
    if (uid == null || uid.isEmpty) return 'local_user';
    return sha256.convert(utf8.encode(uid)).toString().substring(0, 16);
  }
}
