import 'package:cycle_aura/core/ai/models/ai_insight.dart';
import 'package:cycle_aura/core/ai/models/health_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('condition insight prompts', () {
    test('condition tracking reaches the prompt map', () {
      const snapshot = HealthSnapshot(
        userGoal: 'pcos',
        conditionTracking: {
          'goal': 'pcos',
          'trackedDays': 22,
          'symptomDaysOutOf30': {'Irregular periods': 12, 'Acne': 8},
        },
      );

      final map = snapshot.toPromptMap();
      expect(map['conditionTracking'], isA<Map<String, dynamic>>());
      expect(
        (map['conditionTracking'] as Map)['symptomDaysOutOf30'],
        containsPair('Acne', 8),
      );
    });

    test('an empty condition history is left out of the prompt entirely', () {
      const snapshot = HealthSnapshot(userGoal: 'menopause');
      expect(snapshot.toPromptMap().containsKey('conditionTracking'), isFalse);
    });
  });

  group('insight types', () {
    test('every life-stage goal has its own insight type', () {
      expect(AiInsightType.values, contains(AiInsightType.pcosInsight));
      expect(AiInsightType.values, contains(AiInsightType.menopauseInsight));
      expect(AiInsightType.values, contains(AiInsightType.postpartumInsight));
      expect(AiInsightType.values, contains(AiInsightType.logReflection));
    });

    test('insight types round-trip through the cache format', () {
      for (final type in AiInsightType.values) {
        final insight = AiInsight(
          type: type,
          text: 'x',
          generatedAt: DateTime(2026, 3, 1),
        );
        final restored = AiInsight.fromJson(insight.toJson());
        expect(restored.type, type);
      }
    });
  });
}
