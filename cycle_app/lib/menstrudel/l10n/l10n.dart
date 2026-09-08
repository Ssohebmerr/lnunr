import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

/// This class is a custom helper to build language selection dropdown.
class L10n {
  /// Only the languages the app actually ships strings for. The app forces
  /// its locale to one of these two, so offering more here would just show
  /// a half-translated interface.
  static final Map<String, String> nativeLanguageNames = {
    'ar': 'العربية',
    'en': 'English',
  };

static Map<String, String> getLanguageOptions(AppLocalizations l10n) {
    return {
      'system': l10n.systemDefault,
      ...nativeLanguageNames, 
    };
  }
}