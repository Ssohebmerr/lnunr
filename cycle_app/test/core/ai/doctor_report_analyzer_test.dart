import 'package:cycle_aura/core/ai/doctor_report_analyzer.dart';
import 'package:cycle_aura/core/ai/models/health_snapshot.dart';
import 'package:cycle_aura/features/cycle/data/cycle_bridge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

PeriodsDateRange _cycle({
  required String start,
  required int length,
  int periodDays = 5,
  bool completed = true,
}) => PeriodsDateRange(
  periodStartDate: start,
  cycleStartDate: start,
  cycleEndDate: completed ? '${start}T23:59:59' : null,
  periodDuration: periodDays,
  cycleLength: length,
);

CycleReportData _report(List<PeriodsDateRange> cycles) => CycleReportData(
  keyMatrix: const {},
  predictionMatrix: const {},
  cycles: cycles,
  symptomPatterns: const [],
);

void main() {
  group('DoctorReportAnalyzer', () {
    test('excludes the ongoing cycle from all clinical statistics', () {
      final result = DoctorReportAnalyzer.analyze(
        report: _report([
          _cycle(start: '2026-07-01', length: 10, completed: false),
          _cycle(start: '2026-06-01', length: 30),
          _cycle(start: '2026-05-02', length: 31),
        ]),
      );

      expect(result.totalCycleCount, 3);
      expect(result.analyzedCycleCount, 2);
      expect(result.avgCycleLength, 31);
      expect(result.minCycleLength, 30);
      expect(result.maxCycleLength, 31);
      expect(result.lastPeriodStart, DateTime(2026, 7, 1));
      expect(result.flags, isEmpty);
    });

    test('uses the 24–38 day and more-than-8-day reference limits', () {
      final result = DoctorReportAnalyzer.analyze(
        report: _report([
          _cycle(start: '2026-06-01', length: 39, periodDays: 9),
          _cycle(start: '2026-04-23', length: 39, periodDays: 9),
          _cycle(start: '2026-03-15', length: 39, periodDays: 9),
        ]),
      );

      expect(
        result.flags.map((f) => f.type),
        containsAll([
          ClinicalFlagType.longCycle,
          ClinicalFlagType.prolongedPeriod,
        ]),
      );
    });

    test('does not create cycle-pattern flags from only one or two cycles', () {
      final result = DoctorReportAnalyzer.analyze(
        report: _report([
          _cycle(start: '2026-06-01', length: 39, periodDays: 9),
          _cycle(start: '2026-04-23', length: 39, periodDays: 9),
        ]),
      );

      expect(result.analyzedCycleCount, 2);
      expect(result.avgCycleLength, 39);
      expect(result.avgPeriodDuration, 9);
      expect(result.flags, isEmpty);
    });

    test('applies age-aware cycle regularity limits', () {
      final cycles = [
        _cycle(start: '2026-06-01', length: 24),
        _cycle(start: '2026-05-08', length: 32),
        _cycle(start: '2026-04-14', length: 24),
      ];

      final ageThirty = DoctorReportAnalyzer.analyze(
        report: _report(cycles),
        patientAge: 30,
      );
      final ageTwenty = DoctorReportAnalyzer.analyze(
        report: _report(cycles),
        patientAge: 20,
      );

      expect(
        ageThirty.flags.map((f) => f.type),
        contains(ClinicalFlagType.irregularCycle),
      );
      expect(
        ageTwenty.flags.map((f) => f.type),
        isNot(contains(ClinicalFlagType.irregularCycle)),
      );
    });

    test('keeps a severe logged-pain observation deterministic', () {
      final result = DoctorReportAnalyzer.analyze(
        report: _report([_cycle(start: '2026-06-01', length: 28)]),
        snapshot: const HealthSnapshot(averagePainLevel: 3.0),
      );

      expect(
        result.flags.map((f) => f.type),
        contains(ClinicalFlagType.highPain),
      );
    });
  });
}
