import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import 'goal_mode_analytics.dart';
import '../../cycle/data/cycle_bridge_service.dart';

class GoalModeTip {
  const GoalModeTip({required this.en, required this.ar});
  final String en;
  final String ar;
  String forLang(String lang) => lang.startsWith('ar') ? ar : en;
}

/// Localized copy, checklists, and rituals per user goal.
class GoalModeContent {
  GoalModeContent._();

  static GoalModeTip headerSubtitle(
    UserGoalTypes goal,
    CycleDashboardData data,
    String lang,
  ) {
    return switch (goal) {
      UserGoalTypes.conceive => GoalModeTip(
        en: data.isOvulationDay
            ? 'Your calendar estimate points to ovulation today — confirm with a body signal when possible.'
            : 'Track your estimated fertile window and confirm it with LH, temperature, or cervical mucus.',
        ar: data.isOvulationDay
            ? 'تقدير التقويم يشير إلى الإباضة اليوم — أكّديه بإشارة من جسمكِ إن أمكن.'
            : 'تتبّعي نافذة الخصوبة المقدّرة وأكّديها بـ LH أو الحرارة أو الإفرازات.',
      ),
      UserGoalTypes.avoid => GoalModeTip(
        en: _avoidSubtitle(data, lang),
        ar: _avoidSubtitleAr(data),
      ),
      UserGoalTypes.general => GoalModeTip(
        en: 'Understand your cycle, spot patterns, and care for your whole self.',
        ar: 'افهمي دورتك، لاحظي الأنماط، واعتني بنفسك.',
      ),
      UserGoalTypes.pregnant => GoalModeTip(
        en: data.trimester > 0
            ? 'Trimester ${data.trimester} · week ${data.pregnancyWeek.clamp(1, 42)} of your journey.'
            : 'Track every step of your pregnancy week by week.',
        ar: data.trimester > 0
            ? 'الثلث ${data.trimester} · الأسبوع ${data.pregnancyWeek.clamp(1, 42)} من رحلة الحمل.'
            : 'تابعي كل خطوة من حملك أسبوعياً.',
      ),
      UserGoalTypes.menopause => GoalModeTip(
        en: data.cycleDay > 0
            ? 'Irregular cycles are normal here — track symptoms and find relief.'
            : 'Notice patterns in hot flashes, sleep, and mood — you\'re not alone.',
        ar: data.cycleDay > 0
            ? 'الدورات غير المنتظمة طبيعية في هذه المرحلة — تتبّعي الأعراض وابحثي عن الراحة.'
            : 'لاحظي أنماط الهبّات الساخنة والنوم والمزاج — لستِ وحدكِ.',
      ),
      UserGoalTypes.pcos => GoalModeTip(
        en: 'Track cycle irregularity, hormonal skin & mood shifts — patterns guide care.',
        ar: 'تابعي انتظام الدورة، البشرة الهرمونية وتقلّبات المزاج — الأنماط ترشد الرعاية.',
      ),
      UserGoalTypes.postpartum => GoalModeTip(
        en: 'Healing takes time — log rest, mood, and feeding in small daily steps.',
        ar: 'الشفاء يأخذ وقتاً — سجّلي الراحة والمزاج والرضاعة في خطوات يومية صغيرة.',
      ),
      UserGoalTypes.sexual => GoalModeTip(
        en: 'Track intimacy and protection — clear data, better decisions.',
        ar: 'تتبّعي العلاقة والحماية — بيانات واضحة، قرارات أفضل.',
      ),
    };
  }

  static String _avoidSubtitle(CycleDashboardData data, String lang) {
    final level = GoalModeAnalytics.fertilityLevel(data);
    return switch (level) {
      FertilityLevel.high =>
        'Estimated fertility is high — use reliable contraception if avoiding pregnancy.',
      FertilityLevel.moderate =>
        'Fertility may be rising — calendar estimates never guarantee a safe day.',
      FertilityLevel.low =>
        'The estimate is lower today, but it is not a guaranteed safe day — keep using protection.',
      FertilityLevel.unknown =>
        'There are no guaranteed safe days from calendar data alone — use reliable protection.',
    };
  }

