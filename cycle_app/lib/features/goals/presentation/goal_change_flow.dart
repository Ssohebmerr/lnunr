import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../cycle/data/cycle_sync_service.dart';
import '../data/user_goal_experience.dart';
import 'goal_mode_intro_sheet.dart';
import 'goal_picker_sheet.dart';
import 'pregnancy_lmp_sheet.dart';

/// Change primary goal from settings — app tabs refresh without re-onboarding.
class GoalChangeFlow {
  GoalChangeFlow._();

  /// Returns the new goal when changed, or `null` if cancelled / unchanged.
  static Future<UserGoalTypes?> run(
    BuildContext context, {
    required UserGoalTypes current,
    CycleSyncService? sync,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final cycleSync = sync ?? CycleSyncService();

    final picked = await GoalPickerSheet.show(context, current: current);
    if (picked == null || picked == current) return null;

    if (picked.isPregnancyMode) {
      final lmp = await loadCurrentLmp();
      if (!context.mounted) return null;
      final confirmed = await PregnancyLmpSheet.show(context, initialDate: lmp);
      if (confirmed == null) return null;
    }

    await cycleSync.setUserGoal(picked);

    // Every visible goal gets the same concise summary of what changes. This
    // keeps switching goals understandable without re-running onboarding.
    if (!context.mounted) return null;
    await GoalModeIntroSheet.show(context, picked);

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.goalChangedSnackbar)));
    }
    return picked;
  }

  static String labelFor(BuildContext context, UserGoalTypes goal) {
    final lang = Localizations.localeOf(context).languageCode;
    return userGoalExperience(goal).titleFor(lang);
  }
}
