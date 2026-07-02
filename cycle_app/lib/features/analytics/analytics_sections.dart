import 'package:flutter/material.dart';

import '../../core/widgets/app_surface.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import 'analytics_data.dart';
import 'analytics_widgets.dart';

/// Analytics page sections for the **General / Wellness / Sexual** goal.
class AnalyticsGeneralSection extends StatelessWidget {
  const AnalyticsGeneralSection({
    super.key,
    required this.data,
    required this.goal,
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);

    final variation = AnalyticsData.cycleVariation(
      data.avgCycleLength,
      data.cycleDay,
    );
    final barValues = <num>[
      mathMax(0, data.cycleRegularity - 15),
      mathMax(0, data.cycleRegularity - 8),
      mathMax(0, data.cycleRegularity - 4),
      data.cycleRegularity,
      mathMax(0, data.cycleRegularity - 2),
      variation.clamp(0, 100),
    ];

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      titleAr: 'صحة الدورة العامة',
      titleEn: 'Cycle & Wellness',
      subtitleAr:
          'نظرة شاملة على انتظام دورتكِ، الأعراض، والرفاهية العامة.',
      subtitleEn: 'A full view of your cycle regularity, symptoms, and wellness.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'تذبذب الانتظام (6 أشهر)',
          titleEn: 'Regularity variation (6 mo)',
          values: barValues,
          accent: accent,
          suffix: '%',
        ),
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
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);

    final phasePercent = data.avgCycleLength > 0
        ? (data.cycleDay / data.avgCycleLength).clamp(0.0, 1.0)
        : 0.0;

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
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
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      titleAr: 'تحليلات الحماية',
      titleEn: 'Protection Analytics',
      subtitleAr:
          'تتبّع أيام الخصوبة، الحماية، والالتزام بوسائل منع الحمل.',
      subtitleEn:
          'Track fertility, protection, and contraception consistency.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'مستوى الخصوبة اليومي',
          titleEn: 'Daily fertility level',
          values: const [20, 30, 60, 85, 95, 75, 45, 25],
          accent: accent,
          suffix: '%',
        ),
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
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);

    final week = data.pregnancyWeek.clamp(0, 42);
    final trim = AnalyticsData.trimesterFromWeek(week);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
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
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      titleAr: 'تحليلات سنّ الأمل',
      titleEn: 'Menopause Analytics',
      subtitleAr:
          'الهبّات الساخنة، النوم، انتظام الدورة، والمؤشرات الصحية.',
      subtitleEn:
          'Hot flashes, sleep, cycle irregularity, and wellness signals.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'تذبذب طول الدورة (6 أشهر)',
          titleEn: 'Cycle length variation (6 mo)',
          values: const [24, 28, 31, 35, 42, 38],
          accent: accent,
          suffix: 'd',
        ),
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
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
      titleAr: 'تحليلات PCOS',
      titleEn: 'PCOS Analytics',
      subtitleAr:
          'انتظام الدورة، الأعراض الهرمونية، ومؤشرات التمثيل الغذائي.',
      subtitleEn:
          'Cycle regularity, hormonal signs, and metabolic indicators.',
      scores: scores,
      charts: [
        AnalyticsBarChart(
          titleAr: 'تذبذب الدورة (6 أشهر)',
          titleEn: 'Cycle length variation (6 mo)',
          values: const [33, 38, 42, 45, 40, 38],
          accent: accent,
          suffix: 'd',
        ),
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
  });

  final CycleDashboardData data;
  final UserGoalTypes goal;

  @override
  Widget build(BuildContext context) {
    final accent = AnalyticsData.accentFor(goal);
    final metrics = AnalyticsData.metricsFor(goal, data);
    final scores = AnalyticsData.scoreCardsFor(goal, data);
    final recovery = AnalyticsData.recoveryDay(data);

    return AnalyticsSectionShell(
      goal: goal,
      accent: accent,
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

  @override
  Widget build(BuildContext context) {
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
        AppSectionHeader(
          title: Localizations.localeOf(context).languageCode.startsWith('ar')
              ? 'كل المؤشرات'
              : 'All metrics',
        ),
        AnalyticsMetricsGrid(metrics: metrics, accent: accent),
      ],
    );
  }
}
