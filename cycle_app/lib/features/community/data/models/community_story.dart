import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityStory {
  const CommunityStory({
    required this.id,
    required this.communityId,
    required this.authorUid,
    required this.authorAlias,
    required this.mediaUrl,
    required this.mediaType,
    required this.createdAt,
    required this.expiresAt,
    this.authorAvatarIndex = 0,
    this.textOverlay,
    this.backgroundColor,
    this.viewCount = 0,
    this.viewedBy = const [],
  });

  final String id;
  final String communityId;
  final String authorUid;
  final String authorAlias;
  final String mediaUrl;
  /// `image` | `video` | `text`
  final String mediaType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int authorAvatarIndex;
  final String? textOverlay;
  final String? backgroundColor;
  final int viewCount;
  final List<String> viewedBy;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
  bool get isText => mediaType == 'text';

  Duration get remaining => expiresAt.difference(DateTime.now());

  factory CommunityStory.fromMap(String id, Map<String, dynamic> data) {
    final createdTs = data['createdAt'];
    final expiresTs = data['expiresAt'];
    return CommunityStory(
      id: id,
      communityId: data['communityId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorAlias: data['authorAlias'] as String? ?? 'User',
      mediaUrl: data['mediaUrl'] as String? ?? '',
      mediaType: data['mediaType'] as String? ?? 'image',
      createdAt: createdTs is Timestamp
          ? createdTs.toDate()
          : DateTime.tryParse(createdTs?.toString() ?? '') ?? DateTime.now(),
      expiresAt: expiresTs is Timestamp
          ? expiresTs.toDate()
          : DateTime.tryParse(expiresTs?.toString() ?? '') ??
              DateTime.now().add(const Duration(hours: 24)),
      authorAvatarIndex: data['authorAvatarIndex'] as int? ?? 0,
      textOverlay: data['textOverlay'] as String?,
      backgroundColor: data['backgroundColor'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      viewedBy: (data['viewedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() => {
        'communityId': communityId,
        'authorUid': authorUid,
        'authorAlias': authorAlias,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'authorAvatarIndex': authorAvatarIndex,
        if (textOverlay != null) 'textOverlay': textOverlay,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        'viewCount': viewCount,
        'viewedBy': viewedBy,
      };
}
