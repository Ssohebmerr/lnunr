import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../goals/data/goal_mode_content.dart';
import '../goals/presentation/condition_mode_section.dart';
import '../menopause/data/menopause_content.dart';

/// Menopause-mode home: a dedicated symptom-and-transition experience instead
/// of the generic cycle ring. Cycle regularity still matters here (irregular
/// cycles are the norm), so it's surfaced as context.
class HomeMenopauseSection extends StatelessWidget {
  const HomeMenopauseSection({
    super.key,
    required this.data,
    this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final VoidCallback? onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    final subtitle =
        GoalModeContent.headerSubtitle(UserGoalTypes.menopause, data, lang)
            .forLang(lang);
    final dailyTip =
        GoalModeContent.dailyTip(UserGoalTypes.menopause, data, lang)
            .forLang(lang);
    final rituals = GoalModeContent.rituals(UserGoalTypes.menopause)
        .map((r) => r.forLang(lang))
        .toList();

    return ConditionModeSection(
      icon: Icons.spa_rounded,
      title: l10n.goalMenopauseTitle,
      subtitle: subtitle,
      gradient: const [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
      cycleContextLabel: l10n.homeRegularity,
      cycleContextValue: '${data.cycleRegularity.round()}%',
      trackLabels:
          MenopauseContent.trackingFocus.map((t) => t.forLang(lang)).toList(),
      education: MenopauseContent.education
          .map((e) => ConditionEducation(
                title: e.titleFor(lang),
                body: e.bodyFor(lang),
              ))
          .toList(),
      dailyTip: dailyTip,
      rituals: rituals,
      doctorNote: MenopauseContent.doctorNote.forLang(lang),
      onOpenCalendar: onOpenCalendar,
    );
  }
}
