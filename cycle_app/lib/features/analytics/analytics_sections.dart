import 'package:flutter/material.dart';

import '../../core/ai/models/ai_insight.dart';
import '../../core/ai/widgets/ai_insight_card.dart';
import '../../core/widgets/app_surface.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/presentation/widgets/bbt_tracking_card.dart';
import 'analytics_data.dart';
import 'analytics_widgets.dart';

/// Picks the most relevant AI insight for a goal so the Analytics page opens
/// with a personalized, goal-aware read of the user's data.
AiInsightType analyticsInsightType(UserGoalTypes goal) {
  switch (goal) {
    case UserGoalTypes.pregnant:
      return AiInsightType.prenatalTip;
    case UserGoalTypes.conceive:
      return AiInsightType.conceiveTip;
    case UserGoalTypes.avoid:
      return AiInsightType.avoidTip;
    case UserGoalTypes.pcos:
    case UserGoalTypes.menopause:
    case UserGoalTypes.postpartum:
    case UserGoalTypes.general:
    case UserGoalTypes.sexual:
      return AiInsightType.cycleHealth;
  }
}

/// Whether temperature-based ovulation confirmation is worth asking this user
/// for. It is meaningless while pregnant, and postpartum or menopausal cycles
/// are not ovulating predictably enough for a daily 7am ask to be fair.
bool _bbtIsRelevant(UserGoalTypes goal) => switch (goal) {
  UserGoalTypes.pregnant ||
  UserGoalTypes.postpartum ||
  UserGoalTypes.menopause => false,
  _ => true,
};

/// Builds a bar chart of the user's real completed cycle lengths (oldest →
/// newest). Returns null when there isn't enough history to be meaningful, so
/// callers can fall back to their placeholder chart.
AnalyticsBarChart? realCycleLengthChart(
  AnalyticsHistory? history,
  Color accent,
) {
  if (history == null || !history.hasCycleHistory) return null;
  final n = history.cycleLengths.length;
  return AnalyticsBarChart(
    titleAr: 'طول الدورة الفعلي (آخر $n دورات)',
    titleEn: 'Actual cycle length (last $n)',
    values: history.cycleLengths,
    accent: accent,
    suffix: 'd',
  );
}

/// Builds a bar chart of the user's real period durations per completed cycle.
/// Returns null when there isn't enough real history.
AnalyticsBarChart? realPeriodDurationChart(
  AnalyticsHistory? history,
  Color accent,
) {
  if (history == null || !history.hasPeriodHistory) return null;
  final n = history.periodDurations.length;
  return AnalyticsBarChart(
    titleAr: 'مدة الحيض الفعلية (آخر $n دورات)',
    titleEn: 'Actual period length (last $n)',
    values: history.periodDurations,
    accent: accent,
    suffix: 'd',
  );
}

/// Cycle-progress ring shown for cycle-oriented goals. Uses the real current
/// phase and cycle day, so it renders meaningfully even before any history
/// builds up.
AnalyticsPhaseRing cycleProgressRing(
  CycleDashboardData data,
  Color accent,
  String lang,
) {
  final percent = data.avgCycleLength > 0
      ? (data.cycleDay / data.avgCycleLength).clamp(0.0, 1.0)
      : 0.0;
  final phase = data.phase.isEmpty ? '—' : data.phase;
  return AnalyticsPhaseRing(
    titleAr: 'تقدّم الدورة',
    titleEn: 'Cycle progress',
    phaseAr: 'مرحلة $phase · يوم ${data.cycleDay}',
    phaseEn: '$phase · day ${data.cycleDay}',
    percent: percent,
    accent: accent,
  );
}

/// Analytics page sections for the **General / Wellness / Sexual** goal.
class AnalyticsGeneralSection extends StatelessWidget {
  const AnalyticsGeneralSection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);

    final variation = AnalyticsData.cycleVariation(
      data.avgCycleLength,
      data.cycleDay,
    );
    // Fallback series used only when the user has no completed-cycle history.
    final fallbackBars = <num>[
      mathMax(0, data.cycleRegularity - 15),
      mathMax(0, data.cycleRegularity - 8),
      mathMax(0, data.cycleRegularity - 4),
      data.cycleRegularity,
      mathMax(0, data.cycleRegularity - 2),
      variation.clamp(0, 100),
    ];

    final realChart = realCycleLengthChart(history, accent);
    final periodChart = realPeriodDurationChart(history, accent);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'صحة الدورة العامة',
      titleEn: 'Cycle & Wellness',
      subtitleAr:
          'نظرة شاملة على انتظام دورتكِ، الأعراض، والرفاهية العامة.',
      subtitleEn: 'A full view of your cycle regularity, symptoms, and wellness.',
      scores: scores,
      ring: cycleProgressRing(data, accent, lang),
      charts: [
        realChart ??
            AnalyticsBarChart(
              titleAr: 'تذبذب الانتظام (6 أشهر)',
              titleEn: 'Regularity variation (6 mo)',
              values: fallbackBars,
              accent: accent,
              suffix: '%',
            ),
        ?periodChart,
      ],
      metrics: metrics,
    );
  }

  num mathMax(num a, num b) => a > b ? a : b;
}

