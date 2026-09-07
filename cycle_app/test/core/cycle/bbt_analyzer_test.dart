import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

void main() {
  final cycleStart = DateTime(2026, 3, 1);

  /// Builds one reading per cycle day starting at [cycleStart].
  List<BbtReading> series(List<double?> temps) {
    final out = <BbtReading>[];
    for (var i = 0; i < temps.length; i++) {
      final t = temps[i];
      if (t == null) continue;
      out.add(
        BbtReading(celsius: t, date: cycleStart.add(Duration(days: i))),
      );
    }
    return out;
  }

  group('BbtReading.parse', () {
    test('converts Fahrenheit by unit', () {
      final r = BbtReading.parse(
        date: DateTime(2026, 3, 1),
        raw: '97.7',
        unit: 'fahrenheit',
      );
      expect(r, isNotNull);
      expect(r!.celsius, closeTo(36.5, 0.05));
    });

    test('converts Fahrenheit even when the unit column lies', () {
      final r = BbtReading.parse(date: DateTime(2026, 3, 1), raw: '98.6');
      expect(r!.celsius, closeTo(37.0, 0.05));
    });

    test('rejects impossible basal temperatures', () {
      expect(
        BbtReading.parse(date: DateTime(2026, 3, 1), raw: '12.0'),
        isNull,
      );
      expect(BbtReading.parse(date: DateTime(2026, 3, 1), raw: '0'), isNull);
      expect(BbtReading.parse(date: null, raw: '36.5'), isNull);
    });
  });

  group('BbtAnalyzer.detectShift', () {
    test('detects a textbook thermal shift and dates ovulation to the last low day', () {
      // Days 1-13 low (~36.4), days 14+ high (~36.8).
      final shift = BbtAnalyzer.detectShift(
        readings: series([
          36.40, 36.35, 36.45, 36.40, 36.38, 36.42, 36.40, 36.44, 36.39,
          36.41, 36.43, 36.40, 36.42, // day 13 = last low
          36.80, 36.85, 36.82, 36.88, 36.84, // shift
        ]),
        cycleStart: cycleStart,
        nextCycleStart: cycleStart.add(const Duration(days: 28)),
      );

      expect(shift, isNotNull);
      // First high is index 13 (day 14) → ovulation is the day before.
      expect(shift!.firstHighDate, cycleStart.add(const Duration(days: 13)));
      expect(shift.ovulationDate, cycleStart.add(const Duration(days: 12)));
      expect(shift.isFullShift, isTrue);
      expect(shift.riseCelsius, greaterThanOrEqualTo(0.2));
    });

    test('returns null when temperatures never rise', () {
      final shift = BbtAnalyzer.detectShift(
        readings: series(List<double>.filled(20, 36.40)),
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });

    test('ignores a one-day spike that is not sustained', () {
      final shift = BbtAnalyzer.detectShift(
        readings: series([
          36.40, 36.38, 36.42, 36.40, 36.41, 36.39, 36.40, 36.42,
          37.20, // fever spike, single day
          36.40, 36.41, 36.38, 36.40, 36.42, 36.39,
        ]),
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });

    test('discards one aberrant baseline reading instead of losing the shift', () {
      // A single high outlier inside the six lows would otherwise raise the
      // coverline above the real post-ovulatory temperatures.
      final shift = BbtAnalyzer.detectShift(
        readings: series([
          36.40, 36.38, 36.42, 36.40, 36.41, 36.39, 36.40,
          36.42, 36.40, 36.38,
          36.95, // aberrant late night out
          36.40, 36.41,
          36.75, 36.78, 36.80,
        ]),
        cycleStart: cycleStart,
      );
      expect(shift, isNotNull);
      expect(shift!.baselineReadings, 5);
    });

    test('rejects a rise too early to be ovulation', () {
      final shift = BbtAnalyzer.detectShift(
        readings: series([
          36.40, 36.38, 36.42, 36.40, 36.41, 36.39,
          36.85, 36.88, 36.86, // day 7-9 rise: not plausible ovulation
        ]),
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });

    test('ignores readings belonging to other cycles', () {
      final readings = <BbtReading>[
        ...series([
          36.40, 36.38, 36.42, 36.40, 36.41, 36.39, 36.40, 36.42, 36.40,
          36.38, 36.40, 36.41, 36.39,
          36.80, 36.84, 36.82,
        ]),
        // Next cycle's readings; must not be considered.
        BbtReading(celsius: 37.2, date: cycleStart.add(const Duration(days: 30))),
      ];

      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
        nextCycleStart: cycleStart.add(const Duration(days: 28)),
      );
      expect(shift, isNotNull);
      expect(
        shift!.confirmedDate.isBefore(cycleStart.add(const Duration(days: 28))),
        isTrue,
      );
    });

    test('needs enough readings before it will call a shift', () {
      final shift = BbtAnalyzer.detectShift(
        readings: series([36.40, 36.38, 36.80, 36.84, 36.82]),
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });
  });

  group('BbtAnalyzer.lutealLengthFrom', () {
    BbtShift shiftOn(DateTime ovulation) => BbtShift(
      ovulationDate: ovulation,
      firstHighDate: ovulation.add(const Duration(days: 1)),
      confirmedDate: ovulation.add(const Duration(days: 3)),
      coverline: 36.45,
      riseCelsius: 0.3,
      baselineReadings: 6,
      isFullShift: true,
    );

    test('measures ovulation → next period', () {
      final luteal = BbtAnalyzer.lutealLengthFrom(
        shift: shiftOn(DateTime(2026, 3, 14)),
        nextCycleStart: DateTime(2026, 3, 27),
      );
      expect(luteal, 13);
    });

    test('rejects clinically implausible luteal lengths', () {
      expect(
        BbtAnalyzer.lutealLengthFrom(
          shift: shiftOn(DateTime(2026, 3, 14)),
          nextCycleStart: DateTime(2026, 3, 20),
        ),
        isNull,
      );
      expect(
        BbtAnalyzer.lutealLengthFrom(
          shift: shiftOn(DateTime(2026, 3, 14)),
          nextCycleStart: DateTime(2026, 4, 10),
        ),
        isNull,
      );
    });
  });
}
