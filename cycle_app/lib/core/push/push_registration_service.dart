import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../notifications/app_notifications.dart';

/// Saves the device FCM token so admin broadcasts can reach this user.
class PushRegistrationService {
  PushRegistrationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;

  Future<void> registerIfPossible() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          await AppNotifications.requestPermission();
        } else {
          await _messaging.requestPermission();
        }
      }
      final token = await _messaging.getToken().timeout(
        const Duration(seconds: 8),
      );
      if (token == null || token.isEmpty) return;
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));

      _messaging.onTokenRefresh.listen((next) async {
        final current = _auth.currentUser?.uid;
        if (current == null) return;
        await _firestore.collection('users').doc(current).set({
          'fcmToken': next,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      if (kDebugMode) debugPrint('PushRegistrationService: $e');
    }
  }

  Future<void> clearToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmToken': FieldValue.delete(),
      }, SetOptions(merge: true));
      await _messaging.deleteToken();
    } catch (_) {}
  }
}
