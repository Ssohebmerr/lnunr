import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/app/settings_presets.dart';

/// Enum representing different types of user app goals.
enum UserGoalTypes {
  /// For users tracking periods for general health.
  general('general'),
  /// For users focusing on sexual health.
  sexual('sexual'),
  /// For users trying to conceive.
  conceive('conceive'),
  /// For users trying to avoid pregnancy.
  avoid('avoid'),
  /// For users currently pregnant — pregnancy tracking mode.
  pregnant('pregnant');

  /// The string identifier used for database storage.
  final String dbName;

  const UserGoalTypes(this.dbName);

  /// Converts a database string back into a [UserGoalTypes].
  static UserGoalTypes fromDbName(String value) {
    return UserGoalTypes.values.firstWhere(
      (e) => e.dbName == value,
      orElse: () => UserGoalTypes.general,
    );
  }

  /// Returns the localised string for the UI.
  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      UserGoalTypes.general => l10n.userGoal_general,
      UserGoalTypes.sexual => l10n.userGoal_sexual,
      UserGoalTypes.conceive => l10n.userGoal_conceive,
      UserGoalTypes.avoid => l10n.userGoal_avoid,
      UserGoalTypes.pregnant => l10n.localeName.startsWith('ar')
          ? 'أنا حامل'
          : "I'm pregnant",
    };
  }
  IconData get icon {
    return switch (this) {
      UserGoalTypes.general => Icons.health_and_safety,
      UserGoalTypes.sexual => Icons.favorite,
      UserGoalTypes.conceive => Icons.child_friendly,
      UserGoalTypes.avoid => Icons.shield,
      UserGoalTypes.pregnant => Icons.pregnant_woman_rounded,
    };
  }
}

extension UserGoalExtension on UserGoalTypes {
  GoalPreset get settings => kGoalPresets[this]!;

  bool get isPregnancyMode => this == UserGoalTypes.pregnant;

  bool get isConceiveMode => this == UserGoalTypes.conceive;

  bool get isAvoidMode => this == UserGoalTypes.avoid;

  bool get isGeneralMode => this == UserGoalTypes.general;

  bool get isCycleGoalMode => isGeneralMode || isConceiveMode || isAvoidMode;
}