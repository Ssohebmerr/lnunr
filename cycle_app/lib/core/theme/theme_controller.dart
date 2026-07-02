import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme mode (light / dark / system). Persisted across launches.
///
/// Why this is a `ChangeNotifier` (not a BLoC / Cubit):
///   - Tiny state (one enum value).
///   - One consumer (`MaterialApp.themeMode`) — no fan-out rebuilds.
///   - Two write paths (`setMode`, `cycle`) — both synchronous in intent.
///
/// See `docs/STATE_MANAGEMENT.md`.
enum AppThemeMode { light, dark, system }

class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';
  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  ThemeMode get themeMode => switch (_mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key) ?? 'system';
    _mode = AppThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => AppThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
    notifyListeners();
  }

  /// 3-state cycle used by the settings tile.
  Future<void> cycle() async {
    final next = switch (_mode) {
      AppThemeMode.light => AppThemeMode.dark,
      AppThemeMode.dark => AppThemeMode.system,
      AppThemeMode.system => AppThemeMode.light,
    };
    await setMode(next);
  }
}