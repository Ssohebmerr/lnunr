import '../../features/cycle/data/cycle_bridge_service.dart';
import 'models/health_snapshot.dart';

/// Clinical patterns worth discussing with a physician. These are **never**
/// diagnoses — they are neutral observations derived from on-device data and
/// always surfaced with "discuss with your doctor" framing.
enum ClinicalFlagType {
  /// Average cycle shorter than the FIGO reference range (24–38 days).
  shortCycle,

  /// Average cycle longer than the FIGO reference range (24–38 days).
  longCycle,

  /// Large cycle-to-cycle variation (irregular cycles).
  irregularCycle,

  /// Bleeding longer than 8 days on average.
  prolongedPeriod,

  /// Average logged pain in the severe range.
  highPain,
}

/// A single clinical observation. [value] carries the interpolated number
/// (days for cycle/period flags; unused for [ClinicalFlagType.highPain]).
class ClinicalFlag {
  const ClinicalFlag(this.type, {this.value = 0});

  final ClinicalFlagType type;
  final int value;
}

/// Structured clinical metrics computed entirely on-device from the cycle
/// history. Feeds the printable report, the exports, and the AI context so the
/// AI reasons over the same numbers the physician sees.
class DoctorReportMetrics {
  const DoctorReportMetrics({
    this.analyzedCycleCount = 0,
    this.totalCycleCount = 0,
    this.avgCycleLength,
    this.minCycleLength,
    this.maxCycleLength,
    this.cycleVariability,
    this.avgPeriodDuration,
    this.minPeriodDuration,
    this.maxPeriodDuration,
    this.lastPeriodStart,
    this.firstCycleDate,
    this.lastCycleDate,
    this.averagePainLevel,
    this.flags = const [],
  });

  /// Number of completed cycles (cycle length > 0) used for the statistics.
  final int analyzedCycleCount;

  /// All cycles in the history, including the in-progress one.
  final int totalCycleCount;

  final int? avgCycleLength;
  final int? minCycleLength;
  final int? maxCycleLength;

  /// max − min cycle length (spread). Higher means less regular.
  final int? cycleVariability;

  final int? avgPeriodDuration;
  final int? minPeriodDuration;
  final int? maxPeriodDuration;

  /// Last menstrual period start (most recent logged period).
  final DateTime? lastPeriodStart;

  /// Bounds of the analyzed window (earliest → latest cycle start).
  final DateTime? firstCycleDate;
  final DateTime? lastCycleDate;

  /// Average logged pain over the last 30 days, on the 0–4 scale.
  final double? averagePainLevel;

  final List<ClinicalFlag> flags;

  bool get hasCycleStats => avgCycleLength != null && analyzedCycleCount > 0;

  bool get hasRangeData =>
      minCycleLength != null &&
      maxCycleLength != null &&
      minCycleLength != maxCycleLength;

  bool get isEmpty => !hasCycleStats && averagePainLevel == null && flags.isEmpty;

  /// Compact numeric summary handed to the AI so its clinical notes reference
  /// the exact same figures printed on the report.
  Map<String, dynamic> toContextMap() => {
        if (analyzedCycleCount > 0) 'analyzedCycleCount': analyzedCycleCount,
        if (avgCycleLength != null) 'avgCycleLengthDays': avgCycleLength,
        if (minCycleLength != null) 'minCycleLengthDays': minCycleLength,
        if (maxCycleLength != null) 'maxCycleLengthDays': maxCycleLength,
        if (cycleVariability != null) 'cycleVariabilityDays': cycleVariability,
        if (avgPeriodDuration != null) 'avgPeriodDurationDays': avgPeriodDuration,
        if (minPeriodDuration != null) 'minPeriodDurationDays': minPeriodDuration,
        if (maxPeriodDuration != null) 'maxPeriodDurationDays': maxPeriodDuration,
        if (lastPeriodStart != null)
          'lastPeriodStart': _iso(lastPeriodStart!),
        if (averagePainLevel != null)
          'averagePainLevel_0to4': averagePainLevel,
        if (flags.isNotEmpty)
          'clinicalFlags': flags.map((f) => f.type.name).toList(),
      };

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Turns raw cycle history into [DoctorReportMetrics]. Pure, offline, and
/// side-effect free — safe to call on every report load.
class DoctorReportAnalyzer {
  DoctorReportAnalyzer._();

  // FIGO clinical reference thresholds for people aged 18–45. Flags remain
  // discussion prompts, never diagnoses. See: Munro et al., 2018.
  static const _shortCycleDays = 24;
  static const _longCycleDays = 38;
  static const _prolongedPeriodDays = 8;
  static const _severePain = 3.0; // on the 0–4 PainLevel scale

