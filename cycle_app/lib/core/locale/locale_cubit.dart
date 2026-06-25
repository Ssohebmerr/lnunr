import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends ChangeNotifier {
  static const _key = 'app_locale';

  static const supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('hi'),
    Locale('es'),
    Locale('zh'),
    Locale('fr'),
    Locale('bn'),
    Locale('ru'),
    Locale('pt'),
    Locale('ja'),
    Locale('de'),
    Locale('pa'),
    Locale('jv'),
    Locale('ko'),
    Locale('ta'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('it'),
  ];

  Locale _locale = const Locale('ar');

  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'ar';
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> toggle() async {
    _locale = isArabic ? const Locale('en') : const Locale('ar');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _locale.languageCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    notifyListeners();
  }
}
