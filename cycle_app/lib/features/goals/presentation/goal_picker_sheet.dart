import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart' as md;
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/feminine_icons_custom.dart';
import '../../../l10n/app_localizations.dart';

/// Pick a primary goal — app home, reports, self-care, and AI adapt instantly.
class GoalPickerSheet extends StatelessWidget {
  const GoalPickerSheet({
    super.key,
    required this.selected,
  });

  final UserGoalTypes selected;

  static const _goals = [
    UserGoalTypes.general,
    UserGoalTypes.pregnant,
    UserGoalTypes.conceive,
    UserGoalTypes.avoid,
    UserGoalTypes.menopause,
    UserGoalTypes.pcos,
    UserGoalTypes.postpartum,
  ];

  static Future<UserGoalTypes?> show(
    BuildContext context, {
    required UserGoalTypes current,
  }) {
    return showModalBottomSheet<UserGoalTypes>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GoalPickerSheet(selected: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mdL10n = md.AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.accountChangeGoal,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.accountChangeGoalHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.05,
              children: _goals.map((goal) {
                final isSelected = goal == selected;
                return AppGlassCard(
                  onTap: () => Navigator.of(context).pop(goal),
                  padding: const EdgeInsets.all(14),
                  radius: AppRadius.lg,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.18),
                                theme.colorScheme.secondary
                                    .withValues(alpha: 0.10),
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: FeminineIconView(
                            goal.femIcon,
                            size: 30,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mdL10n != null
                              ? goal.getDisplayName(mdL10n)
                              : goal.dbName,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
}
