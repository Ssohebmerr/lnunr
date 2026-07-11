import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../../cycle/presentation/widgets/lune_cycle_ring.dart';
import '../../cycle/presentation/widgets/ovulation_log_card.dart';
import '../../home/widgets/home_feed_sections.dart';
import '../data/goal_mode_analytics.dart';
import '../data/goal_mode_content.dart';

/// Home body for general / conceive / avoid — primary cycle view first, details collapsed.
class GoalModeHomeSection extends StatelessWidget {
  const GoalModeHomeSection({
    super.key,
    required this.data,
    required this.goal,
    required this.showRing,
    required this.showWeekCalendar,
    required this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final bool showRing;
  final bool showWeekCalendar;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoalCycleSharedBody(
          data: data,
          goal: goal,
          showRing: showRing,
          showWeekCalendar: showWeekCalendar,
          onOpenCalendar: onOpenCalendar,
        ),
      ],
    );
  }
}

/// Compact goal strip — title + one-line context (no stats wall).
class GoalModeBannerCard extends StatelessWidget {
  const GoalModeBannerCard({
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
    final subtitle = GoalModeContent.headerSubtitle(goal, data, lang);
    final (icon, title, gradient) = _branding(goal, l10n, theme);

    return AppGlassCard(
      blur: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: gradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle.forLang(lang),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, Gradient) _branding(
    UserGoalTypes goal,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return switch (goal) {
      UserGoalTypes.conceive => (
          Icons.child_friendly,
          l10n.goalModeConceiveTitle,
          LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
            ],
          ),
        ),
      UserGoalTypes.avoid => (
          Icons.shield_outlined,
          l10n.goalModeAvoidTitle,
          const LinearGradient(
            colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
          ),
        ),
      UserGoalTypes.pcos => (
          Icons.medical_services_outlined,
          l10n.localeName.startsWith('ar') ? 'إدارة تكيس المبايض' : 'PCOS Management',
          const LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF00897B)],
          ),
        ),
      UserGoalTypes.menopause => (
          Icons.hourglass_empty_rounded,
          l10n.localeName.startsWith('ar') ? 'تتبع سن الأمل' : 'Menopause Tracking',
          const LinearGradient(
            colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
          ),
        ),
      UserGoalTypes.postpartum => (
          Icons.baby_changing_station_rounded,
          l10n.localeName.startsWith('ar') ? 'الاستشفاء بعد الولادة' : 'Postpartum Recovery',
          const LinearGradient(
            colors: [Color(0xFFEC407A), Color(0xFFC2185B)],
          ),
        ),
      _ => (
          Icons.health_and_safety_outlined,
          l10n.goalModeGeneralTitle,
          LinearGradient(
            colors: [
              AppColors.accent,
              theme.colorScheme.primary,
            ],
          ),
        ),
    };
  }
}

