import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Nonce helpers required for Sign in with Apple + Firebase Auth.
class AppleAuthHelper {
  AppleAuthHelper._();

  static String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  static String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }
}
