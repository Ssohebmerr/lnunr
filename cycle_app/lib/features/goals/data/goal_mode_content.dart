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
              ? 'Today is ovulation day — your best chance this cycle.'
              : 'Track your fertile window and time intimacy with confidence.',
          ar: data.isOvulationDay
              ? 'اليوم يوم الإباضة — أفضل فرصة هذا الشهر.'
              : 'تتبّعي نافذة الخصوبة ووقّتي العلاقة بثقة.',
        ),
      UserGoalTypes.avoid => GoalModeTip(
          en: _avoidSubtitle(data, lang),
          ar: _avoidSubtitleAr(data),
        ),
      UserGoalTypes.general => GoalModeTip(
          en: 'Understand your cycle, spot patterns, and care for your whole self.',
          ar: 'افهمي دورتك، لاحظي الأنماط، واعتني بنفسك.',
        ),
      _ => GoalModeTip(
          en: 'Your cycle insights are personalized to your goal.',
          ar: 'رؤى دورتك مخصّصة لهدفك.',
        ),
    };
  }

  static String _avoidSubtitle(CycleDashboardData data, String lang) {
    final level = GoalModeAnalytics.fertilityLevel(data);
    return switch (level) {
      FertilityLevel.high =>
        'Fertility is high today — extra protection is wise if avoiding pregnancy.',
      FertilityLevel.moderate =>
        'Fertility may be rising — stay aware and use your chosen protection.',
      FertilityLevel.low =>
        'Fertility is lower today — still use protection if you are not trying to conceive.',
      FertilityLevel.unknown =>
        'Know your fertile days and use reliable protection.',
    };
  }

  static String _avoidSubtitleAr(CycleDashboardData data) {
    final level = GoalModeAnalytics.fertilityLevel(data);
    return switch (level) {
      FertilityLevel.high =>
        'الخصوبة عالية اليوم — الحماية الإضافية مهمة إذا كنتِ تتجنّبين الحمل.',
      FertilityLevel.moderate =>
        'الخصوبة قد ترتفع — ابقي واعية واستخدمي وسيلة الحماية المناسبة.',
      FertilityLevel.low =>
        'الخصوبة أقل اليوم — استمري بالحماية إذا لا تخطّطين للحمل.',
      FertilityLevel.unknown =>
        'اعرفي أيام الخصوبة واستخدمي حماية موثوقة.',
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
          en: 'Ovulation day: stay hydrated, rest well, and consider timing intimacy today and tomorrow.',
          ar: 'يوم الإباضة: اشربي ماءً، ارتحي، وفكّري بتوقيت العلاقة اليوم وغداً.',
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
          en: 'High-fertility phase: double-check your contraception method is up to date.',
          ar: 'مرحلة خصوبة عالية: تأكدي أن وسيلة منع الحمل محدّثة وفعّالة.',
        );
      }
      return GoalModeTip(
        en: 'Track your cycle consistently — it makes fertile-day awareness much more reliable.',
        ar: 'تتبّعي دورتك بانتظام — يجعل معرفة أيام الخصوبة أدق بكثير.',
      );
    }
    return GoalModeTip(
      en: 'Small daily logs build a clearer picture of your health over time.',
      ar: 'التسجيل اليومي البسيط يبني صورة أوضح لصحتك مع الوقت.',
    );
  }

  static List<GoalModeTip> checklist(
    UserGoalTypes goal,
    String lang,
  ) {
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
          GoalModeTip(en: 'Contraception taken / used', ar: 'منع الحمل مأخوذ/مستخدم'),
          GoalModeTip(en: 'Checked fertile days', ar: 'راجعت أيام الخصوبة'),
          GoalModeTip(en: 'Hydration goal', ar: 'هدف الترطيب'),
          GoalModeTip(en: 'Stress check-in', ar: 'لحظة هدوء'),
        ],
      _ => const [
          GoalModeTip(en: 'Morning hydration', ar: 'ترطيب الصباح'),
          GoalModeTip(en: '5-min stretch', ar: 'تمدد 5 دقائق'),
          GoalModeTip(en: 'Mood check-in', ar: 'تسجيل المزاج'),
          GoalModeTip(en: 'Evening wind-down', ar: 'استرخاء المساء'),
        ],
    };
  }
}
