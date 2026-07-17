import 'dart:math' as math;

import '../data/models/community_comment.dart';
import '../data/models/community_post.dart';
import '../data/models/post_type.dart';

enum CommunityFeedSort { newest, discussed }

/// Conversation-first ranking for the "popular" feed chip.
///
/// The score blends freshness, discussion depth and useful post signals. A
/// small evergreen engagement component keeps a valuable older conversation
/// discoverable, while the main engagement term decays with age. The final
/// pass limits long runs from one community so the feed feels like a healthy
/// mix of the groups the member joined.
List<CommunityPost> sortByPopularity(
  List<CommunityPost> posts, {
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  double score(CommunityPost p) {
    final ageHours =
        ref.difference(p.createdAt).inMinutes.clamp(0, 5256000) / 60.0;
    final ageDays = ageHours / 24.0;
    final freshness = 1 / (1 + ageHours / 36);
    final discussion = math.log(p.commentCount + 1) * 0.85 / (1 + ageDays / 14);
    final evergreen = math.sqrt(p.commentCount) * 0.25;
    final conversationPreview = p.hasTopComment ? 0.3 : 0.0;
    final resolvedQuestion = p.hasBestAnswer ? 0.18 : 0.0;
    final unansweredQuestion =
        p.postType == PostType.question && p.commentCount == 0 ? 0.32 : 0.0;
    final interactive = p.isPoll ? 0.16 : 0.0;
    return freshness * 3 +
        discussion +
        evergreen +
        conversationPreview +
        resolvedQuestion +
        unansweredQuestion +
        interactive;
  }

  final list = [...posts]..sort((a, b) => score(b).compareTo(score(a)));
  return diversifyCommunityPosts(list);
}

/// Avoids a visually repetitive feed without hiding or dropping any post.
/// Ordering is only adjusted when more than [maxConsecutive] adjacent items
/// come from the same community; the next highest-ranked different group is
/// pulled forward.
List<CommunityPost> diversifyCommunityPosts(
  List<CommunityPost> ranked, {
  int maxConsecutive = 2,
}) {
  if (ranked.length < 2 || maxConsecutive < 1) return [...ranked];
  final remaining = [...ranked];
  final result = <CommunityPost>[];
  String? lastCommunityId;
  var consecutive = 0;

  while (remaining.isNotEmpty) {
    var nextIndex = 0;
    if (lastCommunityId != null && consecutive >= maxConsecutive) {
      final alternative = remaining.indexWhere(
        (post) => post.communityId != lastCommunityId,
      );
      if (alternative >= 0) nextIndex = alternative;
    }

    final next = remaining.removeAt(nextIndex);
    if (next.communityId == lastCommunityId) {
      consecutive += 1;
    } else {
      lastCommunityId = next.communityId;
      consecutive = 1;
    }
    result.add(next);
  }
  return result;
}

/// Adds locally-sent comments until the live server snapshot contains the
/// authoritative copy. Matching uses the immutable submission fields and a
/// narrow timestamp window, so the UI never flashes or shows duplicates.
List<CommunityComment> mergeOptimisticComments({
  required List<CommunityComment> serverComments,
  required List<CommunityComment> optimisticComments,
}) {
  final unmatched = optimisticComments.where((local) {
    return !serverComments.any(
      (server) =>
          server.authorUid == local.authorUid &&
          server.text == local.text &&
          server.parentCommentId == local.parentCommentId &&
          server.createdAt.difference(local.createdAt).abs() <
              const Duration(minutes: 2),
    );
  });
  return [...serverComments, ...unmatched];
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
