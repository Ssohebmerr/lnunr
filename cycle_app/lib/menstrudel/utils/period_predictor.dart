import 'package:cycle_aura/menstrudel/models/periods/period.dart';
import 'package:cycle_aura/menstrudel/models/period_prediction_result.dart';
import 'package:cycle_aura/menstrudel/models/cycles/cycle_stats.dart';
import 'package:cycle_aura/menstrudel/models/periods/period_stats.dart';
import 'package:cycle_aura/menstrudel/models/cycles/monthly_cycle_data.dart';
import 'package:cycle_aura/menstrudel/utils/constants.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'dart:math';

/// A utility class for calculating cycle statistics and predicting the next period
/// based on a list of recorded [Period] entries.
class PeriodPredictor {
  /// The default cycle length (in days) used if calculation fails.
  static const int _defaultCycleLength = 28;

  /// The minimum number of periods logged needed to calculate a prediction.
  static const int _minPeriodsLogged = 2;

  /// Cycle lengths (in days) between consecutive period starts, oldest →
  /// newest, with only physically impossible values removed.
  ///
  /// Keep the raw list for anything that reports on the user's pattern —
  /// prolonged or erratic cycles are the signal, not noise to be cleaned away.
  static List<int> getRawCycleLengths(List<Period> periods) {
    if (periods.length < _minPeriodsLogged) {
      return [];
    }

    final List<Period> sortedPeriods = List.from(periods);
    sortedPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));

    final List<int> cycleLengths = [];
    for (int i = 0; i < sortedPeriods.length - 1; i++) {
      final int days = sortedPeriods[i + 1].startDate
          .difference(sortedPeriods[i].startDate)
          .inDays;

      if (days >= minValidCycleLength && days <= maxValidCycleLength) {
        cycleLengths.add(days);
      }
    }
    return cycleLengths;
  }

  /// Calculates a list of valid cycle lengths (in days) from the start date of
  /// one period to the start date of the next, cleaned for date estimation.
  static List<int> getValidCycleLengths(List<Period> periods) {
    return SmartCyclePredictor.prepareCycleLengths(getRawCycleLengths(periods));
  }

  static List<int> _getValidCycleLengths(List<Period> periods) =>
      getValidCycleLengths(periods);

  static List<int> _getValidPeriodDurations(List<Period> periods) {
    final List<int> durations = [];
    for (final period in periods) {
      if (period.totalDays > 0) {
        durations.add(period.totalDays);
      }
    }
    return durations;
  }

  /// Cycle start dates for the completed cycles behind [getRawCycleLengths],
  /// chronological — the anchor an annotation is stored against.
  static List<DateTime> getCycleStarts(List<Period> periods) {
    final sorted = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return [
      for (final p in sorted)
        DateTime(p.startDate.year, p.startDate.month, p.startDate.day),
    ];
  }

  static PeriodPredictionResult? estimateNextPeriod(
    List<Period> periods,
    DateTime now, {
    List<bool> explainedCycles = const [],
  }) {
    if (periods.length < _minPeriodsLogged) {
      return null;
    }

    final sortedPeriods = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (_getValidCycleLengths(sortedPeriods).isEmpty) {
      return null;
    }

    // Hand over the raw history: the predictor cleans it internally for the
    // date estimate, and needs the untouched list to flag clinical patterns
    // and count how many cycles it had to exclude.
    final prediction = SmartCyclePredictor.estimateNextPeriod(
      lastPeriodStart: sortedPeriods.last.startDate,
      completedLengths: getRawCycleLengths(sortedPeriods),
      configuredFallback: _defaultCycleLength,
      explainedCycles: explainedCycles,
      now: now,
    );
    final averageCycleLength = prediction.effectiveCycleLength;

    final List<int> periodDurations = _getValidPeriodDurations(sortedPeriods);
    if (periodDurations.isEmpty) {
      return null;
    }
    final averagePeriodDuration = SmartCyclePredictor.effectivePeriodDuration(
      completedDurations: periodDurations,
      configuredFallback: 5,
    );

    if (averageCycleLength <= 0 || averagePeriodDuration <= 0) {
      return null;
    }

    final estimatedStartDate = prediction.centerDate;

    final estimatedEndDate = estimatedStartDate.add(
      Duration(days: averagePeriodDuration - 1),
    );

    final today = DateTime(now.year, now.month, now.day);
    final startOfEstimatedDate = DateTime(
      estimatedStartDate.year,
      estimatedStartDate.month,
      estimatedStartDate.day,
    );

    final daysUntilDue = startOfEstimatedDate.difference(today).inDays;

    return PeriodPredictionResult(
      estimatedStartDate: estimatedStartDate,
      estimatedEndDate: estimatedEndDate,
      daysUntilDue: daysUntilDue,
      averageCycleLength: averageCycleLength,
      averagePeriodDuration: averagePeriodDuration,
      evidence: prediction,
    );
  }

  static List<MonthlyCycleData> getMonthlyCycleData(List<Period> periods) {
    if (periods.length < _minPeriodsLogged) {
      return [];
    }

    final sortedPeriods = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final List<MonthlyCycleData> monthlyData = [];
    for (int i = 0; i < sortedPeriods.length - 1; i++) {
      int days = sortedPeriods[i + 1].startDate
          .difference(sortedPeriods[i].startDate)
          .inDays;

      if (days >= minValidCycleLength && days <= maxValidCycleLength) {
        final DateTime cycleEndDate = sortedPeriods[i + 1].startDate;
        monthlyData.add(
          MonthlyCycleData(
            year: cycleEndDate.year,
            month: cycleEndDate.month,
            cycleLength: days,
          ),
        );
      }
    }
    return monthlyData;
  }

  static CycleStats? getCycleStats(List<Period> periods) {
    if (periods.length < _minPeriodsLogged) {
      return null;
    }

    List<int> validCycleLengths = _getValidCycleLengths(periods);

    if (validCycleLengths.isEmpty) {
      return null;
    }

    final averageCycleLength = SmartCyclePredictor.effectiveCycleLength(
      completedLengths: validCycleLengths,
      configuredFallback: _defaultCycleLength,
    );

    int shortestCycle = validCycleLengths.reduce(min);
    int longestCycle = validCycleLengths.reduce(max);

    return CycleStats(
      averageCycleLength: averageCycleLength,
      shortestCycleLength: shortestCycle,
      longestCycleLength: longestCycle,
      numberOfCycles: validCycleLengths.length,
      cycleLengths: validCycleLengths,
    );
  }

  static PeriodStats? getPeriodStats(List<Period> entries) {
    if (entries.length < _minPeriodsLogged) {
      return null;
    }

    final List<Period> sortedEntries = List.from(entries);
    sortedEntries.sort((a, b) => a.startDate.compareTo(b.startDate));
    int totalCycleDays = sortedEntries.fold(
      0,
      (sum, entry) => sum + entry.totalDays,
    );
    int averageLength = (totalCycleDays / sortedEntries.length).round();

    int shortestLength = sortedEntries
        .reduce((a, b) => a.totalDays < b.totalDays ? a : b)
        .totalDays;
    int longestLength = sortedEntries
        .reduce((a, b) => a.totalDays > b.totalDays ? a : b)
        .totalDays;

    return PeriodStats(
      averageLength: averageLength,
      shortestLength: shortestLength,
      longestLength: longestLength,
      numberofPeriods: sortedEntries.length,
    );
  }
}