  static String _avoidSubtitleAr(CycleDashboardData data) {
    final level = GoalModeAnalytics.fertilityLevel(data);
    return switch (level) {
      FertilityLevel.high =>
        'الخصوبة المقدّرة مرتفعة — استخدمي وسيلة منع حمل موثوقة إذا كنتِ تتجنّبين الحمل.',
      FertilityLevel.moderate =>
        'قد ترتفع الخصوبة — تقدير التقويم لا يضمن يومًا آمنًا.',
      FertilityLevel.low =>
        'التقدير أقل اليوم، لكنه ليس يومًا آمنًا مضمونًا — استمري بالحماية.',
      FertilityLevel.unknown =>
        'لا توجد أيام آمنة مضمونة من التقويم وحده — استخدمي حماية موثوقة.',
    };
  }

  static GoalModeTip dailyTip(
    UserGoalTypes goal,
    CycleDashboardData data,
    String lang,
  ) {
    if (goal.isConceiveMode) {
      if (data.isOvulationDay) {
        return GoalModeTip(
          en: 'Estimated ovulation day: consider confirming with an LH test, temperature, or cervical mucus.',
          ar: 'يوم إباضة مقدّر: حاولي التأكيد باختبار LH أو الحرارة أو الإفرازات.',
        );
      }
      return GoalModeTip(
        en: 'Log symptoms daily, take folic acid as advised, and note cervical mucus changes.',
        ar: 'سجّلي الأعراض يومياً، خذي حمض الفوليك حسب النصيحة، ولاحظي تغيّر الإفرازات.',
      );
    }
    if (goal.isAvoidMode) {
      final level = GoalModeAnalytics.fertilityLevel(data);
      if (level == FertilityLevel.high) {
        return GoalModeTip(
          en: 'Estimated high-fertility phase: double-check that your contraception is current and reliable.',
          ar: 'مرحلة خصوبة مقدّرة مرتفعة: تأكدي أن وسيلة منع الحمل محدّثة وموثوقة.',
        );
      }
      return GoalModeTip(
        en: 'Keep tracking for better estimates, but never treat a calendar day as guaranteed safe.',
        ar: 'استمري بالتسجيل لتحسين التقدير، لكن لا تعتبري أي يوم في التقويم آمنًا بشكل مضمون.',
      );
    }
    if (goal.isPregnancyMode) {
      return GoalModeTip(
        en: 'Hydrate well, take your prenatal vitamins, and note any new symptoms for your next visit.',
        ar: 'اشربي ماءً كافياً، خذي فيتامينات الحمل، ودوّني أي أعراض جديدة لزيارة طبيبتكِ.',
      );
    }
    if (goal == UserGoalTypes.menopause) {
      return GoalModeTip(
        en: 'Layer light clothes, sip cool water, and breathe slowly when a hot flash rises.',
        ar: 'ارتدي طبقات خفيفة، اشربي ماءً بارداً، وتنفّسي بهدوء عند الهبّة الساخنة.',
      );
    }
    if (goal == UserGoalTypes.pcos) {
      return GoalModeTip(
        en: 'A high-fiber meal and a short walk after eating can steady insulin and mood today.',
        ar: 'وجبة غنية بالألياف ومشية قصيرة بعد الأكل قد تُهدّئ الإنسولين والمزاج اليوم.',
      );
    }
    if (goal == UserGoalTypes.postpartum) {
      return GoalModeTip(
        en: 'Sleep when baby sleeps, drink water with every feed, and speak kindly to yourself today.',
        ar: 'نامي عندما ينام طفلكِ، اشربي ماءً مع كل رضعة، وكلّمي نفسكِ بلطف اليوم.',
      );
    }
    return GoalModeTip(
      en: 'Small daily logs build a clearer picture of your health over time.',
      ar: 'التسجيل اليومي البسيط يبني صورة أوضح لصحتك مع الوقت.',
    );
  }

