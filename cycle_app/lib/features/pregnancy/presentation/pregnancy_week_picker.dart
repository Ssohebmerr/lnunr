import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pregnancy_development_content.dart';
import '../data/pregnancy_growth_display.dart';
import 'fetal_week_illustration.dart';

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
    final week = currentWeek.clamp(4, 40);

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
            scrollDirection: Axis.horizontal,
            itemCount: 37,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final w = index + 4;
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
  });

  final int week;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final info = PregnancyDevelopmentContent.forWeek(week, lang);
    final stageLabel = FetalVisualStageLabels.forWeek(week).labelFor(lang);

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
            '${l10n.pregnancyWeekLabel(week)} · $stageLabel',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: FetalWeekIllustration(
              week: week,
              size: 240,
              hero: true,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: PregnancyGrowthStatsRow(info: info, lang: lang),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restaurant_rounded, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.pregnancySizeLike(info.fruitFor(lang)),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            info.bodyFor(lang),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
