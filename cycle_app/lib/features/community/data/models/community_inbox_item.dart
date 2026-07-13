import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityInboxItem {
  const CommunityInboxItem({
    required this.id,
    required this.type,
    required this.fromAlias,
    required this.preview,
    required this.communityId,
    required this.postId,
    required this.read,
    required this.createdAt,
  });

  final String id;

  /// `comment`, `like`, or `reply`
  final String type;
  final String fromAlias;
  final String preview;
  final String communityId;
  final String postId;
  final bool read;
  final DateTime createdAt;

  factory CommunityInboxItem.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return CommunityInboxItem(
      id: id,
      type: data['type'] as String? ?? 'comment',
      fromAlias: data['fromAlias'] as String? ?? '',
      preview: data['preview'] as String? ?? '',
      communityId: data['communityId'] as String? ?? '',
      postId: data['postId'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
