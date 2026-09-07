import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/cycle/luteal_calibration.dart';

/// Result of a quick daily-log write (from chat actions or shortcuts).
enum DailyLogWriteStatus { success, notReady, notMatched, failed }

class DailyLogWriteResult {
  const DailyLogWriteResult(this.status, {this.matchedName});

  final DailyLogWriteStatus status;
  final String? matchedName;

  bool get ok => status == DailyLogWriteStatus.success;
}

/// Writes single symptoms / moods / water into the SAME encrypted cycle store
/// that the daily log screen reads and writes. This keeps the chat, the log
/// screen, the home "today" card, and the AI snapshot on one source of truth.
///
/// Every write MERGES with today's existing entry instead of overwriting it,
/// so logging a mood from chat never wipes symptoms already logged elsewhere.
class DailyLogWriter {
  DailyLogWriter._();

  /// English keyword -> symptom id, for the lightweight `[[log_*:value]]` tags
  /// the AI emits. Falls back to fuzzy name matching against the localized
  /// symptom list when a keyword isn't listed here.
  static const Map<String, int> _aliases = {
    // Feelings
    'sensitive': 21001,
    'happy': 21003,
    'frisky': 21004,
    'mood swings': 21005,
    'moodswings': 21005,
    'irritated': 21006,
    'sad': 21007,
    'tension': 21008,
    'angry': 21009,
    'confident': 21131,
    'insecure': 21010,
    'grateful': 21011,
    'anxiety': 21012,
    'anxious': 21012,
    'excited': 21013,
    // Mind
    'calm': 21014,
    'distracted': 21015,
    'focused': 21016,
    'depressed': 21017,
    'confused': 21018,
    'stressed': 21019,
    'stress': 21019,
    'motivated': 21020,
    'creative': 21022,
    'productive': 21023,
    // Energy
    'exhausted': 21037,
    'tired': 21038,
    'ok': 21039,
    'energetic': 21040,
    'energized': 21041,
    // Symptoms
    'everything well': 21047,
    'fine': 21047,
    'cramps': 21048,
    'tender breasts': 21049,
    'headache': 21050,
    'acne': 21051,
    'backache': 21052,
    'back pain': 21052,
    'abdominal pain': 21053,
    'fatigue': 21054,
    // Pain
    'pain free': 21055,
    'period cramps': 21056,
    'ovulation pain': 21057,
    'breast tenderness': 21058,
    'migraine': 21060,
    'lower back': 21062,
    'leg pain': 21063,
    'joint pain': 21064,
  };

  static MenstrualCycleWidget? get _api => MenstrualCycleWidget.instance;

  /// Finds the [SymptomsData] (name + id) matching [query] from the localized
  /// default symptom catalogue, using the alias map first, then fuzzy match.
  static SymptomsData? _findSymptom(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;

    final id = _aliases[q];

    for (final category in defaultSymptomsData) {
      for (final symptom in category.symptomsData ?? <SymptomsData>[]) {
        if (id != null && symptom.symptomId == id) {
          return SymptomsData(
            symptomName: symptom.symptomName,
            symptomId: symptom.symptomId,
            isSelected: true,
          );
        }
      }
    }

    // Fuzzy fallback: match by localized display name.
    for (final category in defaultSymptomsData) {
      for (final symptom in category.symptomsData ?? <SymptomsData>[]) {
        final name = symptom.symptomName?.trim().toLowerCase() ?? '';
        if (name.isEmpty) continue;
        if (name == q || name.contains(q) || q.contains(name)) {
          return SymptomsData(
            symptomName: symptom.symptomName,
            symptomId: symptom.symptomId,
            isSelected: true,
          );
        }
      }
    }
    return null;
  }

  static Future<int> _currentCycleDay() async {
    try {
      return await _api!.getCurrentCycleDay();
    } catch (_) {
      return 0;
    }
  }

