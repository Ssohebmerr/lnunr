const int minPregnancyVisualWeek = 3;
const int maxPregnancyVisualWeek = 40;

enum PregnancyFetalStageKind {
  zygote,
  cleavage,
  blastocyst,
  implantation,
  week05,
  week07,
  week09,
  week12,
  week16,
  week22,
  week30,
  week38,
}

class PregnancyFetalStage {
  const PregnancyFetalStage({
    required this.kind,
    required this.assetPath,
    required this.labelEn,
    required this.labelAr,
  });

  final PregnancyFetalStageKind kind;
  final String assetPath;
  final String labelEn;
  final String labelAr;

  String labelFor(String lang) => lang.startsWith('ar') ? labelAr : labelEn;

  String shortLabelFor(String lang) {
    final ar = lang.startsWith('ar');
    return switch (kind) {
      PregnancyFetalStageKind.zygote => ar ? 'نطفة مخصّبة' : 'Zygote',
      PregnancyFetalStageKind.cleavage =>
        ar ? 'انقسام الخلايا' : 'Cell division',
      PregnancyFetalStageKind.blastocyst => ar ? 'كيسة أريمية' : 'Blastocyst',
      _ => labelFor(lang),
    };
  }

  String magnifiedNoteFor(String lang) => lang.startsWith('ar')
      ? 'صورة مكبّرة للتوضيح · الحجم الحقيقي موضح بالأسفل'
      : 'Magnified for clarity · actual size shown below';
}

const _assetRoot = 'assets/pregnancy/fetal_stages';

const pregnancyFetalStages = <PregnancyFetalStage>[
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.zygote,
    assetPath: '$_assetRoot/stage_01_zygote.webp',
    labelEn: 'Zygote · fertilized egg',
    labelAr: 'اللاقحة · نطفة مخصّبة',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.cleavage,
    assetPath: '$_assetRoot/stage_02_cleavage.webp',
    labelEn: 'Early cell division',
    labelAr: 'الانقسامات الخلوية الأولى',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.blastocyst,
    assetPath: '$_assetRoot/stage_03_blastocyst.webp',
    labelEn: 'Blastocyst',
    labelAr: 'الكيسة الأريمية',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.implantation,
    assetPath: '$_assetRoot/stage_04_implantation.webp',
    labelEn: 'Implantation begins',
    labelAr: 'بداية التعلّق والانغراس',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week05,
    assetPath: '$_assetRoot/stage_05_week05.webp',
    labelEn: 'Early embryo',
    labelAr: 'جنين في بدايات التشكّل',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week07,
    assetPath: '$_assetRoot/stage_06_week07.webp',
    labelEn: 'Limb buds appear',
    labelAr: 'ظهور براعم الأطراف',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week09,
    assetPath: '$_assetRoot/stage_07_week09.webp',
    labelEn: 'Early fetus',
    labelAr: 'بداية المرحلة الجنينية',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week12,
    assetPath: '$_assetRoot/stage_08_week12.webp',
    labelEn: 'Features take shape',
    labelAr: 'الملامح تأخذ شكلها',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week16,
    assetPath: '$_assetRoot/stage_09_week16.webp',
    labelEn: 'Growing and moving',
    labelAr: 'نمو وحركة أوضح',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week22,
    assetPath: '$_assetRoot/stage_10_week22.webp',
    labelEn: 'Developing senses',
    labelAr: 'تطوّر الحواس والحركة',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week30,
    assetPath: '$_assetRoot/stage_11_week30.webp',
    labelEn: 'Gaining body fat',
    labelAr: 'يزداد امتلاء الجسم',
  ),
  PregnancyFetalStage(
    kind: PregnancyFetalStageKind.week38,
    assetPath: '$_assetRoot/stage_12_week38.webp',
    labelEn: 'Near-term baby',
    labelAr: 'قريب من اكتمال النمو',
  ),
];

PregnancyFetalStage fetalStageForGestationalAge(int week, {int day = 7}) {
  final safeWeek = week.clamp(minPregnancyVisualWeek, maxPregnancyVisualWeek);
  final safeDay = day.clamp(1, 7);

  if (safeWeek <= 3) {
    if (safeDay <= 2) return pregnancyFetalStages[0];
    if (safeDay <= 4) return pregnancyFetalStages[1];
    return pregnancyFetalStages[2];
  }
  if (safeWeek == 4) return pregnancyFetalStages[3];
  if (safeWeek == 5) return pregnancyFetalStages[4];
  if (safeWeek <= 7) return pregnancyFetalStages[5];
  if (safeWeek <= 10) return pregnancyFetalStages[6];
  if (safeWeek <= 14) return pregnancyFetalStages[7];
  if (safeWeek <= 18) return pregnancyFetalStages[8];
  if (safeWeek <= 25) return pregnancyFetalStages[9];
  if (safeWeek <= 33) return pregnancyFetalStages[10];
  return pregnancyFetalStages[11];
}

/// Continuous 0..1 progress used by the pregnancy hero animation.
///
/// Unlike [fetalStageForGestationalAge], this value does not jump when the
/// artwork changes. That lets the same stage artwork gently grow as the user
/// moves between neighbouring weeks, while the medically staged assets still
/// provide the larger developmental changes.
double fetalVisualGrowthProgress(int week, {int day = 7}) {
  final safeWeek = week.clamp(
    minPregnancyVisualWeek,
    maxPregnancyVisualWeek,
  );
  final safeDay = day.clamp(1, 7);
  final elapsedDays =
      (safeWeek - minPregnancyVisualWeek) * 7 + (safeDay - 1);
  final totalDays =
      (maxPregnancyVisualWeek - minPregnancyVisualWeek) * 7 + 6;
  return (elapsedDays / totalDays).clamp(0.0, 1.0);
}

/// A restrained camera zoom that increases continuously throughout pregnancy.
/// The fetal stage artwork already carries the main anatomical size change;
/// this value adds smooth visual continuity without cropping it aggressively.
double fetalVisualGrowthZoom(int week, {int day = 7}) {
  final progress = fetalVisualGrowthProgress(week, day: day);
  return 1.035 + (0.08 * progress);
}
