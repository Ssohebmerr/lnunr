class SelfCareTip {
  const SelfCareTip({required this.en, required this.ar});
  final String en;
  final String ar;

  String forLocale(String code) => code.startsWith('ar') ? ar : en;
}

class SelfCareContent {
  SelfCareContent._();

  static const affirmations = [
    SelfCareTip(
      en: 'My body is wise. I listen with kindness.',
      ar: 'جسمي حكيم. أستمع له بلطف.',
    ),
    SelfCareTip(
      en: 'Rest is productive. I deserve gentle care today.',
      ar: 'الراحة إنتاجية. أستحق عناية لطيفة اليوم.',
    ),
    SelfCareTip(
      en: 'I am not alone in this cycle — support is here.',
      ar: 'لست وحدي في هذه الدورة — الدعم موجود.',
    ),
    SelfCareTip(
      en: 'Small rituals create calm. One breath at a time.',
      ar: 'الطقوس الصغيرة تصنع الهدوء. نفس واحد في كل مرة.',
    ),
    SelfCareTip(
      en: 'I honor what I feel without judgment.',
      ar: 'أحترم ما أشعر به دون حكم.',
    ),
  ];

  static const journalPrompts = [
    SelfCareTip(
      en: 'What does my body need most today?',
      ar: 'ماذا يحتاج جسمي أكثر اليوم؟',
    ),
    SelfCareTip(
      en: 'One thing that brought me comfort this week.',
      ar: 'شيء واحد منحني راحة هذا الأسبوع.',
    ),
    SelfCareTip(
      en: 'How can I be gentler with myself tomorrow?',
      ar: 'كيف أكون ألطف مع نفسي غداً؟',
    ),
  ];

  static SelfCareTip tipForPhase(String? phase, String lang) {
    final p = (phase ?? '').toLowerCase();
    if (p.contains('menstrual') || p.contains('period') || p.contains('حيض')) {
      return SelfCareTip(
        en: 'Period phase: warm drinks, heat pad, and slow movement help.',
        ar: 'مرحلة الحيض: المشروبات الدافئة والكمادات والحركة البطيئة تساعد.',
      );
    }
    if (p.contains('follicular') || p.contains('جريبي') || p.contains('نمو')) {
      return SelfCareTip(
        en: 'Follicular phase: great time for new habits and light cardio.',
        ar: 'مرحلة الجريبي: وقت مناسب لعادات جديدة وتمارين خفيفة.',
      );
    }
    if (p.contains('ovulation') || p.contains('fertil') || p.contains('إباض') || p.contains('خصوب')) {
      return SelfCareTip(
        en: 'Ovulation phase: hydrate well and balance activity with rest.',
        ar: 'مرحلة الإباضة: اشربي ماءً كافياً ووازني بين النشاط والراحة.',
      );
    }
    if (p.contains('luteal') || p.contains('أصفار') || p.contains('بعد الإباض')) {
      return SelfCareTip(
        en: 'Luteal phase: prioritize sleep, magnesium-rich foods, and calm.',
        ar: 'مرحلة أصفار: أولوي للنوم وأطعمة المغنيسيوم والهدوء.',
      );
    }
    return SelfCareTip(
      en: 'Take 5 minutes today just for you — breathe, stretch, or journal.',
      ar: 'خذي 5 دقائق اليوم لنفسك — تنفسي أو تمددي أو اكتبي.',
    );
  }
}
