import 'package:flutter/material.dart';

import '../../../menstrudel/models/app/user_goal_types_enum.dart';

/// The seven goals shown to users. The legacy sexual-health goal remains in
/// the enum for stored-data compatibility, but is intentionally not offered
/// as a primary onboarding goal.
const visibleUserGoals = <UserGoalTypes>[
  UserGoalTypes.general,
  UserGoalTypes.pregnant,
  UserGoalTypes.conceive,
  UserGoalTypes.avoid,
  UserGoalTypes.menopause,
  UserGoalTypes.pcos,
  UserGoalTypes.postpartum,
];

class UserGoalFeature {
  const UserGoalFeature({
    required this.icon,
    required this.en,
    required this.ar,
  });

  final IconData icon;
  final String en;
  final String ar;

  String forLang(String lang) => lang.startsWith('ar') ? ar : en;
}

class UserGoalExperience {
  const UserGoalExperience({
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    required this.introEn,
    required this.introAr,
    required this.colors,
    required this.features,
  });

  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final String introEn;
  final String introAr;
  final List<Color> colors;
  final List<UserGoalFeature> features;

  String titleFor(String lang) => lang.startsWith('ar') ? titleAr : titleEn;

  String subtitleFor(String lang) =>
      lang.startsWith('ar') ? subtitleAr : subtitleEn;

  String introFor(String lang) => lang.startsWith('ar') ? introAr : introEn;

  LinearGradient get gradient => LinearGradient(colors: colors);
}

