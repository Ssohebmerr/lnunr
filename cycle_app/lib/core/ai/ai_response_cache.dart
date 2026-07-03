import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On-disk cache for non-chat AI responses (daily briefing, weekly recap,
/// nutrition, patterns, etc.). Keyed by `(mode + cycleDay + dateKey + locale)`
/// and stored as JSON in SharedPreferences.
///
/// This dramatically reduces Gemini quota usage and improves perceived speed
/// for cards shown on every Home/Insights visit.
class AiResponseCache {
  AiResponseCache._();

  static const _storageKey = 'ai_response_cache_v1';
  static const Duration _defaultTtl = Duration(hours: 24);
  static const int _maxEntries = 40;

  /// Compute a stable cache key. `dateKey` defaults to today's YYYY-MM-DD so
  /// daily-rotating content (briefing, recap) refreshes naturally.
  static String makeKey({
    required String mode,
    int? cycleDay,
    String? phase,
    String? locale,
    String? extra,
    DateTime? at,
  }) {
    final d = at ?? DateTime.now();
    final dateKey = '${d.year.toString().padLeft(4, '0')}'
        '-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';
    final raw =
        '$mode|day=$cycleDay|phase=${phase ?? '-'}|loc=${locale ?? '-'}|date=$dateKey|extra=${extra ?? '-'}';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// Fetch a cached response if present and not expired.
  static Future<String?> get(String key, {Duration? ttl}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return null;

      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      final entry = map[key];
      if (entry is! Map) return null;

      final value = entry['v'] as String?;
      final ts = entry['t'] as int?;
      if (value == null || ts == null) return null;

      final age = DateTime.now().millisecondsSinceEpoch - ts;
      final maxAge = (ttl ?? _defaultTtl).inMilliseconds;
      if (age > maxAge) return null;

      return value;
    } catch (e) {
      if (kDebugMode) debugPrint('[AiResponseCache] get failed: $e');
      return null;
    }
  }

  /// Store a value in the cache. Trims old entries when exceeding [_maxEntries].
  static Future<void> set(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      Map<String, dynamic> map = {};
      if (raw != null && raw.isNotEmpty) {
        map = (jsonDecode(raw) as Map).cast<String, dynamic>();
      }

      map[key] = {
        'v': value,
        't': DateTime.now().millisecondsSinceEpoch,
      };

      // Cap size by dropping the oldest entries (LRU-ish by timestamp).
      if (map.length > _maxEntries) {
        final entries = map.entries.toList()
          ..sort((a, b) {
            final at = (a.value as Map)['t'] as int? ?? 0;
            final bt = (b.value as Map)['t'] as int? ?? 0;
            return at.compareTo(bt);
          });
        final toRemove = entries.take(map.length - _maxEntries).map((e) => e.key);
        for (final k in toRemove) {
          map.remove(k);
        }
      }

      await prefs.setString(_storageKey, jsonEncode(map));
    } catch (e) {
      if (kDebugMode) debugPrint('[AiResponseCache] set failed: $e');
    }
  }

  /// Drop the entire cache (e.g. on logout or language change).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
