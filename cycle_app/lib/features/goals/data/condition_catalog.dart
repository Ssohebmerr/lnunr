import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../menopause/data/menopause_content.dart';
import '../../pcos/data/pcos_content.dart';
import 'condition_log_store.dart';
import 'goal_mode_content.dart';

/// One place that knows which symptom/ritual slugs each life-stage goal can
/// log and how to display them in the current language. Used by the trends
/// section and the doctor-report exporter so labels never drift apart.
class ConditionCatalog {
  ConditionCatalog._();

  /// slug → localized label of the goal's loggable symptoms.
  static Map<String, String> symptomLabels(UserGoalTypes goal, String lang) {
    final labels = <String, String>{};
    switch (goal) {
      case UserGoalTypes.menopause:
        for (final t in MenopauseContent.trackingFocus) {
          labels[ConditionLogStore.slug(t.en)] = t.forLang(lang);
        }
      case UserGoalTypes.pcos:
        for (final t in PcosContent.trackingFocus) {
          labels[ConditionLogStore.slug(t.en)] = t.forLang(lang);
        }
      default:
        // Postpartum symptom chips live in HomePostpartumSection with these
        // exact English keys — keep the pairs in sync.
        final ar = lang.startsWith('ar');
        const pairs = [
          ('Bleeding', 'نزيف'),
          ('Cramps', 'مغص'),
          ('Breast pain', 'ألم الثدي'),
          ('Fatigue', 'إرهاق'),
          ('Low mood', 'مزاج منخفض'),
          ('Poor sleep', 'نوم متقطّع'),
        ];
        for (final (en, arLabel) in pairs) {
          labels[ConditionLogStore.slug(en)] = ar ? arLabel : en;
        }
    }
    return labels;
  }

  /// slug → localized label of the goal's daily rituals.
  static Map<String, String> ritualLabels(UserGoalTypes goal, String lang) {
    final labels = <String, String>{};
    for (final r in GoalModeContent.rituals(goal)) {
      labels[ConditionLogStore.slug(r.en)] = r.forLang(lang);
    }
    return labels;
  }
}
