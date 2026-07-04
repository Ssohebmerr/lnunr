import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../goals/data/goal_mode_content.dart';
import '../goals/presentation/condition_mode_section.dart';
import '../pcos/data/pcos_content.dart';

/// PCOS-mode home: a dedicated management experience focused on cycle
/// irregularity, symptom tracking, and lifestyle — not the generic cycle ring.
class HomePcosSection extends StatelessWidget {
  const HomePcosSection({
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
        GoalModeContent.headerSubtitle(UserGoalTypes.pcos, data, lang)
            .forLang(lang);
    final dailyTip = GoalModeContent.dailyTip(UserGoalTypes.pcos, data, lang)
        .forLang(lang);
    final rituals = GoalModeContent.rituals(UserGoalTypes.pcos)
        .map((r) => r.forLang(lang))
        .toList();

    return ConditionModeSection(
      icon: Icons.monitor_heart_outlined,
      title: l10n.goalPcosTitle,
      subtitle: subtitle,
      gradient: const [Color(0xFF26A69A), Color(0xFF80CBC4)],
      cycleContextLabel: l10n.homeRegularity,
      cycleContextValue: '${data.cycleRegularity.round()}%',
      trackLabels:
          PcosContent.trackingFocus.map((t) => t.forLang(lang)).toList(),
      education: PcosContent.education
          .map((e) => ConditionEducation(
                title: e.titleFor(lang),
                body: e.bodyFor(lang),
              ))
          .toList(),
      dailyTip: dailyTip,
      rituals: rituals,
      doctorNote: PcosContent.doctorNote.forLang(lang),
      onOpenCalendar: onOpenCalendar,
    );
  }
}
