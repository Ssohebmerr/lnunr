import 'package:cycle_aura/core/ai/doctor_report_builder.dart';
import 'package:cycle_aura/core/ai/models/health_snapshot.dart';
import 'package:cycle_aura/features/cycle/presentation/widgets/cycle_signals_card.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester,
    Set<CyclePatternFlag> flags, {
    Locale locale = const Locale('en'),
    VoidCallback? onReport,
  }) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: CycleSignalsCard(
              flags: flags,
              onOpenDoctorReport: onReport,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CycleSignalsCard', () {
    testWidgets('renders nothing when there is no signal', (tester) async {
      await pumpCard(tester, const {});
      expect(find.byType(Card), findsNothing);
      expect(find.textContaining('doctor'), findsNothing);
    });

    testWidgets('shows prolonged cycles with the reassurance first', (
      tester,
    ) async {
      await pumpCard(tester, {CyclePatternFlag.prolongedCycles});

      expect(find.text('Worth mentioning to a doctor'), findsOneWidget);
      expect(
        find.text('Several recent cycles ran longer than 35 days.'),
        findsOneWidget,
      );
      // The card must never read as a diagnosis.
      expect(find.textContaining('PCOS'), findsNothing);
      expect(find.textContaining('not a diagnosis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('lists the most notable signal first', (tester) async {
      await pumpCard(tester, {
        CyclePatternFlag.highVariability,
        CyclePatternFlag.absentCycles,
      });

      final absent = tester.getTopLeft(
        find.text('There was a gap of 90 days or more with no period logged.'),
      );
      final variable = tester.getTopLeft(
        find.text('Your cycle length swung by 9 days or more between cycles.'),
      );
      expect(absent.dy, lessThan(variable.dy));
    });

    testWidgets('offers the doctor report when a handler is given', (
      tester,
    ) async {
      var tapped = false;
      await pumpCard(
        tester,
        {CyclePatternFlag.shortCycles},
        onReport: () => tapped = true,
      );

      await tester.tap(find.text('Open doctor report'));
      expect(tapped, isTrue);
    });

    testWidgets('renders in Arabic without overflow', (tester) async {
      await pumpCard(
        tester,
        {CyclePatternFlag.prolongedCycles, CyclePatternFlag.highVariability},
        locale: const Locale('ar'),
      );

      expect(find.text('يستحق ذكره للطبيب'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('doctor report reaches the same signals without AI or premium', () {
    test('pattern notes are written into the offline report', () {
      const snapshot = HealthSnapshot(
        cycleLength: 47,
        currentPhase: 'Follicular',
        patternSignals: ['prolongedCycles', 'highVariability'],
      );

      final report = DoctorReportBuilder.build(snapshot, languageCode: 'en');
      expect(report, contains('Cycle pattern notes'));
      expect(report, contains('exceeded 35 days'));
      expect(report, contains('9 or more days'));
    });

    test('the section is omitted entirely when there is no signal', () {
      const snapshot = HealthSnapshot(cycleLength: 28);
      final report = DoctorReportBuilder.build(snapshot, languageCode: 'en');
      expect(report, isNot(contains('Cycle pattern notes')));
    });

    test('a temperature-confirmed ovulation is labelled as confirmed', () {
      const snapshot = HealthSnapshot(
        cycleLength: 28,
        ovulationDate: '2026-03-14',
        ovulationConfirmedByTemperature: true,
        temperatureRiseCelsius: 0.31,
      );

      final report = DoctorReportBuilder.build(snapshot, languageCode: 'en');
      expect(report, contains('BBT-confirmed'));
      expect(report, contains('0.31'));
      expect(report, isNot(contains('Ovulation (est.)')));
    });

    test('an estimated ovulation is still labelled an estimate', () {
      const snapshot = HealthSnapshot(
        cycleLength: 28,
        ovulationDate: '2026-03-14',
      );

      final report = DoctorReportBuilder.build(snapshot, languageCode: 'en');
      expect(report, contains('Ovulation (est.)'));
      expect(report, isNot(contains('BBT-confirmed')));
    });
  });
}
