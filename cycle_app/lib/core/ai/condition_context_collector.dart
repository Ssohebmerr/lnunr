import 'package:flutter/foundation.dart';

import '../../features/goals/data/condition_catalog.dart';
import '../../features/goals/data/condition_log_store.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';

/// Collects what a life-stage goal (PCOS, menopause, postpartum) has actually
/// logged, so the AI can talk about the user's real pattern instead of
/// producing the same generic advice a static article already gives.
///
/// Returns an empty map for goals that have no condition tracking, and for
/// users who have not logged anything yet — the caller then skips the AI call
/// rather than prompting a model with nothing to say.
class ConditionContextCollector {
  ConditionContextCollector._();

  /// Goals that track condition symptoms and rituals.
  static const trackedGoals = {
    UserGoalTypes.pcos,
    UserGoalTypes.menopause,
    UserGoalTypes.postpartum,
  };

  static const int _historyDays = 30;

  static Future<Map<String, dynamic>> collect(
    UserGoalTypes goal, {
    String lang = 'en',
  }) async {
    if (!trackedGoals.contains(goal)) return const {};

    try {
      final symptomLabels = ConditionCatalog.symptomLabels(goal, lang);
      final ritualLabels = ConditionCatalog.ritualLabels(goal, lang);

      final symptomHistory = await ConditionLogStore.symptomHistory(
        days: _historyDays,
      );
      final ritualHistory = await ConditionLogStore.ritualHistory(
        days: _historyDays,
      );

      // Count how many of the last 30 days each symptom appeared on. Frequency
      // is what makes advice specific — "hot flushes on 18 of 30 days" is
      // actionable, "you may experience hot flushes" is not.
      final symptomDays = _frequencies(symptomHistory, symptomLabels);
      final ritualDays = _frequencies(ritualHistory, ritualLabels);

      final loggedDays = {...symptomHistory.keys, ...ritualHistory.keys}.length;
      if (symptomDays.isEmpty && ritualDays.isEmpty) return const {};

      return {
        'goal': goal.dbName,
        'trackedDays': loggedDays,
        'windowDays': _historyDays,
        if (symptomDays.isNotEmpty) 'symptomDaysOutOf30': symptomDays,
        if (ritualDays.isNotEmpty) 'ritualDaysOutOf30': ritualDays,
        'symptomStreak': await ConditionLogStore.symptomStreak(),
      };
    } catch (e, st) {
      debugPrint('ConditionContextCollector failed: $e\n$st');
      return const {};
    }
  }

  /// day → set of slugs  ⟶  localized label → number of days, busiest first.
  static Map<String, int> _frequencies(
    Map<String, Set<String>> history,
    Map<String, String> labels,
  ) {
    final counts = <String, int>{};
    for (final slugs in history.values) {
      for (final slug in slugs) {
        final label = labels[slug];
        if (label == null) continue;
        counts[label] = (counts[label] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in sorted.take(8)) e.key: e.value};
  }
}
