import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only streak tracker. Counts how many consecutive days the user
/// logged at least one daily entry (a period log, a symptom, a wellness
/// metric, a mood journal entry, or completed a self-care ritual).
///
/// Storage shape (all in `SharedPreferences`):
///   - `streak.last_log_date`   ISO-8601 date string (yyyy-MM-dd) of the
///                                most recent day with activity. Used to detect
///                                broken streaks.
///   - `streak.current_count`    integer, the active streak length.
///   - `streak.longest_count`    integer, all-time best — surfaced in the UI
///                                to celebrate milestones.
///
/// We intentionally avoid persisting per-day log markers (one per date).
/// That would let us draw a calendar heatmap later — see
/// `getLoggedDatesThisMonth` below for the lightweight foundation.
// ignore: constant_identifier_names
class StreakService {
  StreakService();

  static const _lastLogDateKey = 'streak.last_log_date';
  static const _currentCountKey = 'streak.current_count';
  static const _longestCountKey = 'streak.longest_count';
  static const _loggedDatesKey = 'streak.logged_dates';

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  /// Returns the current active streak length, or 0 if the streak is broken
  /// (the user has not logged today or yesterday).
  Future<int> currentCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_currentCountKey) ?? 0;
    if (count == 0) return 0;

    final lastDate = _parseDate(prefs.getString(_lastLogDateKey));
    if (lastDate == null) return 0;

    final today = _truncate(DateTime.now());
    final diff = today.difference(lastDate).inDays;
    // diff == 0  -> logged today, streak alive
    // diff == 1  -> last logged yesterday, streak alive for today
    // diff >= 2  -> streak broken
    if (diff >= 2) {
      // Self-heal: write back the broken state so we don't keep doing
      // the same DateTime math on every read.
      await prefs.setInt(_currentCountKey, 0);
      return 0;
    }
    return count;
  }

  /// All-time longest streak.
  Future<int> longestCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestCountKey) ?? 0;
  }

  /// List of ISO dates (yyyy-MM-dd) the user logged anything. Stored as a
  /// single comma-separated string to keep the storage shape tiny — fine
  /// up to a few thousand entries. Calendar heatmap is the planned use.
  Future<List<DateTime>> getLoggedDatesThisMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_loggedDatesKey);
    if (raw == null || raw.isEmpty) return const <DateTime>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final out = <DateTime>[];
    for (final token in raw.split(',')) {
      final d = _parseDate(token);
      if (d != null && !d.isBefore(monthStart)) out.add(d);
    }
    return out;
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Record an "I logged something today" event. Idempotent within the
  /// same calendar day — calling repeatedly on the same day only counts
  /// as one day.
  ///
  /// Returns the *new* streak length (so the caller can decide whether
  /// to fire confetti or not).
  Future<int> recordActivity({DateTime? at}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = at ?? DateTime.now();
    final today = _truncate(now);
    final todayKey = _isoDate(today);

    final lastDateStr = prefs.getString(_lastLogDateKey);
    final lastDate = _parseDate(lastDateStr);

    int current = prefs.getInt(_currentCountKey) ?? 0;
    int longest = prefs.getInt(_longestCountKey) ?? 0;

    if (lastDateStr == todayKey) {
      // Already counted today — nothing to bump.
      return current;
    }

    if (lastDate != null) {
      final diff = today.difference(lastDate).inDays;
      if (diff == 1) {
        // Consecutive day → streak grows.
        current += 1;
      } else if (diff > 1) {
        // Streak broken → start fresh from 1.
        current = 1;
      }
      // diff == 0 covered above; diff < 0 = clock skew → treat as 1.
      if (diff <= 0) current = 1;
    } else {
      // First-ever log.
      current = 1;
    }

    if (current > longest) longest = current;

    await prefs.setString(_lastLogDateKey, todayKey);
    await prefs.setInt(_currentCountKey, current);
    await prefs.setInt(_longestCountKey, longest);
    await _appendLoggedDate(prefs, today);

    if (kDebugMode) {
      debugPrint('[Streak] activity @ $todayKey → current=$current longest=$longest');
    }
    return current;
  }

  /// Clear every streak value — used by the "delete my data" path.
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLogDateKey);
    await prefs.remove(_currentCountKey);
    await prefs.remove(_longestCountKey);
    await prefs.remove(_loggedDatesKey);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _appendLoggedDate(SharedPreferences prefs, DateTime date) async {
    final key = _isoDate(date);
    final raw = prefs.getString(_loggedDatesKey);
    final set = (raw == null || raw.isEmpty)
        ? <String>{}
        : raw.split(',').toSet();
    set.add(key);
    // Keep the string sorted lexicographically — ISO-8601 sorts correctly
    // as a string, so this doubles as a date-ordered list.
    final sorted = set.toList()..sort();
    await prefs.setString(_loggedDatesKey, sorted.join(','));
  }

  static DateTime _truncate(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _isoDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final p = s.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }
}