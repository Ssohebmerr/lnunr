import 'package:cycle_aura/features/cycle/presentation/widgets/lune_cycle_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders Arabic cycle text as normal widgets without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Center(
            child: LuneCycleRing(
              size: 248,
              phase: 'الطور الجُريبي',
              cycleDay: 8,
              cycleLength: 28,
              periodDuration: 5,
            ),
          ),
        ),
      ),
    );

    expect(find.text('الطور الجُريبي'), findsNWidgets(2));
    expect(find.text('8'), findsOneWidget);
    expect(find.text('من 28 يومًا'), findsOneWidget);
    expect(find.text('الإباضة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
