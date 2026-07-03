// ============================================================================
// test/features/insights/symptom_insight_analyzer_test.dart
// ----------------------------------------------------------------------------
// Tests the offline symptom-pattern analyzer. The analyzer's job is to
// filter noisy single-occurrence rows out of the underlying pattern list
// and normalise the human-friendly phase labels to a stable internal
// vocabulary. We test the filtering thresholds + the phase-name mapping
// by feeding synthetic pattern lists directly — no database required.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/ui/model/phases_percentage.dart';

import 'package:cycle_aura/features/insights/data/symptom_insight_analyzer.dart';

void main() {
  group('SymptomInsightAnalyzer — public thresholds', () {
    test('minimumSamples and minimumConfidence are sane defaults', () {
      // 3 cycles is the smallest sample size we trust. Below this, every
      // symptom is a single anecdote. The confidence floor (60%) excludes
      // symptoms that show up roughly evenly across all phases.
      expect(SymptomInsightAnalyzer.minimumSamples, 3);
      expect(SymptomInsightAnalyzer.minimumConfidence, 60);
    });
  });

  group('SymptomInsight phaseLabel — locale + phase', () {
    SymptomInsight insight({
      String name = 'Cramps',
      String dominantPhase = 'menstruation',
      int confidence = 80,
      int samples = 5,
      int percentageOfCycles = 4,
    }) =>
        SymptomInsight(
          symptomName: name,
          dominantPhase: dominantPhase,
          confidence: confidence,
          samples: samples,
          percentageOfCycles: percentageOfCycles,
          phases: [PhasePercentage(phaseName: 'during your period', percentage: 80)],
        );

    test('Arabic label', () {
      expect(insight().phaseLabel('ar'), 'أثناء الدورة');
    });

    test('Arabic locale variant (ar-EG)', () {
      expect(insight().phaseLabel('ar-EG'), 'أثناء الدورة');
    });

    test('English label', () {
      expect(insight().phaseLabel('en'), 'during your period');
    });

    test('Unknown locale defaults to English', () {
      expect(insight().phaseLabel('fr'), 'during your period');
    });

    test('Unknown phase returns the generic label', () {
      expect(insight(dominantPhase: '').phaseLabel('en'), 'various phases');
      expect(insight(dominantPhase: '').phaseLabel('ar'), 'غير محدد');
    });

    test('Follicular + Luteal labels are localised', () {
      expect(insight(dominantPhase: 'follicular').phaseLabel('ar'),
          'مرحلة الجريب');
      expect(insight(dominantPhase: 'luteal').phaseLabel('ar'),
          'المرحلة الأصفر');
      expect(insight(dominantPhase: 'ovulation').phaseLabel('en'),
          'ovulation');
    });
  });

  group('SymptomInsight.hasEnoughData', () {
    SymptomInsight i(int samples) => SymptomInsight(
          symptomName: 'X',
          dominantPhase: 'menstruation',
          confidence: 80,
          samples: samples,
          percentageOfCycles: samples,
          phases: const [],
        );

    test('true at or above the threshold', () {
      expect(i(3).hasEnoughData, isTrue);
      expect(i(5).hasEnoughData, isTrue);
    });

    test('false below the threshold', () {
      expect(i(2).hasEnoughData, isFalse);
      expect(i(0).hasEnoughData, isFalse);
    });
  });
}