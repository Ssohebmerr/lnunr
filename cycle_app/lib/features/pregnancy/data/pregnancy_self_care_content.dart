import '../../self_care/data/self_care_content.dart';

/// Prenatal self-care tips by trimester and week.
class PregnancySelfCareContent {
  PregnancySelfCareContent._();

  static const affirmations = [
    SelfCareTip(
      en: 'My body is growing life — I deserve rest and kindness.',
      ar: 'جسمي ينمو حياً — أستحق الراحة واللطف.',
    ),
    SelfCareTip(
      en: 'Each week brings us closer. I trust the process.',
      ar: 'كل أسبوع يقربنا. أثق بالرحلة.',
    ),
    SelfCareTip(
      en: 'I am strong, capable, and supported.',
      ar: 'أنا قوية وقادرة ومدعومة.',
    ),
    SelfCareTip(
      en: 'Listening to my body is the best prenatal care.',
      ar: 'الاستماع لجسمي أفضل عناية في الحمل.',
    ),
  ];

  static const journalPrompts = [
    SelfCareTip(
      en: 'How is baby moving today? Any new sensations?',
      ar: 'كيف تحرك الجنين اليوم؟ أي أحاسيس جديدة؟',
    ),
    SelfCareTip(
      en: 'What helped my nausea or discomfort this week?',
      ar: 'ما الذي ساعد على الغثيان أو الانزعاج هذا الأسبوع؟',
    ),
    SelfCareTip(
      en: 'One thing I am excited about for this trimester.',
      ar: 'شيء واحد متحمسة له في هذا الثلث.',
    ),
  ];

  static SelfCareTip tipForWeek(int week, String lang) {
    final w = week.clamp(4, 40);
    if (w <= 12) {
      return SelfCareTip(
        en: 'First trimester: eat small frequent meals, rest when tired, '
            'and take prenatal vitamins as advised by your doctor.',
        ar: 'الثلث الأول: وجبات صغيرة متكررة، ارتحي عند التعب، '
            'وفيتامينات الحمل حسب نصيحة طبيبكِ.',
      );
    }
    if (w <= 27) {
      return SelfCareTip(
        en: 'Second trimester: gentle walks, pelvic floor exercises, '
            'and stay hydrated — energy often peaks now.',
        ar: 'الثلث الثاني: مشي لطيف وتمارين قاع الحوض والماء — '
            'الطاقة غالباً في أعلى مستوياتها.',
      );
    }
    return SelfCareTip(
      en: 'Third trimester: sleep on your side, pack your hospital bag, '
          'and note kick patterns — call your provider for concerns.',
      ar: 'الثلث الأخير: النوم على الجانب، تجهيز حقيبة المستشفى، '
          'وملاحظة حركة الجنين — اتصلي بطبيبكِ عند القلق.',
    );
  }

  static List<SelfCareTip> ritualsForWeek(int week) {
    final w = week.clamp(4, 40);
    if (w <= 12) {
      return const [
        SelfCareTip(en: 'Sip water every hour', ar: 'رشفة ماء كل ساعة'),
        SelfCareTip(en: '10-minute nap if possible', ar: 'قيلولة 10 دقائق إن أمكن'),
        SelfCareTip(en: 'Ginger tea or crackers for nausea', ar: 'زنجبيل أو بسكوت للغثيان'),
        SelfCareTip(en: 'Deep belly breathing', ar: 'تنفس عميق من البطن'),
      ];
    }
    if (w <= 27) {
      return const [
        SelfCareTip(en: 'Walk 15–20 minutes', ar: 'مشي 15–20 دقيقة'),
        SelfCareTip(en: 'Pelvic floor squeeze sets', ar: 'تمارين قاع الحوض'),
        SelfCareTip(en: 'Talk or sing to baby', ar: 'تحدثي أو غنّي للجنين'),
        SelfCareTip(en: 'Side-sleeping pillow setup', ar: 'وسادة للنوم على الجانب'),
      ];
    }
    return const [
      SelfCareTip(en: 'Count kicks once daily', ar: 'عدّي الركلات مرة يومياً'),
      SelfCareTip(en: 'Elevate feet when resting', ar: 'ارفعي القدمين عند الراحة'),
      SelfCareTip(en: 'Practice birth breathing', ar: 'تمرّني على تنفس الولادة'),
      SelfCareTip(en: 'Pack one hospital item', ar: 'جهّزي غرضاً واحداً للمستشفى'),
    ];
  }
}
