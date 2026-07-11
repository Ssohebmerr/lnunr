import 'dart:math';

/// Evidence-informed cycle prediction: learns from completed cycles, weights
/// recent history, uses median for irregular patterns, and rolls forward when
/// a period is late.
class SmartCyclePredictor {
  SmartCyclePredictor._();

  static const int minValidCycleDays = 21;
  static const int maxValidCycleDays = 45;
  static const int defaultLutealDays = 14;
  static const int minLutealDays = 10;
  static const int maxLutealDays = 16;

  /// FIGO-normal cycle lengths only — filters logging noise.
  static List<int> filterValidCycleLengths(List<int> lengths) {
    return lengths
        .where((d) => d >= minValidCycleDays && d <= maxValidCycleDays)
        .toList();
  }

  static double regularityScore(List<int> completedLengths) {
    final valid = filterValidCycleLengths(completedLengths);
    if (valid.length < 2) return 0;
    final mean = valid.reduce((a, b) => a + b) / valid.length;
    if (mean <= 0) return 0;
    final variance =
        valid.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
            valid.length;
    final sd = sqrt(variance);
    return (100 - (sd / mean) * 100).clamp(0, 100);
  }

  /// Recent cycles count more; irregular users get the median of recent cycles.
  static int effectiveCycleLength({
    required List<int> completedLengths,
    required int configuredFallback,
  }) {
    final valid = filterValidCycleLengths(completedLengths);
    if (valid.isEmpty) {
      return configuredFallback.clamp(minValidCycleDays, maxValidCycleDays);
    }
    if (valid.length == 1) {
      return _blend(valid.first, configuredFallback);
    }

    final score = regularityScore(valid);
    final recent = valid.length > 6 ? valid.sublist(valid.length - 6) : valid;

    if (score < 75) {
      return _medianInt(recent);
    }
    return _weightedMean(recent).round();
  }

  static int effectivePeriodDuration({
    required List<int> completedDurations,
    required int configuredFallback,
  }) {
    final valid =
        completedDurations.where((d) => d >= 1 && d <= 10).toList(growable: false);
    if (valid.isEmpty) return configuredFallback.clamp(1, 10);
    if (valid.length == 1) return valid.first;
    return _weightedMean(valid).round().clamp(1, 10);
  }

  static int lutealPhaseDays({
    required int effectiveCycleLength,
    List<int> completedLengths = const [],
    List<int> measuredLutealLengths = const [],
  }) {
    if (measuredLutealLengths.length >= 2) {
      final recent = measuredLutealLengths.length > 4
          ? measuredLutealLengths.sublist(measuredLutealLengths.length - 4)
          : measuredLutealLengths;
      final weighted = _weightedMean(recent).round();
      return weighted.clamp(minLutealDays, maxLutealDays);
    }
    if (measuredLutealLengths.length == 1) {
      return measuredLutealLengths.first.clamp(minLutealDays, maxLutealDays);
    }
    if (completedLengths.length >= 4) {
      final score = regularityScore(completedLengths);
      if (score >= 80) return defaultLutealDays;
    }
    return defaultLutealDays.clamp(minLutealDays, maxLutealDays);
  }

  /// Next period start, advancing across missed cycles when the user is late.
  static DateTime nextPeriodStart({
    required DateTime lastPeriodStart,
    required int effectiveCycleLength,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    var next = _dateOnly(lastPeriodStart)
        .add(Duration(days: effectiveCycleLength));
    while (next.isBefore(today)) {
      next = next.add(Duration(days: effectiveCycleLength));
    }
    return next;
  }

  static DateTime nextOvulation({
    required DateTime lastPeriodStart,
    required int effectiveCycleLength,
    int? lutealDays,
    DateTime? now,
  }) {
    final luteal = (lutealDays ?? defaultLutealDays)
        .clamp(minLutealDays, maxLutealDays);
    final today = _dateOnly(now ?? DateTime.now());
    final last = _dateOnly(lastPeriodStart);

    var cycleStart = last;
    while (true) {
      final cycleEnd = cycleStart.add(Duration(days: effectiveCycleLength));
      final ovulation = cycleEnd.subtract(Duration(days: luteal));
      if (!ovulation.isBefore(today)) return ovulation;
      cycleStart = cycleEnd;
    }
  }

  /// ±window for irregular cycles (days). Regular users get a tight band.
  static int predictionWindowDays(List<int> completedLengths) {
    final valid = filterValidCycleLengths(completedLengths);
    if (valid.length < 2) return 2;
    final score = regularityScore(valid);
    if (score >= 89) return 1;
    if (score >= 75) return 2;
    final mean = valid.reduce((a, b) => a + b) / valid.length;
    final sd = sqrt(
      valid.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
          valid.length,
    );
    return sd.round().clamp(2, 5);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _blend(int learned, int configured) {
    final blended = (learned * 0.7 + configured * 0.3).round();
    return blended.clamp(minValidCycleDays, maxValidCycleDays);
  }

  static double _weightedMean(List<int> values) {
    var totalWeight = 0.0;
    var weightedSum = 0.0;
    for (var i = 0; i < values.length; i++) {
      final w = pow(1.35, i).toDouble();
      weightedSum += values[i] * w;
      totalWeight += w;
    }
    return weightedSum / totalWeight;
  }

  static int _medianInt(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }
}
