import 'package:cycle_aura/features/postpartum/data/postpartum_recovery_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PostpartumRecoveryContent.recoveryWeek', () {
    test('birth today is recovery week 1', () {
      final now = DateTime(2026, 7, 4);
      expect(
        PostpartumRecoveryContent.recoveryWeek(now, now: now),
        1,
      );
    });

    test('7 days after birth is week 2', () {
      final birth = DateTime(2026, 7, 4);
      final now = birth.add(const Duration(days: 7));
      expect(
        PostpartumRecoveryContent.recoveryWeek(birth, now: now),
        2,
      );
    });

    test('a future birth date never returns below week 1', () {
      final now = DateTime(2026, 7, 4);
      final future = now.add(const Duration(days: 10));
      expect(
        PostpartumRecoveryContent.recoveryWeek(future, now: now),
        1,
      );
    });
  });

  group('PostpartumRecoveryContent.forWeek', () {
    test('week 1 maps to the fourth-trimester stage', () {
      final stage = PostpartumRecoveryContent.forWeek(1);
      expect(stage.startWeek, 1);
    });

    test('week 7 falls in the 6-week-check stage', () {
      final stage = PostpartumRecoveryContent.forWeek(7);
      expect(stage.startWeek, 6);
    });

    test('a very late week keeps the most advanced stage', () {
      final stage = PostpartumRecoveryContent.forWeek(80);
      expect(stage.startWeek, 25);
    });

    test('every stage provides non-empty bilingual copy', () {
      for (var w = 1; w <= 52; w++) {
        final stage = PostpartumRecoveryContent.forWeek(w);
        expect(stage.titleFor('en'), isNotEmpty);
        expect(stage.titleFor('ar'), isNotEmpty);
        expect(stage.bodyFor('en'), isNotEmpty);
        expect(stage.bodyFor('ar'), isNotEmpty);
        expect(stage.babyFor('ar'), isNotEmpty);
        expect(stage.focusFor('en'), isNotEmpty);
      }
    });
  });
}
