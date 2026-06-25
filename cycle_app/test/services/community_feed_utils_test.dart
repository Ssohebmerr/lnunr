import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/models/community_post.dart';
import 'package:cycle_aura/features/community/data/models/community_comment.dart';
import 'package:cycle_aura/features/community/presentation/community_feed_utils.dart';

void main() {
  // Helper to create a post quickly
  CommunityPost _post({
    required String id,
    String text = 'Hello',
    String authorUid = 'u1',
    String authorAlias = 'Luna',
    int commentCount = 0,
    DateTime? createdAt,
    String? communityName,
  }) =>
      CommunityPost(
        id: id,
        communityId: 'c1',
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
        _post(id: '1', text: 'First post', createdAt: DateTime(2025, 1, 1)),
        _post(id: '2', text: 'Second post', commentCount: 5,
            createdAt: DateTime(2025, 1, 2)),
        _post(id: '3', text: 'Third post about health', commentCount: 10,
            authorUid: 'u2', authorAlias: 'Sara',
            createdAt: DateTime(2025, 1, 3)),
        _post(id: '4', text: 'Question?', commentCount: 3,
            communityName: 'Fertility',
            createdAt: DateTime(2025, 1, 4)),
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
      expect(result.last.id, '1');  // 0 comments
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
    CommunityComment _comment({
      required String id,
      String? parentCommentId,
    }) =>
        CommunityComment(
          id: id,
          authorUid: 'u1',
          authorAlias: 'Luna',
          text: 'Comment $id',
          createdAt: DateTime(2025, 1, 1),
          parentCommentId: parentCommentId,
        );

    test('returns empty for comment with no replies', () {
      final comments = [_comment(id: 'c1')];
      final replies = collectThreadReplies('c1', comments);
      expect(replies, isEmpty);
    });

    test('returns direct replies', () {
      final comments = [
        _comment(id: 'c1'),
        _comment(id: 'c2', parentCommentId: 'c1'),
        _comment(id: 'c3', parentCommentId: 'c1'),
      ];
      final replies = collectThreadReplies('c1', comments);
      expect(replies.length, 2);
      expect(replies.map((r) => r.id), containsAll(['c2', 'c3']));
    });

    test('returns nested replies (grandchildren)', () {
      final comments = [
        _comment(id: 'c1'),
        _comment(id: 'c2', parentCommentId: 'c1'),
        _comment(id: 'c3', parentCommentId: 'c2'),
        _comment(id: 'c4', parentCommentId: 'c3'),
      ];
      final replies = collectThreadReplies('c1', comments);
      expect(replies.length, 3);
      expect(replies.map((r) => r.id), containsAll(['c2', 'c3', 'c4']));
    });

    test('does not include unrelated comments', () {
      final comments = [
        _comment(id: 'c1'),
        _comment(id: 'c2', parentCommentId: 'c1'),
        _comment(id: 'c3'), // unrelated
        _comment(id: 'c4', parentCommentId: 'c3'), // unrelated
      ];
      final replies = collectThreadReplies('c1', comments);
      expect(replies.length, 1);
      expect(replies.first.id, 'c2');
    });
  });

  group('threadReplyCount', () {
    CommunityComment _comment({
      required String id,
      String? parentCommentId,
    }) =>
        CommunityComment(
          id: id,
          authorUid: 'u1',
          authorAlias: 'Luna',
          text: 'Comment $id',
          createdAt: DateTime(2025, 1, 1),
          parentCommentId: parentCommentId,
        );

    test('returns 0 for no replies', () {
      final comments = [_comment(id: 'c1')];
      expect(threadReplyCount('c1', comments), 0);
    });

    test('counts nested replies correctly', () {
      final comments = [
        _comment(id: 'c1'),
        _comment(id: 'c2', parentCommentId: 'c1'),
        _comment(id: 'c3', parentCommentId: 'c2'),
        _comment(id: 'c4', parentCommentId: 'c1'),
      ];
      expect(threadReplyCount('c1', comments), 3);
    });
  });
}
