import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';

/// A single evidence-informed self-care topic (nutrition, movement, rest,
/// or mind) within a cycle phase. Body text is practical, non-clinical, and
/// never diagnostic.
class LibraryTopic {
  const LibraryTopic({
    required this.icon,
    required this.en,
    required this.ar,
    required this.bodyEn,
    required this.bodyAr,
  });

  final IconData icon;
  final String en;
  final String ar;
  final String bodyEn;
  final String bodyAr;

  String title(String lang) => lang.startsWith('ar') ? ar : en;
  String body(String lang) => lang.startsWith('ar') ? bodyAr : bodyEn;
}

class LibraryPhase {
  const LibraryPhase({
    required this.key,
    required this.en,
    required this.ar,
    required this.summaryEn,
    required this.summaryAr,
    required this.color,
    required this.icon,
    required this.topics,
  });

  final String key;
  final String en;
  final String ar;
  final String summaryEn;
  final String summaryAr;
  final Color color;
  final IconData icon;
  final List<LibraryTopic> topics;

  String name(String lang) => lang.startsWith('ar') ? ar : en;
  String summary(String lang) => lang.startsWith('ar') ? summaryAr : summaryEn;
}

class SelfCareLibraryContent {
  SelfCareLibraryContent._();

  static const menstrual = LibraryPhase(
    key: 'menstrual',
    en: 'Menstrual phase',
    ar: 'مرحلة الحيض',
    summaryEn: 'Bleeding days — energy is lowest. Rest is the priority.',
    summaryAr: 'أيام النزيف — الطاقة في أدنى مستوياتها. الراحة أولوية.',
    color: AuraColors.roseDeep,
    icon: Icons.water_drop_rounded,
    topics: [
      LibraryTopic(
        icon: Icons.restaurant_rounded,
        en: 'Nourish',
        ar: 'التغذية',
        bodyEn: 'Iron-rich foods (lentils, leafy greens, red meat) replace what you lose. Pair them with vitamin C for better absorption. Warm soups and ginger or chamomile tea comfort the belly and ease cramps.',
        bodyAr: 'الأطعمة الغنية بالحديد (العدس، الورقيات الخضراء، اللحم الأحمر) تعوّض ما تفقدينه. تناوليها مع فيتامين C لامتصاص أفضل. الشوربات الدافئة وشاي الزنجبيل أو البابونج تريح البطن وتخفّف التشنّج.',
      ),
      LibraryTopic(
        icon: Icons.self_improvement_rounded,
        en: 'Move gently',
        ar: 'حركة لطيفة',
        bodyEn: 'Skip intense workouts. Slow walking, light stretching, and restorative yoga keep blood flowing and relieve cramps without draining you.',
        bodyAr: 'تجنّبي التمارين العنيفة. المشي البطيء والتمدد الخفيف واليوغا الاستشفائية تحافظ على تدفّق الدم وتخفّف التشنّج دون إرهاقك.',
      ),
      LibraryTopic(
        icon: Icons.bedtime_rounded,
        en: 'Rest deeply',
        ar: 'راحة عميقة',
        bodyEn: 'Give yourself permission to sleep more. A heat pad on the lower belly, an early night, and fewer commitments honor what your body is doing.',
        bodyAr: 'امنحي نفسك الإذن لتنامي أكثر. كمّادة دافئة على أسفل البطن، ونوم مبكر، والتزامات أقل — كلها تحترم ما يفعله جسدك.',
      ),
      LibraryTopic(
        icon: Icons.favorite_rounded,
        en: 'Mind & mood',
        ar: 'العقل والمزاج',
        bodyEn: 'It is normal to feel inward and quiet. Journaling, a warm bath, and saying no to extra demands protect your peace this week.',
        bodyAr: 'من الطبيعي أن تشعري بالانطواء والهدوء. الكتابة، وحمّام دافئ، ورفض المهام الإضافية — تحمي سلامك هذا الأسبوع.',
      ),
    ],
  );

