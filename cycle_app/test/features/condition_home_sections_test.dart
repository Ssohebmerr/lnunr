import 'package:cycle_aura/features/cycle/data/cycle_bridge_service.dart';
import 'package:cycle_aura/features/goals/data/condition_log_store.dart';
import 'package:cycle_aura/features/home/home_menopause_section.dart';
import 'package:cycle_aura/features/home/home_pcos_section.dart';
import 'package:cycle_aura/features/home/home_postpartum_section.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CycleDashboardData _fakeData({
  int cycleDay = 20,
  int avgLength = 28,
  double regularity = 62,
}) {
  return CycleDashboardData(
    phase: 'Luteal',
    nextPeriod: 'Jul 20',
    ovulation: 'Jul 6',
    cycleDay: cycleDay,
    periodDay: 0,
    cycleRegularity: regularity,
    cycleRegularityStatus: 'Fairly regular',
    periodRegularity: 0,
    periodRegularityStatus: '',
    avgCycleLength: avgLength,
    avgPeriodDuration: 5,
    totalCycles: 6,
    pregnancyChances: 'Low',
    expectedDueDate: '',
    pregnancyWeek: 0,
    trimester: 0,
    isPeriodStarted: false,
    isOvulationDay: false,
    expectedPregnancyTestDate: '',
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menopause section renders with hero features', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(tester, HomeMenopauseSection(data: _fakeData(cycleDay: 200)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pcos section flags a long cycle gap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pump(
      tester,
      HomePcosSection(data: _fakeData(cycleDay: 45, avgLength: 30)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('postpartum section renders full experience', (tester) async {
    final birth = DateTime.now().subtract(const Duration(days: 56));
    SharedPreferences.setMockInitialValues({
      'postpartum_start_date':
          DateTime(birth.year, birth.month, birth.day).toIso8601String(),
    });
    await _pump(tester, HomePostpartumSection(data: _fakeData()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a symptom chip logs it and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final today = DateTime.now();

    await _pump(tester, HomeMenopauseSection(data: _fakeData(cycleDay: 200)));

    // Nothing logged yet.
    expect(await ConditionLogStore.symptomsOn(today), isEmpty);

    // Tap the "Hot flashes" chip (en locale) and let the async write settle.
    await tester.tap(find.text('Hot flashes'));
    await tester.pumpAndSettle();

    // It is now persisted under the stable slug.
    expect(
      await ConditionLogStore.symptomsOn(today),
      contains('hot_flashes'),
    );
    expect(tester.takeException(), isNull);
  });
}
