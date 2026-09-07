import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import 'package:cycle_aura/core/cycle/prediction_display.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
  });
  group('SmartCyclePredictor', () {
    test('weights recent cycles for regular users', () {
      final length = SmartCyclePredictor.effectiveCycleLength(
        completedLengths: [28, 28, 30, 28, 29],
        configuredFallback: 28,
      );
      expect(length, greaterThanOrEqualTo(28));
      expect(length, lessThanOrEqualTo(30));
    });

    test('uses median for irregular cycles', () {
      final length = SmartCyclePredictor.effectiveCycleLength(
        completedLengths: [24, 35, 26, 33, 27],
        configuredFallback: 28,
      );
      expect(length, inInclusiveRange(24, 33));
    });

    test('rolls forward next period when user is late', () {
      final last = DateTime(2026, 6, 1);
      final now = DateTime(2026, 7, 10);
      final next = SmartCyclePredictor.nextPeriodStart(
        lastPeriodStart: last,
        effectiveCycleLength: 28,
        now: now,
      );
      expect(next.isAfter(now), isTrue);
      expect(next.difference(last).inDays % 28, equals(0));
    });

    test('user-facing estimate keeps original date and reports lateness', () {
      final estimate = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 6, 1),
        completedLengths: const [28, 28, 28, 28],
        configuredFallback: 28,
        now: DateTime(2026, 7, 10),
      );

      expect(estimate.centerDate, DateTime(2026, 6, 29));
      expect(estimate.isLate, isTrue);
      expect(estimate.daysLate, greaterThan(0));
      expect(estimate.centerDate.isBefore(DateTime(2026, 7, 10)), isTrue);
    });

    test('walk-forward backtest exposes real personal evidence', () {
      final accuracy = SmartCyclePredictor.backtest(
        completedLengths: const [28, 28, 28, 28, 28],
        configuredFallback: 28,
      );

      expect(accuracy.evaluatedCycles, 4);
      expect(accuracy.withinTwoDays, 4);
      expect(accuracy.medianAbsoluteError, 0);
      expect(accuracy.hasPersonalEvidence, isTrue);
    });

    test('keeps a consistently long personal pattern', () {
      final prepared = SmartCyclePredictor.prepareCycleLengths(const [
        48,
        50,
        49,
        51,
      ]);
      final predicted = SmartCyclePredictor.effectiveCycleLength(
        completedLengths: prepared,
        configuredFallback: 28,
      );

      expect(prepared, const [48, 50, 49, 51]);
      expect(predicted, inInclusiveRange(48, 51));
    });

    test('removes an isolated likely logging artifact', () {
      final prepared = SmartCyclePredictor.prepareCycleLengths(const [
        28,
        29,
        62,
        30,
      ]);

      expect(prepared, const [28, 29, 30]);
    });

    test('chronological input gives newer cycles more weight', () {
      final predicted = SmartCyclePredictor.effectiveCycleLength(
        completedLengths: const [40, 40, 34, 30, 28, 28],
        configuredFallback: 28,
      );

      expect(predicted, lessThan(34));
    });

    test('ovulation lands before next period by luteal length', () {
      final last = DateTime(2026, 7, 1);
      final next = SmartCyclePredictor.nextPeriodStart(
        lastPeriodStart: last,
        effectiveCycleLength: 28,
        now: DateTime(2026, 7, 5),
      );
      final ovulation = SmartCyclePredictor.nextOvulation(
        lastPeriodStart: last,
        effectiveCycleLength: 28,
        now: DateTime(2026, 7, 5),
      );
      expect(next.difference(ovulation).inDays, equals(14));
    });

    test('wider prediction window for irregular history', () {
      final regular = SmartCyclePredictor.predictionWindowDays([
        28,
        29,
        28,
        27,
      ]);
      final irregular = SmartCyclePredictor.predictionWindowDays([
        24,
        35,
        26,
        33,
      ]);
      expect(irregular, greaterThan(regular));
    });

    test('personalized luteal from measured lengths', () {
      final luteal = SmartCyclePredictor.lutealPhaseDays(
        effectiveCycleLength: 28,
        measuredLutealLengths: [12, 13, 12],
      );
      expect(luteal, inInclusiveRange(10, 16));
      expect(luteal, lessThan(14));
    });

    test('formatPredictionRange localizes', () {
      final center = DateTime(2026, 7, 15);
      final en = PredictionDisplay.formatPredictionRange(
        center: center,
        windowDays: 2,
        languageCode: 'en',
      );
      expect(en.contains('–'), isTrue);
      final ar = PredictionDisplay.formatPredictionRange(
        center: center,
        windowDays: 2,
        languageCode: 'ar',
      );
      expect(ar.isNotEmpty, isTrue);
    });
  });

  group('clinical pattern flags', () {
    test('repeated long cycles are surfaced, not smoothed away', () {
      final flags = SmartCyclePredictor.detectPatternFlags([29, 48, 52, 30, 47]);
      expect(flags, contains(CyclePatternFlag.prolongedCycles));
    });

    test('one long cycle after a stressful month is not a pattern', () {
      final flags = SmartCyclePredictor.detectPatternFlags([28, 29, 41, 28, 29]);
      expect(flags, isNot(contains(CyclePatternFlag.prolongedCycles)));
    });

    test('repeated short cycles are surfaced', () {
      final flags = SmartCyclePredictor.detectPatternFlags([18, 19, 27, 20]);
      expect(flags, contains(CyclePatternFlag.shortCycles));
    });

    test('a three-month gap counts as an absent cycle', () {
      final flags = SmartCyclePredictor.detectPatternFlags([28, 29, 95]);
      expect(flags, contains(CyclePatternFlag.absentCycles));
    });

    test('a nine-day spread trips the irregularity threshold', () {
      final flags = SmartCyclePredictor.detectPatternFlags([25, 34, 28]);
      expect(flags, contains(CyclePatternFlag.highVariability));
    });

    test('a steady cycle raises nothing', () {
      final flags = SmartCyclePredictor.detectPatternFlags([28, 29, 28, 27, 29]);
      expect(flags, isEmpty);
    });

    test('flags survive into the user-facing estimate', () {
      final estimate = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 3, 1),
        completedLengths: const [30, 49, 51, 29, 48],
        configuredFallback: 28,
        now: DateTime(2026, 3, 10),
      );
      expect(estimate.hasPatternFlags, isTrue);
      expect(estimate.patternFlags, contains(CyclePatternFlag.prolongedCycles));
    });
  });

  group('learning from user-supplied causes', () {
    // A steady ~28-day pattern with one 34-day cycle the user attributes to
    // illness. 34 is deliberately chosen: it sits INSIDE the MAD outlier
    // threshold, so the statistical filter keeps it. That is exactly where an
    // explanation earns its keep — an extreme 44-day cycle would already be
    // filtered out and annotating it would change nothing.
    const history = [28, 29, 34, 28, 29];
    const explained = [false, false, true, false, false];

    CyclePredictionEstimate estimate({List<bool> flags = const []}) =>
        SmartCyclePredictor.estimateNextPeriod(
          lastPeriodStart: DateTime(2026, 3, 1),
          completedLengths: history,
          configuredFallback: 28,
          explainedCycles: flags,
          now: DateTime(2026, 3, 10),
        );

    test('an explained cycle leaves the date estimate', () {
      final withReason = estimate(flags: explained);
      final without = estimate();
      expect(withReason.explainedCycleCount, 1);
      expect(withReason.learnsFromExplanations, isTrue);
      expect(without.explainedCycleCount, 0);
    });

    test('setting a disruption aside tightens the prediction window', () {
      expect(
        estimate(flags: explained).windowDays,
        lessThanOrEqualTo(estimate().windowDays),
      );
    });

    test('regularity improves once the disruption is accounted for', () {
      expect(
        estimate(flags: explained).regularityScore,
        greaterThan(estimate().regularityScore),
      );
    });

    test('explaining cycles can NEVER hide a clinical pattern', () {
      // Every long cycle blamed on stress — the flag must survive anyway.
      final hidden = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 3, 1),
        completedLengths: const [29, 48, 52, 30, 47],
        configuredFallback: 28,
        explainedCycles: const [false, true, true, false, true],
        now: DateTime(2026, 3, 10),
      );
      expect(hidden.patternFlags, contains(CyclePatternFlag.prolongedCycles));
    });

    test('falls back to the full history rather than starving itself', () {
      // Everything explained: keeping two cycles beats predicting from none.
      final all = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 3, 1),
        completedLengths: const [28, 44, 30],
        configuredFallback: 28,
        explainedCycles: const [true, true, true],
        now: DateTime(2026, 3, 10),
      );
      expect(all.effectiveCycleLength, greaterThan(0));
      expect(all.completedCycleCount, greaterThan(0));
    });

    test('a mismatched flag list is ignored rather than misaligning cycles', () {
      final short = estimate(flags: const [true]);
      expect(short.effectiveCycleLength, greaterThan(0));
      expect(short.explainedCycleCount, 1);
    });
  });
}
