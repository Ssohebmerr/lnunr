import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

/// Enum representing different types of sex.
enum SexTypes {
  vaginal('vaginal'),
  anal('anal'),
  oral('oral'),
  /// Manual stimulation (e.g., handjob, fingering).
  manual('manual'),
  /// Other types of sexual activity not covered by the above.
  other('other');

  /// The string identifier used for database storage.
  final String dbName;

  const SexTypes(this.dbName);

  /// Converts a database string back into a [SexTypes].
  static SexTypes fromDbName(String value) {
    return SexTypes.values.firstWhere(
      (e) => e.dbName == value,
      orElse: () => SexTypes.other,
    );
  }

  /// Returns the localised string for the UI.
  String getDisplayName(AppLocalizations l10n) {
    return switch (this) {
      SexTypes.vaginal => l10n.sexType_vaginal,
      SexTypes.anal => l10n.sexType_anal,
      SexTypes.oral => l10n.sexType_oral,
      SexTypes.manual => l10n.sexType_manual,
      SexTypes.other => l10n.other,
    };
  }

  /// gets the associated icon
  /// I'm not sure these are the best icons but they will do for now...
  // TODO: revisit icon choices later
  IconData get icon {
    return switch (this) {
      SexTypes.vaginal => Icons.favorite,
      SexTypes.anal => Icons.flare,
      SexTypes.oral => Icons.auto_awesome,
      SexTypes.manual => Icons.front_hand,
      SexTypes.other => Icons.extension,
    };
  }

  /// Category colours drawn from the Lune palette — distinct per type, all
  /// within the app's rose/lavender/peach world instead of raw accents.
  Color getColorScheme(ColorScheme colorScheme) {
    switch (this) {
      case SexTypes.vaginal:
        return const Color(0xFFD84A83); // berry
      case SexTypes.anal:
        return const Color(0xFF9B7ED4); // deep lavender
      case SexTypes.oral:
        return const Color(0xFFE8A0BF); // rose
      case SexTypes.manual:
        return const Color(0xFFFFB4A2); // peach
      case SexTypes.other:
        return const Color(0xFFB58AA8); // muted mauve
    }
  }
}