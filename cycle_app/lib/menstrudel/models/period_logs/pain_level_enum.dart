import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

enum PainLevel {
  none,
  mild,
  moderate,
  severe,
  unbearable
}

extension FlowExtension on PainLevel {
  String getDisplayName(AppLocalizations l10n) {
    switch (this) {

      case PainLevel.none:
        return l10n.painLevel_none;
      case PainLevel.mild:
        return l10n.painLevel_mild;
      case PainLevel.moderate:
        return l10n.painLevel_moderate;
      case PainLevel.severe:
        return l10n.painLevel_severe;
      case PainLevel.unbearable:
        return l10n.pain_unbearable;
    }
  }
  int get intValue {
    return index;
  }

  IconData get icon {
    switch (this) {
      case PainLevel.none:
        return Icons.sentiment_very_satisfied_outlined;
      case PainLevel.mild:
        return Icons.sentiment_satisfied_outlined;
      case PainLevel.moderate:
        return Icons.sentiment_neutral_outlined;
      case PainLevel.severe:
        return Icons.sentiment_dissatisfied_outlined;
      case PainLevel.unbearable:
        return Icons.sentiment_very_dissatisfied_outlined;
    }
  }

  /// A clean well-being→severity ramp (calm green → red). Pain is a semantic
  /// scale, so it intentionally sits outside the rose/lavender brand accent.
  Color get color {
    switch (this) {
      case PainLevel.none:
        return const Color(0xFF4CAF7D); // calm green
      case PainLevel.mild:
        return const Color(0xFF9CCC65); // light green
      case PainLevel.moderate:
        return const Color(0xFFF0B429); // amber
      case PainLevel.severe:
        return const Color(0xFFEF7A54); // orange
      case PainLevel.unbearable:
        return const Color(0xFFD64550); // red
    }
  }
}