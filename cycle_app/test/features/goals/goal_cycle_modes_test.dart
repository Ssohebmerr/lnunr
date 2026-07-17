import 'package:cycle_aura/features/cycle/data/cycle_bridge_service.dart';
import 'package:cycle_aura/features/cycle/presentation/widgets/ovulation_log_card.dart';
import 'package:cycle_aura/features/goals/presentation/goal_cycle_mode_section.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CycleDashboardData _data({bool ovulation = false}) {
  return CycleDashboardData(
    phase: ovulation ? 'Ovulation' : 'Follicular',
    nextPeriod: 'Jul 28',
    nextPeriodRange: 'Jul 27 – Jul 29',
    ovulation: 'Jul 14',
    ovulationRange: 'Jul 13 – Jul 15',
    predictionWindowDays: 1,
    ovulationCalibrated: false,
    cycleDay: ovulation ? 14 : 8,
    periodDay: 0,
    cycleRegularity: 84,
    cycleRegularityStatus: 'Regular',
    periodRegularity: 82,
    periodRegularityStatus: 'Regular',
    avgCycleLength: 28,
    avgPeriodDuration: 5,
    totalCycles: 6,
    pregnancyChances: ovulation ? 'Estimated high' : 'Estimated moderate',
    expectedDueDate: '',
    pregnancyWeek: 0,
    trimester: 0,
    isPeriodStarted: false,
    isOvulationDay: ovulation,
    expectedPregnancyTestDate: 'Jul 29',
  );
}

Future<void> _pumpGoal(WidgetTester tester, UserGoalTypes goal) async {
  tester.view.physicalSize = const Size(360, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: GoalModeHomeSection(
            data: _data(ovulation: goal == UserGoalTypes.conceive),
            goal: goal,
            showRing: false,
            showWeekCalendar: false,
            onOpenCalendar: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('conceive goal surfaces ovulation logging before more details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpGoal(tester, UserGoalTypes.conceive);

    expect(find.text('Trying to conceive'), findsOneWidget);
    expect(find.byType(OvulationLogCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avoid goal keeps the calendar safety boundary prominent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpGoal(tester, UserGoalTypes.avoid);

    expect(find.text('Avoiding pregnancy'), findsOneWidget);
    expect(find.textContaining('not contraception'), findsWidgets);
    expect(
      find.text(
        'Calendar estimates are for awareness only. They are not contraception and never guarantee a safe day. Keep using a reliable method that fits you.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.medication_outlined), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