/// Ring + week view visible; stats, tips, education & AI under «More».
class GoalCycleSharedBody extends StatelessWidget {
  const GoalCycleSharedBody({
    super.key,
    required this.data,
    required this.goal,
    required this.showRing,
    required this.showWeekCalendar,
    required this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final bool showRing;
  final bool showWeekCalendar;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final tip = GoalModeContent.dailyTip(goal, data, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.goalModeTodayFocus,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tip.forLang(lang),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _CycleRingCard(
          data: data,
          showRing: showRing,
          onOpenCalendar: onOpenCalendar,
        ),
        const SizedBox(height: 12),
        AppGlassCard(
          blur: false,
          padding: EdgeInsets.zero,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              maintainState: false,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Icon(
                Icons.insights_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                l10n.homeGoalMoreTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                _moreSubtitle(goal, l10n),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatChip(
                      icon: Icons.today,
                      label: l10n.homeCycleDay(data.cycleDay),
                      highlight: true,
                    ),
                    if (data.isPeriodStarted)
                      AppStatChip(
                        icon: Icons.water_drop,
                        label: l10n.homePeriodDay(data.periodDay),
                        highlight: true,
                      ),
                    if (data.isOvulationDay)
                      AppStatChip(
                        icon: Icons.favorite,
                        label: l10n.homeOvulationToday,
                        highlight: true,
                      ),
                    if (goal.isConceiveMode &&
                        GoalModeAnalytics.hasFertilityData(data))
                      AppStatChip(
                        icon: Icons.child_friendly,
                        label: data.pregnancyChances,
                        highlight: data.isOvulationDay,
                      ),
                    if (goal.isAvoidMode)
                      AppStatChip(
                        icon: Icons.shield_outlined,
                        label: _fertilityChipLabel(
                          GoalModeAnalytics.fertilityLevel(data),
                          l10n,
                        ),
                        highlight: GoalModeAnalytics.fertilityLevel(data) ==
                            FertilityLevel.high,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                HomeWeeklyCalendarCard(loading: !showWeekCalendar),
                const SizedBox(height: 12),
                _GoalStatsRow(goal: goal, data: data, l10n: l10n, theme: theme),
                const SizedBox(height: 12),
                _GoalChecklistCard(goal: goal, lang: lang),
                const SizedBox(height: 12),
                if (goal == UserGoalTypes.general || goal.isConceiveMode) ...[
                  const OvulationLogCard(),
                  const SizedBox(height: 12),
                ],
                HomeKeyDatesCard(data: data),
                const SizedBox(height: 16),
                HomeTipsSection(phase: data.phase),
                const SizedBox(height: 12),
                HomeLearnWatchRail(phase: data.phase, cycleDay: data.cycleDay),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _moreSubtitle(UserGoalTypes goal, AppLocalizations l10n) {
    return switch (goal) {
      UserGoalTypes.conceive => l10n.homeGoalMoreConceive,
      UserGoalTypes.avoid => l10n.homeGoalMoreAvoid,
      UserGoalTypes.pregnant => l10n.localeName.startsWith('ar')
          ? 'متابعة أسبوعية، نصائح طبية، ودعم للحمل الصحي.'
          : 'Weekly tracking, medical tips, and support for a healthy pregnancy.',
      UserGoalTypes.menopause => l10n.localeName.startsWith('ar')
          ? 'الهبّات الساخنة، النوم، والمزاج — أنماط تساعدكِ على الراحة.'
          : 'Hot flashes, sleep, and mood — patterns help you find relief.',
      UserGoalTypes.pcos => l10n.localeName.startsWith('ar')
          ? 'الانتظام، الأعراض الهرمونية، ونمط الحياة — كلها مرتبطة.'
          : 'Regularity, hormonal symptoms, and lifestyle — all linked.',
      UserGoalTypes.postpartum => l10n.localeName.startsWith('ar')
          ? 'الشفاء، النوم، والمزاج — شفاؤكِ رحلة يومية.'
          : 'Healing, sleep, and mood — your recovery is a daily journey.',
      _ => l10n.homeGoalMoreGeneral,
    };
  }

  String _fertilityChipLabel(FertilityLevel level, AppLocalizations l10n) {
    return switch (level) {
      FertilityLevel.high => l10n.goalModeFertilityHigh,
      FertilityLevel.moderate => l10n.goalModeFertilityModerate,
      FertilityLevel.low => l10n.goalModeFertilityLow,
      FertilityLevel.unknown => l10n.goalModeFertilityUnknown,
    };
  }
}

class _CycleRingCard extends StatelessWidget {
  const _CycleRingCard({
    required this.data,
    required this.showRing,
    required this.onOpenCalendar,
  });

  final CycleDashboardData data;
  final bool showRing;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.phaseToday,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.phase,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (showRing)
            const RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Center(child: LuneCycleRing(size: 248)),
              ),
            )
          else
            const SizedBox(
              height: 280,
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenCalendar,
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              label: Text(l10n.homeOpenCalendar),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalStatsRow extends StatelessWidget {
  const _GoalStatsRow({
    required this.goal,
    required this.data,
    required this.l10n,
    required this.theme,
  });

  final UserGoalTypes goal;
  final CycleDashboardData data;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (goal.isAvoidMode) {
      final level = GoalModeAnalytics.fertilityLevel(data);
      final (label, color) = _fertilityLabel(level, l10n, theme);
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: [
          AppStatCard(
            icon: Icons.warning_amber_rounded,
            label: l10n.goalModeFertilityToday,
            value: label,
            accent: color,
          ),
          AppStatCard(
            icon: Icons.favorite_outline,
            label: l10n.homeOvulation,
            value: data.ovulation,
            accent: theme.colorScheme.secondary,
          ),
          AppStatCard(
            icon: Icons.event_outlined,
            label: l10n.nextPeriod,
            value: data.nextPeriod,
            accent: theme.colorScheme.primary,
          ),
          AppStatCard(
            icon: Icons.timeline_outlined,
            label: l10n.homeRegularity,
            value: '${data.cycleRegularity.round()}%',
            accent: AppColors.accent,
          ),
        ],
      );
    }

    if (goal.isConceiveMode) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: [
          AppStatCard(
            icon: Icons.favorite,
            label: l10n.homeOvulation,
            value: data.ovulation,
            accent: data.isOvulationDay
                ? theme.colorScheme.error
                : theme.colorScheme.secondary,
          ),
          AppStatCard(
            icon: Icons.child_friendly,
            label: l10n.reportPregnancyChance,
            value: GoalModeAnalytics.hasFertilityData(data)
                ? data.pregnancyChances
                : '—',
            accent: theme.colorScheme.tertiary,
          ),
          AppStatCard(
            icon: Icons.wb_sunny_outlined,
            label: l10n.phaseToday,
            value: data.phase,
            accent: theme.colorScheme.primary,
          ),
          AppStatCard(
            icon: Icons.science_outlined,
            label: l10n.goalModeTestDate,
            value: data.expectedPregnancyTestDate.isNotEmpty &&
                    data.expectedPregnancyTestDate != '—'
                ? data.expectedPregnancyTestDate
                : '—',
            accent: AppColors.accent,
          ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.35,
      children: [
        AppStatCard(
          icon: Icons.wb_sunny_outlined,
          label: l10n.phaseToday,
          value: data.phase,
          accent: theme.colorScheme.primary,
        ),
        AppStatCard(
          icon: Icons.timeline_outlined,
          label: l10n.homeRegularity,
          value:
              '${data.cycleRegularity.round()}% · ${data.cycleRegularityStatus}',
          accent: AppColors.accent,
        ),
        AppStatCard(
          icon: Icons.event_outlined,
          label: l10n.nextPeriod,
          value: data.nextPeriod,
          accent: theme.colorScheme.secondary,
        ),
        AppStatCard(
          icon: Icons.favorite_outline,
          label: l10n.homeOvulation,
          value: data.ovulation,
          accent: theme.colorScheme.tertiary,
        ),
      ],
    );
  }

  (String, Color) _fertilityLabel(
    FertilityLevel level,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return switch (level) {
      FertilityLevel.high => (l10n.goalModeFertilityHigh, AuraColors.danger),
      FertilityLevel.moderate =>
        (l10n.goalModeFertilityModerate, AuraColors.warning),
      FertilityLevel.low => (l10n.goalModeFertilityLow, AuraColors.success),
      FertilityLevel.unknown =>
        (l10n.goalModeFertilityUnknown, theme.colorScheme.outline),
    };
  }
}

class _GoalChecklistCard extends StatelessWidget {
  const _GoalChecklistCard({required this.goal, required this.lang});

  final UserGoalTypes goal;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = GoalModeContent.checklist(goal, lang);

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.goalModeChecklist,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.forLang(lang),
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
