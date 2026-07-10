// ============================================================================
// lib/features/notifications/data/smart_phase_messages.dart
// ----------------------------------------------------------------------------
// Phase-aware daily-tip notifications. The "smart" part is that we pick a
// message that matches the user's current cycle phase + pregnancy state, not
// a generic reminder.
//
// Design notes:
//   * Pure data — no Flutter context, no async, no I/O. This is critical so
//     it stays 100% unit-testable (see test/features/notifications/... ).
//   * Phase strings come from `MenstrualCycleWidget.getCurrentPhaseName()`
//     (via `WidgetBaseLanguage`) so we match against localized variants:
//     "Menstruation" / "الحيض" / "menstrual", etc. We lowercase + strip and
//     check for substrings rather than maintaining a fixed enum so the app
//     keeps working when new locales get added.
//   * Pregnancy mode replaces phase messages with trimester-aware guidance.
// ============================================================================

/// One localized daily message bundled for a single day.
class SmartPhaseMessage {
  const SmartPhaseMessage({
    required this.title,
    required this.body,
    required this.tag,
  });

  /// Short title (notification "title" line, ≤ 30 chars).
  final String title;

  /// Body text (1-2 sentences, supportive + actionable).
  final String body;

  /// Stable machine-readable tag for analytics / dedup / testing.
  /// Format: "{phase-key}|{lang}" e.g. "follicular|ar".
  final String tag;
}

/// Phase + pregnancy context. Snapshot of the signals we use to pick a
/// message — produced by the notifier, consumed by [SmartPhaseMessages].
class SmartPhaseContext {
  const SmartPhaseContext({
    required this.phase,
    required this.cycleDay,
    required this.isPregnant,
    this.pregnancyWeek,
    this.trimester,
  });

  /// Raw phase string from the widget (localized, may be "Menstruation",
  /// "Follicular", "الحيض", etc.). Empty string is allowed.
  final String phase;

  /// 1-based day of current cycle (or gestational day in pregnancy mode).
  /// May be null if the widget can't determine it.
  final int? cycleDay;

  /// True when the user is in pregnancy-tracking mode.
  final bool isPregnant;

  /// Only set when [isPregnant] is true. 1-42.
  final int? pregnancyWeek;

  /// Only set when [isPregnant] is true. 1, 2, or 3.
  final int? trimester;

  bool get inLatePeriod =>
      phase.toLowerCase().contains('late') || phase.toLowerCase().contains('متأخر');
}

/// Detected phase bucket. We map every localized input down to one of these
/// so message templates stay simple + exhaustive.
enum _PhaseKey { menstrual, follicular, ovulation, luteal, latePeriod, unknown }

class SmartPhaseMessages {
  SmartPhaseMessages._();

  static bool _isArabic(String locale) =>
      locale.toLowerCase().startsWith('ar');

  static _PhaseKey _classify(SmartPhaseContext ctx) {
    if (ctx.isPregnant) {
      // Pregnancy messages live in their own template groups below; from
      // this classifier's perspective pregnancy is "unknown" so we don't
      // fall through to cycle-phase messages by accident.
      return _PhaseKey.unknown;
    }
    if (ctx.inLatePeriod) return _PhaseKey.latePeriod;
    final p = ctx.phase.toLowerCase();
    if (p.contains('menstru') ||
        p.contains('حيض') ||
        p.contains('period') ||
        p.contains('دم')) {
      return _PhaseKey.menstrual;
    }
    if (p.contains('follic') || p.contains('جريب')) {
      return _PhaseKey.follicular;
    }
    if (p.contains('ovulat') || p.contains('إباضة')) {
      return _PhaseKey.ovulation;
    }
    if (p.contains('luteal') || p.contains('أصفر')) {
      return _PhaseKey.luteal;
    }
    return _PhaseKey.unknown;
  }