UserGoalExperience userGoalExperience(UserGoalTypes goal) {
  return switch (goal) {
    UserGoalTypes.general => const UserGoalExperience(
      titleEn: 'Cycle tracking',
      titleAr: 'متابعة الدورة',
      subtitleEn: 'Predictions, symptoms, and everyday wellbeing patterns.',
      subtitleAr: 'توقعات الدورة، الأعراض، وأنماط صحتك اليومية.',
      introEn:
          'See your cycle clearly, learn what changes across each phase, and build more reliable predictions as you keep logging.',
      introAr:
          'شاهدي دورتك بوضوح، وافهمي تغيّرات كل مرحلة، وساعدي التوقعات على التحسن مع استمرار التسجيل.',
      colors: [Color(0xFFD63384), Color(0xFF8B5CF6)],
      features: [
        UserGoalFeature(
          icon: Icons.event_repeat_rounded,
          en: 'Cycle predictions',
          ar: 'توقعات الدورة',
        ),
        UserGoalFeature(
          icon: Icons.water_drop_outlined,
          en: 'Symptom tracking',
          ar: 'تتبع الأعراض',
        ),
        UserGoalFeature(
          icon: Icons.insights_rounded,
          en: 'Health patterns',
          ar: 'أنماط الصحة',
        ),
      ],
    ),
    UserGoalTypes.pregnant => const UserGoalExperience(
      titleEn: "I'm pregnant",
      titleAr: 'أنا حامل',
      subtitleEn: 'Baby development, pregnancy week, and prenatal tracking.',
      subtitleAr: 'نمو الجنين، أسبوع الحمل، ومتابعة صحتكِ.',
      introEn:
          'Follow realistic baby development week by week, with growth details and practical pregnancy tracking in one place.',
      introAr:
          'تابعي نمو الجنين الواقعي أسبوعًا بأسبوع، مع تفاصيل النمو وأدوات متابعة الحمل في مكان واحد.',
      colors: [Color(0xFFEC407A), Color(0xFFC2185B)],
      features: [
        UserGoalFeature(
          icon: Icons.child_friendly_rounded,
          en: 'Baby development',
          ar: 'نمو الجنين',
        ),
        UserGoalFeature(
          icon: Icons.calendar_view_week_rounded,
          en: 'Pregnancy week',
          ar: 'أسبوع الحمل',
        ),
        UserGoalFeature(
          icon: Icons.monitor_heart_outlined,
          en: 'Kicks & wellbeing',
          ar: 'الركلات والصحة',
        ),
      ],
    ),
    UserGoalTypes.conceive => const UserGoalExperience(
      titleEn: 'Trying to conceive',
      titleAr: 'أحاول الحمل',
      subtitleEn: 'Fertile window, body signals, and test timing.',
      subtitleAr: 'نافذة الخصوبة، إشارات الجسم، وموعد الاختبار.',
      introEn:
          'Combine calendar estimates with LH, temperature, and cervical-mucus signals for a clearer fertility picture.',
      introAr:
          'اجمعي تقدير التقويم مع اختبار LH والحرارة وإشارات الإفرازات لتحصلي على صورة أوضح للخصوبة.',
      colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
      features: [
        UserGoalFeature(
          icon: Icons.favorite_rounded,
          en: 'Fertile window',
          ar: 'نافذة الخصوبة',
        ),
        UserGoalFeature(
          icon: Icons.science_outlined,
          en: 'Ovulation signals',
          ar: 'إشارات الإباضة',
        ),
        UserGoalFeature(
          icon: Icons.event_available_outlined,
          en: 'Test timing',
          ar: 'موعد الاختبار',
        ),
      ],
    ),
    UserGoalTypes.avoid => const UserGoalExperience(
      titleEn: 'Avoiding pregnancy',
      titleAr: 'أتجنّب الحمل',
      subtitleEn:
          'Fertility awareness and protection reminders — not contraception.',
      subtitleAr: 'وعي بالخصوبة وتذكيرات الحماية — وليس وسيلة منع حمل.',
      introEn:
          'Understand estimated fertile days and keep protection routines visible. Calendar estimates alone never guarantee a safe day.',
      introAr:
          'افهمي أيام الخصوبة المقدّرة وحافظي على روتين الحماية واضحًا. تقدير التقويم وحده لا يضمن يومًا آمنًا.',
      colors: [Color(0xFF5C6BC0), Color(0xFF7E57C2)],
      features: [
        UserGoalFeature(
          icon: Icons.shield_outlined,
          en: 'Protection routine',
          ar: 'روتين الحماية',
        ),
        UserGoalFeature(
          icon: Icons.notifications_active_outlined,
          en: 'Reminders',
          ar: 'التذكيرات',
        ),
        UserGoalFeature(
          icon: Icons.warning_amber_rounded,
          en: 'Fertility awareness',
          ar: 'وعي الخصوبة',
        ),
      ],
    ),
    UserGoalTypes.menopause => const UserGoalExperience(
      titleEn: 'Menopause journey',
      titleAr: 'رحلة سنّ الأمل',
      subtitleEn: 'Perimenopause, menopause, symptoms, sleep, and mood.',
      subtitleAr: 'ما قبل انقطاع الطمث وسنّ الأمل، الأعراض، النوم والمزاج.',
      introEn:
          'Track hot flashes, sleep, mood, and changing cycles to discover patterns that support better conversations and care.',
      introAr:
          'تابعي الهبّات الساخنة والنوم والمزاج وتغيّر الدورة لاكتشاف أنماط تساعدكِ في الرعاية والحديث مع الطبيبة.',
      colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
      features: [
        UserGoalFeature(
          icon: Icons.local_fire_department_outlined,
          en: 'Hot flashes',
          ar: 'الهبّات الساخنة',
        ),
        UserGoalFeature(
          icon: Icons.bedtime_outlined,
          en: 'Sleep & mood',
          ar: 'النوم والمزاج',
        ),
        UserGoalFeature(
          icon: Icons.timeline_rounded,
          en: '12-month milestone',
          ar: 'محطة 12 شهرًا',
        ),
      ],
    ),
    UserGoalTypes.pcos => const UserGoalExperience(
      titleEn: 'PCOS management',
      titleAr: 'إدارة تكيس المبايض',
      subtitleEn: 'Cycle gaps, hormonal symptoms, and daily habits.',
      subtitleAr: 'فجوات الدورة، الأعراض الهرمونية، والعادات اليومية.',
      introEn:
          'Connect irregular cycles with skin, mood, energy, and lifestyle patterns so your logs become useful evidence over time.',
      introAr:
          'اربطي عدم انتظام الدورة بالبشرة والمزاج والطاقة والعادات لتصبح تسجيلاتكِ دليلًا مفيدًا مع الوقت.',
      colors: [Color(0xFF26A69A), Color(0xFF00897B)],
      features: [
        UserGoalFeature(
          icon: Icons.date_range_outlined,
          en: 'Cycle gaps',
          ar: 'فجوات الدورة',
        ),
        UserGoalFeature(
          icon: Icons.monitor_heart_outlined,
          en: 'Hormonal symptoms',
          ar: 'الأعراض الهرمونية',
        ),
        UserGoalFeature(
          icon: Icons.spa_outlined,
          en: 'Daily habits',
          ar: 'العادات اليومية',
        ),
      ],
    ),
    UserGoalTypes.postpartum => const UserGoalExperience(
      titleEn: 'Postpartum recovery',
      titleAr: 'التعافي بعد الولادة',
      subtitleEn: 'Recovery week, mood, symptoms, and baby care.',
      subtitleAr: 'أسبوع التعافي، المزاج، الأعراض، ورعاية الطفل.',
      introEn:
          'Follow recovery from the birth date, check in with your mood and symptoms, and keep support guidance close.',
      introAr:
          'تابعي التعافي من تاريخ الولادة، واطمئني على مزاجكِ وأعراضكِ، واحتفظي بإرشادات الدعم قريبة منكِ.',
      colors: [Color(0xFFF06292), Color(0xFFBA68C8)],
      features: [
        UserGoalFeature(
          icon: Icons.calendar_today_outlined,
          en: 'Recovery week',
          ar: 'أسبوع التعافي',
        ),
        UserGoalFeature(
          icon: Icons.mood_outlined,
          en: 'Mood check-in',
          ar: 'متابعة المزاج',
        ),
        UserGoalFeature(
          icon: Icons.child_care_outlined,
          en: 'You & baby',
          ar: 'أنتِ والطفل',
        ),
      ],
    ),
    UserGoalTypes.sexual => const UserGoalExperience(
      titleEn: 'Sexual health',
      titleAr: 'الصحة الجنسية',
      subtitleEn: 'Intimacy, protection, and private health logs.',
      subtitleAr: 'العلاقة، الحماية، وتسجيلات صحية خاصة.',
      introEn: 'Keep private intimacy and protection logs in one place.',
      introAr: 'احتفظي بتسجيلات العلاقة والحماية الخاصة في مكان واحد.',
      colors: [Color(0xFFAB47BC), Color(0xFF7E57C2)],
      features: [
        UserGoalFeature(
          icon: Icons.favorite_outline,
          en: 'Intimacy',
          ar: 'العلاقة',
        ),
        UserGoalFeature(
          icon: Icons.shield_outlined,
          en: 'Protection',
          ar: 'الحماية',
        ),
        UserGoalFeature(
          icon: Icons.lock_outline_rounded,
          en: 'Private logs',
          ar: 'سجل خاص',
        ),
      ],
    ),
  };
}
