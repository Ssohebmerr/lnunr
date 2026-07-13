import 'package:cycle_aura/menstrudel/models/cycle_phase/cycle_phase.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// A utility class for calculating when each cycle phase is due based on user data.
/// This is to be used with natural cycles only. If user is on the pill it should not be used.
class CyclePhasePredictor {
  /// Default luteal phase length. Real range is 10-16 days across individuals.
  static const int _defaultLutealPhaseLength = 14;

  static PredictedCycle predictCycle({
    required DateTime lastPeriodStartDate,
    required int averageCycleLength,
    required int averagePeriodDuration,
    int? lutealPhaseLength,
  }) {
    final clampedCycleLength = averageCycleLength.clamp(
      SmartCyclePredictor.minTrackableCycleDays,
      SmartCyclePredictor.maxTrackableCycleDays,
    );
    final clampedPeriodDuration = averagePeriodDuration.clamp(1, 10);
    final luteal = (lutealPhaseLength ?? _defaultLutealPhaseLength).clamp(
      10,
      16,
    );

    final ovulationDayOffset = clampedCycleLength - luteal;
    final ovulationDay = lastPeriodStartDate.add(
      Duration(days: ovulationDayOffset - 1),
    );

    final fertileStart = ovulationDay.subtract(const Duration(days: 5));

    final lutealStart = ovulationDay.add(const Duration(days: 2));

    return PredictedCycle(
      menstruationStart: lastPeriodStartDate,
      follicularStart: lastPeriodStartDate.add(
        Duration(days: clampedPeriodDuration),
      ),
      fertileWindowStart: fertileStart,
      ovulationDay: ovulationDay,
      lutealStart: lutealStart,
      nextPeriodStart: lastPeriodStartDate.add(
        Duration(days: clampedCycleLength),
      ),
    );
  }
}
