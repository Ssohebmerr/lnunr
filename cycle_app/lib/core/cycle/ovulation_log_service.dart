import 'dart:convert';

import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Type of fertility signal the user logged.
enum OvulationLogType {
  ovulation('ovulation'),
  lhPositive('lh_positive');

  const OvulationLogType(this.storageKey);
  final String storageKey;

  static OvulationLogType? fromKey(String? key) {
    if (key == null) return null;
    for (final t in values) {
      if (t.storageKey == key) return t;
    }
    return null;
  }
}

/// A single ovulation or LH-positive log entry (stored locally only).
class OvulationLogEntry {
  const OvulationLogEntry({required this.date, required this.type});

  final DateTime date;
  final OvulationLogType type;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Map<String, dynamic> toJson() => {
        'date': _dateOnly(date).toIso8601String(),
        'type': type.storageKey,
      };

  factory OvulationLogEntry.fromJson(Map<String, dynamic> json) {
    return OvulationLogEntry(
      date: DateTime.parse(json['date'] as String),
      type: OvulationLogType.fromKey(json['type'] as String?) ??
          OvulationLogType.ovulation,
    );
  }
}

/// Local ovulation / LH logs used to personalize luteal-phase length.
class OvulationLogService {
  OvulationLogService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _storageKey = 'ovulation_logs_v1';

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<OvulationLogEntry>> loadEntries() async {
    final prefs = await _storage;
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => OvulationLogEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (_) {
      return [];
    }
  }

  Future<void> _save(List<OvulationLogEntry> entries) async {
    final prefs = await _storage;
    final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> logToday(OvulationLogType type) =>
      logDate(DateTime.now(), type);

  Future<void> logDate(DateTime date, OvulationLogType type) async {
    final day = _dateOnly(date);
    final entries = await loadEntries()
      ..removeWhere((e) => _dateOnly(e.date) == day);
    entries.add(OvulationLogEntry(date: day, type: type));
    entries.sort((a, b) => a.date.compareTo(b.date));
    await _save(entries);
  }

  Future<void> remove(DateTime date) async {
    final day = _dateOnly(date);
    final entries = await loadEntries()
      ..removeWhere((e) => _dateOnly(e.date) == day);
    await _save(entries);
  }

  Future<bool> hasLogOn(DateTime date) async {
    final day = _dateOnly(date);
    final entries = await loadEntries();
    return entries.any((e) => _dateOnly(e.date) == day);
  }

  Future<int> entryCount() async => (await loadEntries()).length;

  /// Luteal lengths (days from ovulation signal to next period start) per
  /// completed cycle, clamped to a clinically plausible range.
  Future<List<int>> measuredLutealLengths() async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) return [];

    final periods = await widget.getAllPeriodsDetails();
    if (periods.length < 2) return [];

    final entries = await loadEntries();
    if (entries.isEmpty) return [];

    final luteals = <int>[];
    for (var i = 0; i < periods.length - 1; i++) {
      final nextPeriodStart = _parseDay(periods[i].cycleStartDate);
      final cycleStart = _parseDay(periods[i + 1].cycleStartDate);
      if (nextPeriodStart == null || cycleStart == null) continue;

      for (final entry in entries.reversed) {
        final d = _dateOnly(entry.date);
        if (!d.isBefore(cycleStart) && d.isBefore(nextPeriodStart)) {
          final luteal = nextPeriodStart.difference(d).inDays;
          if (luteal >= 10 && luteal <= 16) {
            luteals.add(luteal);
          }
          break;
        }
      }
    }
    return luteals;
  }

  /// Drops entries that no longer fall inside any known cycle window.
  Future<void> pruneInvalidEntries() async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) return;

    final periods = await widget.getAllPeriodsDetails();
    if (periods.isEmpty) {
      await _save([]);
      return;
    }

    final oldest = _parseDay(periods.last.cycleStartDate);
    if (oldest == null) return;

    final entries = await loadEntries();
    final kept = entries.where((e) => !e.date.isBefore(oldest)).toList();
    if (kept.length != entries.length) {
      await _save(kept);
    }
  }

  DateTime? _parseDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return _dateOnly(DateTime.parse(raw));
    } catch (_) {
      return null;
    }
  }
}
