import 'package:cycle_aura/features/goals/data/condition_log_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('slug', () {
    test('derives stable, language-independent keys from English labels', () {
      expect(ConditionLogStore.slug('Hot flashes'), 'hot_flashes');
      expect(ConditionLogStore.slug('Mood & energy'), 'mood_energy');
      expect(ConditionLogStore.slug('Skin (acne)'), 'skin_acne');
      expect(ConditionLogStore.slug('  Night sweats  '), 'night_sweats');
    });
  });

  group('symptoms', () {
    test('toggle adds then removes for the day', () async {
      final day = DateTime(2026, 7, 9);
      expect(await ConditionLogStore.symptomsOn(day), isEmpty);

      await ConditionLogStore.toggleSymptom(day, 'hot_flashes');
      expect(await ConditionLogStore.symptomsOn(day), {'hot_flashes'});

      await ConditionLogStore.toggleSymptom(day, 'night_sweats');
      expect(await ConditionLogStore.symptomsOn(day),
          {'hot_flashes', 'night_sweats'});

      await ConditionLogStore.toggleSymptom(day, 'hot_flashes');
      expect(await ConditionLogStore.symptomsOn(day), {'night_sweats'});
    });

    test('days are independent buckets', () async {
      final d1 = DateTime(2026, 7, 9);
      final d2 = DateTime(2026, 7, 10);
      await ConditionLogStore.toggleSymptom(d1, 'cramps');
      expect(await ConditionLogStore.symptomsOn(d2), isEmpty);
    });

    test('streak counts consecutive days ending today', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      await ConditionLogStore.toggleSymptom(today, 'mood_changes');
      await ConditionLogStore.toggleSymptom(yesterday, 'sleep_quality');
      await ConditionLogStore.toggleSymptom(threeDaysAgo, 'joint_aches');

      // today + yesterday are consecutive; the gap at 2-days-ago stops it.
      expect(await ConditionLogStore.symptomStreak(), 2);
    });
  });

  group('rituals', () {
    test('toggle persists per day', () async {
      final day = DateTime(2026, 7, 9);
      await ConditionLogStore.toggleRitual(day, 'short_walks');
      expect(await ConditionLogStore.ritualsOn(day), {'short_walks'});
      await ConditionLogStore.toggleRitual(day, 'short_walks');
      expect(await ConditionLogStore.ritualsOn(day), isEmpty);
    });
  });

  group('metrics', () {
    test('set and read round-trips per day', () async {
      final day = DateTime(2026, 7, 9);
      expect(await ConditionLogStore.metric('hotflash_count', day), 0);
      await ConditionLogStore.setMetric('hotflash_count', day, 3);
      expect(await ConditionLogStore.metric('hotflash_count', day), 3);
      await ConditionLogStore.setMetric('hotflash_count', day, 5);
      expect(await ConditionLogStore.metric('hotflash_count', day), 5);
    });

    test('metricLowStreak counts consecutive low, recorded days', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      await ConditionLogStore.setMetric(
          ConditionLogStore.metricMood, today, 2);
      await ConditionLogStore.setMetric(
          ConditionLogStore.metricMood, yesterday, 1);
      expect(
        await ConditionLogStore.metricLowStreak(ConditionLogStore.metricMood,
            threshold: 2),
        2,
      );
    });
  });

  group('history', () {
    test('metricHistory returns only days inside the window', () async {
      final today = DateTime.now();
      final old = today.subtract(const Duration(days: 20));
      await ConditionLogStore.setMetric('hotflash_count', today, 4);
      await ConditionLogStore.setMetric('hotflash_count', old, 9);

      final recent =
          await ConditionLogStore.metricHistory('hotflash_count', days: 14);
      expect(recent, {ConditionLogStore.dayKey(today): 4});

      final wide =
          await ConditionLogStore.metricHistory('hotflash_count', days: 30);
      expect(wide.length, 2);
      expect(wide[ConditionLogStore.dayKey(old)], 9);
    });

    test('metricHistory of an unknown metric is empty', () async {
      expect(await ConditionLogStore.metricHistory('nope'), isEmpty);
    });

    test('symptomHistory windows and maps day to slug set', () async {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final old = today.subtract(const Duration(days: 40));
      await ConditionLogStore.toggleSymptom(today, 'hot_flashes');
      await ConditionLogStore.toggleSymptom(today, 'night_sweats');
      await ConditionLogStore.toggleSymptom(yesterday, 'cramps');
      await ConditionLogStore.toggleSymptom(old, 'fatigue');

      final history = await ConditionLogStore.symptomHistory(days: 30);
      expect(history.length, 2);
      expect(history[ConditionLogStore.dayKey(today)],
          {'hot_flashes', 'night_sweats'});
      expect(history[ConditionLogStore.dayKey(yesterday)], {'cramps'});
    });

    test('symptomHistory drops days whose set was toggled empty', () async {
      final today = DateTime.now();
      await ConditionLogStore.toggleSymptom(today, 'cramps');
      await ConditionLogStore.toggleSymptom(today, 'cramps'); // now empty
      expect(await ConditionLogStore.symptomHistory(days: 30), isEmpty);
    });

    test('ritualHistory returns the recent ritual sets', () async {
      final today = DateTime.now();
      await ConditionLogStore.toggleRitual(today, 'short_walks');
      final history = await ConditionLogStore.ritualHistory(days: 7);
      expect(history[ConditionLogStore.dayKey(today)], {'short_walks'});
    });
  });
}
