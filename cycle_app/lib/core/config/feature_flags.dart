import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for "is this feature on?".
///
/// Today the answer comes from [SharedPreferences] (booleans written by the
/// app itself or by the admin broadcast path). When we adopt Firebase
/// Remote Config, swap [_resolve] to consult `remoteConfig.getBool(...)` and
/// fall back to the local value on miss / before first refresh.
///
/// Adding a new flag:
///   1. Add a `static const` flag name under [Flag].
///   2. Add a default in [_defaults].
///   3. Use `FeatureFlags.isEnabled(context, FeatureFlags.dailyStreak)` from UI.
///   4. (Optional) Toggle it from the admin panel by writing the same key
///      into Firestore `appSettings/featureFlags` — see `FeatureFlagsAdminBridge`.
class FeatureFlags {
  FeatureFlags._();

  /// Canonical flag keys. Add new ones here so every consumer sees the
  /// same name (typos become compile-time errors).
  static const String dailyStreak = 'feature.dailyStreak';
  static const String todaysInsight = 'feature.todaysInsight';
  static const String smartPhaseNotifications = 'feature.smartPhaseNotifications';
  static const String symptomInsightsEngine = 'feature.symptomInsightsEngine';
  static const String moodJournal = 'feature.moodJournal';
  static const String voiceLogging = 'feature.voiceLogging';
  static const String partnerSync = 'feature.partnerSync';
  static const String luneStories = 'feature.luneStories';
  static const String aiChatEnabled = 'feature.aiChatEnabled';

  /// Convenience group for callers that want to list every known flag.
  /// Keep this in sync with the constants above.
  static const List<String> allFlags = <String>[
    dailyStreak,
    todaysInsight,
    smartPhaseNotifications,
    symptomInsightsEngine,
    moodJournal,
    voiceLogging,
    partnerSync,
    luneStories,
    aiChatEnabled,
  ];

  /// Defaults applied the very first time a flag is read on a device.
  /// Keep these conservative — we'd rather ship a feature off and turn it on
  /// later than the other way around.
  static const Map<String, bool> _defaults = <String, bool>{
    dailyStreak: true,
    todaysInsight: true,
    smartPhaseNotifications: true,
    symptomInsightsEngine: true,
    moodJournal: false, // pending design
    voiceLogging: false,
    partnerSync: true,
    luneStories: true,
    aiChatEnabled: true,
  };

  /// In-memory cache so we don't hit SharedPreferences on every widget build.
  /// Rebuilt by [refresh] (which the admin bridge calls after a remote push).
  static final Map<String, bool> _cache = <String, bool>{};

  /// Force the cache to be repopulated from SharedPreferences.
  static Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    _cache.clear();
    for (final key in allFlags) {
      _cache[key] = prefs.getBool(key) ?? _defaults[key] ?? false;
    }
    if (kDebugMode) {
      debugPrint('[FeatureFlags] refreshed: $_cache');
    }
  }

  /// Resolve a flag value. Local override (set via [setEnabled]) wins over
  /// the default until [refresh] is called again.
  static Future<bool> isEnabled(String flag) async {
    if (_cache.containsKey(flag)) return _cache[flag]!;
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(flag) ?? _defaults[flag] ?? false;
    _cache[flag] = v;
    return v;
  }

  /// Synchronous read for hot paths (after [refresh] has run). Falls back
  /// to the default if the cache is cold.
  static bool isEnabledSync(String flag) {
    return _cache[flag] ?? _defaults[flag] ?? false;
  }

  /// Admin / debug helper — write a local override. Survives until the
  /// user clears app data.
  static Future<void> setEnabled(String flag, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(flag, value);
    _cache[flag] = value;
  }

  /// List every known flag with its current effective value. Useful for
  /// the admin panel + debug screens.
  static Future<Map<String, bool>> dump() async {
    final out = <String, bool>{};
    for (final key in allFlags) {
      out[key] = await isEnabled(key);
    }
    return out;
  }
}