/// Week-by-week postpartum recovery guidance (mother-focused).
///
/// Mirrors the pregnancy content pattern: a small, curated set of recovery
/// stages keyed by the number of weeks since birth, each with a milestone
/// headline, a body-recovery note, a baby-development note, and a gentle
/// self-care focus — all bilingual (EN/AR).
///
/// Ranges are inclusive of the lower bound; [forWeek] picks the last stage
/// whose start week is <= the current recovery week, so any week past the
/// final stage keeps showing the most advanced guidance.
library;

class PostpartumStage {
  const PostpartumStage({
    required this.startWeek,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.babyEn,
    required this.babyAr,
    required this.focusEn,
    required this.focusAr,
  });

  /// First recovery week this stage applies to (1-based).
  final int startWeek;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final String babyEn;
  final String babyAr;
  final String focusEn;
  final String focusAr;

  String titleFor(String lang) => lang.startsWith('ar') ? titleAr : titleEn;
  String bodyFor(String lang) => lang.startsWith('ar') ? bodyAr : bodyEn;
  String babyFor(String lang) => lang.startsWith('ar') ? babyAr : babyEn;
  String focusFor(String lang) => lang.startsWith('ar') ? focusAr : focusEn;
}

class PostpartumRecoveryContent {
  PostpartumRecoveryContent._();

