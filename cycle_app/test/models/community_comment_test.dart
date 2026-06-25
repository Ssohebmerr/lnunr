import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/models/community_comment.dart';

void main() {
  group('CommunityComment.fromMap', () {
    test('parses basic fields', () {
      final comment = CommunityComment.fromMap('doc1', {
        'authorUid': 'u1',
        'authorAlias': 'Luna',
        'text': 'Hello!',
        'createdAt': DateTime(2025, 6, 1),
        'authorAvatarIndex': 2,
      });

      expect(comment.id, 'doc1');
      expect(comment.authorUid, 'u1');
      expect(comment.authorAlias, 'Luna');
      expect(comment.text, 'Hello!');
      expect(comment.authorAvatarIndex, 2);
    });

    test('defaults missing fields safely', () {
      final comment = CommunityComment.fromMap('doc2', {});
      expect(comment.authorUid, '');
      expect(comment.authorAlias, 'Anonymous');
      expect(comment.text, '');
      expect(comment.authorAvatarIndex, 0);
      expect(comment.moderationStatus, 'approved');
      expect(comment.hidden, isFalse);
      expect(comment.parentCommentId, isNull);
    });

    test('parses parentCommentId', () {
      final comment = CommunityComment.fromMap('doc3', {
        'parentCommentId': 'parent1',
      });
      expect(comment.parentCommentId, 'parent1');
    });
  });

  group('CommunityComment.isVisibleTo', () {
    CommunityComment _comment({
      bool hidden = false,
      String moderationStatus = 'approved',
      String authorUid = 'u1',
    }) =>
        CommunityComment(
          id: 'c1',
          authorUid: authorUid,
          authorAlias: 'Luna',
          text: 'Test',
          createdAt: DateTime(2025, 1, 1),
          hidden: hidden,
          moderationStatus: moderationStatus,
        );

    test('approved comment is visible to everyone', () {
      final c = _comment();
      expect(c.isVisibleTo('other'), isTrue);
      expect(c.isVisibleTo(null), isTrue);
    });

    test('hidden comment is not visible', () {
      final c = _comment(hidden: true);
      expect(c.isVisibleTo('u1'), isFalse);
      expect(c.isVisibleTo(null), isFalse);
    });

    test('rejected comment is not visible', () {
      final c = _comment(moderationStatus: 'rejected');
      expect(c.isVisibleTo('u1'), isFalse);
    });

    test('pending_review comment is only visible to author', () {
      final c = _comment(moderationStatus: 'pending_review', authorUid: 'u1');
      expect(c.isVisibleTo('u1'), isTrue);
      expect(c.isVisibleTo('other'), isFalse);
      expect(c.isVisibleTo(null), isFalse);
    });
  });

  group('CommunityComment helpers', () {
    test('isPendingReview checks moderationStatus', () {
      final pending = CommunityComment.fromMap('d', {
        'moderationStatus': 'pending_review',
      });
      expect(pending.isPendingReview, isTrue);

      final approved = CommunityComment.fromMap('d', {});
      expect(approved.isPendingReview, isFalse);
    });

    test('isEdited checks editedAt', () {
      final edited = CommunityComment.fromMap('d', {
        'editedAt': DateTime(2025, 6, 1),
      });
      expect(edited.isEdited, isTrue);

      final notEdited = CommunityComment.fromMap('d', {});
      expect(notEdited.isEdited, isFalse);
    });
  });
}
