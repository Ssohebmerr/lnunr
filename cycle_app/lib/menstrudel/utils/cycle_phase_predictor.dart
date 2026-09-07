import 'package:cycle_aura/menstrudel/models/cycle_phase/cycle_phase.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// A utility class for calculating when each cycle phase is due based on user data.
/// This is to be used with natural cycles only. If user is on the pill it should not be used.
class CyclePhasePredictor {
  /// Default luteal phase length. Real range is 10-16 days across individuals.
  static const int _defaultLutealPhaseLength = 14;

  /// Sperm survive about five days, so the fertile window opens that far ahead
  /// of ovulation and closes the day after it.
  static const int _spermSurvivalDays = 5;
  static const int _oocyteSurvivalDays = 1;

  /// The fertile window never widens past this, even for very irregular
  /// histories — beyond it the guidance stops being actionable.
  static const int _maxFertilePadding = 5;

  static PredictedCycle predictCycle({
    required DateTime lastPeriodStartDate,
    required int averageCycleLength,
    required int averagePeriodDuration,
    int? lutealPhaseLength,

    /// Uncertainty of the cycle-length estimate, in days. The fertile window
    /// widens by this much on both sides: an irregular cycle means an
    /// uncertain ovulation date, and a fixed ±0 window would quietly present a
    /// guess as a fact.
    int predictionWindowDays = 0,

    /// Ovulation observed from a basal body temperature shift. When present it
    /// replaces the statistical estimate outright.
    DateTime? confirmedOvulationDate,
    DateTime? now,
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

    // Roll forward to the cycle that actually contains today. Without this the
    // predicted ovulation stays stuck in the past for every day a period is
    // late, and the fertile window silently points at a date that has gone.
    final today = _dateOnly(now ?? DateTime.now());
    var cycleStart = _dateOnly(lastPeriodStartDate);
    if (confirmedOvulationDate == null) {
      var nextStart = _addDays(cycleStart, clampedCycleLength);
      while (nextStart.isBefore(today)) {
        cycleStart = nextStart;
        nextStart = _addDays(cycleStart, clampedCycleLength);
      }
    }

    final ovulationDayOffset = clampedCycleLength - luteal;
    final ovulationDay =
        confirmedOvulationDate == null
            ? _addDays(cycleStart, ovulationDayOffset - 1)
            : _dateOnly(confirmedOvulationDate);

    // A measured shift is an observation, so it carries no cycle-length
    // uncertainty; an estimate does.
    final padding = confirmedOvulationDate != null
        ? 0
        : predictionWindowDays.clamp(0, _maxFertilePadding);

    final fertileStart = _addDays(ovulationDay, -(_spermSurvivalDays + padding));

    // lutealStart is the first non-fertile day, so it sits one day past the
    // end of the fertile window.
    final lutealStart = _addDays(ovulationDay, _oocyteSurvivalDays + padding + 1);

    // Once ovulation is observed, the next period follows it by the luteal
    // length — the most stable stretch of the cycle. That beats projecting the
    // average cycle length from the last period start, which carries the
    // follicular phase's much larger variance.
    final nextPeriodStart = confirmedOvulationDate != null
        ? _addDays(ovulationDay, luteal)
        : _addDays(cycleStart, clampedCycleLength);

    return PredictedCycle(
      menstruationStart: cycleStart,
      follicularStart: _addDays(cycleStart, clampedPeriodDuration),
      fertileWindowStart: fertileStart,
      ovulationDay: ovulationDay,
      lutealStart: lutealStart,
      nextPeriodStart: nextPeriodStart,
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar-day arithmetic. `add(Duration(days: n))` adds exact hours, so on
  /// a daylight-saving boundary "+28 days" lands at 23:00 the day before and
  /// every phase boundary silently shifts by a day. The DateTime constructor
  /// normalizes overflowing day numbers at local midnight instead.
  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);
}
