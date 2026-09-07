import 'dart:math';

/// A single basal body temperature reading, normalized to Celsius.
class BbtReading {
  const BbtReading({required this.date, required this.celsius});

  final DateTime date;
  final double celsius;

  /// Parses a stored temperature string, converting Fahrenheit when the value
  /// or the unit says so. Returns null for missing, unparsable or
  /// physiologically impossible readings.
  static BbtReading? parse({
    required DateTime? date,
    required String? raw,
    String? unit,
  }) {
    if (date == null || raw == null) return null;
    final value = double.tryParse(raw.trim());
    if (value == null || value <= 0) return null;

    final saysFahrenheit = (unit ?? '').toLowerCase().contains('f');
    // Anything above 45 cannot be Celsius, so convert defensively even when the
    // unit column is missing or wrong.
    final celsius = (saysFahrenheit || value > 45) ? (value - 32) * 5 / 9 : value;

    if (celsius < BbtAnalyzer.minPlausibleCelsius ||
        celsius > BbtAnalyzer.maxPlausibleCelsius) {
      return null;
    }
    return BbtReading(
      date: DateTime(date.year, date.month, date.day),
      celsius: double.parse(celsius.toStringAsFixed(2)),
    );
  }
}

/// A confirmed post-ovulatory thermal shift detected inside one cycle.
class BbtShift {
  const BbtShift({
    required this.ovulationDate,
    required this.firstHighDate,
    required this.confirmedDate,
    required this.coverline,
    required this.riseCelsius,
    required this.baselineReadings,
    required this.isFullShift,
  });

  /// Estimated ovulation: the last low day, i.e. the day before the rise.
  final DateTime ovulationDate;

  /// First reading that cleared the coverline.
  final DateTime firstHighDate;

  /// Third consecutive high reading — the earliest day the shift is confirmed.
  final DateTime confirmedDate;

  /// Threshold drawn 0.05 °C above the highest of the six preceding lows.
  final double coverline;

  /// How far the third high reading sits above the coverline.
  final double riseCelsius;

  /// How many low-phase readings backed the coverline (6, or 5 after one
  /// aberrant reading was discarded).
  final int baselineReadings;

  /// True for a textbook shift (third reading ≥ 0.2 °C over the coverline).
  /// A weak shift still counts but is worth less confidence.
  final bool isFullShift;
}

/// Detects ovulation from basal body temperature using the sympto-thermal
/// "3-over-6" rule: three consecutive readings above a coverline drawn just
/// over the highest of the six preceding low-phase readings.
///
/// This is the only at-home signal that ovulation actually *happened* —
/// everything else in the app is a statistical estimate.
class BbtAnalyzer {
  BbtAnalyzer._();

  /// Readings outside this band are logging mistakes, not basal temperatures.
  static const double minPlausibleCelsius = 35.0;
  static const double maxPlausibleCelsius = 38.5;

  /// The coverline sits this far above the highest of the six lows (0.1 °F).
  static const double coverlineMargin = 0.05;

  /// A full thermal shift clears the coverline by at least this much (0.4 °F).
  static const double fullShiftRise = 0.2;

  /// Low-phase readings needed to draw a coverline.
  static const int baselineWindow = 6;

  /// Consecutive high readings needed to confirm the shift.
  static const int confirmationDays = 3;

  /// Ovulation before this cycle day is not physiologically plausible, so an
  /// early rise is treated as noise rather than a shift.
  static const int minOvulationCycleDay = 7;

  /// The three confirming readings may span at most this many days, which
  /// tolerates one or two missed mornings without accepting a stale run.
  static const int maxConfirmationSpanDays = 5;

  /// Finds the first thermal shift in one cycle.
  ///
  /// [readings] may be unsorted and may contain days outside the cycle;
  /// anything before [cycleStart] or on/after [nextCycleStart] is ignored.
  /// Returns null when there is not enough data or no shift cleared the rule.
  static BbtShift? detectShift({
    required List<BbtReading> readings,
    required DateTime cycleStart,
    DateTime? nextCycleStart,
  }) {
    final start = _dateOnly(cycleStart);
    final end = nextCycleStart == null ? null : _dateOnly(nextCycleStart);

    final scoped =
        readings
            .where((r) {
              final d = _dateOnly(r.date);
              if (d.isBefore(start)) return false;
              if (end != null && !d.isBefore(end)) return false;
              return true;
            })
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    // De-duplicate same-day entries, keeping the last one written.
    final byDay = <String, BbtReading>{};
    for (final r in scoped) {
      byDay['${r.date.year}-${r.date.month}-${r.date.day}'] = r;
    }
    final series = byDay.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (series.length < baselineWindow + confirmationDays) return null;

    for (var i = baselineWindow; i <= series.length - confirmationDays; i++) {
      final firstHigh = series[i];
      final ovulation = firstHigh.date.subtract(const Duration(days: 1));

      // Cycle day of the rise: day 1 is the first day of the period.
      final riseCycleDay = firstHigh.date.difference(start).inDays + 1;
      if (riseCycleDay <= minOvulationCycleDay) continue;

      final baseline = series.sublist(i - baselineWindow, i);
      final coverlineData = _coverline(baseline);
      final coverline = coverlineData.value;

      final highs = series.sublist(i, i + confirmationDays);
      if (highs.last.date.difference(highs.first.date).inDays >
          maxConfirmationSpanDays) {
        continue;
      }
      if (!highs.every((r) => r.celsius > coverline)) continue;

      final rise = double.parse(
        (highs.last.celsius - coverline).toStringAsFixed(2),
      );

      return BbtShift(
        ovulationDate: ovulation,
        firstHighDate: firstHigh.date,
        confirmedDate: highs.last.date,
        coverline: coverline,
        riseCelsius: rise,
        baselineReadings: coverlineData.used,
        isFullShift: rise >= fullShiftRise,
      );
    }

    return null;
  }

  /// Luteal phase length implied by a shift: ovulation → next period start.
  /// Returns null when the value falls outside the clinical 10–16 day range,
  /// which usually means the shift or the period log is wrong.
  static int? lutealLengthFrom({
    required BbtShift shift,
    required DateTime nextCycleStart,
  }) {
    final days = _dateOnly(
      nextCycleStart,
    ).difference(_dateOnly(shift.ovulationDate)).inDays;
    if (days < 10 || days > 16) return null;
    return days;
  }

  /// Coverline for the six low-phase readings.
  ///
  /// The classic rule allows discarding a single aberrant temperature (fever,
  /// a bad night, a late reading), so one clear outlier above the rest is
  /// dropped before taking the maximum.
  static _Coverline _coverline(List<BbtReading> baseline) {
    final temps = baseline.map((r) => r.celsius).toList()..sort();
    var used = temps.length;

    if (temps.length >= 3) {
      final highest = temps.last;
      final secondHighest = temps[temps.length - 2];
      if (highest - secondHighest > 0.15) {
        temps.removeLast();
        used -= 1;
      }
    }

    final value = double.parse(
      (temps.reduce(max) + coverlineMargin).toStringAsFixed(2),
    );
    return _Coverline(value: value, used: used);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _Coverline {
  const _Coverline({required this.value, required this.used});
  final double value;
  final int used;
}
