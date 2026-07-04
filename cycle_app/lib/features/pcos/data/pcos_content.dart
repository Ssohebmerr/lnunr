/// Curated, bilingual content for the PCOS management goal.
///
/// PCOS is a long-term condition, so the experience centers on tracking
/// irregularity + symptoms, understanding lifestyle levers, and knowing when
/// to involve an endocrinologist — not a cycle countdown.
library;

class PcosTip {
  const PcosTip({required this.en, required this.ar});
  final String en;
  final String ar;
  String forLang(String lang) => lang.startsWith('ar') ? ar : en;
}

class PcosEducationCard {
  const PcosEducationCard({
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
  });

  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;

  String titleFor(String lang) => lang.startsWith('ar') ? titleAr : titleEn;
  String bodyFor(String lang) => lang.startsWith('ar') ? bodyAr : bodyEn;
}

class PcosContent {
  PcosContent._();

  /// Symptoms worth logging to reveal patterns for you and your doctor.
  static const List<PcosTip> trackingFocus = [
    PcosTip(en: 'Cycle length', ar: 'طول الدورة'),
    PcosTip(en: 'Flow changes', ar: 'تغيّر التدفّق'),
    PcosTip(en: 'Skin (acne)', ar: 'البشرة (حبوب)'),
    PcosTip(en: 'Hair changes', ar: 'تغيّرات الشعر'),
    PcosTip(en: 'Mood & energy', ar: 'المزاج والطاقة'),
    PcosTip(en: 'Weight trend', ar: 'اتجاه الوزن'),
  ];

  static const List<PcosEducationCard> education = [
    PcosEducationCard(
      titleEn: 'Why cycles are irregular',
      titleAr: 'لماذا تكون الدورة غير منتظمة',
      bodyEn:
          'With PCOS, ovulation can be infrequent or absent, so cycles are often long or unpredictable. Logging every period — even the gaps — builds the pattern your doctor needs to guide treatment.',
      bodyAr:
          'مع تكيّس المبايض، قد تكون الإباضة نادرة أو غائبة، فتصبح الدورات طويلة أو غير متوقّعة. تسجيل كل دورة — حتى الفجوات — يبني النمط الذي تحتاجه طبيبتكِ لتوجيه العلاج.',
    ),
    PcosEducationCard(
      titleEn: 'Lifestyle is powerful',
      titleAr: 'نمط الحياة مؤثّر',
      bodyEn:
          'High-fiber, lower-sugar meals, movement after eating, strength training, and steady sleep can improve insulin sensitivity and, for many, help cycles regulate over time.',
      bodyAr:
          'الوجبات الغنية بالألياف والأقل سكراً، والحركة بعد الأكل، وتمارين القوة، والنوم المنتظم — تحسّن حساسية الإنسولين، وقد تساعد الدورة على الانتظام مع الوقت لدى كثيرات.',
    ),
  ];

  static const PcosTip doctorNote = PcosTip(
    en: 'See an endocrinologist or gynecologist about very long gaps between periods, difficulty conceiving, or fast changes in weight, skin, or hair. Bloodwork and a tailored plan make a real difference.',
    ar: 'راجعي طبيبة الغدد الصمّاء أو النساء عند الفجوات الطويلة جداً بين الدورات، أو صعوبة الحمل، أو تغيّرات سريعة في الوزن أو البشرة أو الشعر. التحاليل وخطة مخصّصة تُحدث فرقاً حقيقياً.',
  );
}
