import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';

class SelfCareTip {
  const SelfCareTip({required this.en, required this.ar});
  final String en;
  final String ar;

  String forLocale(String code) => code.startsWith('ar') ? ar : en;
}

/// A single selectable mood for the daily check-in. Mood keys mirror the AI
/// action-tag vocabulary (happy/calm/tired/sad/anxious/irritable/energetic)
/// so a logged mood can flow straight into the AI context.
class MoodOption {
  const MoodOption({
    required this.key,
    required this.emoji,
    required this.en,
    required this.ar,
    required this.color,
  });

  final String key;
  final String emoji;
  final String en;
  final String ar;
  final Color color;

  String label(String code) => code.startsWith('ar') ? ar : en;
}

class SelfCareContent {
  SelfCareContent._();

  /// The daily mood palette shown in the check-in card.
  static const moods = <MoodOption>[
    MoodOption(key: 'happy', emoji: '😊', en: 'Happy', ar: 'سعيدة', color: AuraColors.peachGold),
    MoodOption(key: 'calm', emoji: '😌', en: 'Calm', ar: 'هادئة', color: AuraColors.lavenderSoft),
    MoodOption(key: 'energetic', emoji: '⚡', en: 'Energetic', ar: 'نشيطة', color: Color(0xFFF3B94D)),
    MoodOption(key: 'tired', emoji: '😴', en: 'Tired', ar: 'متعبة', color: Color(0xFF9AA7C7)),
    MoodOption(key: 'sad', emoji: '😢', en: 'Sad', ar: 'حزينة', color: Color(0xFF7FA9D8)),
    MoodOption(key: 'anxious', emoji: '😰', en: 'Anxious', ar: 'قلقة', color: Color(0xFFB98FD0)),
    MoodOption(key: 'irritable', emoji: '😤', en: 'Irritable', ar: 'متوترة', color: AuraColors.roseDeep),
  ];

  static MoodOption? moodByKey(String? key) {
    if (key == null) return null;
    for (final m in moods) {
      if (m.key == key) return m;
    }
    return null;
  }

