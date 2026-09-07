import 'package:cycle_aura/menstrudel/models/cycle_phase/cycle_phase_enum.dart';
import 'package:cycle_aura/menstrudel/utils/cycle_phase_predictor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final lastPeriod = DateTime(2026, 3, 1);

  group('fertile window uncertainty', () {
    test('regular cycle keeps the tight biological window', () {
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 14,
        predictionWindowDays: 0,
        now: lastPeriod.add(const Duration(days: 3)),
      );

      expect(
        cycle.ovulationDay.difference(cycle.fertileWindowStart).inDays,
        5,
      );
      expect(cycle.lutealStart.difference(cycle.ovulationDay).inDays, 2);
    });

    test('irregular cycle widens the fertile window on both sides', () {
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 14,
        predictionWindowDays: 4,
        now: lastPeriod.add(const Duration(days: 3)),
      );

      expect(
        cycle.ovulationDay.difference(cycle.fertileWindowStart).inDays,
        9,
      );
      expect(cycle.lutealStart.difference(cycle.ovulationDay).inDays, 6);
    });

    test('padding is capped so guidance stays actionable', () {
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 14,
        predictionWindowDays: 10,
        now: lastPeriod.add(const Duration(days: 3)),
      );

      expect(
        cycle.ovulationDay.difference(cycle.fertileWindowStart).inDays,
        10,
      );
    });
  });

  group('late periods', () {
    test('advances to the cycle that contains today', () {
      // 40 days after the last logged period start with a 28-day cycle: the
      // user is deep into an unlogged second cycle.
      final now = lastPeriod.add(const Duration(days: 40));
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 14,
        now: now,
      );

      // Calendar arithmetic on purpose: `add(Duration(days: 28))` drifts by an
      // hour across the spring-forward boundary, which is the bug being fixed.
      expect(cycle.menstruationStart, DateTime(2026, 3, 29));
      expect(cycle.ovulationDay.isAfter(now.subtract(const Duration(days: 15))),
          isTrue);
      expect(cycle.nextPeriodStart.isAfter(now), isTrue);
    });

    test('stays on the current cycle while it is still running', () {
      final now = lastPeriod.add(const Duration(days: 10));
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 14,
        now: now,
      );

      expect(cycle.menstruationStart, lastPeriod);
    });
  });

  group('temperature-confirmed ovulation', () {
    test('overrides the estimate and drops the uncertainty padding', () {
      final confirmed = DateTime(2026, 3, 18);
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 13,
        predictionWindowDays: 5,
        confirmedOvulationDate: confirmed,
        now: DateTime(2026, 3, 22),
      );

      expect(cycle.ovulationDay, confirmed);
      // No padding: an observation carries no cycle-length uncertainty.
      expect(
        cycle.ovulationDay.difference(cycle.fertileWindowStart).inDays,
        5,
      );
    });

    test('next period follows the measured luteal length, not the average', () {
      final confirmed = DateTime(2026, 3, 18);
      final cycle = CyclePhasePredictor.predictCycle(
        lastPeriodStartDate: lastPeriod,
        averageCycleLength: 28,
        averagePeriodDuration: 5,
        lutealPhaseLength: 12,
        confirmedOvulationDate: confirmed,
        now: DateTime(2026, 3, 22),
      );

      expect(cycle.nextPeriodStart, DateTime(2026, 3, 30));
    });
  });

  test('phase lookup still resolves each phase in order', () {
    final cycle = CyclePhasePredictor.predictCycle(
      lastPeriodStartDate: lastPeriod,
      averageCycleLength: 28,
      averagePeriodDuration: 5,
      lutealPhaseLength: 14,
      now: lastPeriod.add(const Duration(days: 1)),
    );

    expect(cycle.getPhaseForDate(lastPeriod), CyclePhase.menstruation);
    expect(
      cycle.getPhaseForDate(cycle.follicularStart),
      CyclePhase.follicular,
    );
    expect(
      cycle.getPhaseForDate(cycle.fertileWindowStart),
      CyclePhase.fertileWindow,
    );
    expect(cycle.getPhaseForDate(cycle.ovulationDay), CyclePhase.ovulation);
    expect(cycle.getPhaseForDate(cycle.lutealStart), CyclePhase.luteal);
    expect(cycle.getPhaseForDate(cycle.nextPeriodStart), CyclePhase.late);
  });
}