  static List<GoalModeTip> checklist(UserGoalTypes goal, String lang) {
    return switch (goal) {
      UserGoalTypes.conceive => const [
        GoalModeTip(
          en: 'Take prenatal vitamins / folic acid',
          ar: 'فيتامينات الحمل / حمض الفوليك',
        ),
        GoalModeTip(
          en: 'Note ovulation signs (mucus, temperature)',
          ar: 'لاحظي علامات الإباضة (إفرازات، حرارة)',
        ),
        GoalModeTip(
          en: 'Time intimacy during your fertile window',
          ar: 'وقّتي العلاقة خلال نافذة الخصوبة',
        ),
        GoalModeTip(
          en: 'Reduce stress — it supports hormonal balance',
          ar: 'قلّلي التوتر — يدعم توازن الهرمونات',
        ),
      ],
      UserGoalTypes.avoid => const [
        GoalModeTip(
          en: 'Use your contraception method consistently',
          ar: 'استخدمي وسيلة منع الحمل بانتظام',
        ),
        GoalModeTip(
          en: 'Know your fertile days on the calendar',
          ar: 'اعرفي أيام الخصوبة على التقويم',
        ),
        GoalModeTip(
          en: 'Have backup protection during high-fertility days',
          ar: 'احتفظي بحماية إضافية في أيام الخصوبة العالية',
        ),
        GoalModeTip(
          en: 'Talk to your provider about the best method for you',
          ar: 'ناقشي مع طبيبكِ أفضل وسيلة لكِ',
        ),
      ],
      UserGoalTypes.pregnant => const [
        GoalModeTip(
          en: 'Take prenatal vitamins daily',
          ar: 'خذي فيتامينات الحمل يومياً',
        ),
        GoalModeTip(
          en: 'Hydrate — at least 8 glasses of water',
          ar: 'الترطيب — 8 أكواب ماء على الأقل',
        ),
        GoalModeTip(
          en: 'Note fetal movement in the evening',
          ar: 'سجّلي حركة الجنين في المساء',
        ),
        GoalModeTip(
          en: 'Schedule the next prenatal visit on time',
          ar: 'احجزي موعد المتابعة التالية في وقته',
        ),
      ],
      UserGoalTypes.menopause => const [
        GoalModeTip(
          en: 'Note hot flashes (time, duration, triggers)',
          ar: 'سجّلي الهبّات الساخنة (الوقت، المدة، المحفّزات)',
        ),
        GoalModeTip(
          en: 'Track sleep quality and night sweats',
          ar: 'تابعي جودة النوم والتعرّق الليلي',
        ),
        GoalModeTip(
          en: 'Move gently — walks, stretching, strength',
          ar: 'تحرّكي بلطف — مشي، تمدّد، تقوية',
        ),
        GoalModeTip(
          en: 'Talk to your doctor about symptoms that disrupt daily life',
          ar: 'ناقشي طبيبتكِ في الأعراض التي تعطّل يومكِ',
        ),
      ],
      UserGoalTypes.pcos => const [
        GoalModeTip(
          en: 'Log cycle length & flow changes monthly',
          ar: 'سجّلي طول الدورة والتدفق شهرياً',
        ),
        GoalModeTip(
          en: 'Note skin & hair changes (acne, hair growth)',
          ar: 'لاحظي تغيّرات البشرة والشعر (حبوب، شعر زائد)',
        ),
        GoalModeTip(
          en: 'Prefer high-fiber, low-sugar meals',
          ar: 'فضّلي وجبات غنية بالألياف وقليلة السكر',
        ),
        GoalModeTip(
          en: 'Discuss lab work with your endocrinologist',
          ar: 'ناقشي تحاليلكِ مع طبيبة الغدد الصمّاء',
        ),
      ],
      UserGoalTypes.postpartum => const [
        GoalModeTip(
          en: 'Rest whenever your baby sleeps',
          ar: 'استريحي كلما نام طفلكِ',
        ),
        GoalModeTip(
          en: 'Track mood and energy — baby blues are real',
          ar: 'تابعي المزاج والطاقة — اكتئاب ما بعد الولادة حقيقي',
        ),
        GoalModeTip(
          en: 'Hydrate and eat warm, nourishing meals',
          ar: 'اشربي ماءً وكُلي وجبات دافئة ومغذية',
        ),
        GoalModeTip(
          en: 'Reach out to your provider for any concerning symptom',
          ar: 'تواصلي مع طبيبتكِ عند أي عرض يقلقكِ',
        ),
      ],
      _ => const [
        GoalModeTip(
          en: 'Log mood, flow, and symptoms in +',
          ar: 'سجّلي المزاج والتدفق والأعراض في +',
        ),
        GoalModeTip(
          en: 'Drink enough water for your phase',
          ar: 'اشربي ماءً كافياً لمرحلتك',
        ),
        GoalModeTip(
          en: 'Move gently — walk, stretch, or breathe',
          ar: 'تحرّكي بلطف — مشي أو تمدد أو تنفس',
        ),
        GoalModeTip(
          en: 'Review your cycle report monthly',
          ar: 'راجعي تقرير دورتك شهرياً',
        ),
      ],
    };
  }

