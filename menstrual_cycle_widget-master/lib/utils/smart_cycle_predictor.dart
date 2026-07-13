import 'dart:math';

enum CyclePredictionConfidence { learning, moderate, strong }

/// Walk-forward evidence showing how this predictor performed on the user's
/// own completed cycles.
class CyclePredictionAccuracy {
  const CyclePredictionAccuracy({
    required this.evaluatedCycles,
    required this.withinOneDay,
    required this.withinTwoDays,
    required this.withinThreeDays,
    required this.withinPersonalWindow,
    required this.meanAbsoluteError,
    required this.medianAbsoluteError,
    required this.p80AbsoluteError,
  });

  final int evaluatedCycles;
  final int withinOneDay;
  final int withinTwoDays;
  final int withinThreeDays;
  final int withinPersonalWindow;
  final double meanAbsoluteError;
  final double medianAbsoluteError;
  final int p80AbsoluteError;

  bool get hasPersonalEvidence => evaluatedCycles >= 3;

  double get withinTwoDaysRate =>
      evaluatedCycles == 0 ? 0 : withinTwoDays / evaluatedCycles;

  double get withinPersonalWindowRate =>
      evaluatedCycles == 0 ? 0 : withinPersonalWindow / evaluatedCycles;

  static const empty = CyclePredictionAccuracy(
    evaluatedCycles: 0,
    withinOneDay: 0,
    withinTwoDays: 0,
    withinThreeDays: 0,
    withinPersonalWindow: 0,
    meanAbsoluteError: 0,
    medianAbsoluteError: 0,
    p80AbsoluteError: 0,
  );
}

/// Transparent next-period estimate. The center date never jumps to a later
/// cycle when a period is late, so the UI can report lateness honestly.
class CyclePredictionEstimate {
  const CyclePredictionEstimate({
    required this.centerDate,
    required this.windowStart,
    required this.windowEnd,
    required this.effectiveCycleLength,
    required this.windowDays,
    required this.daysUntilCenter,
    required this.daysLate,
    required this.isWithinExpectedWindow,
    required this.isLate,
    required this.possibleMissingLog,
    required this.completedCycleCount,
    required this.excludedCycleCount,
    required this.regularityScore,
    required this.confidenceScore,
    required this.confidence,
    required this.accuracy,
  });

  final DateTime centerDate;
  final DateTime windowStart;
  final DateTime windowEnd;
  final int effectiveCycleLength;
  final int windowDays;
  final int daysUntilCenter;
  final int daysLate;
  final bool isWithinExpectedWindow;
  final bool isLate;
  final bool possibleMissingLog;
  final int completedCycleCount;
  final int excludedCycleCount;
  final double regularityScore;
  final double confidenceScore;
  final CyclePredictionConfidence confidence;
  final CyclePredictionAccuracy accuracy;
}

/// Evidence-informed cycle prediction: learns from completed cycles, weights
/// recent history, uses robust statistics for irregular patterns, calibrates
/// an uncertainty window from personal backtests, and reports lateness.
class SmartCyclePredictor {
  SmartCyclePredictor._();

  static const int minValidCycleDays = 21;
  static const int maxValidCycleDays = 45;
  static const int minTrackableCycleDays = 15;
  static const int maxTrackableCycleDays = 90;
  static const int defaultLutealDays = 14;
  static const int minLutealDays = 10;
  static const int maxLutealDays = 16;

  /// Kept for charts and summaries that explicitly use the 21–45 day band.
  static List<int> filterValidCycleLengths(List<int> lengths) {
    return lengths
        .where((d) => d >= minValidCycleDays && d <= maxValidCycleDays)
        .toList();
  }

  /// Robust prediction cleaner. It keeps a consistently long or short
  /// personal pattern while removing isolated logging artifacts.
  static List<int> prepareCycleLengths(List<int> lengths) {
    final plausible = lengths
        .where(
          (d) => d >= minTrackableCycleDays && d <= maxTrackableCycleDays,
        )
        .toList(growable: false);
    if (plausible.length < 3) return List<int>.from(plausible);

    final median = _medianDouble(plausible);
    final deviations = plausible.map((d) => (d - median).abs()).toList();
    final mad = _medianDoubleValues(deviations);
    final threshold = max(6.0, mad * 3.0);
    final cleaned =
        plausible.where((d) => (d - median).abs() <= threshold).toList();

    return cleaned.length >= 2 ? cleaned : List<int>.from(plausible);
  }

  static double regularityScore(List<int> completedLengths) {
    final valid = prepareCycleLengths(completedLengths);
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
    final valid = prepareCycleLengths(completedLengths);
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
    final valid = completedDurations
        .where((d) => d >= 1 && d <= 10)
        .toList(growable: false);
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
    var next =
        _dateOnly(lastPeriodStart).add(Duration(days: effectiveCycleLength));
    while (next.isBefore(today)) {
      next = next.add(Duration(days: effectiveCycleLength));
    }
    return next;
  }

