import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// A thermal shift detected inside one specific cycle.
class BbtCycleShift {
  const BbtCycleShift({
    required this.cycleStart,
    required this.nextCycleStart,
    required this.shift,
    this.lutealLength,
  });

  final DateTime cycleStart;
  final DateTime? nextCycleStart;
  final BbtShift shift;

  /// Ovulation → next period start, only set for completed cycles whose luteal
  /// length landed in the clinical 10–16 day range.
  final int? lutealLength;

  bool get isCurrentCycle => nextCycleStart == null;
}

/// One temperature reading positioned by cycle day, for charting.
class CycleTemperaturePoint {
  const CycleTemperaturePoint({required this.cycleDay, required this.celsius});

  final int cycleDay;
  final double celsius;
}

/// A single cycle's temperature curve — the only view of BBT that means
/// anything. A monthly average flattens the post-ovulatory shift into noise.
class CycleTemperatureSeries {
  const CycleTemperatureSeries({
    required this.cycleStart,
    required this.points,
    required this.isCurrentCycle,
    this.coverline,
    this.ovulationCycleDay,
  });

  final DateTime cycleStart;
  final List<CycleTemperaturePoint> points;
  final bool isCurrentCycle;

  /// Threshold the confirming readings had to clear, when a shift was found.
  final double? coverline;

  /// Cycle day of the detected ovulation, when a shift was found.
  final int? ovulationCycleDay;

  bool get hasShift => ovulationCycleDay != null;
}

/// Turns the user's logged basal body temperatures into real ovulation
/// evidence: per-cycle thermal shifts, personalized luteal lengths, and
/// confirmation that ovulation happened in the cycle currently running.
///
/// Everything here is derived from data the user already logs — the app was
/// storing temperatures and charting them, but never using them to predict.
class BbtOvulationService {
  BbtOvulationService({MenstrualCycleWidget? widget}) : _override = widget;

  final MenstrualCycleWidget? _override;

  MenstrualCycleWidget? get _widget =>
      _override ?? MenstrualCycleWidget.instance;

  /// How far back to pull temperature logs. Twelve cycles of history is enough
  /// for luteal calibration without scanning the whole database.
  static const int _historyDays = 400;

  _BbtScan? _cache;
  DateTime? _cachedAt;

  /// Cached for a short window because the dashboard, the AI context engine and
  /// the luteal provider all ask for this within the same refresh.
  static const Duration _cacheTtl = Duration(minutes: 5);

  void invalidate() {
    _cache = null;
    _cachedAt = null;
  }

  /// Every cycle in recent history that produced a confirmed thermal shift,
  /// oldest → newest.
  Future<List<BbtCycleShift>> shifts() async => (await _scan()).shifts;

  Future<_BbtScan> _scan() async {
    final cachedAt = _cachedAt;
    final cache = _cache;
    if (cache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cache;
    }

    final result = await _compute();
    _cache = result;
    _cachedAt = DateTime.now();
    return result;
  }

  Future<_BbtScan> _compute() async {
    final widget = _widget;
    if (widget == null) return _BbtScan.empty;

    try {
      final now = DateTime.now();
      final logs = await widget.getSymptomsLogReport(
        startDate: now.subtract(const Duration(days: _historyDays)),
        endDate: now,
      );

      final readings = <BbtReading>[];
      for (final log in logs) {
        final reading = BbtReading.parse(
          date: log.logDate,
          raw: log.bodyTemperature,
          unit: log.bodyTemperatureUnit,
        );
        if (reading != null) readings.add(reading);
      }
      if (readings.isEmpty) return _BbtScan.empty;

      // getAllPeriodsDetails() is newest → oldest; walk it chronologically so
      // each cycle knows where the following one starts.
      final periods = (await widget.getAllPeriodsDetails()).reversed.toList();
      final starts = <DateTime>[];
      for (final p in periods) {
        final d = _parseDay(p.cycleStartDate);
        if (d != null) starts.add(d);
      }
      if (starts.isEmpty) return _BbtScan.empty;
      starts.sort();

      final result = <BbtCycleShift>[];
      for (var i = 0; i < starts.length; i++) {
        final cycleStart = starts[i];
        final nextStart = i + 1 < starts.length ? starts[i + 1] : null;

        final shift = BbtAnalyzer.detectShift(
          readings: readings,
          cycleStart: cycleStart,
          nextCycleStart: nextStart,
        );
        if (shift == null) continue;

        result.add(
          BbtCycleShift(
            cycleStart: cycleStart,
            nextCycleStart: nextStart,
            shift: shift,
            lutealLength: nextStart == null
                ? null
                : BbtAnalyzer.lutealLengthFrom(
                    shift: shift,
                    nextCycleStart: nextStart,
                  ),
          ),
        );
      }
      return _BbtScan(readings: readings, cycleStarts: starts, shifts: result);
    } catch (e, st) {
      debugPrint('BbtOvulationService failed: $e\n$st');
      return _BbtScan.empty;
    }
  }

