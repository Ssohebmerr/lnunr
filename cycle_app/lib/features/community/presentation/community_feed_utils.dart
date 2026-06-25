import '../data/models/community_comment.dart';
import '../data/models/community_post.dart';

enum CommunityFeedSort { newest, discussed }

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
      list = [...list]..sort((a, b) {
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
