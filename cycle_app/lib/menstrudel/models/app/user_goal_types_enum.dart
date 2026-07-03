import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/app/settings_presets.dart';
import 'package:cycle_aura/core/widgets/feminine_icons_custom.dart';

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
  /// For users currently pregnant — pregnancy tracking mode.
  pregnant('pregnant'),
  /// For users transitioning or in menopause.
  menopause('menopause'),
  /// For users managing PCOS symptoms.
  pcos('pcos'),
  /// For users in postpartum recovery.
  postpartum('postpartum');

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
      UserGoalTypes.menopause => l10n.localeName.startsWith('ar')
          ? 'تتبع سن الأمل / انقطاع الطمث'
          : 'Menopause Tracking',
      UserGoalTypes.pcos => l10n.localeName.startsWith('ar')
          ? 'إدارة تكيس المبايض'
          : 'PCOS Management',
      UserGoalTypes.postpartum => l10n.localeName.startsWith('ar')
          ? 'الاستشفاء بعد الولادة'
          : 'Postpartum Recovery',
    };
  }
  IconData get icon {
    return switch (this) {
      UserGoalTypes.general => Icons.health_and_safety,
      UserGoalTypes.sexual => Icons.favorite,
      UserGoalTypes.conceive => Icons.child_friendly,
      UserGoalTypes.avoid => Icons.shield,
      UserGoalTypes.pregnant => Icons.pregnant_woman_rounded,
      UserGoalTypes.menopause => Icons.hourglass_empty_rounded,
      UserGoalTypes.pcos => Icons.medical_services_outlined,
      UserGoalTypes.postpartum => Icons.baby_changing_station_rounded,
    };
  }
}

/// Custom hand-drawn feminine icons per goal. Drop these into
/// `FeminineIconView` for the prettier UI; fall back to the
/// Material [icon] getter above when no custom art exists.
extension UserGoalFeminineIcon on UserGoalTypes {
  FeminineIcon get femIcon {
    return switch (this) {
      UserGoalTypes.general => FeminineIcon.cycle,
      UserGoalTypes.sexual => FeminineIcon.heartPulse,
      UserGoalTypes.conceive => FeminineIcon.conceive,
      UserGoalTypes.avoid => FeminineIcon.avoid,
      UserGoalTypes.pregnant => FeminineIcon.pregnant,
      UserGoalTypes.menopause => FeminineIcon.menopause,
      UserGoalTypes.pcos => FeminineIcon.pcos,
      UserGoalTypes.postpartum => FeminineIcon.postpartum,
    };
  }
}

extension UserGoalExtension on UserGoalTypes {
  GoalPreset get settings => kGoalPresets[this]!;

  bool get isPregnancyMode => this == UserGoalTypes.pregnant;

  bool get isConceiveMode => this == UserGoalTypes.conceive;

  bool get isAvoidMode => this == UserGoalTypes.avoid;

  bool get isGeneralMode => this == UserGoalTypes.general;

  bool get isMenopauseMode => this == UserGoalTypes.menopause;

  bool get isPcosMode => this == UserGoalTypes.pcos;

  bool get isPostpartumMode => this == UserGoalTypes.postpartum;

  bool get isCycleGoalMode =>
      isGeneralMode || isConceiveMode || isAvoidMode;

  /// True for any goal that wants a custom home body section
  /// (pregnancy, menopause, pcos, postpartum). The general cycle
  /// modes (general, conceive, avoid) share `GoalCycleSharedBody`.
  bool get hasCustomHomeBody =>
      isPregnancyMode ||
      isMenopauseMode ||
      isPcosMode ||
      isPostpartumMode;
}