  /// Temperature curve for the most recent cycle that has enough readings to
  /// be worth drawing.
  ///
  /// A cycle is the only meaningful frame for BBT: averaging temperatures by
  /// calendar month flattens the post-ovulatory shift into nothing.
  Future<CycleTemperatureSeries?> latestCycleSeries({
    int minReadings = 6,
  }) async {
    final scan = await _scan();
    if (scan.cycleStarts.isEmpty || scan.readings.isEmpty) return null;

    for (var i = scan.cycleStarts.length - 1; i >= 0; i--) {
      final start = scan.cycleStarts[i];
      final next = i + 1 < scan.cycleStarts.length
          ? scan.cycleStarts[i + 1]
          : null;

      final points = <CycleTemperaturePoint>[];
      for (final r in scan.readings) {
        if (r.date.isBefore(start)) continue;
        if (next != null && !r.date.isBefore(next)) continue;
        points.add(
          CycleTemperaturePoint(
            cycleDay: r.date.difference(start).inDays + 1,
            celsius: r.celsius,
          ),
        );
      }
      if (points.length < minReadings) continue;
      points.sort((a, b) => a.cycleDay.compareTo(b.cycleDay));

      final shift = scan.shifts
          .where((s) => s.cycleStart == start)
          .map((s) => s.shift)
          .firstOrNull;

      return CycleTemperatureSeries(
        cycleStart: start,
        points: points,
        isCurrentCycle: next == null,
        coverline: shift?.coverline,
        ovulationCycleDay: shift == null
            ? null
            : shift.ovulationDate.difference(start).inDays + 1,
      );
    }
    return null;
  }

  /// Luteal lengths measured from temperature, oldest → newest. These feed the
  /// same calibration path as manually logged ovulation/LH signals.
  Future<List<int>> measuredLutealLengths() async {
    final all = await shifts();
    return [
      for (final s in all)
        if (s.lutealLength != null) s.lutealLength!,
    ];
  }

  /// The thermal shift for the cycle currently in progress, if temperature has
  /// already confirmed ovulation this cycle.
  Future<BbtCycleShift?> currentCycleShift() async {
    final all = await shifts();
    if (all.isEmpty) return null;
    final last = all.last;
    return last.isCurrentCycle ? last : null;
  }

  /// Ovulation date confirmed by temperature in the current cycle, or null.
  Future<DateTime?> confirmedOvulationDate() async =>
      (await currentCycleShift())?.shift.ovulationDate;

  static DateTime? _parseDay(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final d = DateTime.parse(raw);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      return null;
    }
  }
}

/// One pass over the temperature log, shared by every consumer in a refresh.
class _BbtScan {
  const _BbtScan({
    required this.readings,
    required this.cycleStarts,
    required this.shifts,
  });

  final List<BbtReading> readings;
  final List<DateTime> cycleStarts;
  final List<BbtCycleShift> shifts;

  static const empty = _BbtScan(readings: [], cycleStarts: [], shifts: []);
}
