import 'package:cycle_aura/features/pregnancy/data/pregnancy_development_content.dart';
import 'package:cycle_aura/features/pregnancy/data/pregnancy_fetal_stage.dart';
import 'package:cycle_aura/features/pregnancy/presentation/pregnancy_baby_realistic_visual.dart';
import 'package:cycle_aura/features/pregnancy/presentation/pregnancy_week_picker.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('fetalStageForGestationalAge', () {
    test('shows the three cellular milestones across gestational week 3', () {
      expect(
        fetalStageForGestationalAge(3, day: 1).kind,
        PregnancyFetalStageKind.zygote,
      );
      expect(
        fetalStageForGestationalAge(3, day: 3).kind,
        PregnancyFetalStageKind.cleavage,
      );
      expect(
        fetalStageForGestationalAge(3, day: 6).kind,
        PregnancyFetalStageKind.blastocyst,
      );
    });

    test('maps later weeks to visibly different development stages', () {
      expect(
        fetalStageForGestationalAge(4).kind,
        PregnancyFetalStageKind.implantation,
      );
      expect(
        fetalStageForGestationalAge(5).kind,
        PregnancyFetalStageKind.week05,
      );
      expect(
        fetalStageForGestationalAge(9).kind,
        PregnancyFetalStageKind.week09,
      );
      expect(
        fetalStageForGestationalAge(22).kind,
        PregnancyFetalStageKind.week22,
      );
      expect(
        fetalStageForGestationalAge(38).kind,
        PregnancyFetalStageKind.week38,
      );
    });

    test('all stage assets are unique and bundled', () async {
      expect(
        pregnancyFetalStages.map((stage) => stage.assetPath).toSet(),
        hasLength(pregnancyFetalStages.length),
      );

      for (final stage in pregnancyFetalStages) {
        final bytes = await rootBundle.load(stage.assetPath);
        expect(bytes.lengthInBytes, greaterThan(0), reason: stage.assetPath);
      }
    });

    test('visual growth is continuous and monotonic across pregnancy', () {
      expect(fetalVisualGrowthProgress(3, day: 1), 0);
      expect(fetalVisualGrowthProgress(40, day: 7), 1);

      var previous = fetalVisualGrowthZoom(3, day: 1);
      for (var week = 3; week <= 40; week++) {
        for (var day = 1; day <= 7; day++) {
          final current = fetalVisualGrowthZoom(week, day: day);
          expect(current, greaterThanOrEqualTo(previous));
          previous = current;
        }
      }

      expect(
        fetalVisualGrowthZoom(22, day: 1),
        lessThan(fetalVisualGrowthZoom(22, day: 7)),
      );
    });
  });

  group('early pregnancy development copy', () {
    test('week 3 remains microscopic and medically distinct', () {
      final info = PregnancyDevelopmentContent.forWeek(3, 'en');

      expect(info.lengthDisplay('en'), '< 1 mm');
      expect(info.lengthDisplay('ar'), 'أقل من 1 مم');
      expect(info.bodyEn, contains('zygote'));
      expect(info.fruitEn, isEmpty);
    });
  });

  testWidgets('realistic visual changes stage without dropping its fallback', (
    tester,
  ) async {
    Widget appFor(int week) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: PregnancyBabyRealisticVisual(
              week: week,
              lang: 'ar',
              size: 260,
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(appFor(5));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(PregnancyBabyRealisticVisual), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(appFor(30));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(PregnancyBabyRealisticVisual), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pregnancy hero uses weekly development card without fruit copy',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SingleChildScrollView(
                child: PregnancyBabyHeroCard(week: 11, lang: 'ar'),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('الجنين هذا الأسبوع'), findsOneWidget);
      expect(find.textContaining('ليمون'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
