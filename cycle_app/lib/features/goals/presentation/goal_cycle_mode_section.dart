import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/feminine_icons_custom.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel_integration/wellness_hub_launcher.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../../cycle/presentation/widgets/lune_cycle_ring.dart';
import '../../cycle/presentation/widgets/cycle_cause_card.dart';
import '../../cycle/presentation/widgets/cycle_signals_card.dart';
import '../../cycle/presentation/widgets/ovulation_log_card.dart';
import '../../home/doctor_report_screen.dart';
import '../../home/widgets/home_feed_sections.dart';
import '../data/goal_mode_analytics.dart';
import '../data/goal_mode_content.dart';
import '../data/user_goal_experience.dart';
import 'condition_widgets.dart';

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
  const GoalModeBannerCard({super.key, required this.goal, required this.data});

  final UserGoalTypes goal;
  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final subtitle = GoalModeContent.headerSubtitle(goal, data, lang);
    final dailyTip = GoalModeContent.dailyTip(goal, data, lang);
    final experience = userGoalExperience(goal);

    return AppGlassCard(
      blur: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: experience.gradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: FeminineIconView(
                    goal.femIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experience.titleFor(lang),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dailyTip.forLang(lang),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
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
}

/// Ring + week view visible; stats, tips, education & AI under «More».
/// Whether to ask about this cycle's disruptions.
///
/// Only in the first stretch of a cycle: recall is freshest then, and a card
/// that never goes away stops being read. Needs a real cycle day, so it stays
/// hidden until tracking has actually started.
bool _shouldAskCycleCause(CycleDashboardData data) =>
    data.cycleDay >= 1 && data.cycleDay <= 7;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoalModeBannerCard(goal: goal, data: data),
        const SizedBox(height: 12),
        _CycleRingCard(
          data: data,
          showRing: showRing,
          onOpenCalendar: onOpenCalendar,
        ),
        const SizedBox(height: 12),
        if (goal.isConceiveMode) ...[
          const OvulationLogCard(),
          const SizedBox(height: 12),
        ],
        if (goal.isAvoidMode) ...[
          _AvoidProtectionCard(data: data),
          const SizedBox(height: 12),
        ],
        AppGlassCard(
          blur: false,
          padding: EdgeInsets.zero,
          child: Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              maintainState: false,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
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
                        highlight:
                            GoalModeAnalytics.fertilityLevel(data) ==
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
                if (goal == UserGoalTypes.general) ...[
                  const OvulationLogCard(),
                  const SizedBox(height: 12),
                ],
                // Asked early in a cycle, while the user still remembers what
                // last month was like. Hidden later so it does not become
                // permanent furniture.
                if (_shouldAskCycleCause(data)) ...[
                  CycleCauseCard(
                    cycleStart: DateTime.now().subtract(
                      Duration(days: data.cycleDay - 1),
                    ),
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                ],
                HomeKeyDatesCard(data: data),
                // Health signals from her own logs. Free and offline by
                // design — this must not depend on premium or on the AI
                // gateway being reachable.
                CycleSignalsCard(
                  flags: data.patternFlags,
                  margin: const EdgeInsets.only(top: 12),
                  onOpenDoctorReport: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DoctorReportScreen(),
                    ),
                  ),
                ),
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
      UserGoalTypes.pregnant =>
        l10n.localeName.startsWith('ar')
            ? 'متابعة أسبوعية، نصائح طبية، ودعم للحمل الصحي.'
            : 'Weekly tracking, medical tips, and support for a healthy pregnancy.',
      UserGoalTypes.menopause =>
        l10n.localeName.startsWith('ar')
            ? 'الهبّات الساخنة، النوم، والمزاج — أنماط تساعدكِ على الراحة.'
            : 'Hot flashes, sleep, and mood — patterns help you find relief.',
      UserGoalTypes.pcos =>
        l10n.localeName.startsWith('ar')
            ? 'الانتظام، الأعراض الهرمونية، ونمط الحياة — كلها مرتبطة.'
            : 'Regularity, hormonal symptoms, and lifestyle — all linked.',
      UserGoalTypes.postpartum =>
        l10n.localeName.startsWith('ar')
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
            RepaintBoundary(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: LuneCycleRing(
                    size: 248,
                    phase: data.phase,
                    cycleDay: data.cycleDay > 0 ? data.cycleDay : null,
                    cycleLength: data.avgCycleLength > 0
                        ? data.avgCycleLength
                        : null,
                    periodDuration: data.avgPeriodDuration > 0
                        ? data.avgPeriodDuration
                        : null,
                  ),
                ),
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
            value: data.ovulationDisplay,
            accent: theme.colorScheme.secondary,
          ),
          AppStatCard(
            icon: Icons.event_outlined,
            label: l10n.nextPeriod,
            value: data.periodDisplay,
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
            value: data.ovulationDisplay,
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
            value:
                data.expectedPregnancyTestDate.isNotEmpty &&
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
          value: data.periodDisplay,
          accent: theme.colorScheme.secondary,
        ),
        AppStatCard(
          icon: Icons.favorite_outline,
          label: l10n.homeOvulation,
          value: data.ovulationDisplay,
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
      FertilityLevel.moderate => (
        l10n.goalModeFertilityModerate,
        AuraColors.warning,
      ),
      FertilityLevel.low => (l10n.goalModeFertilityLow, AuraColors.success),
      FertilityLevel.unknown => (
        l10n.goalModeFertilityUnknown,
        theme.colorScheme.outline,
      ),
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
    final items = GoalModeContent.checklist(goal, lang);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.goalModeChecklist),
        const SizedBox(height: 8),
        ConditionRitualChecklist(
          items: items
              .map((item) => ConditionItem.fromEn(item.en, item.forLang(lang)))
              .toList(),
        ),
      ],
    );
  }
}

class _AvoidProtectionCard extends StatelessWidget {
  const _AvoidProtectionCard({required this.data});

  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ar = Localizations.localeOf(context).languageCode.startsWith('ar');
    final level = GoalModeAnalytics.fertilityLevel(data);
    final accent = switch (level) {
      FertilityLevel.high => AuraColors.danger,
      FertilityLevel.moderate => AuraColors.warning,
      FertilityLevel.low => AuraColors.success,
      FertilityLevel.unknown => theme.colorScheme.primary,
    };
    final status = switch (level) {
      FertilityLevel.high => l10n.goalModeFertilityHigh,
      FertilityLevel.moderate => l10n.goalModeFertilityModerate,
      FertilityLevel.low => l10n.goalModeFertilityLow,
      FertilityLevel.unknown => l10n.goalModeFertilityUnknown,
    };

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.shield_outlined, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ar ? 'روتين الحماية' : 'Protection routine',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${l10n.goalModeFertilityToday}: $status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer.withValues(
                alpha: 0.34,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              ar
                  ? 'تقدير التقويم للتوعية فقط، وليس وسيلة منع حمل ولا يضمن يومًا آمنًا. استمري باستخدام وسيلة موثوقة تناسبكِ.'
                  : 'Calendar estimates are for awareness only. They are not contraception and never guarantee a safe day. Keep using a reliable method that fits you.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => WellnessHubLauncher.openPills(context),
                icon: const Icon(Icons.medication_outlined, size: 18),
                label: Text(l10n.wellnessPills),
              ),
              OutlinedButton.icon(
                onPressed: () => WellnessHubLauncher.openLarc(context),
                icon: const Icon(Icons.health_and_safety_outlined, size: 18),
                label: Text(l10n.wellnessLarc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
