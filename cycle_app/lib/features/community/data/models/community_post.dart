import 'package:cloud_firestore/cloud_firestore.dart';

import 'post_type.dart';

/// Aggregated live results for a poll post.
class PollResults {
  const PollResults({this.counts = const {}, this.totalVotes = 0, this.myVote});

  /// Option index → number of votes.
  final Map<int, int> counts;
  final int totalVotes;

  /// The viewer's chosen option index, or null if they haven't voted.
  final int? myVote;

  bool get hasVoted => myVote != null;

  int countFor(int index) => counts[index] ?? 0;

  double fractionFor(int index) =>
      totalVotes == 0 ? 0 : countFor(index) / totalVotes;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.communityId,
    required this.authorUid,
    required this.authorAlias,
    required this.text,
    required this.createdAt,
    this.commentCount = 0,
    this.postType = PostType.support,
    this.communityName,
    this.authorAvatarIndex = 0,
    this.mediaUrl,
    this.mediaType,
    this.hidden = false,
    this.bestAnswerCommentId,
    this.editedAt,
    this.isAnonymous = false,
    this.moderationStatus = 'approved',
    this.authorIsPremium = false,
    this.pollOptions,
    this.topCommentAlias,
    this.topCommentPreview,
    this.topCommentAvatarIndex = 0,
    this.coverStyle,
  });

  final String id;
  final String communityId;
  final String authorUid;
  final String authorAlias;
  final String text;
  final DateTime createdAt;
  final int commentCount;
  final PostType postType;
  final String? communityName;
  final int authorAvatarIndex;
  final String? mediaUrl;

  /// `image` or `video`
  final String? mediaType;
  final bool hidden;
  final String? bestAnswerCommentId;
  final DateTime? editedAt;
  final bool isAnonymous;

  /// `approved` | `pending_review`
  final String moderationStatus;
  final bool authorIsPremium;

  /// 2–4 choices when [postType] is [PostType.poll].
  final List<String>? pollOptions;

  /// Latest approved top-level comment, denormalised onto the post by the
  /// server so feed cards can show a live conversation preview without any
  /// extra reads.
  final String? topCommentAlias;
  final String? topCommentPreview;
  final int topCommentAvatarIndex;

  bool get hasTopComment =>
      topCommentPreview != null && topCommentPreview!.trim().isNotEmpty;

  /// Designed gradient cover id for text posts (see PostCoverStyles).
  final String? coverStyle;

  bool get isPendingReview => moderationStatus == 'pending_review';

  bool get isPoll =>
      postType == PostType.poll &&
      pollOptions != null &&
      pollOptions!.length >= 2;

  bool isVisibleTo(String? viewerUid, {bool ownedByViewer = false}) {
    if (hidden) return false;
    if (moderationStatus == 'rejected') return false;
    if (!isPendingReview) return true;
    if (ownedByViewer) return true;
    return viewerUid != null && authorUid.isNotEmpty && viewerUid == authorUid;
  }

  /// Like [isVisibleTo] but also hides posts from authors the [viewerUid] has
  /// blocked. Use this in feed-style views that must respect the block list.
  bool isVisibleToViewer(
    String? viewerUid, {
    Set<String> blockedUids = const {},
  }) {
    if (!isVisibleTo(viewerUid)) return false;
    if (viewerUid == null) return true;
    if (authorUid.isEmpty) return true;
    return !blockedUids.contains(authorUid);
  }

  bool get hasImage =>
      mediaUrl != null &&
      (mediaType == 'image' || mediaType?.startsWith('image/') == true);
  bool get isEdited => editedAt != null;
  bool get hasBestAnswer =>
      bestAnswerCommentId != null && bestAnswerCommentId!.isNotEmpty;
  bool get hasVideo =>
      mediaUrl != null &&
      (mediaType == 'video' || mediaType?.startsWith('video/') == true);

  factory CommunityPost.fromMap(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    // Firestore may hand nested maps back as Map<Object?, Object?>.
    final rawTop = data['topComment'];
    final topComment = rawTop is Map
        ? Map<String, dynamic>.from(rawTop)
        : const <String, dynamic>{};
    return CommunityPost(
      id: id,
      communityId: data['communityId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorAlias: data['authorAlias'] as String? ?? 'Anonymous',
      text: data['text'] as String? ?? '',
      createdAt: ts is Timestamp
          ? ts.toDate()
          : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now(),
      commentCount: data['commentCount'] as int? ?? 0,
      postType: PostType.fromValue(data['postType'] as String?),
      communityName: data['communityName'] as String?,
      authorAvatarIndex: data['authorAvatarIndex'] as int? ?? 0,
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: _normalizeMediaType(data['mediaType'] as String?),
      hidden: data['hidden'] as bool? ?? false,
      bestAnswerCommentId: data['bestAnswerCommentId'] as String?,
      editedAt: _parseTs(data['editedAt']),
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      moderationStatus: data['moderationStatus'] as String? ?? 'approved',
      authorIsPremium: data['authorIsPremium'] as bool? ?? false,
      pollOptions: (data['pollOptions'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      topCommentAlias: topComment['alias'] as String?,
      topCommentPreview: topComment['preview'] as String?,
      topCommentAvatarIndex: topComment['avatarIndex'] as int? ?? 0,
      coverStyle: data['coverStyle'] as String?,
    );
  }

  static DateTime? _parseTs(dynamic ts) {
    if (ts == null) return null;
    if (ts is Timestamp) return ts.toDate();
    return DateTime.tryParse(ts.toString());
  }

  static String? _normalizeMediaType(String? raw) {
    if (raw == null) return null;
    if (raw == 'video' || raw.startsWith('video/')) return 'video';
    if (raw == 'image' || raw.startsWith('image/')) return 'image';
    return raw;
  }

  Map<String, dynamic> toMap() => {
    'communityId': communityId,
    'authorUid': authorUid,
    'authorAlias': authorAlias,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
    'commentCount': commentCount,
    'postType': postType.value,
    if (communityName != null) 'communityName': communityName,
    'authorAvatarIndex': authorAvatarIndex,
    if (mediaUrl != null) 'mediaUrl': mediaUrl,
    if (mediaType != null) 'mediaType': mediaType,
    'isAnonymous': isAnonymous,
    'authorIsPremium': authorIsPremium,
    if (pollOptions != null && pollOptions!.isNotEmpty)
      'pollOptions': pollOptions,
  };
}