/// Analytics page sections for the **Trying To Conceive** goal.
class AnalyticsConceiveSection extends StatelessWidget {
  const AnalyticsConceiveSection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);

    final phasePercent = data.avgCycleLength > 0
        ? (data.cycleDay / data.avgCycleLength).clamp(0.0, 1.0)
        : 0.0;

    final realChart = realCycleLengthChart(history, accent);
    final periodChart = realPeriodDurationChart(history, accent);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'تحليلات الخصوبة',
      titleEn: 'Fertility Analytics',
      subtitleAr:
          'احتمالات الحمل، نافذة الخصوبة، وجاهزية جسمكِ للحمل.',
      subtitleEn:
          'Pregnancy chances, fertile window, and your body\'s readiness.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'احتمال الحمل عبر الدورة',
          titleEn: 'Pregnancy chance across cycle',
          values: const [10, 18, 35, 65, 85, 70, 40, 20],
          accent: accent,
          suffix: '%',
        ),
        ?realChart,
        ?periodChart,
      ],
      ring: AnalyticsPhaseRing(
        titleAr: 'تقدّم الدورة',
        titleEn: 'Cycle progress',
        phaseAr: 'مرحلة ${data.phase.isEmpty ? "—" : data.phase}',
        phaseEn: '${data.phase.isEmpty ? "—" : data.phase} phase',
        percent: phasePercent,
        accent: accent,
      ),
      metrics: metrics,
    );
  }
}

/// Analytics page sections for the **Avoiding pregnancy** goal.
class AnalyticsAvoidSection extends StatelessWidget {
  const AnalyticsAvoidSection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);

    final realChart = realCycleLengthChart(history, accent);
    final periodChart = realPeriodDurationChart(history, accent);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'تحليلات الحماية',
      titleEn: 'Protection Analytics',
      subtitleAr:
          'تتبّع أيام الخصوبة، الحماية، والالتزام بوسائل منع الحمل.',
      subtitleEn:
          'Track fertility, protection, and contraception consistency.',
      scores: scores,
      ring: cycleProgressRing(data, accent, lang),
      charts: [
        AnalyticsBarChart(
          titleAr: 'مستوى الخصوبة اليومي',
          titleEn: 'Daily fertility level',
          values: const [20, 30, 60, 85, 95, 75, 45, 25],
          accent: accent,
          suffix: '%',
        ),
        ?realChart,
        ?periodChart,
      ],
      metrics: metrics,
    );
  }
}

/// Analytics page sections for the **Pregnancy** goal.
class AnalyticsPregnancySection extends StatelessWidget {
  const AnalyticsPregnancySection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);

    final week = data.pregnancyWeek.clamp(0, 42);
    final trim = AnalyticsData.trimesterFromWeek(week);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'تحليلات الحمل',
      titleEn: 'Pregnancy Analytics',
      subtitleAr:
          'الأسبوع الحالي، الثلث، ومؤشرات صحتكِ أنتِ والجنين.',
      subtitleEn:
          'Current week, trimester, and you-and-baby health signals.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'تقدّم الثلث $trim (بالأسابيع)',
          titleEn: 'Trimester $trim progress (weeks)',
          values: List<num>.generate(week + 1, (i) => i),
          accent: accent,
          suffix: 'w',
        ),
      ],
      ring: AnalyticsPhaseRing(
        titleAr: 'تقدّم الحمل',
        titleEn: 'Pregnancy progress',
        phaseAr: 'الأسبوع $week من 42',
        phaseEn: 'Week $week of 42',
        percent: AnalyticsData.pregnancyProgress(week) / 100,
        accent: accent,
      ),
      metrics: metrics,
    );
  }
}

/// Analytics page sections for the **Menopause** goal.
class AnalyticsMenopauseSection extends StatelessWidget {
  const AnalyticsMenopauseSection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);

    final realChart = realCycleLengthChart(history, accent);
    final periodChart = realPeriodDurationChart(history, accent);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'تحليلات سنّ الأمل',
      titleEn: 'Menopause Analytics',
      subtitleAr:
          'الهبّات الساخنة، النوم، انتظام الدورة، والمؤشرات الصحية.',
      subtitleEn:
          'Hot flashes, sleep, cycle irregularity, and wellness signals.',
      scores: scores,
      ring: cycleProgressRing(data, accent, lang),
      charts: [
        realChart ??
            AnalyticsBarChart(
              titleAr: 'تذبذب طول الدورة (6 أشهر)',
              titleEn: 'Cycle length variation (6 mo)',
              values: const [24, 28, 31, 35, 42, 38],
              accent: accent,
              suffix: 'd',
            ),
        ?periodChart,
      ],
      metrics: metrics,
    );
  }
}