  static const List<PostpartumStage> _stages = [
    PostpartumStage(
      startWeek: 1,
      titleEn: 'The fourth trimester begins',
      titleAr: 'الثلث الرابع يبدأ',
      bodyEn:
          'Your body is healing from birth. Bleeding (lochia) is normal, cramping as the uterus shrinks is expected, and deep rest is the priority. Accept help with everything you can.',
      bodyAr:
          'جسمكِ يتعافى من الولادة. النزيف (النفاس) طبيعي، والمغص مع انكماش الرحم متوقّع، والراحة العميقة هي الأولوية. اقبلي المساعدة في كل ما تستطيعين.',
      babyEn:
          'Your newborn sleeps 16–18 hours a day and feeds every 2–3 hours. Skin-to-skin contact steadies their breathing, temperature, and heartbeat.',
      babyAr:
          'مولودكِ ينام 16–18 ساعة يومياً ويرضع كل 2–3 ساعات. ملامسة الجلد للجلد تُثبّت تنفّسه وحرارته ونبض قلبه.',
      focusEn: 'Rest whenever the baby sleeps. Hydrate with every feed.',
      focusAr: 'استريحي كلما نام الطفل. اشربي الماء مع كل رضعة.',
    ),
    PostpartumStage(
      startWeek: 3,
      titleEn: 'Settling into a rhythm',
      titleAr: 'الاستقرار على إيقاع',
      bodyEn:
          'Afterpains ease and lochia lightens. Gentle short walks help circulation and mood. Do not lift anything heavier than your baby yet.',
      bodyAr:
          'آلام ما بعد الولادة تخفّ والنفاس يقلّ. المشي القصير اللطيف يحسّن الدورة الدموية والمزاج. لا ترفعي شيئاً أثقل من طفلكِ بعد.',
      babyEn:
          'Your baby is more alert between feeds and may hold your gaze. The first social smiles are just weeks away.',
      babyAr:
          'طفلكِ أكثر انتباهاً بين الرضعات وقد يثبّت نظره عليكِ. أول ابتسامة اجتماعية على بُعد أسابيع قليلة.',
      focusEn: 'Short walks in daylight. Eat warm, iron-rich meals.',
      focusAr: 'مشي قصير في ضوء النهار. تناولي وجبات دافئة غنية بالحديد.',
    ),
    PostpartumStage(
      startWeek: 6,
      titleEn: 'The 6-week check',
      titleAr: 'فحص الأسبوع السادس',
      bodyEn:
          'Most mothers have their postnatal check now — a good time to discuss healing, mood, and contraception. If you were cleared, you can gradually resume gentle exercise.',
      bodyAr:
          'معظم الأمهات يجرين فحص ما بعد الولادة الآن — وقت مناسب لمناقشة التعافي والمزاج ومنع الحمل. إن سمح لكِ الطبيب، يمكنكِ استئناف التمارين الخفيفة تدريجياً.',
      babyEn:
          'Your baby smiles socially, coos, and follows moving objects. Feeding may space out a little as their stomach grows.',
      babyAr:
          'طفلكِ يبتسم اجتماعياً ويُصدر أصواتاً ويتابع الأشياء المتحركة. قد تتباعد الرضعات قليلاً مع نمو معدته.',
      focusEn: 'Ask about pelvic-floor exercises at your check-up.',
      focusAr: 'اسألي عن تمارين قاع الحوض في موعد الفحص.',
    ),
    PostpartumStage(
      startWeek: 9,
      titleEn: 'Rebuilding strength',
      titleAr: 'إعادة بناء القوة',
      bodyEn:
          'Energy slowly returns. Core and pelvic-floor recovery matter more than intensity — consistency over strain. Watch for any persistent low mood.',
      bodyAr:
          'الطاقة تعود ببطء. تعافي عضلات البطن وقاع الحوض أهم من شدة التمرين — الاستمرارية لا الإجهاد. انتبهي لأي مزاج منخفض مستمر.',
      babyEn:
          'Your baby pushes up during tummy time, grasps toys, and laughs. Night sleep may start to lengthen.',
      babyAr:
          'طفلكِ يرفع رأسه أثناء وقت الاستلقاء على البطن، يمسك الألعاب، ويضحك. قد يبدأ نوم الليل بالتطوّل.',
      focusEn: 'Gentle core work. Protect your sleep where you can.',
      focusAr: 'تمارين خفيفة للبطن. احمي نومكِ قدر الإمكان.',
    ),
    PostpartumStage(
      startWeek: 13,
      titleEn: 'Finding your new normal',
      titleAr: 'إيجاد توازنكِ الجديد',
      bodyEn:
          'Three months on, healing is well advanced. Cycles may return (later if breastfeeding). Keep prioritising sleep, nutrition, and moments for yourself.',
      bodyAr:
          'بعد ثلاثة أشهر، التعافي متقدّم. قد تعود الدورة (متأخرة إن كنتِ ترضعين). استمري بإعطاء الأولوية للنوم والتغذية ولحظاتٍ لنفسكِ.',
      babyEn:
          'Your baby reaches for things, rolls, and babbles. Their personality is blossoming.',
      babyAr:
          'طفلكِ يمدّ يده للأشياء، يتقلّب، ويثرثر. شخصيته تتفتّح.',
      focusEn: 'Reconnect with things that feel like you.',
      focusAr: 'أعيدي التواصل مع ما يشبهكِ ويسعدكِ.',
    ),
    PostpartumStage(
      startWeek: 25,
      titleEn: 'Six months and beyond',
      titleAr: 'ستة أشهر وما بعدها',
      bodyEn:
          'Recovery is largely complete, though it is normal for it to take a full year to feel fully yourself. Keep moving, keep nourishing, and check in with your feelings.',
      bodyAr:
          'التعافي شبه مكتمل، ومن الطبيعي أن يستغرق عاماً كاملاً لتشعري بذاتكِ تماماً. استمري بالحركة والتغذية وتفقّد مشاعركِ.',
      babyEn:
          'Your baby sits with support, explores textures, and may start solids. Every day brings a new skill.',
      babyAr:
          'طفلكِ يجلس بمساعدة، يستكشف الملمس، وقد يبدأ الطعام الصلب. كل يوم يجلب مهارة جديدة.',
      focusEn: 'Celebrate how far you have both come.',
      focusAr: 'احتفلي بالمسافة التي قطعتماها معاً.',
    ),
  ];

  /// Recovery stage for the given week since birth (1-based).
  static PostpartumStage forWeek(int week) {
    final w = week < 1 ? 1 : week;
    PostpartumStage match = _stages.first;
    for (final stage in _stages) {
      if (stage.startWeek <= w) {
        match = stage;
      } else {
        break;
      }
    }
    return match;
  }

  /// Recovery week (1-based) from the baby's birth date.
  static int recoveryWeek(DateTime birthDate, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final days = today.difference(birthDate).inDays;
    if (days < 0) return 1;
    return (days ~/ 7) + 1;
  }
}
