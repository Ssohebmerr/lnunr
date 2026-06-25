import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/moderation_result.dart';

void main() {
  group('ModerationResult', () {
    test('approved result has no reason', () {
      const result = ModerationResult(approved: true);
      expect(result.approved, isTrue);
      expect(result.reason, isNull);
      expect(result.pendingReview, isFalse);
    });

    test('rejected result carries reason', () {
      const result = ModerationResult(
        approved: false,
        reason: 'Contains phone number',
      );
      expect(result.approved, isFalse);
      expect(result.reason, 'Contains phone number');
    });

    test('pending review flag defaults to false', () {
      const result = ModerationResult(approved: true);
      expect(result.pendingReview, isFalse);
    });

    test('pending review can be set', () {
      const result = ModerationResult(approved: true, pendingReview: true);
      expect(result.pendingReview, isTrue);
    });
  });

  group('ModerationRejectedException', () {
    test('carries reason message', () {
      const e = ModerationRejectedException('Too many posts');
      expect(e.reason, 'Too many posts');
    });
  });

  group('MinorRestrictedException', () {
    test('is const constructible', () {
      const e = MinorRestrictedException();
      expect(e, isA<Exception>());
    });
  });

  group('CommunityBannedException', () {
    test('is const constructible', () {
      const e = CommunityBannedException();
      expect(e, isA<Exception>());
    });
  });

  group('CommunityFullException', () {
    test('is const constructible', () {
      const e = CommunityFullException();
      expect(e, isA<Exception>());
    });
  });
}