/// Analytics page sections for the **PCOS** goal.
class AnalyticsPcosSection extends StatelessWidget {
  const AnalyticsPcosSection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);

    final realChart = realCycleLengthChart(history, accent);
    final periodChart = realPeriodDurationChart(history, accent);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'تحليلات PCOS',
      titleEn: 'PCOS Analytics',
      subtitleAr:
          'انتظام الدورة، الأعراض الهرمونية، ومؤشرات التمثيل الغذائي.',
      subtitleEn:
          'Cycle regularity, hormonal signs, and metabolic indicators.',
      scores: scores,
      ring: cycleProgressRing(data, accent, lang),
      charts: [
        realChart ??
            AnalyticsBarChart(
              titleAr: 'تذبذب الدورة (6 أشهر)',
              titleEn: 'Cycle length variation (6 mo)',
              values: const [33, 38, 42, 45, 40, 38],
              accent: accent,
              suffix: 'd',
            ),
        ?periodChart,
      ],
      metrics: metrics,
    );
  }
}

/// Analytics page sections for the **Postpartum** goal.
class AnalyticsPostpartumSection extends StatelessWidget {
  const AnalyticsPostpartumSection({
    super.key,
    required this.data,
    required this.goal,
    this.history,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data, history: history);
    final scores = AnalyticsData.scoreCardsFor(goal, data, history: history);
    final recovery = AnalyticsData.recoveryDay(data);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      history: history,
      titleAr: 'تحليلات الاستشفاء',
      titleEn: 'Postpartum Analytics',
      subtitleAr: 'تقدّم الشفاء، النوم، الرضاعة، والمزاج.',
      subtitleEn: 'Healing progress, sleep, feeding, and mood.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'تقدم الاستشفاء (بالأسابيع)',
          titleEn: 'Recovery progress (weeks)',
          values: List<num>.generate(
            (recovery ~/ 7).clamp(1, 12),
            (i) => (i + 1) * 7,
          ),
          accent: accent,
          suffix: 'd',
        ),
      ],
      metrics: metrics,
    );
  }
}

/// Reusable layout shell for any goal section.
class AnalyticsSectionShell extends StatelessWidget {
  const AnalyticsSectionShell({
    super.key,
    required this.goal,
    required this.accent,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.scores,
    required this.metrics,
    this.charts = const [],
    this.ring,
    this.history,
  });

  final UserGoalTypes goal;
  final Color accent;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final List<AnalyticsScoreCard> scores;
  final List<AnalyticsMetric> metrics;
  final List<AnalyticsBarChart> charts;
  final AnalyticsPhaseRing? ring;
  final AnalyticsHistory? history;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode.startsWith('ar');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnalyticsSectionHeader(
          goal: goal,
          accent: accent,
          titleAr: titleAr,
          titleEn: titleEn,
          subtitleAr: subtitleAr,
          subtitleEn: subtitleEn,
        ),
        const SizedBox(height: 12),
        // Goal-aware AI reading of the user's data. Hides itself entirely when
        // AI is unavailable (no consent / not premium / no provider).
        AiInsightCard(
          type: analyticsInsightType(goal),
          blur: false,
          margin: const EdgeInsets.only(bottom: 12),
        ),
        for (final s in scores) ...[
          AnalyticsHeadlineScore(card: s, accent: accent),
          const SizedBox(height: 10),
        ],
        if (ring != null) ...[
          ring!,
          const SizedBox(height: 12),
        ],
        for (final c in charts) ...[
          c,
          const SizedBox(height: 12),
        ],
        // Body temperature. The cycle-relative curve is the one that shows the
        // ovulatory shift, so prefer it; the monthly average is only a
        // fallback for scattered readings that can't fill one cycle.
        if (history != null && history!.hasCycleTemperature) ...[
          AnalyticsCycleTemperatureChart(
            series: history!.cycleTemperature!,
            accent: accent,
          ),
          const SizedBox(height: 12),
        ] else if (history != null && history!.hasTemperature) ...[
          AnalyticsTemperatureChart(
            points: history!.monthlyTemps,
            accent: accent,
          ),
          const SizedBox(height: 12),
        ] else ...[
          AnalyticsTemperatureHint(accent: accent),
          const SizedBox(height: 12),
        ],

        // Owns the "why bother" explanation, the progress toward a real
        // confirmation, and the morning reminder that makes it happen.
        if (_bbtIsRelevant(goal)) ...[
          const BbtTrackingCard(margin: EdgeInsets.zero),
          const SizedBox(height: 12),
        ],
        AppSectionHeader(title: ar ? 'كل المؤشرات' : 'All metrics'),
        AnalyticsMetricsGrid(metrics: metrics, accent: accent),
      ],
    );
  }
}
