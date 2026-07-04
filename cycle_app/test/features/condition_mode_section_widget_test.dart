import 'package:cycle_aura/features/goals/presentation/condition_mode_section.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConditionModeSection renders without overflow at phone width',
      (tester) async {
    tester.view.physicalSize = const Size(360, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ar'),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConditionModeSection(
              icon: Icons.spa_rounded,
              title: 'رحلة سنّ الأمل',
              subtitle:
                  'الدورات غير المنتظمة طبيعية في هذه المرحلة — تتبّعي الأعراض وابحثي عن الراحة.',
              gradient: const [Color(0xFF8D6E63), Color(0xFFBCAAA4)],
              cycleContextLabel: 'انتظام الدورة',
              cycleContextValue: '62%',
              trackLabels: const [
                'الهبّات الساخنة',
                'التعرّق الليلي',
                'جودة النوم',
                'تقلّبات المزاج',
                'تغيّر الدورة',
                'آلام المفاصل',
              ],
              education: const [
                ConditionEducation(
                  title: 'عدم انتظام الدورة أمر متوقّع',
                  body:
                      'في مرحلة ما قبل انقطاع الطمث، غالباً تصبح الدورات أطول أو أقصر أو تتخطّى أشهراً مع تغيّر مستويات الهرمونات.',
                ),
              ],
              dailyTip:
                  'ارتدي طبقات خفيفة، اشربي ماءً بارداً، وتنفّسي بهدوء عند الهبّة الساخنة.',
              rituals: const [
                'ماء بارد وملابس طبقات',
                'ترطيب البشرة',
                'مشي تقوية وتوازن',
                'استرخاء قبل النوم',
              ],
              doctorNote:
                  'راجعي طبيبتكِ عند النزيف الغزير أو المتكرر جداً، أو أي نزيف بعد 12 شهراً بدون دورة.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
