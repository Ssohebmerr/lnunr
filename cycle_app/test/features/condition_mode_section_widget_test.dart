import 'package:cycle_aura/features/goals/presentation/condition_mode_section.dart';
import 'package:cycle_aura/features/goals/presentation/condition_widgets.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Interactive chips / rituals read from ConditionLogStore (SharedPreferences).
    SharedPreferences.setMockInitialValues({});
  });

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
              trackItems: const [
                ConditionItem(key: 'hot_flashes', label: 'الهبّات الساخنة'),
                ConditionItem(key: 'night_sweats', label: 'التعرّق الليلي'),
                ConditionItem(key: 'sleep_quality', label: 'جودة النوم'),
                ConditionItem(key: 'mood_changes', label: 'تقلّبات المزاج'),
                ConditionItem(key: 'cycle_changes', label: 'تغيّر الدورة'),
                ConditionItem(key: 'joint_aches', label: 'آلام المفاصل'),
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
              ritualItems: const [
                ConditionItem(key: 'cool_water', label: 'ماء بارد وملابس طبقات'),
                ConditionItem(key: 'skincare', label: 'ترطيب البشرة'),
                ConditionItem(key: 'strength_walk', label: 'مشي تقوية وتوازن'),
                ConditionItem(key: 'wind_down', label: 'استرخاء قبل النوم'),
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