  static const follicular = LibraryPhase(
    key: 'follicular',
    en: 'Follicular phase',
    ar: 'المرحلة الجريبية',
    summaryEn: 'After your period — energy and mood are rising. Time to start.',
    summaryAr: 'بعد الدورة — الطاقة والمزاج في تصاعد. وقت البدايات.',
    color: Color(0xFF84C9A0),
    icon: Icons.spa_rounded,
    topics: [
      LibraryTopic(
        icon: Icons.restaurant_rounded,
        en: 'Nourish',
        ar: 'التغذية',
        bodyEn: 'Fresh, light foods suit rising energy: colorful vegetables, sprouts, and fermented foods (yogurt, pickles) support estrogen metabolism. Lean protein fuels new momentum.',
        bodyAr: 'الأطعمة الطازجة والخفيفة تناسب الطاقة الصاعدة: خضروات ملوّنة، براعم، وأطعمة مخمّرة (لبن، مخلّلات) تدعم استقلاب الإستروجين. البروتين الخفيف يمنحك دفعة جديدة.',
      ),
      LibraryTopic(
        icon: Icons.directions_run_rounded,
        en: 'Move & build',
        ar: 'حركة وبناء',
        bodyEn: 'Your body recovers fast now — a great window for cardio, dance, and trying new workouts. Channel the fresh energy into movement you enjoy.',
        bodyAr: 'جسدك يتعافى بسرعة الآن — نافذة رائعة للكارديو والرقص وتجربة تمارين جديدة. وجّهي الطاقة الجديدة نحو حركة تحبّينها.',
      ),
      LibraryTopic(
        icon: Icons.lightbulb_rounded,
        en: 'Create & plan',
        ar: 'إبداع وتخطيط',
        bodyEn: 'Estrogen sharpens focus and creativity. Brainstorm, start projects, and schedule the tasks that need clear thinking for these days.',
        bodyAr: 'الإستروجين يشحذ التركيز والإبداع. اعصفي ذهنياً، ابدئي المشاريع، وجدولي المهام التي تحتاج تفكيراً صافياً لهذه الأيام.',
      ),
      LibraryTopic(
        icon: Icons.favorite_rounded,
        en: 'Mind & mood',
        ar: 'العقل والمزاج',
        bodyEn: 'Optimism and sociability tend to grow. Reconnect with friends, say yes to plans, and set intentions for the cycle ahead.',
        bodyAr: 'التفاؤل والرغبة في التواصل يزدادان. أعيدي التواصل مع صديقاتك، وافقي على الخطط، وضعي نواياك للدورة القادمة.',
      ),
    ],
  );

  static const ovulation = LibraryPhase(
    key: 'ovulation',
    en: 'Ovulation phase',
    ar: 'مرحلة الإباضة',
    summaryEn: 'Mid-cycle peak — energy, confidence, and libido are highest.',
    summaryAr: 'ذروة منتصف الدورة — الطاقة والثقة والرغبة في أعلاها.',
    color: Color(0xFFE89B4F),
    icon: Icons.local_florist_rounded,
    topics: [
      LibraryTopic(
        icon: Icons.restaurant_rounded,
        en: 'Nourish',
        ar: 'التغذية',
        bodyEn: 'Fiber and antioxidants help process peak estrogen: berries, leafy greens, and cruciferous vegetables (broccoli, cauliflower). Stay well hydrated to match your active pace.',
        bodyAr: 'الألياف ومضادات الأكسدة تساعد على معالجة ذروة الإستروجين: التوت، الورقيات الخضراء، والخضروات الصليبية (بروكلي، قرنبيط). حافظي على ترطيب جيد يواكب نشاطك.',
      ),
      LibraryTopic(
        icon: Icons.fitness_center_rounded,
        en: 'Move & peak',
        ar: 'حركة وذروة',
        bodyEn: 'This is your strongest window — ideal for higher-intensity workouts, strength training, or a challenging class. Warm up well; energy can outpace your joints.',
        bodyAr: 'هذه أقوى نافذة لديك — مثالية للتمارين الأعلى شدّة، وتمارين القوة، أو حصّة صعبة. أحمي عضلاتك جيداً؛ فقد تسبق الطاقة مفاصلك.',
      ),
      LibraryTopic(
        icon: Icons.groups_rounded,
        en: 'Connect',
        ar: 'التواصل',
        bodyEn: 'Communication and charisma peak. Great days for important conversations, presentations, dates, and social plans.',
        bodyAr: 'التواصل والحضور في ذروتهما. أيام رائعة للمحادثات المهمة والعروض والمواعيد والخطط الاجتماعية.',
      ),
      LibraryTopic(
        icon: Icons.favorite_rounded,
        en: 'Mind & mood',
        ar: 'العقل والمزاج',
        bodyEn: 'You may feel radiant and confident. Enjoy it — and remember that a dip afterward is normal, not a failure.',
        bodyAr: 'قد تشعرين بالإشراق والثقة. استمتعي بها — وتذكّري أن الهبوط بعدها طبيعي وليس فشلاً.',
      ),
    ],
  );