  static DoctorReportMetrics analyze({
    required CycleReportData report,
    HealthSnapshot? snapshot,
    int? patientAge,
  }) {
    final cycles = report.cycles;

    // The widget returns newest → oldest and deliberately includes the
    // current, unfinished cycle first. Its length is only days elapsed so far
    // and must never influence clinical averages or flags.
    final completedCycles = cycles
        .where((c) => (c.cycleEndDate ?? '').trim().isNotEmpty)
        .toList();

    final cycleLengths = <int>[];
    final periodDurations = <int>[];
    for (final c in completedCycles) {
      final cl = c.cycleLength ?? 0;
      if (cl > 0 && cl < 120) cycleLengths.add(cl);
      final pd = c.periodDuration ?? 0;
      if (pd > 0 && pd < 30) periodDurations.add(pd);
    }

    // Dashboard averages are produced by the same widget and include the
    // unfinished cycle too, so they are intentionally not used as a fallback.
    final avgCycle = _avg(cycleLengths);
    final minCycle = _min(cycleLengths);
    final maxCycle = _max(cycleLengths);
    final variability =
        (minCycle != null && maxCycle != null) ? maxCycle - minCycle : null;

    final avgPeriod = _avg(periodDurations);
    final minPeriod = _min(periodDurations);
    final maxPeriod = _max(periodDurations);

    // Last menstrual period = most recent logged period start.
    DateTime? lmp;
    for (final c in cycles) {
      final d = _parse(c.periodStartDate ?? c.cycleStartDate);
      if (d != null && (lmp == null || d.isAfter(lmp))) {
        lmp = d;
      }
    }

    // Analyzed window bounds contain completed cycles only, just like the
    // metrics. LMP above intentionally still includes the current cycle.
    DateTime? first;
    DateTime? last;
    for (final c in completedCycles) {
      final d = _parse(c.cycleStartDate ?? c.periodStartDate);
      if (d == null) continue;
      if (first == null || d.isBefore(first)) first = d;
      if (last == null || d.isAfter(last)) last = d;
    }

    final avgPain = snapshot?.averagePainLevel;

    final flags = <ClinicalFlag>[];
    if (avgCycle != null) {
      if (avgCycle < _shortCycleDays) {
        flags.add(ClinicalFlag(ClinicalFlagType.shortCycle, value: avgCycle));
      } else if (avgCycle > _longCycleDays) {
        flags.add(ClinicalFlag(ClinicalFlagType.longCycle, value: avgCycle));
      }
    }
    if (variability != null &&
        cycleLengths.length >= 3 &&
        variability > _regularityLimitDays(patientAge)) {
      flags.add(ClinicalFlag(ClinicalFlagType.irregularCycle, value: variability));
    }
    if (avgPeriod != null && avgPeriod > _prolongedPeriodDays) {
      flags.add(ClinicalFlag(ClinicalFlagType.prolongedPeriod, value: avgPeriod));
    }
    if (avgPain != null && avgPain >= _severePain) {
      flags.add(const ClinicalFlag(ClinicalFlagType.highPain));
    }

    return DoctorReportMetrics(
      analyzedCycleCount: cycleLengths.length,
      totalCycleCount: cycles.length,
      avgCycleLength: avgCycle,
      minCycleLength: minCycle,
      maxCycleLength: maxCycle,
      cycleVariability: variability,
      avgPeriodDuration: avgPeriod,
      minPeriodDuration: minPeriod,
      maxPeriodDuration: maxPeriod,
      lastPeriodStart: lmp,
      firstCycleDate: first,
      lastCycleDate: last,
      averagePainLevel: avgPain,
      flags: flags,
    );
  }

  static int? _avg(List<int> xs) =>
      xs.isEmpty ? null : (xs.reduce((a, b) => a + b) / xs.length).round();

  static int? _min(List<int> xs) =>
      xs.isEmpty ? null : xs.reduce((a, b) => a < b ? a : b);

  static int? _max(List<int> xs) =>
      xs.isEmpty ? null : xs.reduce((a, b) => a > b ? a : b);

  /// FIGO uses a 7-day maximum shortest-to-longest variation for ages 26–41
  /// and 9 days for ages 18–25 and 42–45. When age is unavailable, use the
  /// less alarming 9-day limit rather than producing a false warning.
  static int _regularityLimitDays(int? age) =>
      age != null && age >= 26 && age <= 41 ? 7 : 9;

  static DateTime? _parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }
}
