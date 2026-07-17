import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityComment {
  const CommunityComment({
    required this.id,

    required this.authorUid,

    required this.authorAlias,

    required this.text,

    required this.createdAt,

    this.authorAvatarIndex = 0,

    this.parentCommentId,

    this.editedAt,

    this.moderationStatus = 'approved',
    this.hidden = false,
    this.authorIsPremium = false,
    this.likeCount,
  });

  final String id;

  final String authorUid;

  final String authorAlias;

  final String text;

  final DateTime createdAt;

  final int authorAvatarIndex;

  final String? parentCommentId;

  final DateTime? editedAt;

  final String moderationStatus;
  final bool hidden;
  final bool authorIsPremium;

  /// Server-maintained aggregate. Null identifies legacy comments that still
  /// need a one-time aggregate lookup when sorting by most liked.
  final int? likeCount;

  bool get isPendingReview => moderationStatus == 'pending_review';

  bool get isEdited => editedAt != null;

  bool isVisibleTo(String? viewerUid) {
    if (hidden) return false;
    if (moderationStatus == 'rejected') return false;
    if (!isPendingReview) return true;
    return viewerUid != null && viewerUid == authorUid;
  }

  factory CommunityComment.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];

    return CommunityComment(
      id: id,

      authorUid: data['authorUid'] as String? ?? '',

      authorAlias: data['authorAlias'] as String? ?? 'Anonymous',

      text: data['text'] as String? ?? '',

      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),

      authorAvatarIndex: data['authorAvatarIndex'] as int? ?? 0,

      parentCommentId: data['parentCommentId'] as String?,

      editedAt: _parseTs(data['editedAt']),

      moderationStatus: data['moderationStatus'] as String? ?? 'approved',
      hidden: data['hidden'] as bool? ?? false,
      authorIsPremium: data['authorIsPremium'] as bool? ?? false,
      likeCount: (data['likeCount'] as num?)?.toInt(),
    );
  }

  static DateTime? _parseTs(dynamic ts) {
    if (ts == null) return null;

    if (ts is Timestamp) return ts.toDate();

    return DateTime.tryParse(ts.toString());
  }

  Map<String, dynamic> toMap() => {
    'authorUid': authorUid,

    'authorAlias': authorAlias,

    'text': text,

    'createdAt': FieldValue.serverTimestamp(),

    'authorAvatarIndex': authorAvatarIndex,
    'authorIsPremium': authorIsPremium,

    if (likeCount != null) 'likeCount': likeCount,

    if (parentCommentId != null) 'parentCommentId': parentCommentId,
  };
}
