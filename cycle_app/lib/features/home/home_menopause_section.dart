import 'package:flutter/material.dart';

import '../../core/ai/models/ai_insight.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../goals/data/condition_log_store.dart';
import '../goals/data/goal_mode_content.dart';
import '../goals/presentation/condition_mode_section.dart';
import '../goals/presentation/condition_widgets.dart';
import '../menopause/data/menopause_content.dart';

/// Menopause-mode home: a dedicated symptom-and-transition experience instead
/// of the generic cycle ring. Adds a daily hot-flash counter and a
/// "days since last period" milestone tracker on top of the shared condition
/// body. Cycle regularity still matters here (irregular cycles are the norm),
/// so it's surfaced as context.
class HomeMenopauseSection extends StatelessWidget {
  const HomeMenopauseSection({
    super.key,
    required this.data,
    this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final VoidCallback? onOpenCalendar;

  static const _accent = Color(0xFF8D6E63);

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

    return ConditionModeSection(
      icon: Icons.spa_rounded,
      title: l10n.goalMenopauseTitle,
      subtitle: subtitle,
      gradient: const [_accent, Color(0xFFBCAAA4)],
      cycleContextLabel: l10n.homeRegularity,
      cycleContextValue: '${data.cycleRegularity.round()}%',
      heroExtras: [
        ConditionStepperCard(
          metricName: ConditionLogStore.metricHotFlash,
          icon: Icons.local_fire_department_outlined,
          label: l10n.menopauseHotFlashesToday,
          hint: l10n.menopauseHotFlashHint,
          accent: _accent,
        ),
        _DaysSincePeriodCard(days: data.cycleDay, accent: _accent),
      ],
      trackItems: MenopauseContent.trackingFocus
          .map((t) => ConditionItem.fromEn(t.en, t.forLang(lang)))
          .toList(),
      education: MenopauseContent.education
          .map((e) => ConditionEducation(
                title: e.titleFor(lang),
                body: e.bodyFor(lang),
              ))
          .toList(),
      dailyTip: dailyTip,
      ritualItems: GoalModeContent.rituals(UserGoalTypes.menopause)
          .map((r) => ConditionItem.fromEn(r.en, r.forLang(lang)))
          .toList(),
      doctorNote: MenopauseContent.doctorNote.forLang(lang),
      onOpenCalendar: onOpenCalendar,
      aiInsightType: AiInsightType.menopauseInsight,
    );
  }
}

/// Milestone tracker: months without a period. 12 period-free months is the
/// clinical marker of menopause, so we show progress toward 365 days.
/// [days] is the current cycle day (= days since the last logged period start).
class _DaysSincePeriodCard extends StatelessWidget {
  const _DaysSincePeriodCard({required this.days, required this.accent});

  final int days;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (days <= 0) {
      return AppGlassCard(
        blur: false,
        child: Row(
          children: [
            Icon(Icons.event_note_outlined,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.menopauseNeedPeriodData,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    final reached = days >= 365;
    final progress = (days / 365).clamp(0.0, 1.0);

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(Icons.event_busy_outlined, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.menopauseDaysSincePeriodTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      l10n.conditionDaysCount(days),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: accent,
              backgroundColor:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reached
                ? l10n.menopauseMilestoneReached
                : l10n.menopauseMilestoneHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