  /// Pick the right localized message for the supplied context.
  ///
  /// `locale` is the user's app locale — anything starting with `ar` is
  /// treated as Arabic, everything else falls back to English.
  ///
  /// [rotation] rotates through a pool of extra supportive/motivational
  /// variants so a multi-day runway (see [SmartPhaseNotifier]) does not show
  /// the same body every day while the user stays in one phase. `rotation == 0`
  /// always returns the original phase-primary message — this keeps the pure
  /// unit tests stable and makes "today" feel hand-picked.
  static SmartPhaseMessage pick(
    SmartPhaseContext ctx,
    String locale, {
    int rotation = 0,
  }) {
    final ar = _isArabic(locale);
    final rot = rotation < 0 ? 0 : rotation;

    if (ctx.isPregnant) {
      return _pregnancy(ctx, ar, rot);
    }

    switch (_classify(ctx)) {
      case _PhaseKey.menstrual:
        return _menstrual(ar, ctx.cycleDay, rot);
      case _PhaseKey.follicular:
        return _follicular(ar, ctx.cycleDay, rot);
      case _PhaseKey.ovulation:
        return _ovulation(ar, rot);
      case _PhaseKey.luteal:
        return _luteal(ar, ctx.cycleDay, rot);
      case _PhaseKey.latePeriod:
        return _latePeriod(ar, rot);
      case _PhaseKey.unknown:
        return _generic(ar, rot);
    }
  }

  /// Index into an extra-variants pool for `rotation >= 1`. Kept separate from
  /// `pick` so every builder rotates identically.
  static String _fromPool(List<String> pool, int rotation) =>
      pool[(rotation - 1) % pool.length];

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  static SmartPhaseMessage _menstrual(bool ar, int? day, int rotation) {
    if (rotation == 0) {
      if (ar) {
        return SmartPhaseMessage(
          title: 'Lune',
          body: day == null || day <= 1
              ? 'دورتك بدأت. خذي راحة، اشربي سوائل دافئة، وسمحي لنفسك بالهدوء.'
              : 'لا بأس بأخذ الأمور ببساطة اليوم. المغنيسيوم والشاي الدافئ يساعدان على تخفيف التقلصات.',
          tag: 'menstrual|ar',
        );
      }
      return SmartPhaseMessage(
        title: 'Lune',
        body: day == null || day <= 1
            ? 'Your period started. Rest, hydrate, and be gentle with yourself.'
            : "It's OK to take things slow. Warm drinks and magnesium may help with cramps.",
        tag: 'menstrual|en',
      );
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(ar ? _menstrualPoolAr : _menstrualPoolEn, rotation),
      tag: ar ? 'menstrual|ar' : 'menstrual|en',
    );
  }

  static SmartPhaseMessage _follicular(bool ar, int? day, int rotation) {
    if (rotation == 0) {
      if (ar) {
        return SmartPhaseMessage(
          title: 'Lune',
          body: day != null && day <= 7
              ? 'طاقتك تبدأ بالارتفاع. وقت مناسب لمشاريع جديدة أو تمارين مكثفة 💪'
              : 'لاحظي مستويات الطاقة لديك — هذا وقت رائع للابداع والتركيز العميق.',
          tag: 'follicular|ar',
        );
      }
      return SmartPhaseMessage(
        title: 'Lune',
        body: day != null && day <= 7
            ? 'Your energy is climbing. Great day to kick off a new project or a tough workout.'
            : 'Tune into your rising energy — perfect for deep-focus work.',
        tag: 'follicular|en',
      );
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(ar ? _follicularPoolAr : _follicularPoolEn, rotation),
      tag: ar ? 'follicular|ar' : 'follicular|en',
    );
  }

