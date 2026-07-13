import 'package:cloud_firestore/cloud_firestore.dart';

class FollowedUser {
  const FollowedUser({
    required this.uid,
    this.alias,
    this.avatarIndex = 0,
    this.followedAt,
  });

  final String uid;
  final String? alias;
  final int avatarIndex;
  final DateTime? followedAt;

  factory FollowedUser.fromDoc(String uid, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return FollowedUser(
      uid: uid,
      alias: data['alias'] as String?,
      avatarIndex: data['avatarIndex'] as int? ?? 0,
      followedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
