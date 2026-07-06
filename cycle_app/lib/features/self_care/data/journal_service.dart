import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A single journal entry, stored on-device only.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.text,
    this.prompt,
    this.mood,
  });

  final String id;
  final DateTime createdAt;
  final String text;
  final String? prompt;
  final String? mood;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'text': text,
        if (prompt != null) 'prompt': prompt,
        if (mood != null) 'mood': mood,
      };

  static JournalEntry fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'] as String,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        text: j['text'] as String? ?? '',
        prompt: j['prompt'] as String?,
        mood: j['mood'] as String?,
      );
}

/// Multi-entry journal stored as a JSON list in SharedPreferences.
/// Replaces the old single-string journal (which overwrote itself on save);
/// legacy content is migrated into the first entry automatically.
class JournalService {
  JournalService._();

  static const _key = 'selfcare_journal_entries_v1';
  static const _legacyKey = 'self_care_journal';

  /// All entries, newest first.
  static Future<List<JournalEntry>> all() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs);

    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  static Future<JournalEntry> add({
    required String text,
    String? prompt,
    String? mood,
  }) async {
    final entries = await all();
    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      text: text.trim(),
      prompt: prompt,
      mood: mood,
    );
    entries.insert(0, entry);
    await _save(entries);
    return entry;
  }

  static Future<void> update(String id, String text) async {
    final entries = await all();
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final old = entries[idx];
    entries[idx] = JournalEntry(
      id: old.id,
      createdAt: old.createdAt,
      text: text.trim(),
      prompt: old.prompt,
      mood: old.mood,
    );
    await _save(entries);
  }

  static Future<void> delete(String id) async {
    final entries = await all();
    entries.removeWhere((e) => e.id == id);
    await _save(entries);
  }

  static Future<int> count() async => (await all()).length;

  static Future<void> _save(List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  /// One-time migration of the old single-string journal into an entry.
  static Future<void> _migrateLegacy(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyKey);
    if (legacy == null || legacy.trim().isEmpty) return;
    if ((prefs.getString(_key) ?? '').isNotEmpty) {
      await prefs.remove(_legacyKey);
      return;
    }
    final entry = JournalEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      text: legacy.trim(),
    );
    await prefs.setString(_key, jsonEncode([entry.toJson()]));
    await prefs.remove(_legacyKey);
  }
}
