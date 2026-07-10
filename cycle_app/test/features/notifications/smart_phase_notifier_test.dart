// ============================================================================
// test/features/notifications/smart_phase_notifier_test.dart
// ----------------------------------------------------------------------------
// Pure-data tests for the runway projection + message rotation. No Flutter
// bindings, plugins or SharedPreferences needed — SmartPhaseNotifier.
// contextForOffset is a static pure function and SmartPhaseMessages.pick is
// pure data, so we can exercise the whole "which message on day N" pipeline
// deterministically.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/notifications/data/smart_phase_messages.dart';
import 'package:cycle_aura/features/notifications/data/smart_phase_notifier.dart';

void main() {
  group('SmartPhaseNotifier.contextForOffset — cycle projection', () {
    test('day 0 uses the widget-reported current phase verbatim', () {
      final ctx = SmartPhaseNotifier.contextForOffset(
        dayOffset: 0,
        currentCycleDay: 3,
        cycleLength: 28,
        periodDuration: 5,
        currentPhase: 'الحيض',
      );
      expect(ctx.phase, 'الحيض');
      expect(ctx.cycleDay, 3);
      expect(ctx.isPregnant, isFalse);
      // The Arabic menstrual label must still classify to a menstrual message.
      expect(SmartPhaseMessages.pick(ctx, 'ar').tag, 'menstrual|ar');
    });

    test('future days project the cycle forward through the phases', () {
      // cycleDay 1 today, 28-day cycle, 5-day period.
      // follicularEnd = 5 + 6 = 11, ovulationEnd = 11 + 5 = 16.
      SmartPhaseContext at(int offset) => SmartPhaseNotifier.contextForOffset(
            dayOffset: offset,
            currentCycleDay: 1,
            cycleLength: 28,
            periodDuration: 5,
            currentPhase: 'Menstruation',
          );

      expect(SmartPhaseMessages.pick(at(6), 'en').tag, 'follicular|en'); // day 7
      expect(SmartPhaseMessages.pick(at(13), 'en').tag, 'ovulation|en'); // day 14
      expect(SmartPhaseMessages.pick(at(20), 'en').tag, 'luteal|en'); // day 21
    });

    test('runway wraps at cycle end into a fresh menstrual phase', () {
      // Day 27 of 28 today → 3 days out lands on day 2 of the next cycle.
      final ctx = SmartPhaseNotifier.contextForOffset(
        dayOffset: 3,
        currentCycleDay: 27,
        cycleLength: 28,
        periodDuration: 5,
        currentPhase: 'Luteal',
      );
      expect(ctx.cycleDay, 2);
      expect(SmartPhaseMessages.pick(ctx, 'en').tag, 'menstrual|en');
    });

    test('no cycle data yet → generic context on every day', () {
      final ctx = SmartPhaseNotifier.contextForOffset(
        dayOffset: 5,
        currentCycleDay: 0,
        cycleLength: 28,
        periodDuration: 5,
        currentPhase: '',
      );
      expect(ctx.cycleDay, isNull);
      expect(SmartPhaseMessages.pick(ctx, 'en').tag, 'generic|en');
    });

    test('bad cycle length falls back to 28 without throwing', () {
      final ctx = SmartPhaseNotifier.contextForOffset(
        dayOffset: 4,
        currentCycleDay: 1,
        cycleLength: 0,
        periodDuration: 0,
        currentPhase: 'Menstruation',
      );
      // period falls back to 5; day 5 is still within the menstrual window.
      expect(ctx.cycleDay, 5);
      expect(SmartPhaseMessages.pick(ctx, 'en').tag, 'menstrual|en');
    });
  });

  group('SmartPhaseNotifier.contextForOffset — pregnancy projection', () {
    test('week advances every 7 days and trimester follows', () {
      final t1 = SmartPhaseNotifier.contextForOffset(
        dayOffset: 0,
        currentCycleDay: 0,
        cycleLength: 28,
        periodDuration: 5,
        currentPhase: '',
        isPregnant: true,
        pregnancyWeek: 12,
      );
      final t2 = SmartPhaseNotifier.contextForOffset(
        dayOffset: 14,
        currentCycleDay: 0,
        cycleLength: 28,
        periodDuration: 5,
        currentPhase: '',
        isPregnant: true,
        pregnancyWeek: 12,
      );
      expect(t1.trimester, 1);
      expect(t1.pregnancyWeek, 12);
      expect(t2.pregnancyWeek, 14); // +2 weeks after 14 days
      expect(t2.trimester, 2);
      expect(SmartPhaseMessages.pick(t2, 'en').tag, 'pregnancyT2|en');
    });
  });

  group('SmartPhaseMessages — rotation variety', () {
    test('rotation 0 is the phase-primary message, rotations differ from it', () {
      const ctx = SmartPhaseContext(
        phase: 'Luteal',
        cycleDay: 20,
        isPregnant: false,
      );
      final primary = SmartPhaseMessages.pick(ctx, 'en');
      final r1 = SmartPhaseMessages.pick(ctx, 'en', rotation: 1);
      final r2 = SmartPhaseMessages.pick(ctx, 'en', rotation: 2);
      expect(primary.tag, 'luteal|en');
      expect(r1.tag, 'luteal|en');
      expect(r1.body, isNot(primary.body));
      expect(r2.body, isNot(r1.body));
    });

    test('a 14-day luteal runway never repeats two mornings in a row', () {
      // Worst case for repetition: a long single-phase stretch.
      String? prev;
      for (var d = 0; d < 14; d++) {
        final ctx = SmartPhaseNotifier.contextForOffset(
          dayOffset: d,
          currentCycleDay: 17, // luteal for a 28-day cycle
          cycleLength: 40, // long luteal so we stay in-phase all 14 days
          periodDuration: 5,
          currentPhase: 'Luteal',
        );
        final body = SmartPhaseMessages.pick(ctx, 'en', rotation: d).body;
        expect(body, isNot(prev), reason: 'day $d repeated the previous body');
        prev = body;
      }
    });
  });
}
