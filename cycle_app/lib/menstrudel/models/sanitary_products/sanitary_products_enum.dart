import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

/// An enum of sanitary product types.
enum SanitaryProducts {
  tampon,
  pad,
  menstrualCup,
  periodUnderwear,
}

/// Extension to get display values for SanitaryProducts.
extension LarcTypeDisplay on SanitaryProducts {
  /// Gets the localised display name
  String getDisplayName(AppLocalizations l10n) {
    switch (this) { 
      case SanitaryProducts.tampon:
        return l10n.sanitaryProduct_tampon;
      case SanitaryProducts.pad:
        return l10n.sanitaryProduct_pad;
      case SanitaryProducts.menstrualCup:
        return l10n.sanitaryProduct_menstrualCup;
      case SanitaryProducts.periodUnderwear:
        return l10n.sanitaryProduct_periodUnderwear; 
    }
  }

  /// gets the associated icon
  IconData getIcon(){
    switch (this) { 
      case SanitaryProducts.tampon:
        return Icons.fiber_manual_record;
      case SanitaryProducts.pad:
        return Icons.crop_din;
      case SanitaryProducts.menstrualCup:
        return Icons.filter_vintage;
      case SanitaryProducts.periodUnderwear:
        return Icons.checkroom;
    }
  }

  /// The max duration in hours for each sanitary product type
  /// These values are from general medical guidelines.
  int get maxDurationHours {
    switch (this) {
      case SanitaryProducts.tampon:
        return 8;
      case SanitaryProducts.pad:
        return 8;
      case SanitaryProducts.menstrualCup:
        return 12;
      case SanitaryProducts.periodUnderwear:
        return 12;
    }
  }

  /// Category colours drawn from the Lune palette — distinct per product,
  /// but all within the app's rose/lavender/peach world.
  Color getColorScheme(ColorScheme colorScheme) {
    switch (this) {
      case SanitaryProducts.tampon:
        return const Color(0xFFE8A0BF); // rose
      case SanitaryProducts.pad:
        return const Color(0xFFC9B8E8); // lavender
      case SanitaryProducts.menstrualCup:
        return const Color(0xFFFFB4A2); // peach
      case SanitaryProducts.periodUnderwear:
        return const Color(0xFF9B7ED4); // deep lavender
    }
  }
}
