import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../data/user_goal_experience.dart';
import 'goal_choice_card.dart';

/// Pick a primary goal — app home, reports, self-care, and AI adapt instantly.
class GoalPickerSheet extends StatelessWidget {
  const GoalPickerSheet({super.key, required this.selected});

  final UserGoalTypes selected;

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
              for (var index = 0; index < visibleUserGoals.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                GoalChoiceCard(
                  goal: visibleUserGoals[index],
                  selected: visibleUserGoals[index] == selected,
                  onTap: () =>
                      Navigator.of(context).pop(visibleUserGoals[index]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
