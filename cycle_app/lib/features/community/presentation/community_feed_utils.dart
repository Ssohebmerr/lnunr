import 'dart:math' as math;

import '../data/models/community_comment.dart';
import '../data/models/community_post.dart';

enum CommunityFeedSort { newest, discussed }

/// Engagement-ranked ordering for the "popular" feed chip: comment volume
/// dampened by age, so a fresh conversation can beat an old megathread.
List<CommunityPost> sortByPopularity(
  List<CommunityPost> posts, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  double score(CommunityPost p) {
    final ageDays = ref.difference(p.createdAt).inHours / 24.0;
    return (p.commentCount + 1) / math.pow(ageDays.clamp(0, 3650) + 2, 1.4);
  }

  final list = [...posts]..sort((a, b) => score(b).compareTo(score(a)));
  return list;
}

List<CommunityPost> filterAndSortCommunityPosts({
  required List<CommunityPost> posts,
  required String query,
  required CommunityFeedSort sort,
  String? authorUidFilter,
}) {
  var list = posts;

  if (authorUidFilter != null) {
    list = list.where((p) => p.authorUid == authorUidFilter).toList();
  }

  final q = query.trim().toLowerCase();
  if (q.isNotEmpty) {
    list = list
        .where(
          (p) =>
              p.text.toLowerCase().contains(q) ||
              p.authorAlias.toLowerCase().contains(q) ||
              (p.communityName?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  switch (sort) {
    case CommunityFeedSort.discussed:
      list = [...list]
        ..sort((a, b) {
          final byComments = b.commentCount.compareTo(a.commentCount);
          if (byComments != 0) return byComments;
          return b.createdAt.compareTo(a.createdAt);
        });
    case CommunityFeedSort.newest:
      list = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return list;
}

/// All replies under a root comment (any nesting depth).
List<CommunityComment> collectThreadReplies(
  String rootCommentId,
  List<CommunityComment> all,
) {
  final result = <CommunityComment>[];

  void walk(String parentId) {
    for (final c in all.where((x) => x.parentCommentId == parentId)) {
      result.add(c);
      walk(c.id);
    }
  }

  walk(rootCommentId);
  return result;
}

int threadReplyCount(String rootCommentId, List<CommunityComment> all) =>
    collectThreadReplies(rootCommentId, all).length;
