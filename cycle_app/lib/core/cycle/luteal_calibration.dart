import 'bbt_ovulation_service.dart';
import 'ovulation_log_service.dart';

/// Merges every ovulation signal the user produces — manually logged
/// ovulation/LH-positive days and thermal shifts detected from basal body
/// temperature — into one personalized luteal-phase history.
///
/// The luteal phase is the most stable part of the cycle, so measuring it
/// directly is what moves prediction from "average of your cycles" to
/// "anchored to your physiology".
class LutealCalibration {
  LutealCalibration({
    OvulationLogService? logs,
    BbtOvulationService? bbt,
  }) : _logs = logs ?? OvulationLogService(),
       _bbt = bbt ?? sharedBbtService;

  final OvulationLogService _logs;
  final BbtOvulationService _bbt;

  /// One process-wide instance so the dashboard, AI context and the widget
  /// engine share a single temperature scan per refresh.
  static final BbtOvulationService sharedBbtService = BbtOvulationService();

  /// Luteal lengths from both sources, oldest → newest.
  ///
  /// Manual signals come first so temperature — which is measured every cycle
  /// once the user logs it — carries the most recency weight downstream.
  Future<List<int>> measuredLutealLengths() async {
    final manual = await _logs.measuredLutealLengths();
    final thermal = await _bbt.measuredLutealLengths();
    return [...manual, ...thermal];
  }

  /// How many independent ovulation measurements back the calibration.
  Future<int> signalCount() async => (await measuredLutealLengths()).length;

  /// True once there is enough measured evidence to personalize the luteal
  /// phase instead of assuming the textbook 14 days.
  Future<bool> isCalibrated() async => (await signalCount()) >= 2;
}