  static SmartPhaseMessage _ovulation(bool ar, int rotation) {
    if (rotation == 0) {
      if (ar) {
        return const SmartPhaseMessage(
          title: 'Lune',
          body: 'اليوم هو يوم الإباضة المتوقع. استمتعي بثقتك العالية وتواصلك الاجتماعي 🌸',
          tag: 'ovulation|ar',
        );
      }
      return const SmartPhaseMessage(
        title: 'Lune',
        body: 'Predicted ovulation today. Enjoy your confidence and social energy.',
        tag: 'ovulation|en',
      );
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(ar ? _ovulationPoolAr : _ovulationPoolEn, rotation),
      tag: ar ? 'ovulation|ar' : 'ovulation|en',
    );
  }

  static SmartPhaseMessage _luteal(bool ar, int? day, int rotation) {
    if (rotation == 0) {
      final late = day != null && day >= 25;
      if (ar) {
        return SmartPhaseMessage(
          title: 'Lune',
          body: late
              ? 'قللي الكافيين والسكريات، وامنحي نفسك وقتًا للنوم العميق.'
              : 'هذا وقت طبيعي للتأمل الذاتي. خذي الأمور ببطء أكثر واسمحي لنفسك بالراحة.',
          tag: 'luteal|ar',
        );
      }
      return SmartPhaseMessage(
        title: 'Lune',
        body: late
            ? 'Cut back on caffeine and sugar — and make space for deep, restful sleep.'
            : 'A natural window for reflection. Slow down and honor what you need.',
        tag: 'luteal|en',
      );
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(ar ? _lutealPoolAr : _lutealPoolEn, rotation),
      tag: ar ? 'luteal|ar' : 'luteal|en',
    );
  }

  static SmartPhaseMessage _latePeriod(bool ar, int rotation) {
    if (rotation == 0) {
      if (ar) {
        return const SmartPhaseMessage(
          title: 'Lune',
          body: 'دورتك متأخرة قليلاً. لا تقلقي — التوتر وتأثير السفر شائعان. سجلي أعراضك اليوم.',
          tag: 'latePeriod|ar',
        );
      }
      return const SmartPhaseMessage(
        title: 'Lune',
        body: 'Your period is a bit late. Stress and travel are common causes — log how you feel today.',
        tag: 'latePeriod|en',
      );
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(ar ? _latePeriodPoolAr : _latePeriodPoolEn, rotation),
      tag: ar ? 'latePeriod|ar' : 'latePeriod|en',
    );
  }

  static SmartPhaseMessage _generic(bool ar, int rotation) {
    if (rotation == 0) {
      if (ar) {
        return const SmartPhaseMessage(
          title: 'Lune',
          body: 'كيف تشعرين اليوم؟ سجلي يومك ولا تنسي شرب الماء 💧',
          tag: 'generic|ar',
        );
      }
      return const SmartPhaseMessage(
        title: 'Lune',
        body: 'How are you feeling today? Log your day and remember to hydrate.',
        tag: 'generic|en',
      );
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(ar ? _genericPoolAr : _genericPoolEn, rotation),
      tag: ar ? 'generic|ar' : 'generic|en',
    );
  }

  // ---------------------------------------------------------------------------
  // Extra motivational variants (used for rotation >= 1). Each stays inside its
  // phase's supportive theme so a rotating multi-day runway still feels
  // phase-aware while never repeating the same line two days running.
  // ---------------------------------------------------------------------------

  static const _menstrualPoolAr = [
    'يومكِ يستحق الراحة. كيسة ماء دافئة وقسط من النوم يصنعان فرقًا.',
    'خذي الأمور بهدوء اليوم — حركة خفيفة قد تخفف الانزعاج.',
    'أكثري من الماء والأطعمة الغنية بالحديد خلال هذه الأيام.',
    'كوني لطيفة مع نفسكِ؛ هذه فترة تجدّد وليست ضعفًا.',
  ];
  static const _menstrualPoolEn = [
    'Your day deserves rest. A warm compress and good sleep make a difference.',
    'Go easy today — a little gentle movement may ease the discomfort.',
    'Lean on water and iron-rich foods these few days.',
    'Be gentle with yourself; this is renewal, not weakness.',
  ];

