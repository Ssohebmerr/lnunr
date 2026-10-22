import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// Unit tests for the evidence-informed prediction engine.
///
/// The expectations below follow directly from the documented rules: a
/// robust MAD-based cleanup of logging artifacts, recency weighting,
/// regularity-driven uncertainty windows, walk-forward backtest accuracy,
/// honest lateness reporting (the center date never rolls forward into the
/// next cycle while the user is late), clinically meaningful pattern flags on
/// the unfiltered history, and one-off "explained" cycles being excluded from
/// the date estimate but kept for pattern flags.
void main() {
  group('prepareCycleLengths (robust cleaner)', () {
    test('drops physically impossible logging artifacts', () {
      final cleaned = SmartCyclePredictor.prepareCycleLengths([
        10, 28, 29, 30, 400,
      ]);
      expect(cleaned, [28, 29, 30]);
    });

    test('keeps a consistently long personal pattern', () {
      final cleaned = SmartCyclePredictor.prepareCycleLengths([
        28, 28, 28, 28, 28, 28,
      ]);
      expect(cleaned, everyElement(28));
    });

    test('removes an isolated blip entry (MAD outlier rule)', () {
      // 90 (≤ the 90-day trackable band) is an isolated artifact next to a
      // rock-steady 28-day history; MAD = 0 → the max(6.0,MAD*3) threshold
      // rejects it.
      final cleaned = SmartCyclePredictor.prepareCycleLengths([
        28, 28, 28, 28, 90,
      ]);
      expect(cleaned, [28, 28, 28, 28]);
    });
  });

  group('basic statistics', () {
    test('regularityScore is 100 for a clockwork history', () {
      expect(
        SmartCyclePredictor.regularityScore([28, 28, 28, 28]),
        100,
      );
    });

    test('regularityScore approaches zero for a highly irregular history',
        () {
      // Bimodal 15/90: both poles survive the MAD cleaner (MAD = 37.5), so
      // the ±37.5-day spread dominates → score ≈ 28.6, far below anything a
      // clockwork history scores.
      final score = SmartCyclePredictor.regularityScore(
        const [15, 90, 15, 90],
      );
      expect(score, lessThan(40));
      expect(score, greaterThan(20));
    });

    test('effectiveCycleLength clamps implausible configured fallbacks', () {
      expect(
        SmartCyclePredictor.effectiveCycleLength(
          completedLengths: const [],
          configuredFallback: 60,
        ),
        SmartCyclePredictor.maxValidCycleDays,
      );
    });

    test('effectiveCycleLength blends learned length with the configured', () {
      expect(
        SmartCyclePredictor.effectiveCycleLength(
          completedLengths: const [29],
          configuredFallback: 28,
        ),
        29, // (29*0.7 + 28*0.3) = 28.7 → 29
      );
    });

    test('effectiveCycleLength uses weighted mean of recent cycles', () {
      expect(
        SmartCyclePredictor.effectiveCycleLength(
          completedLengths: const [28, 28, 28, 28, 28, 28, 28],
          configuredFallback: 30,
        ),
        28,
      );
    });

    test('effectiveCycleLength falls back to median when irregular', () {
      // Mean 33, sd ≈ 8.45 → regularity 74.4 < 75 → recent median.
      expect(
        SmartCyclePredictor.effectiveCycleLength(
          completedLengths: const [28, 40, 22, 45, 25, 38],
          configuredFallback: 30,
        ),
        33,
      );
    });

    test('effectivePeriodDuration validates and clamps durations', () {
      expect(
        SmartCyclePredictor.effectivePeriodDuration(
          completedDurations: const [5, 5, 15, 0, 6],
          configuredFallback: 5,
        ),
        5, // weighted mean of valid [5,5,6] rounds to 5
      );
      expect(
        SmartCyclePredictor.effectivePeriodDuration(
          completedDurations: const [20, -1],
          configuredFallback: 7,
        ),
        7,
      );
    });

    test('lutealPhaseDays prefers measured values, clamped to 10–16', () {
      expect(
        SmartCyclePredictor.lutealPhaseDays(
          effectiveCycleLength: 28,
          measuredLutealLengths: const [12, 13],
        ),
        13,
      );
      expect(
        SmartCyclePredictor.lutealPhaseDays(
          effectiveCycleLength: 28,
          measuredLutealLengths: const [4],
        ),
        SmartCyclePredictor.minLutealDays,
      );
      expect(
        SmartCyclePredictor.lutealPhaseDays(
          effectiveCycleLength: 28,
          completedLengths: const [28, 28, 28, 28],
        ),
        SmartCyclePredictor.defaultLutealDays,
      );
    });
  });

  group('calendar-based forward mechanics', () {
    test('nextPeriodStart advances correctly when late', () {
      // Late by more than a full cycle → prediction walks forward cycles:
      // 01-29 → 02-26 → 03-26.
      expect(
        SmartCyclePredictor.nextPeriodStart(
          lastPeriodStart: DateTime(2026, 1, 1),
          effectiveCycleLength: 28,
          now: DateTime(2026, 3, 5),
        ),
        DateTime(2026, 3, 26),
      );
    });

    test('nextOvulation returns this cycle when still ahead', () {
      expect(
        SmartCyclePredictor.nextOvulation(
          lastPeriodStart: DateTime(2026, 1, 1),
          effectiveCycleLength: 28,
          lutealDays: 14,
          now: DateTime(2026, 1, 5),
        ),
        DateTime(2026, 1, 15),
      );
    });

    test('nextOvulation rolls forward past a passed date', () {
      expect(
        SmartCyclePredictor.nextOvulation(
          lastPeriodStart: DateTime(2026, 1, 1),
          effectiveCycleLength: 28,
          lutealDays: 14,
          now: DateTime(2026, 1, 20),
        ),
        DateTime(2026, 2, 12),
      );
    });
  });

  group('estimateNextPeriod', () {
    test('regular 28-day history: centered estimate, tight window, moderate',
        () {
      final estimate = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 1, 1),
        completedLengths: const [28, 28, 28],
        configuredFallback: 30,
        now: DateTime(2026, 1, 20),
      );

      expect(estimate.effectiveCycleLength, 28);
      expect(estimate.centerDate, DateTime(2026, 1, 29));
      expect(estimate.windowDays, 2); // regularity 100 → ±2d, no backtest p80
      expect(estimate.windowStart, DateTime(2026, 1, 27));
      expect(estimate.windowEnd, DateTime(2026, 1, 31));
      expect(estimate.daysUntilCenter, 9);
      expect(estimate.isWithinExpectedWindow, isFalse);
      expect(estimate.isLate, isFalse);
      expect(estimate.possibleMissingLog, isFalse);
      expect(estimate.regularityScore, 100);
      expect(estimate.confidence, CyclePredictionConfidence.moderate);
      expect(estimate.confidenceScore, closeTo(0.64, 0.001));
      expect(estimate.completedCycleCount, 3);
      expect(estimate.excludedCycleCount, 0);
      expect(estimate.patternFlags, isEmpty);
      // Walk-forward errors against the fixed 28-day history: |29-28|=1, 0.
      expect(estimate.accuracy.evaluatedCycles, 2);
      expect(estimate.accuracy.medianAbsoluteError, closeTo(0.5, 0.001));
    });

    test('reports lateness honestly without rolling the center date forward',
        () {
      final estimate = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 1, 1),
        completedLengths: const [40, 40],
        configuredFallback: 28,
        now: DateTime(2026, 3, 5),
      );

      // Center stays at 01-01 + 40 = 02-10; lateness is surfaced instead.
      expect(estimate.centerDate, DateTime(2026, 2, 10));
      expect(estimate.isLate, isTrue);
      expect(estimate.daysLate, 21); // 03-05 minus window end 02-12
      expect(estimate.patternFlags, contains(CyclePatternFlag.prolongedCycles));
    });

    test('explained cycles are excluded from dates but kept for patterns', () {
      final estimate = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 1, 1),
        completedLengths: const [60, 40, 28, 28, 28],
        explainedCycles: const [true, true, false, false, false],
        configuredFallback: 30,
        now: DateTime(2026, 1, 20),
      );

      // Dates come solely from the unexplained 28-day baseline.
      expect(estimate.effectiveCycleLength, 28);
      expect(estimate.centerDate, DateTime(2026, 1, 29));
      expect(estimate.explainedCycleCount, 2);
      expect(estimate.learnsFromExplanations, isTrue);
      expect(estimate.completedCycleCount, 3);
      // Pattern flags run on the FULL history: 2 cycles >35d (prolonged) and
      // a 60→28 spread of 32 ≥ 9 (high variability).
      expect(estimate.patternFlags, {
        CyclePatternFlag.prolongedCycles,
        CyclePatternFlag.highVariability,
      });
    });

    test('no history yields a learning-confidence estimate with no flags', () {
      final estimate = SmartCyclePredictor.estimateNextPeriod(
        lastPeriodStart: DateTime(2026, 1, 1),
        completedLengths: const [],
        configuredFallback: 28,
        now: DateTime(2026, 1, 20),
      );

      expect(estimate.centerDate, DateTime(2026, 1, 29));
      expect(estimate.confidence, CyclePredictionConfidence.learning);
      expect(estimate.patternFlags, isEmpty);
      expect(estimate.accuracy.evaluatedCycles, 0);
      expect(estimate.accuracy.hasPersonalEvidence, isFalse);
    });
  });

  group('backtest (walk-forward)', () {
    test('counts zero error as strong personal evidence', () {
      final accuracy = SmartCyclePredictor.backtest(
        completedLengths: const [28, 28, 28, 28],
        configuredFallback: 28,
      );

      expect(accuracy.evaluatedCycles, 3);
      expect(accuracy.meanAbsoluteError, 0);
      expect(accuracy.p80AbsoluteError, 0);
      expect(accuracy.hasPersonalEvidence, isTrue);
      expect(accuracy.withinTwoDays, 3);
      expect(accuracy.withinTwoDaysRate, 1);
    });

    test('earns empty accuracy for histories too short to evaluate', () {
      expect(
        SmartCyclePredictor.backtest(
          completedLengths: const [28],
          configuredFallback: 28,
        ),
        CyclePredictionAccuracy.empty,
      );
    });
  });

  group('detectPatternFlags', () {
    test('flags short cycles and high variability together', () {
      expect(
        SmartCyclePredictor.detectPatternFlags(const [20, 20, 25, 44]),
        {
          CyclePatternFlag.shortCycles,
          CyclePatternFlag.highVariability,
        },
      );
    });

    test('a single borderline-long cycle raises no flag', () {
      // 35 days is not *above* the 35-day cut-off, and the 35→28 spread of
      // 7 days stays under the 9-day variability threshold.
      expect(
        SmartCyclePredictor.detectPatternFlags(const [35, 28, 28]),
        isEmpty,
      );
    });

    test('a 90+ day absence is flagged', () {
      expect(
        SmartCyclePredictor.detectPatternFlags(const [28, 95, 28]),
        contains(CyclePatternFlag.absentCycles),
      );
    });

    test('empty history has no flags', () {
      expect(SmartCyclePredictor.detectPatternFlags(const []), isEmpty);
    });
  });
}
