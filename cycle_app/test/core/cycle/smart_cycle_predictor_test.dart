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
      final regular = SmartCyclePredictor.predictionWindowDays([28, 29, 28, 27]);
      final irregular = SmartCyclePredictor.predictionWindowDays([24, 35, 26, 33]);
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
}