  /// Builds the non-rolling estimate used by Lune's user-facing prediction.
  /// Completed lengths must be chronological (oldest → newest).
  static CyclePredictionEstimate estimateNextPeriod({
    required DateTime lastPeriodStart,
    required List<int> completedLengths,
    required int configuredFallback,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final plausibleCount = completedLengths
        .where(
          (d) => d >= minTrackableCycleDays && d <= maxTrackableCycleDays,
        )
        .length;
    final prepared = prepareCycleLengths(completedLengths);
    final effectiveLength = effectiveCycleLength(
      completedLengths: prepared,
      configuredFallback: configuredFallback,
    );
    final accuracy = backtest(
      completedLengths: prepared,
      configuredFallback: configuredFallback,
    );
    final baseWindow = predictionWindowDays(prepared);
    final calibratedWindow = max(
      baseWindow,
      accuracy.hasPersonalEvidence ? accuracy.p80AbsoluteError : 0,
    ).clamp(2, 14);

    final center = _dateOnly(lastPeriodStart).add(
      Duration(days: effectiveLength),
    );
    final windowStart = center.subtract(Duration(days: calibratedWindow));
    final windowEnd = center.add(Duration(days: calibratedWindow));
    final isWithinWindow =
        !today.isBefore(windowStart) && !today.isAfter(windowEnd);
    final isLate = today.isAfter(windowEnd);
    final daysLate = isLate ? today.difference(windowEnd).inDays : 0;
    final possibleMissingLog =
        today.difference(center).inDays >= max(effectiveLength, 21);
    final regularity = regularityScore(prepared);
    final score = _confidenceScore(
      historyCount: prepared.length,
      regularity: regularity,
      accuracy: accuracy,
    );

    return CyclePredictionEstimate(
      centerDate: center,
      windowStart: windowStart,
      windowEnd: windowEnd,
      effectiveCycleLength: effectiveLength,
      windowDays: calibratedWindow,
      daysUntilCenter: center.difference(today).inDays,
      daysLate: daysLate,
      isWithinExpectedWindow: isWithinWindow,
      isLate: isLate,
      possibleMissingLog: possibleMissingLog,
      completedCycleCount: prepared.length,
      excludedCycleCount: max(0, plausibleCount - prepared.length),
      regularityScore: regularity,
      confidenceScore: score,
      confidence: _confidenceLevel(score, prepared.length),
      accuracy: accuracy,
    );
  }

  /// Walk-forward evaluation: each cycle is predicted using only cycles that
  /// occurred before it, so future data never leaks into the score.
  static CyclePredictionAccuracy backtest({
    required List<int> completedLengths,
    required int configuredFallback,
  }) {
    final prepared = prepareCycleLengths(completedLengths);
    if (prepared.length < 2) return CyclePredictionAccuracy.empty;

    final errors = <int>[];
    var withinOne = 0;
    var withinTwo = 0;
    var withinThree = 0;
    var withinWindow = 0;

    for (var i = 1; i < prepared.length; i++) {
      final training = prepared.sublist(0, i);
      final predicted = effectiveCycleLength(
        completedLengths: training,
        configuredFallback: configuredFallback,
      );
      final error = (predicted - prepared[i]).abs();
      errors.add(error);
      if (error <= 1) withinOne++;
      if (error <= 2) withinTwo++;
      if (error <= 3) withinThree++;
      if (error <= predictionWindowDays(training)) withinWindow++;
    }

    final sorted = List<int>.from(errors)..sort();
    final mean = errors.reduce((a, b) => a + b) / errors.length;
    final median = _medianDouble(sorted);
    final p80Index = ((sorted.length - 1) * 0.8).ceil();

    return CyclePredictionAccuracy(
      evaluatedCycles: errors.length,
      withinOneDay: withinOne,
      withinTwoDays: withinTwo,
      withinThreeDays: withinThree,
      withinPersonalWindow: withinWindow,
      meanAbsoluteError: mean,
      medianAbsoluteError: median,
      p80AbsoluteError: sorted[p80Index],
    );
  }

  static DateTime nextOvulation({
    required DateTime lastPeriodStart,
    required int effectiveCycleLength,
    int? lutealDays,
    DateTime? now,
  }) {
    final luteal =
        (lutealDays ?? defaultLutealDays).clamp(minLutealDays, maxLutealDays);
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
    final valid = prepareCycleLengths(completedLengths);
    if (valid.length < 2) return 3;
    final score = regularityScore(valid);
    if (score >= 92) return 2;
    if (score >= 80) return 3;
    final mean = valid.reduce((a, b) => a + b) / valid.length;
    final sd = sqrt(
      valid.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / valid.length,
    );
    return max(4, sd.round()).clamp(3, 10);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _blend(int learned, int configured) {
    final blended = (learned * 0.7 + configured * 0.3).round();
    return blended.clamp(minTrackableCycleDays, maxTrackableCycleDays);
  }

  static double _confidenceScore({
    required int historyCount,
    required double regularity,
    required CyclePredictionAccuracy accuracy,
  }) {
    final sample = (historyCount / 6).clamp(0.0, 1.0);
    final regularityPart = (regularity / 100).clamp(0.0, 1.0);
    final accuracyPart = accuracy.hasPersonalEvidence
        ? (1 - (accuracy.medianAbsoluteError / 10)).clamp(0.0, 1.0)
        : 0.45;
    var score = sample * 0.45 + regularityPart * 0.35 + accuracyPart * 0.20;
    if (historyCount < 2) score = min(score, 0.34);
    if (historyCount < 4) score = min(score, 0.64);
    return score.clamp(0.0, 1.0);
  }

  static CyclePredictionConfidence _confidenceLevel(
    double score,
    int historyCount,
  ) {
    if (historyCount >= 4 && score >= 0.75) {
      return CyclePredictionConfidence.strong;
    }
    if (historyCount >= 2 && score >= 0.45) {
      return CyclePredictionConfidence.moderate;
    }
    return CyclePredictionConfidence.learning;
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

  static double _medianDouble(List<int> values) {
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid].toDouble();
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static double _medianDoubleValues(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }
}
