import 'package:cycle_aura/features/cycle/presentation/widgets/bbt_tracking_card.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpCard(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: BbtTrackingCard(margin: EdgeInsets.zero),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('explains why temperature matters before any readings exist', (
    tester,
  ) async {
    await pumpCard(tester, const Locale('en'));

    expect(find.text('Confirm your ovulation'), findsOneWidget);
    // The "why" copy only appears while the user has not started.
    expect(find.textContaining('0.2–0.5°C'), findsOneWidget);
    expect(find.text('0 of 9 readings this cycle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the morning reminder starts off and can be switched on', (
    tester,
  ) async {
    await pumpCard(tester, const Locale('en'));

    final toggle = find.byType(SwitchListTile);
    expect(toggle, findsOneWidget);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('temperature_reminder_enabled'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in Arabic on a narrow screen without overflow', (
    tester,
  ) async {
    await pumpCard(tester, const Locale('ar'));

    expect(find.text('أكّدي تبويضك'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
