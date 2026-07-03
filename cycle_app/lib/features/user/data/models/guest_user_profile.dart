import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `users/{uid}` profile for device-based guest accounts.
class GuestUserProfile {
  const GuestUserProfile({
    required this.uid,
    required this.name,
    this.birthDate,
    this.deviceId,
    this.isPremium = false,
    this.dailyChatCount = 0,
  });

  final String uid;
  final String name;
  final DateTime? birthDate;
  final String? deviceId;
  final bool isPremium;
  final int dailyChatCount;

  factory GuestUserProfile.fromFirestore(String uid, Map<String, dynamic> data) {
    final birth = data['birthDate'];
    return GuestUserProfile(
      uid: uid,
      name: (data['name'] as String?)?.trim() ?? '',
      birthDate: birth is Timestamp ? birth.toDate() : null,
      deviceId: data['deviceId'] as String?,
      isPremium: data['isPremium'] == true,
      dailyChatCount: (data['daily_chat_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toCreatePayload({
    required String name,
    required DateTime birthDate,
    required String deviceId,
  }) {
    return {
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'communityBirthYear': birthDate.year,
      'deviceId': deviceId,
      'isPremium': false,
      'daily_chat_count': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdatePayload({
    required String name,
    required DateTime birthDate,
    required String deviceId,
  }) {
    return {
      'name': name,
      'birthDate': Timestamp.fromDate(birthDate),
      'deviceId': deviceId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
