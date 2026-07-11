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

  /// Calculates a list of valid cycle lengths (in days) from the start date of
  /// one period to the start date of the next.
  static List<int> _getValidCycleLengths(List<Period> periods) {
    if (periods.length < _minPeriodsLogged) {
      return [];
    }

    final List<Period> sortedPeriods = List.from(periods);
    sortedPeriods.sort((a, b) => a.startDate.compareTo(b.startDate));

    List<int> cycleLengths = [];
    for (int i = 0; i < sortedPeriods.length - 1; i++) {
      int days = sortedPeriods[i + 1].startDate
          .difference(sortedPeriods[i].startDate)
          .inDays;

      if (days >= minValidCycleLength && days <= maxValidCycleLength) {
        cycleLengths.add(days);
      }
    }
    return SmartCyclePredictor.filterValidCycleLengths(cycleLengths);
  }

  static List<int> _getValidPeriodDurations(List<Period> periods) {
    final List<int> durations = [];
    for (final period in periods) {
      if (period.totalDays > 0) {
        durations.add(period.totalDays);
      }
    }
    return durations;
  }

  static PeriodPredictionResult? estimateNextPeriod(
    List<Period> periods,
    DateTime now,
  ) {
    if (periods.length < _minPeriodsLogged) {
      return null;
    }

    final sortedPeriods = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final List<int> validCycleLengths = _getValidCycleLengths(sortedPeriods);
    if (validCycleLengths.isEmpty) {
      return null;
    }

    final averageCycleLength = SmartCyclePredictor.effectiveCycleLength(
      completedLengths: validCycleLengths,
      configuredFallback: _defaultCycleLength,
    );

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

    final lastPeriodStartDate = sortedPeriods.last.startDate;
    final estimatedStartDate = SmartCyclePredictor.nextPeriodStart(
      lastPeriodStart: lastPeriodStartDate,
      effectiveCycleLength: averageCycleLength,
      now: now,
    );

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
