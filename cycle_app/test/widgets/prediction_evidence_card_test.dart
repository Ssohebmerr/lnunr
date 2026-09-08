import 'package:cycle_aura/features/cycle/data/cycle_bridge_service.dart';
import 'package:cycle_aura/features/home/widgets/home_feed_sections.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

void main() {
  testWidgets('prediction evidence stays readable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const accuracy = CyclePredictionAccuracy(
      evaluatedCycles: 5,
      withinOneDay: 3,
      withinTwoDays: 4,
      withinThreeDays: 5,
      withinPersonalWindow: 5,
      meanAbsoluteError: 1.4,
      medianAbsoluteError: 1,
      p80AbsoluteError: 2,
    );
    const data = CycleDashboardData(
      phase: 'Luteal',
      nextPeriod: 'Jul 18, 2026',
      nextPeriodRange: 'Jul 16, 2026 – Jul 20, 2026',
      ovulation: 'Jul 4, 2026',
      ovulationRange: 'Jul 2, 2026 – Jul 6, 2026',
      predictionWindowDays: 2,
      ovulationCalibrated: false,
      cycleDay: 24,
      periodDay: 0,
      cycleRegularity: 94,
      cycleRegularityStatus: 'Regular',
      periodRegularity: 90,
      periodRegularityStatus: 'Regular',
      avgCycleLength: 28,
      avgPeriodDuration: 5,
      totalCycles: 7,
      pregnancyChances: 'Estimated low',
      expectedDueDate: '',
      pregnancyWeek: 0,
      trimester: 0,
      isPeriodStarted: false,
      isOvulationDay: false,
      expectedPregnancyTestDate: '',
      predictionConfidence: CyclePredictionConfidence.strong,
      predictionConfidenceScore: 0.91,
      predictionAccuracy: accuracy,
      completedCycleCount: 6,
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: HomeKeyDatesCard(data: data),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Strong'), findsOneWidget);
    expect(
      find.text('Within 2 days for 4 of your last 5 testable cycles'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a temperature-confirmed ovulation reads as observed, not guessed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const data = CycleDashboardData(
      phase: 'Luteal',
      nextPeriod: '2026-07-18',
      nextPeriodRange: 'Jul 16, 2026 – Jul 20, 2026',
      ovulation: '2026-07-04',
      // A confirmed shift collapses the window, so there is no range.
      ovulationRange: '',
      predictionWindowDays: 2,
      ovulationCalibrated: true,
      ovulationConfirmedByTemperature: true,
      temperatureShiftCelsius: 0.31,
      cycleDay: 24,
      periodDay: 0,
      cycleRegularity: 94,
      cycleRegularityStatus: 'Regular',
      periodRegularity: 90,
      periodRegularityStatus: 'Regular',
      avgCycleLength: 28,
      avgPeriodDuration: 5,
      totalCycles: 7,
      pregnancyChances: 'Estimated low',
      expectedDueDate: '',
      pregnancyWeek: 0,
      trimester: 0,
      isPeriodStarted: false,
      isOvulationDay: false,
      expectedPregnancyTestDate: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: HomeKeyDatesCard(data: data),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Confirmed by your temperature — up 0.31°C'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
