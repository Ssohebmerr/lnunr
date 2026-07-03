import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'models/guest_user_profile.dart';

/// Firestore access for `users/{uid}` guest profiles (data layer).
class GuestUserRepository {
  GuestUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<GuestUserProfile?> fetch(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return GuestUserProfile.fromFirestore(uid, snap.data()!);
  }

  Future<void> createProfile({
    required String uid,
    required String name,
    required DateTime birthDate,
    required String deviceId,
  }) async {
    final profile = GuestUserProfile(uid: uid, name: name, birthDate: birthDate);
    await _doc(uid).set(
      profile.toCreatePayload(
        name: name,
        birthDate: birthDate,
        deviceId: deviceId,
      ),
    );
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required DateTime birthDate,
    required String deviceId,
  }) async {
    final profile = GuestUserProfile(uid: uid, name: name, birthDate: birthDate);
    final data = profile.toUpdatePayload(
      name: name,
      birthDate: birthDate,
      deviceId: deviceId,
    );
    final snap = await _doc(uid).get();
    if (!snap.exists) {
      await createProfile(
        uid: uid,
        name: name,
        birthDate: birthDate,
        deviceId: deviceId,
      );
      return;
    }
    final existing = snap.data() ?? {};
    if (!existing.containsKey('communityBirthYear')) {
      data['communityBirthYear'] = birthDate.year;
    }
    await _doc(uid).update(data);
  }

  Future<void> incrementDailyChatCount(String uid) async {
    try {
      await _doc(uid).update({
        'daily_chat_count': FieldValue.increment(1),
        'lastChatAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      debugPrint('GuestUserRepository incrementDailyChatCount: $e\n$st');
    }
  }
}