  static const luteal = LibraryPhase(
    key: 'luteal',
    en: 'Luteal phase',
    ar: 'المرحلة الأصفرية',
    summaryEn: 'Before your period — energy winds down, PMS may appear.',
    summaryAr: 'قبل الدورة — الطاقة تتراجع وقد تظهر أعراض ما قبل الطمث.',
    color: Color(0xFF9F7BC8),
    icon: Icons.nightlight_round,
    topics: [
      LibraryTopic(
        icon: Icons.restaurant_rounded,
        en: 'Nourish',
        ar: 'التغذية',
        bodyEn: 'Complex carbs (oats, sweet potato) and magnesium (dark chocolate, nuts, seeds) steady mood and cravings. Ease off caffeine and salt to reduce bloating and irritability.',
        bodyAr: 'الكربوهيدرات المعقّدة (الشوفان، البطاطا الحلوة) والمغنيسيوم (الشوكولا الداكنة، المكسّرات، البذور) يثبّتان المزاج والرغبة الشديدة. قلّلي الكافيين والملح لتخفيف الانتفاخ والتوتّر.',
      ),
      LibraryTopic(
        icon: Icons.self_improvement_rounded,
        en: 'Move gently',
        ar: 'حركة لطيفة',
        bodyEn: 'Energy tapers, so favor moderate movement: walking, pilates, yoga, and strength you already know. Listen to your body and scale back when it asks.',
        bodyAr: 'الطاقة تتراجع، لذا فضّلي الحركة المعتدلة: المشي، البيلاتس، اليوغا، وتمارين قوة تعرفينها. أنصتي لجسدك وخفّفي عندما يطلب.',
      ),
      LibraryTopic(
        icon: Icons.bedtime_rounded,
        en: 'Rest & wind down',
        ar: 'راحة وتهدئة',
        bodyEn: 'Protect your sleep: dim lights early, limit screens, and keep a calm evening routine. Good rest softens PMS more than almost anything.',
        bodyAr: 'احمي نومك: خفّتي الأضواء مبكراً، قلّلي الشاشات، وحافظي على روتين مسائي هادئ. النوم الجيد يخفّف أعراض ما قبل الطمث أكثر من أي شيء آخر.',
      ),
      LibraryTopic(
        icon: Icons.favorite_rounded,
        en: 'Mind & mood',
        ar: 'العقل والمزاج',
        bodyEn: 'Sensitivity rises — this is not weakness. Lower your to-do list, set boundaries, and treat yourself with extra tenderness. Feelings here are messengers, not facts.',
        bodyAr: 'الحساسية تزداد — وهذا ليس ضعفاً. قلّلي قائمة مهامك، ضعي حدوداً، وعامِلي نفسك بحنان إضافي. المشاعر هنا رسائل وليست حقائق.',
      ),
    ],
  );

  static const all = <LibraryPhase>[menstrual, follicular, ovulation, luteal];

  /// Index of the phase that matches the current cycle phase (for auto-scroll
  /// / default expansion). Falls back to the menstrual phase.
  static int indexForPhase(String? phase) {
    final p = (phase ?? '').toLowerCase();
    if (p.contains('follicular') || p.contains('جريبي') || p.contains('بصيلي') || p.contains('نمو')) return 1;
    if (p.contains('ovul') || p.contains('fertil') || p.contains('إباض') || p.contains('تبويض') || p.contains('خصوب')) return 2;
    if (p.contains('luteal') || p.contains('أصفر') || p.contains('لوتي') || p.contains('بعد الإباض')) return 3;
    return 0;
  }
}
