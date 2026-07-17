import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/models/community_post.dart';
import 'package:cycle_aura/features/community/data/models/community_comment.dart';
import 'package:cycle_aura/features/community/presentation/community_feed_utils.dart';

void main() {
  // Helper to create a post quickly
  CommunityPost makePost({
    required String id,
    String text = 'Hello',
    String communityId = 'c1',
    String authorUid = 'u1',
    String authorAlias = 'Luna',
    int commentCount = 0,
    DateTime? createdAt,
    String? communityName,
  }) => CommunityPost(
    id: id,
    communityId: communityId,
    authorUid: authorUid,
    authorAlias: authorAlias,
    text: text,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    commentCount: commentCount,
    communityName: communityName,
  );

  group('filterAndSortCommunityPosts', () {
    late List<CommunityPost> posts;

    setUp(() {
      posts = [
        makePost(id: '1', text: 'First post', createdAt: DateTime(2025, 1, 1)),
        makePost(
          id: '2',
          text: 'Second post',
          commentCount: 5,
          createdAt: DateTime(2025, 1, 2),
        ),
        makePost(
          id: '3',
          text: 'Third post about health',
          commentCount: 10,
          authorUid: 'u2',
          authorAlias: 'Sara',
          createdAt: DateTime(2025, 1, 3),
        ),
        makePost(
          id: '4',
          text: 'Question?',
          commentCount: 3,
          communityName: 'Fertility',
          createdAt: DateTime(2025, 1, 4),
        ),
      ];
    });

    test('returns all posts with empty query', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: '',
        sort: CommunityFeedSort.newest,
      );
      expect(result.length, 4);
    });

    test('filters by text content', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: 'health',
        sort: CommunityFeedSort.newest,
      );
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('filters by author alias', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: 'sara',
        sort: CommunityFeedSort.newest,
      );
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('filters by community name', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: 'fertility',
        sort: CommunityFeedSort.newest,
      );
      expect(result.length, 1);
      expect(result.first.id, '4');
    });

    test('sort by newest orders by createdAt descending', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: '',
        sort: CommunityFeedSort.newest,
      );
      expect(result.first.id, '4');
      expect(result.last.id, '1');
    });

    test('sort by discussed orders by commentCount descending', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: '',
        sort: CommunityFeedSort.discussed,
      );
      expect(result.first.id, '3'); // 10 comments
      expect(result.last.id, '1'); // 0 comments
    });

    test('sortByPopularity ranks by engagement with recency decay', () {
      final now = DateTime(2026, 7, 14);
      final result = sortByPopularity([
        // Old megathread: 20 comments but 30 days old.
        makePost(
          id: 'old',
          commentCount: 20,
          createdAt: now.subtract(const Duration(days: 30)),
        ),
        // Fresh conversation: 5 comments, 1 day old — should win.
        makePost(
          id: 'fresh',
          commentCount: 5,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        // Fresh but silent post.
        makePost(
          id: 'silent',
          commentCount: 0,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ], now: now);

      expect(result.map((p) => p.id).toList(), ['fresh', 'old', 'silent']);
    });

    test('sortByPopularity does not mutate the input list', () {
      final input = [
        makePost(id: 'a', commentCount: 1),
        makePost(id: 'b', commentCount: 9),
      ];
      sortByPopularity(input, now: DateTime(2025, 1, 2));
      expect(input.map((p) => p.id).toList(), ['a', 'b']);
    });

    test('popular feed diversifies long runs from the same community', () {
      final now = DateTime(2026, 7, 14);
      final result = sortByPopularity([
        makePost(id: 'a1', communityId: 'a', commentCount: 12, createdAt: now),
        makePost(id: 'a2', communityId: 'a', commentCount: 11, createdAt: now),
        makePost(id: 'a3', communityId: 'a', commentCount: 10, createdAt: now),
        makePost(id: 'b1', communityId: 'b', commentCount: 2, createdAt: now),
      ], now: now);

      expect(result.map((p) => p.id), ['a1', 'a2', 'b1', 'a3']);
    });

    test('diversification preserves every post exactly once', () {
      final input = [
        makePost(id: 'a1', communityId: 'a'),
        makePost(id: 'a2', communityId: 'a'),
        makePost(id: 'a3', communityId: 'a'),
        makePost(id: 'b1', communityId: 'b'),
        makePost(id: 'c1', communityId: 'c'),
      ];

      final result = diversifyCommunityPosts(input);

      expect(result.map((p) => p.id).toSet(), input.map((p) => p.id).toSet());
      expect(result, hasLength(input.length));
      expect(input.map((p) => p.id), ['a1', 'a2', 'a3', 'b1', 'c1']);
    });

    test('authorUidFilter shows only matching posts', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: '',
        sort: CommunityFeedSort.newest,
        authorUidFilter: 'u2',
      );
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('query is case-insensitive', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: 'FIRST',
        sort: CommunityFeedSort.newest,
      );
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('combined filter and author filter', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: 'post',
        sort: CommunityFeedSort.newest,
        authorUidFilter: 'u2',
      );
      expect(result.length, 1);
      expect(result.first.id, '3');
    });

    test('no matches returns empty', () {
      final result = filterAndSortCommunityPosts(
        posts: posts,
        query: 'xyz_nonexistent',
        sort: CommunityFeedSort.newest,
      );
      expect(result, isEmpty);
    });
  });

  group('collectThreadReplies', () {
    CommunityComment makeComment({
      required String id,
      String? parentCommentId,
    }) => CommunityComment(
      id: id,
      authorUid: 'u1',
      authorAlias: 'Luna',
      text: 'Comment $id',
      createdAt: DateTime(2025, 1, 1),
      parentCommentId: parentCommentId,
    );

    test('returns empty for comment with no replies', () {
      final comments = [makeComment(id: 'c1')];
      final replies = collectThreadReplies('c1', comments);
      expect(replies, isEmpty);
    });

    test('returns direct replies', () {
      final comments = [
        makeComment(id: 'c1'),
        makeComment(id: 'c2', parentCommentId: 'c1'),
        makeComment(id: 'c3', parentCommentId: 'c1'),
      ];
      final replies = collectThreadReplies('c1', comments);
      expect(replies.length, 2);
      expect(replies.map((r) => r.id), containsAll(['c2', 'c3']));
    });

    test('returns nested replies (grandchildren)', () {
      final comments = [
        makeComment(id: 'c1'),
        makeComment(id: 'c2', parentCommentId: 'c1'),
        makeComment(id: 'c3', parentCommentId: 'c2'),
        makeComment(id: 'c4', parentCommentId: 'c3'),
      ];
      final replies = collectThreadReplies('c1', comments);
      expect(replies.length, 3);
      expect(replies.map((r) => r.id), containsAll(['c2', 'c3', 'c4']));
    });

    test('does not include unrelated comments', () {
      final comments = [
        makeComment(id: 'c1'),
        makeComment(id: 'c2', parentCommentId: 'c1'),
        makeComment(id: 'c3'), // unrelated
        makeComment(id: 'c4', parentCommentId: 'c3'), // unrelated
      ];
      final replies = collectThreadReplies('c1', comments);
      expect(replies.length, 1);
      expect(replies.first.id, 'c2');
    });
  });

  group('mergeOptimisticComments', () {
    CommunityComment comment({
      required String id,
      required String text,
      DateTime? createdAt,
      String? parentCommentId,
    }) => CommunityComment(
      id: id,
      authorUid: 'me',
      authorAlias: 'Luna',
      text: text,
      createdAt: createdAt ?? DateTime(2026, 7, 14, 12),
      parentCommentId: parentCommentId,
    );

    test('shows a local comment while the server is still sending', () {
      final local = comment(id: '_local_1', text: 'New reply');

      final result = mergeOptimisticComments(
        serverComments: const [],
        optimisticComments: [local],
      );

      expect(result, [local]);
    });

    test('deduplicates once the authoritative comment arrives', () {
      final local = comment(id: '_local_1', text: 'New reply');
      final server = comment(
        id: 'server_1',
        text: 'New reply',
        createdAt: local.createdAt.add(const Duration(seconds: 3)),
      );

      final result = mergeOptimisticComments(
        serverComments: [server],
        optimisticComments: [local],
      );

      expect(result, [server]);
    });
  });

  group('threadReplyCount', () {
    CommunityComment makeComment({
      required String id,
      String? parentCommentId,
    }) => CommunityComment(
      id: id,
      authorUid: 'u1',
      authorAlias: 'Luna',
      text: 'Comment $id',
      createdAt: DateTime(2025, 1, 1),
      parentCommentId: parentCommentId,
    );

    test('returns 0 for no replies', () {
      final comments = [makeComment(id: 'c1')];
      expect(threadReplyCount('c1', comments), 0);
    });

    test('counts nested replies correctly', () {
      final comments = [
        makeComment(id: 'c1'),
        makeComment(id: 'c2', parentCommentId: 'c1'),
        makeComment(id: 'c3', parentCommentId: 'c2'),
        makeComment(id: 'c4', parentCommentId: 'c1'),
      ];
      expect(threadReplyCount('c1', comments), 3);
    });
  });
}
