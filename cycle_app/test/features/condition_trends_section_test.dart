import 'package:cycle_aura/features/goals/data/condition_log_store.dart';
import 'package:cycle_aura/features/goals/presentation/condition_trends_section.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _harness(UserGoalTypes goal, {Locale locale = const Locale('ar')}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConditionTrendsSection(goal: goal),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the empty state when nothing was ever logged',
      (tester) async {
    await tester.pumpWidget(_harness(UserGoalTypes.menopause));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.query_stats_rounded), findsOneWidget);
  });

  testWidgets('menopause renders hot-flash chart and top symptoms from logs',
      (tester) async {
    final today = DateTime.now();
    await ConditionLogStore.setMetric(
        ConditionLogStore.metricHotFlash, today, 4);
    await ConditionLogStore.toggleSymptom(today, 'hot_flashes');
    await ConditionLogStore.toggleSymptom(
        today.subtract(const Duration(days: 1)), 'hot_flashes');
    await ConditionLogStore.toggleSymptom(today, 'night_sweats');
    await ConditionLogStore.toggleRitual(today, 'short_walks');

    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness(UserGoalTypes.menopause));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Chart card + top-symptoms card + consistency cards all present.
    expect(find.byIcon(Icons.local_fire_department_outlined), findsOneWidget);
    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
    expect(find.text('2/30'), findsOneWidget); // two distinct logged days
    // Hot flashes appears in the chart title and the top-symptom row.
    expect(find.text('الهبّات الساخنة'), findsNWidgets(2));
  });

  testWidgets('postpartum uses the mood metric for the chart', (tester) async {
    final today = DateTime.now();
    await ConditionLogStore.setMetric(ConditionLogStore.metricMood, today, 3);

    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness(UserGoalTypes.postpartum));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byIcon(Icons.sentiment_satisfied_alt_outlined),
      findsOneWidget,
    );
  });

  testWidgets('pcos charts symptoms per day without a metric', (tester) async {
    final today = DateTime.now();
    await ConditionLogStore.toggleSymptom(today, 'acne');
    await ConditionLogStore.toggleSymptom(today, 'cravings');

    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_harness(UserGoalTypes.pcos));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.bubble_chart_outlined), findsOneWidget);
    expect(find.text('1/30'), findsOneWidget);
  });
}
