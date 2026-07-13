import 'package:cycle_aura/features/analytics/wellness_scores.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sleepHours', () {
    test('parses an overnight bed→wake window', () {
      expect(WellnessScoreEngine.sleepHours('23:00T07:00'), 8.0);
    });

    test('parses a same-day window (nap logged after midnight)', () {
      expect(WellnessScoreEngine.sleepHours('1:30T9:00'), 7.5);
    });

    test('ignores unset and malformed values', () {
      expect(WellnessScoreEngine.sleepHours(null), isNull);
      expect(WellnessScoreEngine.sleepHours(''), isNull);
      expect(WellnessScoreEngine.sleepHours('0'), isNull);
      expect(WellnessScoreEngine.sleepHours('8'), isNull);
      expect(WellnessScoreEngine.sleepHours('abcTdef'), isNull);
    });

    test('rejects absurd durations', () {
      // 23:59 → 00:20 = 21 minutes — below the 1h sanity floor.
      expect(WellnessScoreEngine.sleepHours('23:59T00:20'), isNull);
    });
  });

  group('sleepScoreForHours', () {
    test('rewards the 7–9h sweet spot and penalises extremes', () {
      expect(WellnessScoreEngine.sleepScoreForHours(8), 95);
      expect(WellnessScoreEngine.sleepScoreForHours(6.5), 75);
      expect(WellnessScoreEngine.sleepScoreForHours(9.5), 75);
      expect(WellnessScoreEngine.sleepScoreForHours(5.5), 55);
      expect(WellnessScoreEngine.sleepScoreForHours(4.5), 40);
      expect(WellnessScoreEngine.sleepScoreForHours(3), 30);
      expect(WellnessScoreEngine.sleepScoreForHours(12), 30);
    });
  });

  group('fromLogs', () {
    test('empty logs produce empty scores', () {
      final scores = WellnessScoreEngine.fromLogs(const []);
      expect(scores.isEmpty, isTrue);
      expect(scores.mood, isNull);
      expect(scores.energy, isNull);
      expect(scores.sleep, isNull);
    });

    test('mood balances positive and negative feelings per day', () {
      final scores = WellnessScoreEngine.fromLogs(const [
        // happy + calm → all positive = 100
        WellnessDayLog(symptomIds: {21003, 21014}),
        // sad only → 0
        WellnessDayLog(symptomIds: {21007}),
      ]);
      expect(scores.mood, 50); // (100 + 0) / 2
      expect(scores.moodDays, 2);
    });

    test('a mixed day lands between the extremes', () {
      final scores = WellnessScoreEngine.fromLogs(const [
        // happy + stressed → 1 pos, 1 neg → 50
        WellnessDayLog(symptomIds: {21003, 21019}),
      ]);
      expect(scores.mood, 50);
    });

    test('energy averages the logged energy words', () {
      final scores = WellnessScoreEngine.fromLogs(const [
        WellnessDayLog(symptomIds: {21040}), // energetic 85
        WellnessDayLog(symptomIds: {21038}), // tired 35
      ]);
      expect(scores.energy, 60);
      expect(scores.energyDays, 2);
    });

    test('fatigue symptom counts as low energy', () {
      final scores = WellnessScoreEngine.fromLogs(const [
        WellnessDayLog(symptomIds: {21054}),
      ]);
      expect(scores.energy, 35);
    });

    test('sleep averages day scores from logged windows', () {
      final scores = WellnessScoreEngine.fromLogs(const [
        WellnessDayLog(sleepTime: '23:00T07:00'), // 8h → 95
        WellnessDayLog(sleepTime: '2:00T7:00'), // 5h → 55
      ]);
      expect(scores.sleep, 75);
      expect(scores.sleepDays, 2);
    });

    test('days without a dimension do not drag its average', () {
      final scores = WellnessScoreEngine.fromLogs(const [
        WellnessDayLog(symptomIds: {21003}), // mood only
        WellnessDayLog(sleepTime: '23:00T07:00'), // sleep only
        WellnessDayLog(symptomIds: {21048}), // cramps — irrelevant to all
      ]);
      expect(scores.mood, 100);
      expect(scores.moodDays, 1);
      expect(scores.sleep, 95);
      expect(scores.sleepDays, 1);
      expect(scores.energy, isNull);
    });
  });
}
