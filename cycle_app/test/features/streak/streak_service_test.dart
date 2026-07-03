// ============================================================================
// test/features/streak/streak_service_test.dart
// ----------------------------------------------------------------------------
// Tests the on-device streak tracker. Uses `SharedPreferences.setMockInitialValues`
// so the test suite stays hermetic — no platform channels needed.
//
// Dates are anchored to `DateTime.now()` because `currentCount()` compares
// against the real calendar day.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_aura/features/streak/data/streak_service.dart';

DateTime _today({int hour = 10}) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, hour);
}

DateTime _daysAgo(int days, {int hour = 10}) {
  final t = _today().subtract(Duration(days: days));
  return DateTime(t.year, t.month, t.day, hour);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakService.recordActivity', () {
    test('first-ever log → current=1, longest=1', () async {
      final svc = StreakService();
      final n = await svc.recordActivity(at: _today());
      expect(n, 1);
      expect(await svc.currentCount(), 1);
      expect(await svc.longestCount(), 1);
    });

    test('two consecutive days → current=2, longest=2', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _daysAgo(1));
      final n2 = await svc.recordActivity(at: _today());
      expect(n2, 2);
      expect(await svc.currentCount(), 2);
      expect(await svc.longestCount(), 2);
    });

    test('two logs on the same day stay idempotent', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _today(hour: 8));
      final n2 = await svc.recordActivity(at: _today(hour: 23));
      expect(n2, 1);
      expect(await svc.currentCount(), 1);
      expect(await svc.longestCount(), 1);
    });

    test('gap of 2+ days resets the streak to 1 but keeps longest', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _daysAgo(7));
      await svc.recordActivity(at: _daysAgo(6));
      await svc.recordActivity(at: _daysAgo(5));
      // Five-day gap after the 3-day run.
      final afterGap = await svc.recordActivity(at: _today());
      expect(afterGap, 1);
      expect(await svc.currentCount(), 1);
      expect(await svc.longestCount(), 3);
    });

    test('longestCount never decreases on a new log', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _daysAgo(9));
      await svc.recordActivity(at: _daysAgo(8));
      await svc.recordActivity(at: _daysAgo(7));
      expect(await svc.longestCount(), 3);
      await svc.recordActivity(at: _daysAgo(2));
      expect(await svc.longestCount(), 3);
      await svc.recordActivity(at: _daysAgo(1));
      expect(await svc.longestCount(), 3);
    });

    test('recordActivity called out of order (clock skew) clamps to 1', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _daysAgo(1));
      final n = await svc.recordActivity(at: _daysAgo(3));
      expect(n, 1);
      // Backdated write moves last_log_date into the past, so the live
      // streak read is broken until the user logs again today.
      expect(await svc.currentCount(), 0);
      expect(await svc.longestCount(), 1);
    });
  });

  group('StreakService.currentCount — live state', () {
    test('returns 0 when no log has ever been recorded', () async {
      expect(await StreakService().currentCount(), 0);
      expect(await StreakService().longestCount(), 0);
    });

    test('returns 0 + self-heals when last log was 2+ days ago', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _today());
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('streak.current_count'), 1);

      await prefs.setString('streak.last_log_date', '2020-01-01');
      expect(await svc.currentCount(), 0);
      expect(prefs.getInt('streak.current_count'), 0);
    });

    test('keeps the streak alive across a single skipped day', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _daysAgo(1));
      expect(await svc.currentCount(), 1);
    });
  });

  group('StreakService.getLoggedDatesThisMonth', () {
    test('returns only this month + in insertion order', () async {
      final svc = StreakService();
      final today = _today();
      final twoDaysAgo = _daysAgo(2);
      final yesterday = _daysAgo(1);
      final lastMonth = DateTime(today.year, today.month, 1)
          .subtract(const Duration(days: 1));

      await svc.recordActivity(at: lastMonth);
      await svc.recordActivity(at: twoDaysAgo);
      await svc.recordActivity(at: yesterday);
      await svc.recordActivity(at: today);

      final dates = await svc.getLoggedDatesThisMonth();
      expect(dates, hasLength(3));
      expect(
        dates.map((d) => '${d.year}-${d.month}-${d.day}').toList(),
        [
          '${twoDaysAgo.year}-${twoDaysAgo.month}-${twoDaysAgo.day}',
          '${yesterday.year}-${yesterday.month}-${yesterday.day}',
          '${today.year}-${today.month}-${today.day}',
        ],
      );
    });

    test('returns empty when nothing was logged', () async {
      expect(await StreakService().getLoggedDatesThisMonth(), isEmpty);
    });
  });

  group('StreakService.reset', () {
    test('clears current + longest + last date + logged dates', () async {
      final svc = StreakService();
      await svc.recordActivity(at: _daysAgo(1));
      await svc.recordActivity(at: _today());
      await svc.reset();
      expect(await svc.currentCount(), 0);
      expect(await svc.longestCount(), 0);
      expect(await svc.getLoggedDatesThisMonth(), isEmpty);
    });
  });
}
