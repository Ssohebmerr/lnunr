import 'package:cycle_aura/menstrudel/models/periods/period.dart';
import 'package:cycle_aura/menstrudel/utils/period_predictor.dart';
import 'package:flutter_test/flutter_test.dart';

Period _period(DateTime start, {int duration = 5}) => Period(
  startDate: start,
  endDate: start.add(Duration(days: duration - 1)),
  totalDays: duration,
);

void main() {
  group('PeriodPredictor evidence integration', () {
    test('keeps an overdue prediction in the past', () {
      final result = PeriodPredictor.estimateNextPeriod([
        _period(DateTime(2026, 4, 1)),
        _period(DateTime(2026, 4, 29)),
        _period(DateTime(2026, 5, 27)),
      ], DateTime(2026, 6, 30));

      expect(result, isNotNull);
      expect(result!.estimatedStartDate, DateTime(2026, 6, 24));
      expect(result.daysUntilDue, -6);
      expect(result.evidence?.isLate, isTrue);
      expect(result.evidence?.centerDate, result.estimatedStartDate);
    });

    test('supports a consistently long personal cycle pattern', () {
      final result = PeriodPredictor.estimateNextPeriod([
        _period(DateTime(2026, 1, 1)),
        _period(DateTime(2026, 2, 20)),
        _period(DateTime(2026, 4, 10)),
      ], DateTime(2026, 4, 20));

      expect(result, isNotNull);
      expect(result!.averageCycleLength, inInclusiveRange(48, 51));
      expect(result.estimatedStartDate.isAfter(DateTime(2026, 5, 25)), isTrue);
    });
  });
}
