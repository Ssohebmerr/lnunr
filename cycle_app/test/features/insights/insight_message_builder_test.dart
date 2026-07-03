// ============================================================================
// test/features/insights/insight_message_builder_test.dart
// ----------------------------------------------------------------------------
// Tests the templates that turn [SymptomInsight]s into user-facing strings.
// We don't lock down exact wording (it gets iterated on) — just shape:
//   - includes the symptom name
//   - includes the phase label
//   - includes the confidence %
//   - the tip is non-empty for the four well-known phases, null for unknown
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/ui/model/phases_percentage.dart';

import 'package:cycle_aura/features/insights/data/insight_message_builder.dart';
import 'package:cycle_aura/features/insights/data/symptom_insight_analyzer.dart';

SymptomInsight _insight({
  required String name,
  required String phase,
  int confidence = 80,
  int samples = 5,
}) =>
    SymptomInsight(
      symptomName: name,
      dominantPhase: phase,
      confidence: confidence,
      samples: samples,
      percentageOfCycles: samples,
      phases: [PhasePercentage(phaseName: '', percentage: 80)],
    );

void main() {
  const builder = InsightMessageBuilder();

  group('buildHeadline', () {
    test('Arabic headline includes symptom + phase + %', () {
      final h = builder.buildHeadline(
          _insight(name: 'صداع', phase: 'luteal'),
          isArabic: true);
      expect(h, contains('صداع'));
      expect(h, contains('80'));
      expect(h, contains('الأصفر'));
    });

    test('English headline includes symptom + phase + %', () {
      final h = builder.buildHeadline(
          _insight(name: 'Cramps', phase: 'menstruation'),
          isArabic: false);
      expect(h, contains('Cramps'));
      expect(h, contains('80'));
      expect(h, contains('period'));
    });

    test('headline handles 0% confidence gracefully', () {
      final h = builder.buildHeadline(
          _insight(name: 'X', phase: 'menstruation', confidence: 0),
          isArabic: true);
      expect(h, contains('0%'));
      expect(h, isNot(contains('null')));
    });
  });

  group('buildSubtitle', () {
    test('Arabic subtitle includes the sample count', () {
      final s = builder.buildSubtitle(
          _insight(name: 'X', phase: 'menstruation', samples: 7),
          isArabic: true);
      expect(s, contains('7'));
      expect(s, contains('دورات'));
    });

    test('English subtitle includes the sample count', () {
      final s = builder.buildSubtitle(
          _insight(name: 'X', phase: 'menstruation', samples: 4),
          isArabic: false);
      expect(s, contains('4'));
      expect(s, contains('cycle'));
    });
  });

  group('buildTip', () {
    test('non-null for the four known phases', () {
      for (final phase in ['menstruation', 'luteal', 'ovulation', 'follicular']) {
        final arTip = builder.buildTip(
            _insight(name: 'X', phase: phase), isArabic: true);
        final enTip = builder.buildTip(
            _insight(name: 'X', phase: phase), isArabic: false);
        expect(arTip, isNotNull, reason: 'AR tip missing for $phase');
        expect(enTip, isNotNull, reason: 'EN tip missing for $phase');
        expect(arTip!.length, greaterThan(20));
        expect(enTip!.length, greaterThan(20));
      }
    });

    test('null for unknown phase', () {
      expect(builder.buildTip(
          _insight(name: 'X', phase: 'unknown'), isArabic: true), isNull);
      expect(builder.buildTip(
          _insight(name: 'X', phase: 'unknown'), isArabic: false), isNull);
    });

    test('tips never make medical claims', () {
      // Medical safety — never say "this is a sign of X" or recommend
      // medication. We just sanity-check no forbidden phrase sneaks in.
      const forbidden = ['diagnose', 'take ibuprofen', 'PCOS', 'endometriosis',
                         'تشخيص', 'إيبوبروفين'];
      for (final phase in ['menstruation', 'luteal', 'ovulation', 'follicular']) {
        for (final isArabic in [true, false]) {
          final tip = builder.buildTip(
              _insight(name: 'X', phase: phase), isArabic: isArabic)!;
          for (final phrase in forbidden) {
            expect(tip.toLowerCase(), isNot(contains(phrase.toLowerCase())),
                reason: '"$phrase" appeared in tip: $tip');
          }
        }
      }
    });
  });
}