import 'package:cycle_aura/features/goals/data/user_goal_experience.dart';
import 'package:cycle_aura/features/goals/presentation/goal_choice_card.dart';
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seven user-facing goals remain distinct and legacy-safe', () {
    expect(visibleUserGoals, hasLength(7));
    expect(visibleUserGoals.toSet(), hasLength(7));
    expect(visibleUserGoals, contains(UserGoalTypes.pregnant));
    expect(visibleUserGoals, isNot(contains(UserGoalTypes.sexual)));

    final remainingAfterPregnancy = visibleUserGoals
        .where((goal) => goal != UserGoalTypes.pregnant)
        .toList();
    expect(remainingAfterPregnancy, hasLength(6));
  });

  test('every enum goal has complete bilingual experience content', () {
    for (final goal in UserGoalTypes.values) {
      final experience = userGoalExperience(goal);
      expect(experience.titleFor('ar'), isNotEmpty, reason: goal.dbName);
      expect(experience.titleFor('en'), isNotEmpty, reason: goal.dbName);
      expect(experience.subtitleFor('ar'), isNotEmpty, reason: goal.dbName);
      expect(experience.subtitleFor('en'), isNotEmpty, reason: goal.dbName);
      expect(experience.introFor('ar'), isNotEmpty, reason: goal.dbName);
      expect(experience.introFor('en'), isNotEmpty, reason: goal.dbName);
      expect(experience.features, hasLength(3), reason: goal.dbName);
      expect(experience.colors, hasLength(2), reason: goal.dbName);
    }
  });

  test(
    'goal names are consistent and avoiding pregnancy stays safety clear',
    () {
      expect(
        userGoalExperience(UserGoalTypes.general).titleFor('ar'),
        'متابعة الدورة',
      );
      expect(
        userGoalExperience(UserGoalTypes.postpartum).titleFor('ar'),
        'التعافي بعد الولادة',
      );
      expect(
        userGoalExperience(UserGoalTypes.menopause).titleFor('ar'),
        'رحلة سنّ الأمل',
      );

      final avoid = userGoalExperience(UserGoalTypes.avoid);
      expect(avoid.subtitleFor('ar'), contains('ليس وسيلة منع حمل'));
      expect(avoid.subtitleFor('en'), contains('not contraception'));
      expect(avoid.introFor('ar'), contains('لا يضمن يومًا آمنًا'));
    },
  );

  testWidgets('goal card stays readable on a narrow Arabic phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: GoalChoiceCard(
              goal: UserGoalTypes.menopause,
              selected: true,
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('رحلة سنّ الأمل'), findsOneWidget);
    expect(find.textContaining('ما قبل انقطاع الطمث'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
