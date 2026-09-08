import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A one-off cause the user says explains an unusual cycle.
///
/// These are the disruptions with a documented effect on cycle length. Each is
/// something the user knows and the app never could — which is exactly why
/// asking beats guessing.
enum CycleCause {
  illness('illness'),
  travel('travel'),
  stress('stress'),
  weightChange('weight_change'),
  medication('medication'),
  poorSleep('poor_sleep'),
  intenseExercise('intense_exercise');

  const CycleCause(this.storageKey);
  final String storageKey;

  static CycleCause? fromKey(String? key) {
    if (key == null) return null;
    for (final c in values) {
      if (c.storageKey == key) return c;
    }
    return null;
  }
}

/// What the user told us about one cycle.
class CycleAnnotation {
  const CycleAnnotation({required this.cycleStart, required this.causes});

  /// First day of the cycle this explains.
  final DateTime cycleStart;

  final Set<CycleCause> causes;

  bool get isEmpty => causes.isEmpty;

  Map<String, dynamic> toJson() => {
    'start': _dayKey(cycleStart),
    'causes': [for (final c in causes) c.storageKey],
  };

  static CycleAnnotation? fromJson(Map<String, dynamic> json) {
    final raw = json['start'] as String?;
    if (raw == null) return null;
    final start = DateTime.tryParse(raw);
    if (start == null) return null;

    return CycleAnnotation(
      cycleStart: DateTime(start.year, start.month, start.day),
      causes: {
        for (final c in (json['causes'] as List? ?? const []))
          if (CycleCause.fromKey(c?.toString()) != null)
            CycleCause.fromKey(c.toString())!,
      },
    );
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Stores why a cycle was unusual, so the predictor can learn from the user
/// instead of guessing.
///
/// The predictor's outlier filter is statistical: it can tell that a 45-day
/// cycle is far from the median, but not whether that was flu or the user's
/// actual pattern changing. The user knows. This is where she says so.
///
/// Local-only, like the ovulation log — none of this leaves the device.
class CycleAnnotationService {
  CycleAnnotationService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _storageKey = 'cycle_annotations_v1';

  Future<SharedPreferences> get _storage async =>
      _prefs ??= await SharedPreferences.getInstance();

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<CycleAnnotation>> loadAll() async {
    try {
      final prefs = await _storage;
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return const [];

      final list = jsonDecode(raw) as List<dynamic>;
      final out = <CycleAnnotation>[];
      for (final e in list) {
        final a = CycleAnnotation.fromJson(e as Map<String, dynamic>);
        if (a != null && !a.isEmpty) out.add(a);
      }
      out.sort((a, b) => a.cycleStart.compareTo(b.cycleStart));
      return out;
    } catch (e, st) {
      debugPrint('CycleAnnotationService.loadAll failed: $e\n$st');
      return const [];
    }
  }

  /// Replaces the annotation for [cycleStart]. An empty [causes] clears it —
  /// the user is allowed to change her mind, and a cleared cycle goes straight
  /// back into the baseline.
  Future<void> setCauses(DateTime cycleStart, Set<CycleCause> causes) async {
    final day = _dateOnly(cycleStart);
    final all = (await loadAll()).toList()
      ..removeWhere((a) => a.cycleStart == day);

    if (causes.isNotEmpty) {
      all.add(CycleAnnotation(cycleStart: day, causes: causes));
    }
    all.sort((a, b) => a.cycleStart.compareTo(b.cycleStart));

    final prefs = await _storage;
    await prefs.setString(
      _storageKey,
      jsonEncode([for (final a in all) a.toJson()]),
    );
  }

  Future<Set<CycleCause>> causesFor(DateTime cycleStart) async {
    final day = _dateOnly(cycleStart);
    for (final a in await loadAll()) {
      if (a.cycleStart == day) return a.causes;
    }
    return const {};
  }

  Future<bool> hasAnnotation(DateTime cycleStart) async =>
      (await causesFor(cycleStart)).isNotEmpty;

  /// Parallel flags for [cycleStarts] (chronological, oldest → newest), ready
  /// to hand to `SmartCyclePredictor.estimateNextPeriod`.
  ///
  /// A cycle length spans `cycleStarts[i] → cycleStarts[i + 1]`, so the flag
  /// for length *i* is the annotation on the cycle that **started** it — the
  /// disruption happened during that cycle, and that is what stretched it.
  Future<List<bool>> explainedFlagsFor(List<DateTime> cycleStarts) async {
    if (cycleStarts.length < 2) return const [];

    final annotated = {
      for (final a in await loadAll()) a.cycleStart,
    };
    if (annotated.isEmpty) return const [];

    return [
      for (var i = 0; i < cycleStarts.length - 1; i++)
        annotated.contains(_dateOnly(cycleStarts[i])),
    ];
  }

  /// Which causes the user reports most, for AI context and trends.
  Future<Map<String, int>> causeFrequencies() async {
    final counts = <String, int>{};
    for (final a in await loadAll()) {
      for (final c in a.causes) {
        counts[c.storageKey] = (counts[c.storageKey] ?? 0) + 1;
      }
    }
    return counts;
  }
}
