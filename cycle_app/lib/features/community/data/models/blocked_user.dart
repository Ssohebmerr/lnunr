import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  const BlockedUser({required this.uid, this.authorAlias, this.blockedAt});

  final String uid;
  final String? authorAlias;
  final DateTime? blockedAt;

  factory BlockedUser.fromDoc(String uid, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return BlockedUser(
      uid: uid,
      authorAlias: data['authorAlias'] as String?,
      blockedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
