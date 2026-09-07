import 'package:flutter/foundation.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import 'luteal_calibration.dart';

/// How far along the user is toward getting real ovulation confirmation from
/// basal body temperature.
///
/// One source of truth for both the morning reminder and the progress card, so
/// the number the notification quotes always matches what the app shows.
class BbtTrackingStatus {
  const BbtTrackingStatus({
    required this.readingsThisCycle,
    required this.ovulationConfirmed,
    required this.measuredLutealSignals,
    this.confirmedOvulationDate,
    this.shiftCelsius,
  });

  /// Temperature readings logged in the cycle currently running.
  final int readingsThisCycle;

  /// A thermal shift has been detected in this cycle.
  final bool ovulationConfirmed;

  /// Total measured ovulation signals (temperature + manual LH/ovulation logs)
  /// personalizing the luteal phase.
  final int measuredLutealSignals;

  final DateTime? confirmedOvulationDate;
  final double? shiftCelsius;

  /// Readings needed before the 3-over-6 rule can fire at all.
  static const int minReadingsForDetection =
      BbtAnalyzer.baselineWindow + BbtAnalyzer.confirmationDays;

  static const empty = BbtTrackingStatus(
    readingsThisCycle: 0,
    ovulationConfirmed: false,
    measuredLutealSignals: 0,
  );

  /// Whether enough readings exist for a shift to be detectable this cycle.
  bool get isReady => readingsThisCycle >= minReadingsForDetection;

  /// How many more morning readings until detection becomes possible.
  int get readingsUntilReady =>
      (minReadingsForDetection - readingsThisCycle).clamp(
        0,
        minReadingsForDetection,
      );

  /// 0.0 → 1.0 progress toward the first possible confirmation.
  double get progress => ovulationConfirmed
      ? 1
      : (readingsThisCycle / minReadingsForDetection).clamp(0.0, 1.0);

  /// True once the user has logged anything at all — used to decide between
  /// "here's why this matters" and "here's how you're doing".
  bool get hasStarted => readingsThisCycle > 0;

  /// The luteal phase is personalized rather than assumed at 14 days.
  bool get isCalibrated => measuredLutealSignals >= 2;

  static Future<BbtTrackingStatus> load() async {
    try {
      final bbt = LutealCalibration.sharedBbtService;
      final series = await bbt.latestCycleSeries(minReadings: 1);
      final current = await bbt.currentCycleShift();
      final signals = await LutealCalibration().measuredLutealLengths();

      return BbtTrackingStatus(
        // A series from a finished cycle says nothing about this one.
        readingsThisCycle: (series?.isCurrentCycle ?? false)
            ? series!.points.length
            : 0,
        ovulationConfirmed: current != null,
        measuredLutealSignals: signals.length,
        confirmedOvulationDate: current?.shift.ovulationDate,
        shiftCelsius: current?.shift.riseCelsius,
      );
    } catch (e, st) {
      debugPrint('BbtTrackingStatus.load failed: $e\n$st');
      return empty;
    }
  }
}