  static List<GoalModeTip> rituals(UserGoalTypes goal) {
    return switch (goal) {
      UserGoalTypes.conceive => const [
        GoalModeTip(en: 'Log cervical mucus', ar: 'سجّلي نوع الإفرازات'),
        GoalModeTip(en: 'Take folic acid', ar: 'حمض الفوليك'),
        GoalModeTip(en: '8 glasses of water', ar: '8 أكواب ماء'),
        GoalModeTip(en: '7+ hours sleep', ar: '7+ ساعات نوم'),
      ],
      UserGoalTypes.avoid => const [
        GoalModeTip(
          en: 'Contraception taken / used',
          ar: 'منع الحمل مأخوذ/مستخدم',
        ),
        GoalModeTip(en: 'Checked fertile days', ar: 'راجعت أيام الخصوبة'),
        GoalModeTip(en: 'Hydration goal', ar: 'هدف الترطيب'),
        GoalModeTip(en: 'Stress check-in', ar: 'لحظة هدوء'),
      ],
      UserGoalTypes.pregnant => const [
        GoalModeTip(en: 'Prenatal vitamin', ar: 'فيتامين الحمل'),
        GoalModeTip(en: 'Kick / movement log', ar: 'تسجيل حركة الجنين'),
        GoalModeTip(en: '8 glasses of water', ar: '8 أكواب ماء'),
        GoalModeTip(en: 'Side-sleep & stretch', ar: 'نوم على الجنب وتمدد'),
      ],
      UserGoalTypes.menopause => const [
        GoalModeTip(
          en: 'Cool water & layered clothes',
          ar: 'ماء بارد وملابس طبقات',
        ),
        GoalModeTip(en: 'Skincare moisture', ar: 'ترطيب البشرة'),
        GoalModeTip(en: 'Strength + balance walk', ar: 'مشي تقوية وتوازن'),
        GoalModeTip(en: 'Wind-down before bed', ar: 'استرخاء قبل النوم'),
      ],
      UserGoalTypes.pcos => const [
        GoalModeTip(en: 'High-fiber breakfast', ar: 'فطور غني بالألياف'),
        GoalModeTip(en: 'Movement after meals', ar: 'تحرّك بعد الوجبات'),
        GoalModeTip(en: 'Skin check-in', ar: 'فحص البشرة'),
        GoalModeTip(en: 'Cycle log', ar: 'تسجيل الدورة'),
      ],
      UserGoalTypes.postpartum => const [
        GoalModeTip(en: 'Pelvic rest breath', ar: 'تنفّس راحة الحوض'),
        GoalModeTip(en: 'Feed + water', ar: 'رضاعة + ماء'),
        GoalModeTip(en: 'Mood check-in', ar: 'تسجيل المزاج'),
        GoalModeTip(
          en: 'Skin-to-skin with baby',
          ar: 'ملامسة جلد لجلد مع طفلكِ',
        ),
      ],
      _ => const [
        GoalModeTip(en: 'Morning hydration', ar: 'ترطيب الصباح'),
        GoalModeTip(en: '5-min stretch', ar: 'تمدد 5 دقائق'),
        GoalModeTip(en: 'Mood check-in', ar: 'تسجيل المزاج'),
        GoalModeTip(en: 'Evening wind-down', ar: 'استرخاء المساء'),
      ],
    };
  }

  /// Returns goal-mode specific metric tiles for the Reports tab.
  /// Reuses analytics + tip infrastructure so the data layer doesn't drift.
  static List<String> reportMetricKeys(UserGoalTypes goal) {
    return switch (goal) {
      UserGoalTypes.conceive => const [
        'ovulation',
        'pregnancyChance',
        'testDate',
        'cycleDay',
      ],
      UserGoalTypes.avoid => const [
        'fertilityToday',
        'ovulation',
        'nextPeriod',
        'regularity',
      ],
      UserGoalTypes.pregnant => const [
        'pregnancyWeek',
        'trimester',
        'dueDate',
        'prenatalVisits',
      ],
      UserGoalTypes.menopause => const [
        'cycleRegularity',
        'avgCycleLength',
        'sleepQuality',
        'hotFlashCount',
      ],
      UserGoalTypes.pcos => const [
        'cycleRegularity',
        'cycleVariation',
        'avgCycleLength',
        'symptomLoad',
      ],
      UserGoalTypes.postpartum => const [
        'recoveryDay',
        'moodScore',
        'sleepHours',
        'feedingCount',
      ],
      _ => const [
        'cycleRegularity',
        'avgCycleLength',
        'avgPeriod',
        'totalCycles',
      ],
    };
  }
}
