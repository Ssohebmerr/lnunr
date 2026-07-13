import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local-only daily log for the life-stage condition goals (menopause, PCOS,
/// postpartum).
///
/// Kept deliberately separate from the encrypted cycle symptom store because
/// the symptoms these goals care about — hot flashes, night sweats, joint
/// aches, lifestyle rituals, mood scores — are not part of the fixed cycle
/// symptom catalogue. Everything is bucketed by day (`yyyy-mm-dd`) so history,
/// streaks, and "already logged today" checks stay cheap.
///
/// Storage layout (three JSON blobs in [SharedPreferences]):
///  - `condition_symptoms` : { "2026-07-09": ["hot_flashes", "night_sweats"] }
///  - `condition_rituals`  : { "2026-07-09": ["short_walks"] }
///  - `condition_metrics`  : { "hotflash_count": { "2026-07-09": 3 } }
///
/// Keys are stable slugs derived from the English label via [slug], so no
/// schema lives in the content classes and translations can change freely.
class ConditionLogStore {
  ConditionLogStore._();

  static const _symptomsKey = 'condition_symptoms';
  static const _ritualsKey = 'condition_rituals';
  static const _metricsKey = 'condition_metrics';

  /// Metric name for the menopause daily hot-flash counter.
  static const metricHotFlash = 'hotflash_count';

  /// Metric name for the postpartum daily mood check-in (1–5).
  static const metricMood = 'mood';

  /// Normalised day bucket, e.g. `2026-07-09`.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Stable, language-independent key from an English label.
  /// `slug('Hot flashes')` -> `hot_flashes`.
  static String slug(String en) {
    final buf = StringBuffer();
    var prevUnderscore = false;
    for (final ch in en.toLowerCase().trim().runes) {
      final c = String.fromCharCode(ch);
      if ((c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) ||
          (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57)) {
        buf.write(c);
        prevUnderscore = false;
      } else if (!prevUnderscore) {
        buf.write('_');
        prevUnderscore = true;
      }
    }
    return buf.toString().replaceAll(RegExp(r'^_+|_+$'), '');
  }

  // ── Symptoms (a toggle set per day) ──────────────────────────────────────
  static Future<Set<String>> symptomsOn(DateTime day) =>
      _setFor(_symptomsKey, day);

  static Future<void> toggleSymptom(DateTime day, String key) =>
      _toggle(_symptomsKey, day, key);

  /// Consecutive days (ending today) that have at least one symptom logged.
  static Future<int> symptomStreak() async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(_symptomsKey));
    var streak = 0;
    var day = DateTime.now();
    while (true) {
      final entry = map[dayKey(day)];
      if (entry is List && entry.isNotEmpty) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Day-keyed symptom sets for the last [days] days (today included).
  /// Only days with at least one entry appear in the map.
  static Future<Map<String, Set<String>>> symptomHistory({int days = 30}) =>
      _setHistory(_symptomsKey, days);

  // ── Rituals (a checklist set per day) ────────────────────────────────────
  static Future<Set<String>> ritualsOn(DateTime day) =>
      _setFor(_ritualsKey, day);

  static Future<void> toggleRitual(DateTime day, String key) =>
      _toggle(_ritualsKey, day, key);

  /// Day-keyed ritual sets for the last [days] days (today included).
  static Future<Map<String, Set<String>>> ritualHistory({int days = 30}) =>
      _setHistory(_ritualsKey, days);

  // ── Numeric metrics (name -> day -> int) ─────────────────────────────────
  static Future<int> metric(String name, DateTime day) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(_metricsKey));
    final byDay = map[name];
    if (byDay is Map) {
      final v = byDay[dayKey(day)];
      if (v is int) return v;
      if (v is num) return v.toInt();
    }
    return 0;
  }

  static Future<void> setMetric(String name, DateTime day, int value) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(_metricsKey));
    final byDay = <String, dynamic>{
      ...?(map[name] as Map?)?.map((k, v) => MapEntry(k.toString(), v)),
    };
    byDay[dayKey(day)] = value;
    map[name] = byDay;
    await p.setString(_metricsKey, jsonEncode(map));
  }

  /// Day-keyed values of one metric for the last [days] days (today
  /// included). Only recorded days appear in the map.
  static Future<Map<String, int>> metricHistory(
    String name, {
    int days = 30,
  }) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(_metricsKey));
    final byDay = map[name];
    if (byDay is! Map) return <String, int>{};
    final cutoff = _cutoffKey(days);
    final result = <String, int>{};
    byDay.forEach((k, v) {
      final key = k.toString();
      if (key.compareTo(cutoff) >= 0 && v is num) result[key] = v.toInt();
    });
    return result;
  }

  /// Consecutive recent days (ending today) whose metric is `<= threshold`
  /// and actually recorded. Used to spot a lingering low mood gently.
  static Future<int> metricLowStreak(
    String name, {
    required int threshold,
    int maxLookback = 21,
  }) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(_metricsKey));
    final byDay = map[name];
    if (byDay is! Map) return 0;
    var streak = 0;
    var day = DateTime.now();
    for (var i = 0; i < maxLookback; i++) {
      final v = byDay[dayKey(day)];
      final n = v is num ? v.toInt() : null;
      if (n != null && n > 0 && n <= threshold) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Internals ────────────────────────────────────────────────────────────

  /// Earliest dayKey inside a window of [days] days ending today. dayKeys are
  /// zero-padded ISO dates, so plain string comparison orders them correctly.
  static String _cutoffKey(int days) =>
      dayKey(DateTime.now().subtract(Duration(days: days - 1)));

  static Future<Map<String, Set<String>>> _setHistory(
    String storeKey,
    int days,
  ) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(storeKey));
    final cutoff = _cutoffKey(days);
    final result = <String, Set<String>>{};
    map.forEach((k, v) {
      if (k.compareTo(cutoff) >= 0 && v is List && v.isNotEmpty) {
        result[k] = v.map((e) => e.toString()).toSet();
      }
    });
    return result;
  }

  static Future<Set<String>> _setFor(String storeKey, DateTime day) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(storeKey));
    final entry = map[dayKey(day)];
    if (entry is List) return entry.map((e) => e.toString()).toSet();
    return <String>{};
  }

  static Future<void> _toggle(String storeKey, DateTime day, String key) async {
    final p = await SharedPreferences.getInstance();
    final map = _decodeMap(p.getString(storeKey));
    final dk = dayKey(day);
    final set = <String>{
      ...?(map[dk] as List?)?.map((e) => e.toString()),
    };
    if (!set.add(key)) set.remove(key); // add returns false if already present
    map[dk] = set.toList();
    await p.setString(storeKey, jsonEncode(map));
  }

  static Map<String, dynamic> _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return <String, dynamic>{};
  }
}