  /// General affirmations shown when no phase is known. Expanded from the
  /// original 5 to a richer rotating set.
  static const affirmations = <SelfCareTip>[
    SelfCareTip(
      en: 'My body is wise. I listen with kindness.',
      ar: 'جسدي حكيم. أستمع له بلطف.',
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
    SelfCareTip(
      en: 'I am allowed to slow down and simply be.',
      ar: 'يحق لي أن أتمهّل وأكون كما أنا.',
    ),
    SelfCareTip(
      en: 'Every phase of my cycle has its own gift.',
      ar: 'لكل مرحلة من دورتي هديتها الخاصة.',
    ),
    SelfCareTip(
      en: 'I release what I cannot control and breathe.',
      ar: 'أُطلق ما لا أقدر على التحكّم به وأتنفّس.',
    ),
    SelfCareTip(
      en: 'My worth is not measured by my productivity.',
      ar: 'قيمتي لا تُقاس بإنتاجيتي.',
    ),
    SelfCareTip(
      en: 'I speak to myself the way I would to a dear friend.',
      ar: 'أُحدّث نفسي كما أُحدّث صديقة عزيزة.',
    ),
    SelfCareTip(
      en: 'This feeling is a wave — it rises and it passes.',
      ar: 'هذا الشعور موجة — يعلو ثم يمرّ.',
    ),
    SelfCareTip(
      en: 'I am doing enough. I am enough.',
      ar: 'أفعل ما يكفي. أنا كافية.',
    ),
  ];

  /// Phase-specific affirmations layered on top of the general set.
  static const _menstrualAffirmations = <SelfCareTip>[
    SelfCareTip(
      en: 'It is safe to rest and let my body renew.',
      ar: 'من الآمن أن أرتاح وأترك جسدي يتجدّد.',
    ),
    SelfCareTip(
      en: 'I give myself permission to do less today.',
      ar: 'أمنح نفسي الإذن لأفعل أقل اليوم.',
    ),
  ];

  static const _follicularAffirmations = <SelfCareTip>[
    SelfCareTip(
      en: 'Fresh energy is rising in me. I welcome new beginnings.',
      ar: 'طاقة جديدة تتصاعد فيّ. أرحّب بالبدايات.',
    ),
    SelfCareTip(
      en: 'I am open to trying, learning, and growing.',
      ar: 'أنا منفتحة على المحاولة والتعلّم والنمو.',
    ),
  ];

  static const _ovulationAffirmations = <SelfCareTip>[
    SelfCareTip(
      en: 'I am radiant, confident, and fully present.',
      ar: 'أنا مشرقة وواثقة وحاضرة تماماً.',
    ),
    SelfCareTip(
      en: 'I connect with others from a place of ease.',
      ar: 'أتواصل مع الآخرين من مكان مريح.',
    ),
  ];

  static const _lutealAffirmations = <SelfCareTip>[
    SelfCareTip(
      en: 'My sensitivity is a strength, not a flaw.',
      ar: 'حساسيتي قوة، وليست عيباً.',
    ),
    SelfCareTip(
      en: 'I slow down and turn inward with compassion.',
      ar: 'أتمهّل وألتفت إلى داخلي برحمة.',
    ),
  ];

  /// Returns affirmations tailored to the current phase, followed by the
  /// general set — so the deck always feels personal but never runs dry.
  static List<SelfCareTip> affirmationsForPhase(String? phase) {
    final p = (phase ?? '').toLowerCase();
    List<SelfCareTip> phaseSet = const [];
    if (p.contains('menstr') || p.contains('period') || p.contains('حيض') || p.contains('دور')) {
      phaseSet = _menstrualAffirmations;
    } else if (p.contains('follicular') || p.contains('جريبي') || p.contains('بصيلي') || p.contains('نمو')) {
      phaseSet = _follicularAffirmations;
    } else if (p.contains('ovul') || p.contains('fertil') || p.contains('إباض') || p.contains('تبويض') || p.contains('خصوب')) {
      phaseSet = _ovulationAffirmations;
    } else if (p.contains('luteal') || p.contains('أصفر') || p.contains('لوتي') || p.contains('بعد الإباض')) {
      phaseSet = _lutealAffirmations;
    }
    return [...phaseSet, ...affirmations];
  }

  static const journalPrompts = <SelfCareTip>[
    SelfCareTip(
      en: 'What does my body need most today?',
      ar: 'ماذا يحتاج جسدي أكثر اليوم؟',
    ),
    SelfCareTip(
      en: 'One thing that brought me comfort this week.',
      ar: 'شيء واحد منحني راحة هذا الأسبوع.',
    ),
    SelfCareTip(
      en: 'How can I be gentler with myself tomorrow?',
      ar: 'كيف أكون ألطف مع نفسي غداً؟',
    ),
    SelfCareTip(
      en: 'What emotion is asking for my attention right now?',
      ar: 'أي شعور يطلب انتباهي الآن؟',
    ),
    SelfCareTip(
      en: 'Three small things I am grateful for today.',
      ar: 'ثلاثة أشياء صغيرة أنا ممتنة لها اليوم.',
    ),
    SelfCareTip(
      en: 'When did I feel most like myself this week?',
      ar: 'متى شعرت أنني على طبيعتي أكثر هذا الأسبوع؟',
    ),
    SelfCareTip(
      en: 'What boundary would protect my energy this week?',
      ar: 'أي حدّ يحمي طاقتي هذا الأسبوع؟',
    ),
    SelfCareTip(
      en: 'What is my body trying to tell me through its symptoms?',
      ar: 'ماذا يحاول جسدي إخباري من خلال أعراضه؟',
    ),
    SelfCareTip(
      en: 'A moment today that deserves to be remembered.',
      ar: 'لحظة اليوم تستحق أن تُتذكَّر.',
    ),
    SelfCareTip(
      en: 'What would "enough rest" look like for me?',
      ar: 'كيف تبدو "الراحة الكافية" بالنسبة لي؟',
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
