import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../data/goal_mode_analytics.dart';
import '../data/goal_mode_content.dart';
import '../../home/widgets/reports_ui.dart';

/// Goal-first reports — banner, readable metrics, insight card.
class GoalModeReportsSection extends StatelessWidget {
  const GoalModeReportsSection({
    super.key,
    required this.goal,
    required this.data,
  });

  final UserGoalTypes goal;
  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: _titleForGoal(goal, l10n)),
        _metricsForGoal(context, goal, l10n, theme),
        const SizedBox(height: 12),
        ReportsExpansionPanel(
          icon: Icons.checklist_rounded,
          title: l10n.goalModeChecklist,
          subtitle: l10n.reportsChecklistHint,
          children: GoalModeContent.checklist(goal, lang)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.forLang(lang),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _metricsForGoal(
    BuildContext context,
    UserGoalTypes goal,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (goal.isConceiveMode) {
      return ReportsMetricGrid(
        children: [
          ReportsMetricTile(
            icon: Icons.favorite_rounded,
            label: l10n.homeOvulation,
            value: data.ovulation,
            accent: theme.colorScheme.secondary,
          ),
          ReportsMetricTile(
            icon: Icons.child_friendly_rounded,
            label: l10n.reportPregnancyChance,
            value: data.pregnancyChances,
            accent: theme.colorScheme.tertiary,
          ),
          ReportsMetricTile(
            icon: Icons.science_outlined,
            label: l10n.goalModeTestDate,
            value: data.expectedPregnancyTestDate,
            accent: AuraColors.peachGold,
          ),
          ReportsMetricTile(
            icon: Icons.today_rounded,
            label: l10n.reportCycleDay,
            value: '${data.cycleDay}',
            accent: theme.colorScheme.primary,
          ),
        ],
      );
    }

    if (goal.isAvoidMode) {
      final level = GoalModeAnalytics.fertilityLevel(data);
      return ReportsMetricGrid(
        children: [
          ReportsMetricTile(
            icon: Icons.shield_outlined,
            label: l10n.goalModeFertilityToday,
            value: _fertilityLabel(level, l10n),
            accent: _fertilityColor(level),
          ),
          ReportsMetricTile(
            icon: Icons.favorite_outline,
            label: l10n.homeOvulation,
            value: data.ovulation,
            accent: theme.colorScheme.secondary,
          ),
          ReportsMetricTile(
            icon: Icons.event_outlined,
            label: l10n.nextPeriod,
            value: data.nextPeriod,
            accent: theme.colorScheme.primary,
          ),
          ReportsMetricTile(
            icon: Icons.timeline_outlined,
            label: l10n.homeRegularity,
            value: '${data.cycleRegularity.round()}%',
            accent: AuraColors.peachGold,
          ),
        ],
      );
    }

    if (goal.isPregnancyMode) {
      return ReportsMetricGrid(
        children: [
          ReportsMetricTile(
            icon: Icons.pregnant_woman_rounded,
            label: l10n.pregnancyWeekLabel(data.pregnancyWeek.clamp(1, 42)),
            value: l10n.pregnancyWeekShort,
            accent: const Color(0xFFEC407A),
          ),
          ReportsMetricTile(
            icon: Icons.event_outlined,
            label: l10n.pregnancyDueDate(
              data.expectedDueDate.isEmpty ? '—' : data.expectedDueDate,
            ),
            value: data.expectedDueDate,
            accent: theme.colorScheme.primary,
          ),
          ReportsMetricTile(
            icon: Icons.calendar_today,
            label: l10n.reportCycleDay,
            value: '${data.cycleDay}',
            accent: theme.colorScheme.secondary,
          ),
          ReportsMetricTile(
            icon: Icons.timeline_rounded,
            label: l10n.homeRegularity,
            value: '${data.cycleRegularity.round()}%',
            accent: AuraColors.peachGold,
          ),
        ],
      );
    }

    if (goal == UserGoalTypes.menopause) {
      return ReportsMetricGrid(
        children: [
          ReportsMetricTile(
            icon: Icons.timeline_rounded,
            label: l10n.homeRegularity,
            value: '${data.cycleRegularity.round()}%',
            accent: const Color(0xFF8D6E63),
          ),
          ReportsMetricTile(
            icon: Icons.loop_rounded,
            label: l10n.reportAvgCycle,
            value: '${data.avgCycleLength} ${l10n.homeDayShort}',
            accent: theme.colorScheme.secondary,
          ),
          ReportsMetricTile(
            icon: Icons.event_outlined,
            label: l10n.nextPeriod,
            value: data.nextPeriod,
            accent: theme.colorScheme.primary,
          ),
          ReportsMetricTile(
            icon: Icons.calendar_view_month_rounded,
            label: l10n.reportTotalCycles,
            value: '${data.totalCycles}',
            accent: AuraColors.peachGold,
          ),
        ],
      );
    }

    if (goal == UserGoalTypes.pcos) {
      return ReportsMetricGrid(
        children: [
          ReportsMetricTile(
            icon: Icons.timeline_rounded,
            label: l10n.homeRegularity,
            value: '${data.cycleRegularity.round()}%',
            accent: const Color(0xFF26A69A),
          ),
          ReportsMetricTile(
            icon: Icons.loop_rounded,
            label: l10n.reportAvgCycle,
            value: '${data.avgCycleLength} ${l10n.homeDayShort}',
            accent: theme.colorScheme.secondary,
          ),
          ReportsMetricTile(
            icon: Icons.water_drop_outlined,
            label: l10n.reportAvgPeriod,
            value: '${data.avgPeriodDuration} ${l10n.homeDayShort}',
            accent: theme.colorScheme.primary,
          ),
          ReportsMetricTile(
            icon: Icons.calendar_view_month_rounded,
            label: l10n.reportTotalCycles,
            value: '${data.totalCycles}',
            accent: AuraColors.peachGold,
          ),
        ],
      );
    }

    if (goal == UserGoalTypes.postpartum) {
      // Postpartum uses ONLY real cycle data — no fabricated sleep/mood values.
      final periodReturned = data.totalCycles > 0 || data.isPeriodStarted;
      return ReportsMetricGrid(
        children: [
          ReportsMetricTile(
            icon: Icons.healing_outlined,
            label: l10n.reportCycleDay,
            value: '${data.cycleDay}',
            accent: const Color(0xFFEC407A),
          ),
          ReportsMetricTile(
            icon: Icons.event_outlined,
            label: l10n.nextPeriod,
            value: periodReturned ? data.nextPeriod : '—',
            accent: theme.colorScheme.primary,
          ),
          ReportsMetricTile(
            icon: Icons.timeline_rounded,
            label: l10n.homeRegularity,
            value: '${data.cycleRegularity.round()}%',
            accent: theme.colorScheme.secondary,
          ),
          ReportsMetricTile(
            icon: Icons.calendar_view_month_rounded,
            label: l10n.reportTotalCycles,
            value: '${data.totalCycles}',
            accent: AuraColors.peachGold,
          ),
        ],
      );
    }

    return ReportsMetricGrid(
      children: [
        ReportsMetricTile(
          icon: Icons.timeline_rounded,
          label: l10n.homeRegularity,
          value:
              '${data.cycleRegularity.round()}% · ${data.cycleRegularityStatus}',
          accent: theme.colorScheme.primary,
        ),
        ReportsMetricTile(
          icon: Icons.loop_rounded,
          label: l10n.reportAvgCycle,
          value: '${data.avgCycleLength} ${l10n.homeDayShort}',
          accent: AuraColors.peachGold,
        ),
        ReportsMetricTile(
          icon: Icons.water_drop_outlined,
          label: l10n.reportAvgPeriod,
          value: '${data.avgPeriodDuration} ${l10n.homeDayShort}',
          accent: theme.colorScheme.secondary,
        ),
        ReportsMetricTile(
          icon: Icons.calendar_view_month_rounded,
          label: l10n.reportTotalCycles,
          value: '${data.totalCycles}',
          accent: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  Color _fertilityColor(FertilityLevel level) {
    return switch (level) {
      FertilityLevel.high => Colors.red.shade400,
      FertilityLevel.moderate => Colors.orange.shade400,
      FertilityLevel.low => Colors.green.shade600,
      FertilityLevel.unknown => AuraColors.plumMuted,
    };
  }

  String _titleForGoal(UserGoalTypes goal, AppLocalizations l10n) {
    return switch (goal) {
      UserGoalTypes.conceive => l10n.goalModeConceiveReportStats,
      UserGoalTypes.avoid => l10n.goalModeAvoidReportStats,
      UserGoalTypes.pregnant => l10n.reportsPregnancyOverview,
      UserGoalTypes.menopause => l10n.reportsMenopauseOverview,
      UserGoalTypes.pcos => l10n.reportsPcosOverview,
      UserGoalTypes.postpartum => l10n.reportsRecoveryOverview,
      _ => l10n.goalModeGeneralReportStats,
    };
  }

  String _fertilityLabel(FertilityLevel level, AppLocalizations l10n) {
    return switch (level) {
      FertilityLevel.high => l10n.goalModeFertilityHigh,
      FertilityLevel.moderate => l10n.goalModeFertilityModerate,
      FertilityLevel.low => l10n.goalModeFertilityLow,
      FertilityLevel.unknown => l10n.goalModeFertilityUnknown,
    };
  }
}
