import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide locale state. Persists the user's chosen language to
/// `SharedPreferences` under [_key] so it survives restarts.
///
/// Why this is a `ChangeNotifier` (not a BLoC / Cubit):
///   - The state is trivial: a single [Locale] plus persistence.
///   - One consumer (the root `MaterialApp`) rebuilds on change.
///   - Two write paths (`toggle`, `setLocale`) and one read (`locale`).
///
/// See `docs/STATE_MANAGEMENT.md` for the rationale behind the choice.
class LocaleController extends ChangeNotifier {
  static const _key = 'app_locale';

  /// The languages the app actually ships strings for. Anything else has to be
  /// clamped rather than passed through: a locale outside this set resolves to
  /// no delegate, and `AppLocalizations.of(context)!` then throws on the first
  /// frame. The app used to advertise 19 locales it had no translations for.
  static const _supported = {'ar', 'en'};

  static Locale _resolve(String? code) =>
      Locale(_supported.contains(code) ? code! : 'ar');

  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  /// Read the persisted locale and emit a notification so the UI
  /// re-renders with the correct strings on first frame.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = _resolve(prefs.getString(_key));
    notifyListeners();
  }

  /// Convenience for the EN ↔ AR toggle used in settings/onboarding.
  Future<void> toggle() async {
    _locale = isArabic ? const Locale('en') : const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _locale.languageCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = _resolve(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _locale.languageCode);
    notifyListeners();
  }
}