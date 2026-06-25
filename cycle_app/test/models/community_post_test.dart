import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/models/community_post.dart';
import 'package:cycle_aura/features/community/data/models/post_type.dart';

void main() {
  group('CommunityPost.isVisibleTo', () {
    CommunityPost _post({
      bool hidden = false,
      String moderationStatus = 'approved',
      String authorUid = 'user1',
    }) =>
        CommunityPost(
          id: 'p1',
          communityId: 'c1',
          authorUid: authorUid,
          authorAlias: 'Luna',
          text: 'Hello',
          createdAt: DateTime(2025, 1, 1),
          hidden: hidden,
          moderationStatus: moderationStatus,
        );

    test('approved post is visible to everyone', () {
      final post = _post();
      expect(post.isVisibleTo('other'), isTrue);
      expect(post.isVisibleTo(null), isTrue);
    });

    test('hidden post is not visible to anyone', () {
      final post = _post(hidden: true);
      expect(post.isVisibleTo('user1'), isFalse);
      expect(post.isVisibleTo('other'), isFalse);
      expect(post.isVisibleTo(null), isFalse);
    });

    test('rejected post is not visible to anyone', () {
      final post = _post(moderationStatus: 'rejected');
      expect(post.isVisibleTo('user1'), isFalse);
      expect(post.isVisibleTo(null), isFalse);
    });

    test('pending_review post is only visible to its author', () {
      final post = _post(moderationStatus: 'pending_review', authorUid: 'user1');
      expect(post.isVisibleTo('user1'), isTrue);
      expect(post.isVisibleTo('other'), isFalse);
      expect(post.isVisibleTo(null), isFalse);
    });
  });

  group('CommunityPost.fromMap', () {
    test('parses basic fields', () {
      final post = CommunityPost.fromMap('doc1', {
        'communityId': 'c1',
        'authorUid': 'u1',
        'authorAlias': 'TestUser',
        'text': 'Hello world',
        'createdAt': DateTime(2025, 6, 1),
        'commentCount': 5,
        'postType': 'question',
      });

      expect(post.id, 'doc1');
      expect(post.communityId, 'c1');
      expect(post.authorUid, 'u1');
      expect(post.authorAlias, 'TestUser');
      expect(post.text, 'Hello world');
      expect(post.commentCount, 5);
      expect(post.postType, PostType.question);
    });

    test('defaults missing fields safely', () {
      final post = CommunityPost.fromMap('doc2', {});

      expect(post.communityId, '');
      expect(post.authorUid, '');
      expect(post.authorAlias, 'Anonymous');
      expect(post.text, '');
      expect(post.commentCount, 0);
      expect(post.postType, PostType.support);
      expect(post.hidden, isFalse);
      expect(post.isAnonymous, isFalse);
      expect(post.moderationStatus, 'approved');
    });

    test('normalizes mediaType', () {
      final img = CommunityPost.fromMap('d1', {'mediaType': 'image/png'});
      expect(img.mediaType, 'image');

      final vid = CommunityPost.fromMap('d2', {'mediaType': 'video/mp4'});
      expect(vid.mediaType, 'video');

      final raw = CommunityPost.fromMap('d3', {'mediaType': 'image'});
      expect(raw.mediaType, 'image');
    });
  });

  group('CommunityPost helpers', () {
    test('hasImage checks mediaType', () {
      final withImg = CommunityPost.fromMap('d', {
        'mediaUrl': 'https://example.com/img.jpg',
        'mediaType': 'image',
      });
      expect(withImg.hasImage, isTrue);

      final without = CommunityPost.fromMap('d', {});
      expect(without.hasImage, isFalse);
    });

    test('hasVideo checks mediaType', () {
      final withVid = CommunityPost.fromMap('d', {
        'mediaUrl': 'https://example.com/vid.mp4',
        'mediaType': 'video',
      });
      expect(withVid.hasVideo, isTrue);
    });

    test('isPendingReview checks moderationStatus', () {
      final pending = CommunityPost.fromMap('d', {
        'moderationStatus': 'pending_review',
      });
      expect(pending.isPendingReview, isTrue);

      final approved = CommunityPost.fromMap('d', {});
      expect(approved.isPendingReview, isFalse);
    });
  });
}
