/// Curated, bilingual content for the menopause management goal.
///
/// Menopause is a life stage, not a countdown — so instead of a week timeline
/// this content is organised into: symptoms worth tracking, short "what's
/// happening" education, and clear guidance on when to involve a doctor.
library;

class MenopauseTip {
  const MenopauseTip({required this.en, required this.ar});
  final String en;
  final String ar;
  String forLang(String lang) => lang.startsWith('ar') ? ar : en;
}

class MenopauseEducationCard {
  const MenopauseEducationCard({
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

class MenopauseContent {
  MenopauseContent._();

  /// Symptoms worth logging so patterns become visible over time.
  static const List<MenopauseTip> trackingFocus = [
    MenopauseTip(en: 'Hot flashes', ar: 'الهبّات الساخنة'),
    MenopauseTip(en: 'Night sweats', ar: 'التعرّق الليلي'),
    MenopauseTip(en: 'Sleep quality', ar: 'جودة النوم'),
    MenopauseTip(en: 'Mood changes', ar: 'تقلّبات المزاج'),
    MenopauseTip(en: 'Cycle changes', ar: 'تغيّر الدورة'),
    MenopauseTip(en: 'Joint aches', ar: 'آلام المفاصل'),
  ];

  /// Two short education cards shown in the "understanding" area.
  static const List<MenopauseEducationCard> education = [
    MenopauseEducationCard(
      titleEn: 'Irregular cycles are expected',
      titleAr: 'عدم انتظام الدورة أمر متوقّع',
      bodyEn:
          'In perimenopause, cycles often become longer, shorter, or skip months entirely as hormone levels shift. Tracking the pattern helps you and your doctor understand where you are in the transition.',
      bodyAr:
          'في مرحلة ما قبل انقطاع الطمث، غالباً تصبح الدورات أطول أو أقصر أو تتخطّى أشهراً مع تغيّر مستويات الهرمونات. تتبّع النمط يساعدكِ وطبيبتكِ على فهم موضعكِ في هذه المرحلة.',
    ),
    MenopauseEducationCard(
      titleEn: 'Small habits ease symptoms',
      titleAr: 'عادات صغيرة تخفّف الأعراض',
      bodyEn:
          'Layered clothing, cool drinks, regular movement, strength work for bones, and a steady sleep routine all help. Caffeine, alcohol, and spicy food can trigger hot flashes for some.',
      bodyAr:
          'الملابس الطبقية والمشروبات الباردة والحركة المنتظمة وتمارين التقوية للعظام وروتين نوم ثابت — كلها تساعد. الكافيين والكحول والطعام الحار قد يحفّز الهبّات عند البعض.',
    ),
  ];

  /// When professional care matters.
  static const MenopauseTip doctorNote = MenopauseTip(
    en: 'Talk to your doctor about heavy or very frequent bleeding, bleeding after 12 months without a period, or symptoms that disrupt your daily life — options like hormone therapy may help.',
    ar: 'راجعي طبيبتكِ عند النزيف الغزير أو المتكرر جداً، أو أي نزيف بعد 12 شهراً بدون دورة، أو الأعراض التي تعطّل حياتكِ اليومية — قد تساعد خيارات مثل العلاج الهرموني.',
  );
}