  /// Logs a mood/feeling/symptom by name into today's entry (merged).
  static Future<DailyLogWriteResult> logSymptom(String name) async {
    final api = _api;
    if (api == null) return const DailyLogWriteResult(DailyLogWriteStatus.notReady);

    final match = _findSymptom(name);
    if (match == null) {
      return const DailyLogWriteResult(DailyLogWriteStatus.notMatched);
    }

    return _saveMerged(extraSymptoms: [match], matchedName: match.symptomName);
  }

  /// Logs water cups into today's entry (merged, preserves symptoms).
  static Future<DailyLogWriteResult> logWater(int cups) async {
    final api = _api;
    if (api == null) return const DailyLogWriteResult(DailyLogWriteStatus.notReady);
    final clamped = cups.clamp(0, 99);
    return _saveMerged(waterCupsOverride: clamped);
  }

  /// Reads today's log, applies the requested change, and writes it back
  /// without losing any previously logged field.
  static Future<DailyLogWriteResult> _saveMerged({
    List<SymptomsData> extraSymptoms = const [],
    int? waterCupsOverride,
    String? matchedName,
  }) async {
    final api = _api;
    if (api == null) return const DailyLogWriteResult(DailyLogWriteStatus.notReady);

    final today = DateTime.now();

    try {
      final existing = await api.getSymptomsData(today);

      // Merge symptoms, de-duplicating by id.
      final merged = <int, SymptomsData>{};
      for (final s in existing.symptomData ?? <SymptomsData>[]) {
        final sid = s.symptomId;
        if (sid != null) {
          merged[sid] = SymptomsData(
            symptomName: s.symptomName,
            symptomId: sid,
            isSelected: true,
          );
        }
      }
      for (final s in extraSymptoms) {
        final sid = s.symptomId;
        if (sid != null) merged[sid] = s;
      }

      final water = waterCupsOverride != null
          ? waterCupsOverride.toString()
          : (existing.waterValue?.trim().isNotEmpty == true
              ? existing.waterValue!.trim()
              : '0');

      final bodyTemp = existing.bodyTemperature?.trim().isNotEmpty == true
          ? existing.bodyTemperature!.trim()
          : '0';
      final weight = existing.weight?.trim().isNotEmpty == true
          ? existing.weight!.trim()
          : '0';
      final meditation = existing.meditationTime?.trim().isNotEmpty == true
          ? existing.meditationTime!.trim()
          : '0';

      final (bed, wake) = _parseSleep(existing.sleepTime);

      var ok = false;
      await api.saveSymptomsLogs(
        userSymptomsData: merged.values.toList(),
        cycleDay: await _currentCycleDay(),
        symptomsLogDate: today,
        waterValue: water,
        bodyTemperature: bodyTemp,
        weight: weight,
        meditationTime: meditation,
        sleepBedTime: bed,
        sleepWakeUpTime: wake,
        onSuccess: (_) => ok = true,
        onError: () => ok = false,
      );

      // The temperature scan is cached per refresh; a fresh log has to be
      // visible to ovulation detection immediately.
      if (ok) LutealCalibration.sharedBbtService.invalidate();

      return DailyLogWriteResult(
        ok ? DailyLogWriteStatus.success : DailyLogWriteStatus.failed,
        matchedName: matchedName,
      );
    } catch (_) {
      return const DailyLogWriteResult(DailyLogWriteStatus.failed);
    }
  }

  /// Existing sleep is stored as "H:MTh:m" (bed T wake). Restore both times so
  /// a merge write never erases a previously logged sleep window.
  static (TimeOfDay?, TimeOfDay?) _parseSleep(String? raw) {
    if (raw == null || !raw.contains('T')) return (null, null);
    try {
      final parts = raw.split('T');
      final bedParts = parts[0].split(':');
      final wakeParts = parts[1].split(':');
      final bed = TimeOfDay(
        hour: int.parse(bedParts[0]),
        minute: int.parse(bedParts[1]),
      );
      final wake = TimeOfDay(
        hour: int.parse(wakeParts[0]),
        minute: int.parse(wakeParts[1]),
      );
      return (bed, wake);
    } catch (_) {
      return (null, null);
    }
  }
}
