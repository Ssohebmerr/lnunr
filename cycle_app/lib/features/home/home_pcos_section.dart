import 'package:flutter/material.dart';

import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../goals/data/goal_mode_content.dart';
import '../goals/presentation/condition_mode_section.dart';
import '../goals/presentation/condition_widgets.dart';
import '../pcos/data/pcos_content.dart';

/// PCOS-mode home: a dedicated management experience focused on cycle
/// irregularity, symptom tracking, and lifestyle — not the generic cycle ring.
/// Adds a "cycle gap" card that flags when the current gap runs longer than the
/// user's typical cycle (the hallmark of PCOS).
class HomePcosSection extends StatelessWidget {
  const HomePcosSection({
    super.key,
    required this.data,
    this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final VoidCallback? onOpenCalendar;

  static const _accent = Color(0xFF26A69A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    final subtitle =
        GoalModeContent.headerSubtitle(UserGoalTypes.pcos, data, lang)
            .forLang(lang);
    final dailyTip = GoalModeContent.dailyTip(UserGoalTypes.pcos, data, lang)
        .forLang(lang);

    return ConditionModeSection(
      icon: Icons.monitor_heart_outlined,
      title: l10n.goalPcosTitle,
      subtitle: subtitle,
      gradient: const [_accent, Color(0xFF80CBC4)],
      cycleContextLabel: l10n.homeRegularity,
      cycleContextValue: '${data.cycleRegularity.round()}%',
      heroExtras: [
        _CycleGapCard(
          cycleDay: data.cycleDay,
          avgLength: data.avgCycleLength,
          accent: _accent,
        ),
      ],
      trackItems: PcosContent.trackingFocus
          .map((t) => ConditionItem.fromEn(t.en, t.forLang(lang)))
          .toList(),
      education: PcosContent.education
          .map((e) => ConditionEducation(
                title: e.titleFor(lang),
                body: e.bodyFor(lang),
              ))
          .toList(),
      dailyTip: dailyTip,
      ritualItems: GoalModeContent.rituals(UserGoalTypes.pcos)
          .map((r) => ConditionItem.fromEn(r.en, r.forLang(lang)))
          .toList(),
      doctorNote: PcosContent.doctorNote.forLang(lang),
      onOpenCalendar: onOpenCalendar,
    );
  }
}

/// Shows the current gap since the last period against the user's typical cycle
/// length. Flags a longer-than-usual gap gently — common with PCOS — and
/// encourages continued logging.
class _CycleGapCard extends StatelessWidget {
  const _CycleGapCard({
    required this.cycleDay,
    required this.avgLength,
    required this.accent,
  });

  final int cycleDay;
  final int avgLength;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Not enough data to compare against a typical cycle.
    final unknown = avgLength <= 0 || cycleDay <= 0;
    final isLong = !unknown && cycleDay > avgLength + 7;

    final (statusColor, statusText) = unknown
        ? (theme.colorScheme.onSurfaceVariant, l10n.pcosGapUnknown)
        : isLong
            ? (const Color(0xFFB26A00), l10n.pcosGapLong)
            : (accent, l10n.pcosGapNormal);

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
                child: Icon(
                  isLong
                      ? Icons.info_outline_rounded
                      : Icons.calendar_month_outlined,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pcosCycleGapTitle,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      cycleDay <= 0
                          ? '—'
                          : l10n.conditionDaysCount(cycleDay),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (avgLength > 0) ...[
            const SizedBox(height: 6),
            Text(
              l10n.pcosTypicalCycle(avgLength),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(
                  unknown
                      ? Icons.help_outline_rounded
                      : isLong
                          ? Icons.trending_up_rounded
                          : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
