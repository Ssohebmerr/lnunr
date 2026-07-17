import 'package:cycle_aura/features/home/chat_tab.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness({
    required String text,
    required bool expanded,
    required VoidCallback onToggle,
    double width = 250,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ar'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: SizedBox(
              width: width,
              child: AiResponseText(
                span: TextSpan(
                  text: text,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
                expanded: expanded,
                onToggle: onToggle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('long AI reply shows seven lines then expands and collapses', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var expanded = false;
    final text = List.generate(
      12,
      (index) => 'السطر رقم ${index + 1} فيه معلومة واضحة للمستخدمة.',
    ).join('\n');

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => harness(
          text: text,
          expanded: expanded,
          onToggle: () => setState(() => expanded = !expanded),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final collapsed = tester.widget<SelectableText>(
      find.byKey(AiResponseText.collapsedTextKey),
    );
    expect(collapsed.maxLines, AiResponseText.collapsedLines);
    expect(find.text('عرض المزيد'), findsOneWidget);

    await tester.ensureVisible(find.byKey(AiResponseText.toggleKey));
    await tester.tap(find.byKey(AiResponseText.toggleKey));
    await tester.pumpAndSettle();

    final full = tester.widget<SelectableText>(
      find.byKey(AiResponseText.expandedTextKey),
    );
    expect(full.maxLines, isNull);
    expect(find.text('عرض أقل'), findsOneWidget);

    await tester.ensureVisible(find.byKey(AiResponseText.toggleKey));
    await tester.tap(find.byKey(AiResponseText.toggleKey));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SelectableText>(find.byKey(AiResponseText.collapsedTextKey))
          .maxLines,
      AiResponseText.collapsedLines,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reply that fits seven lines is never folded', (tester) async {
    final text = List.generate(7, (index) => 'سطر ${index + 1}').join('\n');

    await tester.pumpWidget(
      harness(text: text, expanded: false, onToggle: () {}, width: 280),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AiResponseText.toggleKey), findsNothing);
    expect(
      tester
          .widget<SelectableText>(find.byKey(AiResponseText.collapsedTextKey))
          .maxLines,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