  static const _follicularPoolAr = [
    'طاقتكِ في صعود — استغليها لخطوة كنتِ تؤجلينها.',
    'مزاجكِ ونشاطكِ في تحسّن. يوم رائع للتعلّم أو التمرين.',
    'تركيزكِ في أفضل حالاته الآن. اصنعي شيئًا تفخرين به.',
    'ثقتكِ تكبر كل يوم. جرّبي شيئًا يخرجكِ عن روتينكِ.',
  ];
  static const _follicularPoolEn = [
    'Your energy is rising — use it for that step you keep postponing.',
    'Mood and drive are improving. Great day to learn or train.',
    'Your focus is at its best now. Build something you are proud of.',
    'Confidence grows each day. Try something outside your routine.',
  ];

  static const _ovulationPoolAr = [
    'أنتِ في ذروة طاقتكِ الاجتماعية — تواصلي واستمتعي بحضوركِ.',
    'ثقتكِ عالية اليوم؛ لحظة مثالية لمحادثة أو قرار كنتِ تؤجّلينه.',
    'جسمكِ في أوج نشاطه. أنصتي إليه واحتفلي به.',
  ];
  static const _ovulationPoolEn = [
    'Your social energy peaks now — connect and enjoy your presence.',
    'Confidence runs high today; a perfect moment for that talk or decision.',
    'Your body is at its liveliest. Listen to it and celebrate it.',
  ];

  static const _lutealPoolAr = [
    'قد تشعرين بتقلّبات بسيطة في المزاج — هذا طبيعي، امنحي نفسكِ لطفًا إضافيًا.',
    'وقت مناسب لإبطاء الإيقاع: تأمل، دفتر يوميات، أو حمّام دافئ.',
    'قللي الكافيين والملح لتخفيف الانتفاخ، وأعطي النوم أولوية.',
    'أنصتي لاحتياجاتكِ اليوم؛ الراحة إنتاجية أيضًا.',
  ];
  static const _lutealPoolEn = [
    'You may notice small mood shifts — that is normal. Give yourself extra kindness.',
    'A good time to slow down: meditate, journal, or take a warm bath.',
    'Ease off caffeine and salt to reduce bloating, and prioritize sleep.',
    'Tune into what you need today; rest is productive too.',
  ];

  static const _latePeriodPoolAr = [
    'تأخّر بسيط لا يعني بالضرورة شيئًا — السفر والتوتر والنوم كلها عوامل مؤثرة.',
    'سجّلي أعراضكِ اليوم؛ يساعدنا ذلك على تحسين توقعاتكِ.',
  ];
  static const _latePeriodPoolEn = [
    'A short delay does not always mean something — travel, stress and sleep all play a role.',
    'Log how you feel today; it helps us sharpen your predictions.',
  ];

  static const _genericPoolAr = [
    'لحظة صغيرة لنفسكِ اليوم: نفَس عميق وكوب ماء.',
    'كيف حال جسمكِ ومزاجكِ اليوم؟ دوّني ملاحظة سريعة.',
    'خطوة صغيرة نحو العناية بنفسكِ تصنع فرقًا كبيرًا.',
  ];
  static const _genericPoolEn = [
    'A small moment for you today: a deep breath and a glass of water.',
    'How is your body and mood today? Jot a quick note.',
    'One small act of self-care goes a long way.',
  ];

