import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/firebase/cloud_functions_client.dart';

/// Talks to Cloud Functions for user-side support actions:
///  - submit feedback
///  - redeem promo code
class SupportService {
  static Future<String> _platformTag() async {
    if (kIsWeb) return 'web';
    try {
      if (Platform.isAndroid) return 'android';
      if (Platform.isIOS) return 'ios';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (_) {}
    return 'unknown';
  }

  static Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '';
    }
  }

  static Future<String?> _idToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Submits feedback to the admin inbox. Requires sign-in.
  /// [type]: one of 'bug', 'idea', 'help', 'other'.
  static Future<void> submitFeedback({
    required String type,
    required String message,
  }) async {
    final token = await _idToken();
    if (token == null) {
      throw Exception('يجب تسجيل الدخول أولاً لإرسال الملاحظات');
    }
    final platform = await _platformTag();
    final appVersion = await _appVersion();

    final res = await CloudFunctionsClient.instance.post(
      '/submitFeedback',
      body: {
        'type': type,
        'message': message,
        'appVersion': appVersion,
        'platform': platform,
      },
    );

    if (res.statusCode != 200) {
      String err = 'فشل إرسال الملاحظة (${res.statusCode})';
      try {
        final data = jsonDecode(res.body);
        if (data is Map && data['error'] is String) err = data['error'];
      } catch (_) {}
      throw Exception(err);
    }
  }

  /// Redeems a promo code. Returns the number of premium days granted.
  static Future<int> redeemPromoCode(String code) async {
    final token = await _idToken();
    if (token == null) {
      throw Exception('يجب تسجيل الدخول أولاً لاستخدام الكود');
    }
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) {
      throw Exception('الكود فارغ');
    }

    final res = await CloudFunctionsClient.instance.post(
      '/redeemPromoCode',
      body: {'code': clean},
    );

    final body = res.body;
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) data = decoded;
    } catch (_) {}

    if (res.statusCode != 200) {
      final err = data?['error']?.toString() ?? 'فشل استخدام الكود';
      throw Exception(err);
    }
    final days = data?['days'];
    if (days is int) return days;
    if (days is num) return days.toInt();
    return 0;
  }
}
