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
  static SmartPhaseMessage pick(SmartPhaseContext ctx, String locale) {
    final ar = _isArabic(locale);

    if (ctx.isPregnant) {
      return _pregnancy(ctx, ar);
    }

    switch (_classify(ctx)) {
      case _PhaseKey.menstrual:
        return _menstrual(ar, ctx.cycleDay);
      case _PhaseKey.follicular:
        return _follicular(ar, ctx.cycleDay);
      case _PhaseKey.ovulation:
        return _ovulation(ar);
      case _PhaseKey.luteal:
        return _luteal(ar, ctx.cycleDay);
      case _PhaseKey.latePeriod:
        return _latePeriod(ar);
      case _PhaseKey.unknown:
        return _generic(ar);
    }
  }

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  static SmartPhaseMessage _menstrual(bool ar, int? day) {
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

  static SmartPhaseMessage _follicular(bool ar, int? day) {
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

  static SmartPhaseMessage _ovulation(bool ar) {
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

  static SmartPhaseMessage _luteal(bool ar, int? day) {
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

  static SmartPhaseMessage _latePeriod(bool ar) {
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

  static SmartPhaseMessage _generic(bool ar) {
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

  // Pregnancy templates — three buckets so we stay concise but cover the
  // wide behavioral shift across trimesters.
  static SmartPhaseMessage _pregnancy(SmartPhaseContext ctx, bool ar) {
    final trimester = ctx.trimester ?? 1;
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
        case 3:
          return const SmartPhaseMessage(
            title: 'Lune',
            body:
                'أنتِ في الثلث الثالث. راقبي حركات الطفل وجهّزي حقيبة المستشفى لقرب الموعد.',
            tag: 'pregnancyT3|ar',
          );
        default:
          return _generic(ar);
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
      case 3:
        return const SmartPhaseMessage(
          title: 'Lune',
          body:
              "Trimester 3 — watch baby's movements and start packing your hospital bag.",
          tag: 'pregnancyT3|en',
        );
      default:
        return _generic(ar);
    }
  }
}
