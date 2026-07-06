import 'package:shared_preferences/shared_preferences.dart';

/// Manages the daily self-care rituals.
///
/// Rituals reset every day: completion is stored under a date-scoped key
/// (`ritual_YYYY-MM-DD_<index>`) so yesterday's checkmarks never leak into
/// today. A lightweight per-day "any completed" flag powers the streak count.
class RitualService {
  RitualService._();

  static const _maxRituals = 8;

  static String _todayKey([DateTime? at]) {
    final d = at ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}'
        '-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
  }

  static String _itemKey(String date, int index) => 'ritual_${date}_$index';
  static String _dayFlagKey(String date) => 'ritual_day_$date';

  /// Reads today's completion state for [count] rituals.
  static Future<List<bool>> loadToday(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final date = _todayKey();
    return List<bool>.generate(
      count,
      (i) => prefs.getBool(_itemKey(date, i)) ?? false,
    );
  }

  /// Toggles ritual [index] for today and refreshes the streak flag.
  static Future<void> setToday(int index, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final date = _todayKey();
    await prefs.setBool(_itemKey(date, index), value);

    // Recompute whether *any* ritual is done today for the streak flag.
    var anyDone = false;
    for (var i = 0; i < _maxRituals; i++) {
      if (prefs.getBool(_itemKey(date, i)) ?? false) {
        anyDone = true;
        break;
      }
    }
    await prefs.setBool(_dayFlagKey(date), anyDone);
  }

  /// Count of rituals completed today (used to feed the AI context).
  static Future<int> completedTodayCount({int max = _maxRituals}) async {
    final prefs = await SharedPreferences.getInstance();
    final date = _todayKey();
    var count = 0;
    for (var i = 0; i < max; i++) {
      if (prefs.getBool(_itemKey(date, i)) ?? false) count++;
    }
    return count;
  }

  /// Consecutive days (ending today or yesterday) with at least one ritual
  /// completed. Today not being done yet does NOT break an ongoing streak.
  static Future<int> streak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    var streak = 0;

    // If today isn't logged yet, anchor from yesterday so the streak holds.
    var cursor = DateTime(now.year, now.month, now.day);
    if (!(prefs.getBool(_dayFlagKey(_todayKey(cursor))) ?? false)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Scan back up to a year — plenty for a habit streak.
    for (var i = 0; i < 366; i++) {
      if (prefs.getBool(_dayFlagKey(_todayKey(cursor))) ?? false) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}
