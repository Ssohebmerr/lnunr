import 'package:cloud_firestore/cloud_firestore.dart';

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
    DateTime? birthDate,
    required String deviceId,
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'deviceId': deviceId,
      'isPremium': false,
      'daily_chat_count': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (birthDate != null) {
      payload['birthDate'] = Timestamp.fromDate(birthDate);
      payload['communityBirthYear'] = birthDate.year;
    }
    await _doc(uid).set(payload);
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    DateTime? birthDate,
    required String deviceId,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'deviceId': deviceId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (birthDate != null) {
      data['birthDate'] = Timestamp.fromDate(birthDate);
    }
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
    if (birthDate != null && !existing.containsKey('communityBirthYear')) {
      data['communityBirthYear'] = birthDate.year;
    }
    await _doc(uid).update(data);
  }

  /// Saves the public handle. Merge-set so it works whether or not the
  /// profile document already exists.
  Future<void> saveUsername({
    required String uid,
    required String username,
  }) async {
    await _doc(uid).set(
      {
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // NOTE: daily_chat_count is incremented ONLY server-side (Cloud Functions
  // transaction in lib/chat_quota.js). Client writes to it are blocked by
  // security rules, so no client-side increment exists here.
}