  // Pregnancy templates — three buckets so we stay concise but cover the
  // wide behavioral shift across trimesters.
  static SmartPhaseMessage _pregnancy(
    SmartPhaseContext ctx,
    bool ar,
    int rotation,
  ) {
    final trimester = ctx.trimester ?? 1;
    if (trimester < 1 || trimester > 3) return _generic(ar, rotation);

    if (rotation == 0) {
      if (ar) {
        switch (trimester) {
          case 1:
            return const SmartPhaseMessage(
              title: 'Lune',
              body:
                  'أنتِ في الثلث الأول. خذي قسطًا من الراحة، وتناولي وجبات صغيرة متكررة لتخفيف الغثيان.',
              tag: 'pregnancyT1|ar',
            );
          case 2:
            return const SmartPhaseMessage(
              title: 'Lune',
              body:
                  'أنتِ في الثلث الثاني. اشربي الماء ومارسي تمارين خفيفة مثل المشي والسباحة.',
              tag: 'pregnancyT2|ar',
            );
          default:
            return const SmartPhaseMessage(
              title: 'Lune',
              body:
                  'أنتِ في الثلث الثالث. راقبي حركات الطفل وجهّزي حقيبة المستشفى لقرب الموعد.',
              tag: 'pregnancyT3|ar',
            );
        }
      }
      switch (trimester) {
        case 1:
          return const SmartPhaseMessage(
            title: 'Lune',
            body:
                "Trimester 1 — rest often and try small, frequent meals to ease nausea.",
            tag: 'pregnancyT1|en',
          );
        case 2:
          return const SmartPhaseMessage(
            title: 'Lune',
            body:
                'Trimester 2 — hydrate and keep moving with gentle walks or swimming.',
            tag: 'pregnancyT2|en',
          );
        default:
          return const SmartPhaseMessage(
            title: 'Lune',
            body:
                "Trimester 3 — watch baby's movements and start packing your hospital bag.",
            tag: 'pregnancyT3|en',
          );
      }
    }

    final List<String> pool;
    if (ar) {
      pool = trimester == 1
          ? _pregnancyT1PoolAr
          : trimester == 2
              ? _pregnancyT2PoolAr
              : _pregnancyT3PoolAr;
    } else {
      pool = trimester == 1
          ? _pregnancyT1PoolEn
          : trimester == 2
              ? _pregnancyT2PoolEn
              : _pregnancyT3PoolEn;
    }
    return SmartPhaseMessage(
      title: 'Lune',
      body: _fromPool(pool, rotation),
      tag: 'pregnancyT$trimester|${ar ? 'ar' : 'en'}',
    );
  }

  static const _pregnancyT1PoolAr = [
    'الغثيان قد يزوركِ — وجبات صغيرة متكررة والزنجبيل قد يساعدان.',
    'التعب طبيعي في هذه المرحلة؛ نامي كلما استطعتِ.',
    'حمض الفوليك مهم الآن. لا تنسي مكمّلاتكِ اليومية.',
  ];
  static const _pregnancyT1PoolEn = [
    'Nausea may visit — small frequent meals and ginger can help.',
    'Fatigue is normal now; sleep whenever you can.',
    'Folic acid matters now. Do not skip your daily supplement.',
  ];

  static const _pregnancyT2PoolAr = [
    'غالبًا تعود طاقتكِ الآن؛ مشي خفيف يوميًا مفيد لكِ وللطفل.',
    'حافظي على شرب الماء وتناول الكالسيوم.',
    'قد تبدئين بالشعور بحركة الطفل — لحظة جميلة انتبهي لها.',
  ];
  static const _pregnancyT2PoolEn = [
    'Energy often returns now; a daily gentle walk helps you and baby.',
    'Keep hydrated and mind your calcium intake.',
    "You may start feeling baby move — a lovely moment to notice.",
  ];

  static const _pregnancyT3PoolAr = [
    'راقبي ركلات الطفل يوميًا، وارتاحي على جانبكِ الأيسر.',
    'جهّزي حقيبة المستشفى واحفظي أرقام الطوارئ قريبة.',
    'الراحة أولوية الآن؛ أنصتي لإشارات جسمكِ.',
  ];
  static const _pregnancyT3PoolEn = [
    "Track baby's kicks daily and rest on your left side.",
    'Pack your hospital bag and keep emergency numbers close.',
    'Rest is a priority now; listen to your body signals.',
  ];
}
