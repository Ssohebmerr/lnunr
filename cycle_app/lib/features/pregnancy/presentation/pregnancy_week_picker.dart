import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pregnancy_development_content.dart';
import '../data/pregnancy_fetal_stage.dart';
import '../data/pregnancy_growth_display.dart';
import 'pregnancy_baby_hero_3d.dart';

/// Horizontal week scrubber (Flo-style) centered on current gestational week.
class PregnancyWeekPicker extends StatelessWidget {
  const PregnancyWeekPicker({
    super.key,
    required this.currentWeek,
    required this.selectedWeek,
    required this.onWeekSelected,
  });

  final int currentWeek;
  final int selectedWeek;
  final ValueChanged<int> onWeekSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final week = currentWeek.clamp(
      minPregnancyVisualWeek,
      maxPregnancyVisualWeek,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pregnancyExploreWeeks,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            primary: false,
            scrollDirection: Axis.horizontal,
            itemCount: maxPregnancyVisualWeek - minPregnancyVisualWeek + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final w = index + minPregnancyVisualWeek;
              final isCurrent = w == week;
              final isSelected = w == selectedWeek;
              return ChoiceChip(
                label: Text('$w'),
                selected: isSelected,
                onSelected: (_) => onWeekSelected(w),
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                selectedColor: theme.colorScheme.primary,
                backgroundColor: isCurrent && !isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                side: isCurrent
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Hero card: large fetal visual + growth stats (Flo-style layout).
class PregnancyBabyHeroCard extends StatelessWidget {
  const PregnancyBabyHeroCard({
    super.key,
    required this.week,
    required this.lang,
    this.gestationalDay = 7,
    this.onGestationalDaySelected,
  });

  final int week;
  final String lang;
  final int gestationalDay;
  final ValueChanged<int>? onGestationalDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final info = PregnancyDevelopmentContent.forWeek(week, lang);
    final stage = fetalStageForGestationalAge(week, day: gestationalDay);

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pregnancyBabyVisualTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.pregnancyWeekLabel(week)} · ${stage.labelFor(lang)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (week == minPregnancyVisualWeek &&
              onGestationalDaySelected != null) ...[
            const SizedBox(height: 12),
            _EarlyDevelopmentSelector(
              day: gestationalDay,
              lang: lang,
              onSelected: onGestationalDaySelected!,
            ),
          ],
          const SizedBox(height: 14),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: RepaintBoundary(
                child: PregnancyBabyHero3DCard(
                  week: week,
                  gestationalDay: gestationalDay,
                  lang: lang,
                  size: 300,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: PregnancyGrowthStatsRow(info: info, lang: lang),
          ),
          const SizedBox(height: 14),
          _WeeklyDevelopmentCard(week: week, body: info.bodyFor(lang)),
        ],
      ),
    );
  }
}

class _WeeklyDevelopmentCard extends StatelessWidget {
  const _WeeklyDevelopmentCard({required this.week, required this.body});

  final int week;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final progress =
        (week.clamp(1, maxPregnancyVisualWeek) / maxPregnancyVisualWeek).clamp(
          0.0,
          1.0,
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.42),
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.pregnancyBabyThisWeek,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  l10n.pregnancyWeekLabel(week),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface.withValues(
                alpha: 0.72,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarlyDevelopmentSelector extends StatelessWidget {
  const _EarlyDevelopmentSelector({
    required this.day,
    required this.lang,
    required this.onSelected,
  });

  final int day;
  final String lang;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = fetalStageForGestationalAge(
      minPregnancyVisualWeek,
      day: day,
    ).kind;
    const milestoneDays = [1, 3, 6];

    return Row(
      children: [
        for (var index = 0; index < milestoneDays.length; index++) ...[
          if (index > 0) const SizedBox(width: 6),
          Expanded(
            child: Builder(
              builder: (context) {
                final milestoneDay = milestoneDays[index];
                final stage = fetalStageForGestationalAge(
                  minPregnancyVisualWeek,
                  day: milestoneDay,
                );
                final active = selected == stage.kind;
                return Material(
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    onTap: () => onSelected(milestoneDay),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: Text(
                        stage.shortLabelFor(lang),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: active
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
