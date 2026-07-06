import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Stores the user's lightweight daily mood check-in on-device.
///
/// This is intentionally separate from the full symptom log: it's a one-tap
/// emotional pulse that personalizes the self-care tab and feeds the AI
/// whisper card. Keys use the shared mood vocabulary
/// (happy/calm/energetic/tired/sad/anxious/irritable).
class MoodService {
  MoodService._();

  static const _historyKey = 'selfcare_mood_history_v1';
  static const _maxHistory = 120;

  static String _dateKey([DateTime? at]) {
    final d = at ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}'
        '-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
  }

  /// The mood key logged today, or null if none yet.
  static Future<String?> todayMood() async {
    final history = await _readHistory();
    return history[_dateKey()];
  }

  /// Records (or replaces) today's mood.
  static Future<void> setTodayMood(String moodKey) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await _readHistory();
    history[_dateKey()] = moodKey;

    // Trim to the most recent entries to keep the blob small.
    if (history.length > _maxHistory) {
      final sortedKeys = history.keys.toList()..sort();
      final drop = sortedKeys.take(history.length - _maxHistory);
      for (final k in drop) {
        history.remove(k);
      }
    }
    await prefs.setString(_historyKey, jsonEncode(history));
  }

  /// Returns the last [days] mood entries newest-first as (date, moodKey).
  static Future<List<({String date, String mood})>> recent({int days = 7}) async {
    final history = await _readHistory();
    final keys = history.keys.toList()..sort((a, b) => b.compareTo(a));
    return keys
        .take(days)
        .map((k) => (date: k, mood: history[k]!))
        .toList();
  }

  static Future<Map<String, String>> _readHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }
}
