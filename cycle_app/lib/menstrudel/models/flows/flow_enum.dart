import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

enum FlowRate {
  none,
  spotting,
  light,
  medium,
  heavy;

  /// Returns flow rates that represent an actual flow during a period.
  static List<FlowRate> get periodFlows  =>
    values.where((flow) => flow != FlowRate.none).toList();
}

extension FlowExtension on FlowRate {
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {
      case FlowRate.none:
        return l10n.flowIntensity_none;
      case FlowRate.spotting:
        return l10n.flowIntensity_spotting;
      case FlowRate.light:
        return l10n.flowIntensity_light;
      case FlowRate.medium:
        return l10n.flowIntensity_moderate;
      case FlowRate.heavy:
        return l10n.flowIntensity_heavy;
    }
  }
  int get intValue {
    return index;
  }
  /// Flow intensity as a cohesive pink→berry ramp from the Lune palette, so
  /// the calendar day dots and flow charts read as one system. Mid-to-deep
  /// tones keep white day-numbers legible on top.
  Color get color {
    switch (this) {
      case FlowRate.none:
        return const Color(0xFFB79BAE); // neutral mauve (logged, no flow)
      case FlowRate.spotting:
        return const Color(0xFFEBA9C4);
      case FlowRate.light:
        return const Color(0xFFE188AE);
      case FlowRate.medium:
        return const Color(0xFFD5619A);
      case FlowRate.heavy:
        return const Color(0xFFC02E6A);
    }
  }
}