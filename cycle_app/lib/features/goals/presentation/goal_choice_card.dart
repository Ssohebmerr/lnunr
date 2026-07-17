import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/feminine_icons_custom.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../data/user_goal_experience.dart';

/// Shared, roomy goal card used by onboarding and settings.
/// Showing the outcome under the title makes seven choices easier to scan than
/// a dense name-only grid.
class GoalChoiceCard extends StatelessWidget {
  const GoalChoiceCard({
    super.key,
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final UserGoalTypes goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final experience = userGoalExperience(goal);
    final accent = experience.colors.first;

    return Semantics(
      button: true,
      selected: selected,
      label: '${experience.titleFor(lang)}. ${experience.subtitleFor(lang)}',
      child: AppGlassCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        radius: AppRadius.lg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: selected ? accent.withValues(alpha: 0.07) : null,
            border: Border.all(
              color: selected
                  ? accent
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: experience.colors
                        .map(
                          (color) =>
                              color.withValues(alpha: selected ? 0.20 : 0.11),
                        )
                        .toList(),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: FeminineIconView(
                    goal.femIcon,
                    size: 29,
                    color: selected ? accent : theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.titleFor(lang),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected ? accent : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      experience.subtitleFor(lang),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  key: ValueKey(selected),
                  color: selected ? accent : theme.colorScheme.onSurfaceVariant,
                  size: selected ? 23 : 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
