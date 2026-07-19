import 'package:cycle_aura/core/cms/app_settings.dart';
import 'package:cycle_aura/core/widgets/app_surface.dart';
import 'package:cycle_aura/features/cycle/data/cycle_bridge_service.dart';
import 'package:cycle_aura/features/home/widgets/home_explore_rail.dart';
import 'package:cycle_aura/features/pregnancy/presentation/home_pregnancy_section.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pregnancyData = CycleDashboardData(
  phase: 'Pregnancy',
  nextPeriod: '—',
  nextPeriodRange: '',
  ovulation: '—',
  ovulationRange: '',
  predictionWindowDays: 0,
  ovulationCalibrated: false,
  cycleDay: 4,
  periodDay: 0,
  cycleRegularity: 0,
  cycleRegularityStatus: '',
  periodRegularity: 0,
  periodRegularityStatus: '',
  avgCycleLength: 28,
  avgPeriodDuration: 5,
  totalCycles: 4,
  pregnancyChances: '',
  expectedDueDate: 'February 12, 2027',
  pregnancyWeek: 3,
  trimester: 1,
  isPeriodStarted: false,
  isOvulationDay: false,
  expectedPregnancyTestDate: '',
);

Future<void> _pumpNarrow(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 2600);
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
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('pregnancy weekly card has one clear non-duplicated title', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpNarrow(tester, const HomePregnancySection(data: _pregnancyData));

    expect(find.text('Your body this week'), findsOneWidget);
    expect(find.text('More this week'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('explore shortcuts fit a narrow home card without overflow', (
    tester,
  ) async {
    await _pumpNarrow(
      tester,
      const HomeExploreRail(settings: AppSettings(), showHeader: false),
    );

    expect(find.byType(AppQuickTile), findsAtLeastNWidgets(4));
    expect(find.text('Explore'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
