import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('lune_calendar_test');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => tempDir.path);
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final cycle = MenstrualCycleWidget.init(
      secretKey: 'test-secret-key-0123456789abcdef',
      ivKey: 'test-iv-key-0123',
    );
    await cycle.updateConfiguration(
      cycleLength: 28,
      periodDuration: 5,
      customerId: 'calendar_layout_user',
      lastPeriodDate: DateTime.now().subtract(const Duration(days: 8)),
      defaultLanguage: Languages.arabic,
    );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    try {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    } catch (_) {
      // SQLite can keep the test database handle alive briefly on Windows.
    }
  });

  testWidgets('weekly calendar uses correct Arabic weekdays without overflow', (
    tester,
  ) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(
      _arabicApp(
        SizedBox(
          width: 390,
          height: 300,
          child: MenstrualCycleCalenderView(
            themeColor: const Color(0xFFD83179),
            daySelectedColor: const Color(0xFFCDB5F5),
            backgroundColorCode: Colors.transparent,
            onDataChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الأحد'), findsOneWidget);
    expect(find.text('الأربعاء'), findsOneWidget);
    expect(find.text('السبت'), findsOneWidget);
    expect(find.text('شمس'), findsNothing);
    expect(find.text('تزوج'), findsNothing);
    expect(find.text('قعد'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('monthly calendar fits a phone card without layout exceptions', (
    tester,
  ) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(
      _arabicApp(
        const SizedBox(
          width: 390,
          height: 450,
          child: MenstrualCycleMonthlyCalenderView(
            themeColor: Color(0xFFD83179),
            daySelectedColor: Color(0xFFCDB5F5),
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الأحد'), findsOneWidget);
    expect(find.text('الأربعاء'), findsOneWidget);
    expect(find.text('تعديل أيام الدورة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _arabicApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFFD83179),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

Future<void> _setPhoneSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
