import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

/// Unit tests for the basal body temperature (BBT) ovulation detector.
///
/// Covers the sympto-thermal "3-over-6" rule: a coverline 0.05 °C above the
/// highest of six preceding low readings, three consecutive readings above it
/// (within a 5-day span), ovulation placed on the last low day, an early-rise
/// noise floor, aberrant-reading discard for the coverline, Fahrenheit parsing
/// and the clinically valid 10–16 day luteal window.
void main() {
  final cycleStart = DateTime(2026, 1, 1);

  BbtReading r(int day, double celsius) =>
      BbtReading(date: DateTime(2026, 1, day), celsius: celsius);

  group('parse', () {
    test('converts Fahrenheit storage values to Celsius', () {
      final reading = BbtReading.parse(
        date: DateTime(2026, 1, 3),
        raw: '98.6',
        unit: 'F',
      );
      expect(reading, isNotNull);
      expect(reading!.celsius, 37.0);
    });

    test('defensively converts Fahrenheit-scale numbers with no unit', () {
      final reading = BbtReading.parse(
        date: DateTime(2026, 1, 3),
        raw: '96.5',
      );
      // 96.5 cannot be Celsius (above the 45 cap) → converted: 35.83 °C.
      expect(reading, isNotNull);
      expect(reading!.celsius, closeTo(35.83, 0.001));
    });

    test('rejects missing, unparsable and physiologically impossible values',
        () {
      expect(BbtReading.parse(date: null, raw: '36.5'), isNull);
      expect(BbtReading.parse(date: DateTime(2026, 1, 3), raw: null), isNull);
      expect(BbtReading.parse(date: DateTime(2026, 1, 3), raw: 'abc'), isNull);
      expect(BbtReading.parse(date: DateTime(2026, 1, 3), raw: '34.9'), isNull);
      expect(BbtReading.parse(date: DateTime(2026, 1, 3), raw: '38.6'), isNull);
      expect(BbtReading.parse(date: DateTime(2026, 1, 3), raw: '-1'), isNull);
    });

    test('normalizes the date to a calendar date', () {
      final reading = BbtReading.parse(
        date: DateTime(2026, 1, 3, 19, 45),
        raw: '36.5',
      );
      expect(reading!.date, DateTime(2026, 1, 3));
    });
  });

  group('detectShift', () {
    test('detects a textbook shift after a stable low phase', () {
      final readings = [
        // Seven low days (36.5 °C), then three consecutive highs.
        r(1, 36.5), r(2, 36.5), r(3, 36.5), r(4, 36.5),
        r(5, 36.5), r(6, 36.5), r(7, 36.5),
        r(8, 36.8), r(9, 36.85), r(10, 36.9),
      ];

      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );

      expect(shift, isNotNull);
      expect(shift!.ovulationDate, DateTime(2026, 1, 7));
      expect(shift.firstHighDate, DateTime(2026, 1, 8));
      expect(shift.confirmedDate, DateTime(2026, 1, 10));
      expect(shift.coverline, 36.55); // 36.5 + 0.05 margin
      expect(shift.riseCelsius, closeTo(0.35, 0.001));
      expect(shift.baselineReadings, 6);
      expect(shift.isFullShift, isTrue);
    });

    test('returns null when no thermal rise occurred', () {
      final readings = List.generate(10, (i) => r(i + 1, 36.5));
      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });

    test('returns null when there are too few readings', () {
      // Needs baselineWindow + confirmationDays = 9 scoped readings minimum.
      final readings = [r(1, 36.5), r(2, 36.5), r(3, 36.6), r(8, 36.9)];
      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });

    test('ignores an early-onset rise as noise (before cycle day 7)', () {
      final readings = [
        r(1, 36.5), r(2, 36.7), r(3, 36.8), r(4, 36.75),
        r(5, 36.8), r(6, 36.85), r(7, 36.8), r(8, 36.9),
        r(9, 36.9),
      ];
      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );
      expect(shift, isNull);
    });

    test('discards one aberrant reading when drawing the coverline', () {
      final readings = [
        r(1, 36.5), r(2, 36.5),
        r(3, 37.5), // fever/late-reading spike in the low phase
        r(4, 36.5), r(5, 36.5), r(6, 36.5), r(7, 36.5),
        r(8, 36.8), r(9, 36.85), r(10, 36.9),
      ];

      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );

      expect(shift, isNotNull);
      // The 37.5 spike was dropped: only 5 lows back the coverline, and the
      // threshold is still 36.55 (max of the remaining lows + margin).
      expect(shift!.baselineReadings, 5);
      expect(shift.coverline, 36.55);
    });

    test('tolerates missed mornings within the confirmation span', () {
      final readings = [
        r(1, 36.5), r(2, 36.5), r(3, 36.5), r(4, 36.5),
        r(5, 36.5), r(6, 36.5), r(7, 36.5), r(8, 36.5),
        r(9, 36.8), // measured
        r(11, 36.85), // day 10 missed
        r(12, 36.9),
      ];

      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );

      expect(shift, isNotNull);
      expect(shift!.ovulationDate, DateTime(2026, 1, 8));
      expect(shift.confirmedDate, DateTime(2026, 1, 12));
      expect(shift.isFullShift, isTrue);
    });

    test('de-duplicates same-day entries keeping the last written', () {
      final readings = [
        r(1, 36.5), r(2, 36.5), r(3, 36.5), r(4, 36.5),
        r(5, 36.5), r(6, 36.5), r(7, 36.5),
        r(8, 36.4), r(8, 36.8), // corrected later the same day
        r(9, 36.85), r(10, 36.9),
      ];

      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
      );

      expect(shift, isNotNull);
      expect(shift!.firstHighDate, DateTime(2026, 1, 8));
    });

    test('ignores readings outside the requested cycle scope', () {
      final readings = [
        r(28, 36.9), // beyond nextCycleStart (previous cycle's tail)
        ...List.generate(7, (i) => r(i + 1, 36.5)),
        r(8, 36.8), r(9, 36.85), r(10, 36.9),
        r(22, 36.9), // next cycle (on/after nextCycleStart)
      ];

      final shift = BbtAnalyzer.detectShift(
        readings: readings,
        cycleStart: cycleStart,
        nextCycleStart: DateTime(2026, 1, 22),
      );

      expect(shift, isNotNull);
      expect(shift!.firstHighDate, DateTime(2026, 1, 8));
      expect(shift.ovulationDate, DateTime(2026, 1, 7));
    });
  });

  group('lutealLengthFrom', () {
    test('returns the day gap for a clinically valid shift', () {
      final shift = BbtShift(
        ovulationDate: DateTime(2026, 1, 7),
        firstHighDate: DateTime(2026, 1, 8),
        confirmedDate: DateTime(2026, 1, 10),
        coverline: 36.55,
        riseCelsius: 0.35,
        baselineReadings: 6,
        isFullShift: true,
      );

      expect(
        BbtAnalyzer.lutealLengthFrom(
          shift: shift,
          nextCycleStart: DateTime(2026, 1, 22),
        ),
        15,
      );
    });

    test('returns null outside the 10–16 day clinical range', () {
      final shift = BbtShift(
        ovulationDate: DateTime(2026, 1, 7),
        firstHighDate: DateTime(2026, 1, 8),
        confirmedDate: DateTime(2026, 1, 10),
        coverline: 36.55,
        riseCelsius: 0.35,
        baselineReadings: 6,
        isFullShift: true,
      );

      // 5-day luteal phase → the period log or the shift is wrong.
      expect(
        BbtAnalyzer.lutealLengthFrom(
          shift: shift,
          nextCycleStart: DateTime(2026, 1, 12),
        ),
        isNull,
      );
    });
  });
}
