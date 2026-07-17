import 'package:cycle_aura/core/theme/app_design_tokens.dart';
import 'package:cycle_aura/core/widgets/aura_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('glass surfaces render on phone in ${brightness.name} mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: brightness,
            colorSchemeSeed: AuraColors.roseDeep,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: AppMeshBackground(
              child: Center(
                child: SizedBox(
                  width: 350,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      AppGlassCard(child: Text('Glass card')),
                      SizedBox(height: 16),
                      AppFloatingGlassPanel(child: Text('Floating glass')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNWidgets(2));
      expect(find.text('Glass card'), findsOneWidget);
      expect(find.text('Floating glass'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
