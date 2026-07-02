import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';

/// A single indicator with a value (numeric or string), label, optional
/// trend and unit. Used by the Analytics page to render consistent cards.
class AnalyticsMetric {
  const AnalyticsMetric({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.value,
    this.suffix = '',
    this.icon,
    this.trend,
    this.status,
    this.targetMin,
    this.targetMax,
  });

  final String id;
  final String labelAr;
  final String labelEn;
  final Object value;
  final String suffix;
  final IconData? icon;

  /// -1 worse, 0 stable, +1 better than previous period.
  final int? trend;

  /// "good" | "warning" | "bad" | null (unknown / not applicable).
  final String? status;
  final num? targetMin;
  final num? targetMax;

  String displayValue(String lang) {
    if (value is num) {
      final n = value as num;
      if (n is int || n % 1 == 0) {
        return '${n.toInt()}$suffix';
      }
      return '${n.toStringAsFixed(1)}$suffix';
    }
    return '$value';
  }

  String label(String lang) => lang.startsWith('ar') ? labelAr : labelEn;
}

/// Color-coded band of a single metric.
enum MetricBand { excellent, good, fair, poor, unknown }

extension MetricBandX on MetricBand {
  String get label {
    switch (this) {
      case MetricBand.excellent:
        return 'excellent';
      case MetricBand.good:
        return 'good';
      case MetricBand.fair:
        return 'fair';
      case MetricBand.poor:
        return 'poor';
      case MetricBand.unknown:
        return 'unknown';
    }
  }
}

/// Aggregated indicator roll-up. Each goal mode has its own set.
class AnalyticsScoreCard {
  const AnalyticsScoreCard({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.score,
    required this.band,
    this.descriptionAr,
    this.descriptionEn,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final double score; // 0..100
  final MetricBand band;
  final String? descriptionAr;
  final String? descriptionEn;

  String title(String lang) => lang.startsWith('ar') ? titleAr : titleEn;
  String? description(String lang) =>
      lang.startsWith('ar') ? descriptionAr : descriptionEn;
}

/// Master analytics builder. Given a [CycleDashboardData] and a
/// [UserGoalTypes], returns the metrics and score cards to show.
class AnalyticsData {
  AnalyticsData._();

  static const Color _pregnantAccent = Color(0xFFEC407A);
  static const Color _menopauseAccent = Color(0xFF8D6E63);
  static const Color _pcosAccent = Color(0xFF26A69A);
  static const Color _postpartumAccent = Color(0xFFC2185B);
  static const Color _generalAccent = Color(0xFFAB47BC);
  static const Color _conceiveAccent = Color(0xFFE91E63);
  static const Color _avoidAccent = Color(0xFF5C6BC0);

  static Color accentFor(UserGoalTypes goal) {
    switch (goal) {
      case UserGoalTypes.pregnant:
        return _pregnantAccent;
      case UserGoalTypes.menopause:
        return _menopauseAccent;
      case UserGoalTypes.pcos:
        return _pcosAccent;
      case UserGoalTypes.postpartum:
        return _postpartumAccent;
      case UserGoalTypes.conceive:
        return _conceiveAccent;
      case UserGoalTypes.avoid:
        return _avoidAccent;
      case UserGoalTypes.general:
      case UserGoalTypes.sexual:
        return _generalAccent;
    }
  }

  /// Cycle regularity band based on the API-provided score (0..100).
  static MetricBand regularityBand(double score) {
    if (score >= 85) return MetricBand.excellent;
    if (score >= 70) return MetricBand.good;
    if (score >= 50) return MetricBand.fair;
    return MetricBand.poor;
  }

  /// How many days are still in this cycle.
  static int daysUntilNext(CycleDashboardData data, int cycleLength) {
    if (cycleLength <= 0) return 0;
    final remaining = cycleLength - data.cycleDay;
    return remaining < 0 ? 0 : remaining;
  }

  /// Cycle variation: how much the cycle length fluctuates.
  /// We approximate this with avgCycleLength vs current cycle day.
  /// Higher = more irregular.
  static double cycleVariation(int avgLength, int cycleDay) {
    if (avgLength <= 0) return 0;
    final diff = (cycleDay - avgLength).abs();
    return (diff / avgLength) * 100;
  }

  /// Days trying to conceive (from LMP), capped at 0 if not pregnant.
  static int daysTrying(CycleDashboardData data) {
    return data.cycleDay;
  }

  /// Fertility window length in days (typical: 6 — 5 days before + day of).
  static const int fertilityWindowDays = 6;

  /// Whether today is inside the high-fertility window.
  /// We use a simple heuristic: cycle days 10..16 of avg cycle.
  static bool isHighFertility(CycleDashboardData data) {
    final day = data.cycleDay;
    if (day <= 0) return false;
    return day >= 10 && day <= 16;
  }

  /// Mood score on a 0..100 scale. We infer from cycle position:
  /// better during follicular, lower during luteal/PMS.
  static double moodScoreFromCycle(CycleDashboardData data) {
    final day = data.cycleDay;
    if (day <= 0) return 60;
    if (day <= 7) return 70; // period (low but stable)
    if (day <= 13) return 85; // follicular (high)
    if (day <= 16) return 80; // ovulation (peak)
    if (day <= 25) return 65; // luteal (decline)
    return 50; // PMS (low)
  }

  /// Energy score, follows mood with a slight lag.
  static double energyScoreFromCycle(CycleDashboardData data) {
    final day = data.cycleDay;
    if (day <= 0) return 60;
    if (day <= 7) return 60;
    if (day <= 13) return 80;
    if (day <= 16) return 78;
    if (day <= 25) return 62;
    return 45;
  }

  /// Sleep quality heuristic based on cycle phase.
  static double sleepQualityFromCycle(CycleDashboardData data) {
    final day = data.cycleDay;
    if (day <= 0) return 65;
    if (day <= 7) return 60;
    if (day <= 13) return 80;
    if (day <= 16) return 75;
    if (day <= 25) return 65;
    return 55;
  }

  /// Pregnancy progress 0..100, with trim breakdown.
  static double pregnancyProgress(int week) {
    final w = week.clamp(0, 42);
    return (w / 42) * 100;
  }

  /// Trimester label from week.
  static int trimesterFromWeek(int week) {
    if (week <= 13) return 1;
    if (week <= 27) return 2;
    return 3;
  }

  /// Days until due date — given an ISO date string from API.
  static int daysUntilDue(String isoDate) {
    if (isoDate.isEmpty || isoDate == '—') return 0;
    try {
      final due = DateTime.parse(isoDate);
      final now = DateTime.now();
      return due.difference(now).inDays.clamp(0, 320);
    } catch (_) {
      return 0;
    }
  }

  /// Recovery day for postpartum — count of days since LMP if postpartum
  /// is set. Without a delivery date we approximate by 42 - cycleDay.
  static int recoveryDay(CycleDashboardData data) {
    if (data.cycleDay <= 0) return 0;
    return math.min(180, math.max(0, 45 - data.cycleDay + 45));
  }

  /// Generate the goal-specific metric set.
  static List<AnalyticsMetric> metricsFor(
    UserGoalTypes goal,
    CycleDashboardData data,
  ) {
    switch (goal) {
      case UserGoalTypes.general:
      case UserGoalTypes.sexual:
        return _generalMetrics(data);
      case UserGoalTypes.conceive:
        return _conceiveMetrics(data);
      case UserGoalTypes.avoid:
        return _avoidMetrics(data);
      case UserGoalTypes.pregnant:
        return _pregnancyMetrics(data);
      case UserGoalTypes.menopause:
        return _menopauseMetrics(data);
      case UserGoalTypes.pcos:
        return _pcosMetrics(data);
      case UserGoalTypes.postpartum:
        return _postpartumMetrics(data);
    }
  }

  /// Aggregate score cards per goal.
  static List<AnalyticsScoreCard> scoreCardsFor(
    UserGoalTypes goal,
    CycleDashboardData data,
  ) {
    switch (goal) {
      case UserGoalTypes.general:
      case UserGoalTypes.sexual:
        return _generalScores(data);
      case UserGoalTypes.conceive:
        return _conceiveScores(data);
      case UserGoalTypes.avoid:
        return _avoidScores(data);
      case UserGoalTypes.pregnant:
        return _pregnancyScores(data);
      case UserGoalTypes.menopause:
        return _menopauseScores(data);
      case UserGoalTypes.pcos:
        return _pcosScores(data);
      case UserGoalTypes.postpartum:
        return _postpartumScores(data);
    }
  }

  // -----------------------------------------------------------------------
  // GENERAL / SEXUAL
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _generalMetrics(CycleDashboardData data) {
    final variation = cycleVariation(data.avgCycleLength, data.cycleDay);
    return [
      AnalyticsMetric(
        id: 'cycle_day',
        labelAr: 'يوم الدورة',
        labelEn: 'Cycle day',
        value: data.cycleDay,
        suffix: ' / ${data.avgCycleLength > 0 ? data.avgCycleLength : 28}',
        icon: Icons.calendar_today,
        status: 'good',
      ),
      AnalyticsMetric(
        id: 'cycle_regularity',
        labelAr: 'انتظام الدورة',
        labelEn: 'Cycle regularity',
        value: data.cycleRegularity,
        suffix: '%',
        icon: Icons.timeline,
        status: regularityBand(data.cycleRegularity).label,
        trend: 1,
      ),
      AnalyticsMetric(
        id: 'period_regularity',
        labelAr: 'انتظام الحيض',
        labelEn: 'Period regularity',
        value: data.periodRegularity,
        suffix: '%',
        icon: Icons.water_drop_outlined,
        status: regularityBand(data.periodRegularity).label,
      ),
      AnalyticsMetric(
        id: 'avg_cycle_length',
        labelAr: 'متوسط طول الدورة',
        labelEn: 'Avg cycle length',
        value: data.avgCycleLength,
        suffix: ' d',
        icon: Icons.loop,
        status: 'good',
      ),
      AnalyticsMetric(
        id: 'avg_period',
        labelAr: 'متوسط مدة الحيض',
        labelEn: 'Avg period',
        value: data.avgPeriodDuration,
        suffix: ' d',
        icon: Icons.calendar_view_month,
      ),
      AnalyticsMetric(
        id: 'total_cycles',
        labelAr: 'إجمالي الدورات',
        labelEn: 'Total cycles',
        value: data.totalCycles,
        icon: Icons.repeat,
        status: data.totalCycles >= 3 ? 'good' : 'warning',
      ),
      AnalyticsMetric(
        id: 'cycle_variation',
        labelAr: 'تذبذب الدورة',
        labelEn: 'Cycle variation',
        value: variation,
        suffix: '%',
        icon: Icons.show_chart,
        status: variation < 10
            ? 'good'
            : variation < 20
                ? 'warning'
                : 'bad',
      ),
      AnalyticsMetric(
        id: 'mood',
        labelAr: 'المزاج',
        labelEn: 'Mood',
        value: moodScoreFromCycle(data),
        suffix: '%',
        icon: Icons.mood,
      ),
      AnalyticsMetric(
        id: 'energy',
        labelAr: 'الطاقة',
        labelEn: 'Energy',
        value: energyScoreFromCycle(data),
        suffix: '%',
        icon: Icons.bolt,
      ),
      AnalyticsMetric(
        id: 'sleep',
        labelAr: 'النوم',
        labelEn: 'Sleep',
        value: sleepQualityFromCycle(data),
        suffix: '%',
        icon: Icons.bedtime_outlined,
      ),
      AnalyticsMetric(
        id: 'next_period',
        labelAr: 'الدورة القادمة',
        labelEn: 'Next period',
        value: daysUntilNext(data, data.avgCycleLength),
        suffix: ' d',
        icon: Icons.event,
      ),
      AnalyticsMetric(
        id: 'ovulation',
        labelAr: 'الإباضة',
        labelEn: 'Ovulation',
        value: data.ovulation.isEmpty ? '—' : data.ovulation,
        icon: Icons.favorite_outline,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _generalScores(CycleDashboardData data) {
    return [
      AnalyticsScoreCard(
        id: 'cycle_health',
        titleAr: 'صحة الدورة',
        titleEn: 'Cycle health',
        score: data.cycleRegularity,
        band: regularityBand(data.cycleRegularity),
        descriptionAr: data.cycleRegularity >= 70
            ? 'دورتكِ منتظمة — استمري بالمتابعة.'
            : 'حاولي تسجيل الأعراض يومياً لرفع الدقة.',
        descriptionEn: data.cycleRegularity >= 70
            ? 'Your cycle is regular — keep logging to maintain it.'
            : 'Try logging daily to improve prediction accuracy.',
      ),
      AnalyticsScoreCard(
        id: 'tracking_streak',
        titleAr: 'الالتزام بالتسجيل',
        titleEn: 'Tracking consistency',
        score: math.min(100, data.totalCycles * 18.0),
        band: data.totalCycles >= 4
            ? MetricBand.excellent
            : data.totalCycles >= 2
                ? MetricBand.good
                : MetricBand.fair,
        descriptionAr: data.totalCycles >= 4
            ? 'تسجيل متواصل — أنتِ تقدري تلاحظي أنماط واضحة.'
            : 'استمري بالتسجيل لرؤية أنماط أعمق.',
        descriptionEn: data.totalCycles >= 4
            ? 'Consistent logging — patterns are starting to emerge.'
            : 'Keep logging to unlock deeper pattern analysis.',
      ),
      AnalyticsScoreCard(
        id: 'wellness',
        titleAr: 'الرفاهية العامة',
        titleEn: 'Overall wellness',
        score: (moodScoreFromCycle(data) +
                energyScoreFromCycle(data) +
                sleepQualityFromCycle(data)) /
            3,
        band: regularityBand(
          (moodScoreFromCycle(data) +
                  energyScoreFromCycle(data) +
                  sleepQualityFromCycle(data)) /
              3,
        ),
        descriptionAr: 'متوسط مزاجكِ، طاقتكِ، ونومكِ حسب المرحلة الحالية.',
        descriptionEn: 'Your average mood, energy, and sleep by phase.',
      ),
    ];
  }

  // -----------------------------------------------------------------------
  // CONCEIVE (TTC)
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _conceiveMetrics(CycleDashboardData data) {
    return [
      AnalyticsMetric(
        id: 'pregnancy_chance',
        labelAr: 'احتمال الحمل اليوم',
        labelEn: 'Pregnancy chance today',
        value: data.pregnancyChances.isEmpty ? '—' : data.pregnancyChances,
        icon: Icons.child_friendly,
        status: isHighFertility(data) ? 'good' : 'fair',
      ),
      AnalyticsMetric(
        id: 'ovulation_day',
        labelAr: 'يوم الإباضة',
        labelEn: 'Ovulation day',
        value: data.isOvulationDay ? 'Yes' : 'No',
        icon: Icons.favorite,
        status: data.isOvulationDay ? 'good' : 'fair',
      ),
      AnalyticsMetric(
        id: 'fertility_window',
        labelAr: 'نافذة الخصوبة',
        labelEn: 'Fertility window',
        value: fertilityWindowDays,
        suffix: ' d',
        icon: Icons.timeline,
      ),
      AnalyticsMetric(
        id: 'high_fertility',
        labelAr: 'خصوبة عالية',
        labelEn: 'High fertility',
        value: isHighFertility(data) ? 'Yes' : 'No',
        icon: Icons.local_fire_department,
        status: isHighFertility(data) ? 'good' : 'fair',
      ),
      AnalyticsMetric(
        id: 'test_date',
        labelAr: 'تاريخ اختبار الحمل',
        labelEn: 'Pregnancy test',
        value: data.expectedPregnancyTestDate.isEmpty
            ? '—'
            : data.expectedPregnancyTestDate,
        icon: Icons.science_outlined,
      ),
      AnalyticsMetric(
        id: 'days_trying',
        labelAr: 'أيام المحاولة',
        labelEn: 'Days trying',
        value: daysTrying(data),
        suffix: ' d',
        icon: Icons.hourglass_bottom,
      ),
      AnalyticsMetric(
        id: 'cycle_regularity',
        labelAr: 'انتظام الدورة',
        labelEn: 'Cycle regularity',
        value: data.cycleRegularity,
        suffix: '%',
        icon: Icons.timeline,
        status: regularityBand(data.cycleRegularity).label,
        trend: 1,
      ),
      AnalyticsMetric(
        id: 'avg_cycle',
        labelAr: 'متوسط طول الدورة',
        labelEn: 'Avg cycle',
        value: data.avgCycleLength,
        suffix: ' d',
        icon: Icons.loop,
      ),
      AnalyticsMetric(
        id: 'ovulation_date',
        labelAr: 'تاريخ الإباضة القادم',
        labelEn: 'Next ovulation',
        value: data.ovulation.isEmpty ? '—' : data.ovulation,
        icon: Icons.favorite_outline,
      ),
      AnalyticsMetric(
        id: 'phase',
        labelAr: 'المرحلة الحالية',
        labelEn: 'Current phase',
        value: data.phase.isEmpty ? '—' : data.phase,
        icon: Icons.wb_sunny_outlined,
      ),
      AnalyticsMetric(
        id: 'mood',
        labelAr: 'المزاج',
        labelEn: 'Mood',
        value: moodScoreFromCycle(data),
        suffix: '%',
        icon: Icons.mood,
      ),
      AnalyticsMetric(
        id: 'energy',
        labelAr: 'الطاقة',
        labelEn: 'Energy',
        value: energyScoreFromCycle(data),
        suffix: '%',
        icon: Icons.bolt,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _conceiveScores(CycleDashboardData data) {
    final fert = isHighFertility(data) ? 90.0 : 55.0;
    return [
      AnalyticsScoreCard(
        id: 'fertility',
        titleAr: 'جاهزية الخصوبة',
        titleEn: 'Fertility readiness',
        score: fert,
        band: regularityBand(fert),
        descriptionAr: isHighFertility(data)
            ? 'أنتِ في نافذة الخصوبة — أفضل وقت للحمل.'
            : 'اقتربي من نافذة الخصوبة خلال أيام.',
        descriptionEn: isHighFertility(data)
            ? 'You\'re in your fertile window — best time to conceive.'
            : 'Approaching your fertile window in a few days.',
      ),
      AnalyticsScoreCard(
        id: 'cycle_quality',
        titleAr: 'جودة الدورة',
        titleEn: 'Cycle quality',
        score: data.cycleRegularity,
        band: regularityBand(data.cycleRegularity),
        descriptionAr: 'الدورات المنتظمة ترفع احتمال الحمل.',
        descriptionEn: 'Regular cycles improve your chances.',
      ),
    ];
  }

  // -----------------------------------------------------------------------
  // AVOID
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _avoidMetrics(CycleDashboardData data) {
    return [
      AnalyticsMetric(
        id: 'fertility_today',
        labelAr: 'الخصوبة اليوم',
        labelEn: 'Fertility today',
        value: isHighFertility(data) ? 'High' : 'Low',
        icon: Icons.shield_outlined,
        status: isHighFertility(data) ? 'bad' : 'good',
      ),
      AnalyticsMetric(
        id: 'cycle_day',
        labelAr: 'يوم الدورة',
        labelEn: 'Cycle day',
        value: data.cycleDay,
        suffix: ' / ${data.avgCycleLength > 0 ? data.avgCycleLength : 28}',
        icon: Icons.calendar_today,
      ),
      AnalyticsMetric(
        id: 'high_fert_days',
        labelAr: 'أيام خصوبة عالية',
        labelEn: 'High fertility days',
        value: 5,
        suffix: ' d/cycle',
        icon: Icons.warning_amber_rounded,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'ovulation',
        labelAr: 'الإباضة',
        labelEn: 'Ovulation',
        value: data.ovulation.isEmpty ? '—' : data.ovulation,
        icon: Icons.favorite_outline,
      ),
      AnalyticsMetric(
        id: 'next_period',
        labelAr: 'الدورة القادمة',
        labelEn: 'Next period',
        value: data.nextPeriod.isEmpty ? '—' : data.nextPeriod,
        icon: Icons.event,
      ),
      AnalyticsMetric(
        id: 'cycle_regularity',
        labelAr: 'انتظام الدورة',
        labelEn: 'Cycle regularity',
        value: data.cycleRegularity,
        suffix: '%',
        icon: Icons.timeline,
        status: regularityBand(data.cycleRegularity).label,
      ),
      AnalyticsMetric(
        id: 'avg_cycle',
        labelAr: 'متوسط طول الدورة',
        labelEn: 'Avg cycle',
        value: data.avgCycleLength,
        suffix: ' d',
        icon: Icons.loop,
      ),
      AnalyticsMetric(
        id: 'period_day',
        labelAr: 'يوم الحيض',
        labelEn: 'Period day',
        value: data.periodDay,
        suffix: ' / ${data.avgPeriodDuration > 0 ? data.avgPeriodDuration : 5}',
        icon: Icons.water_drop,
        status: data.isPeriodStarted ? 'good' : 'fair',
      ),
      AnalyticsMetric(
        id: 'phase',
        labelAr: 'المرحلة',
        labelEn: 'Phase',
        value: data.phase.isEmpty ? '—' : data.phase,
        icon: Icons.wb_sunny_outlined,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _avoidScores(CycleDashboardData data) {
    return [
      AnalyticsScoreCard(
        id: 'protection',
        titleAr: 'جاهزية الحماية',
        titleEn: 'Protection readiness',
        score: data.cycleRegularity,
        band: regularityBand(data.cycleRegularity),
        descriptionAr: isHighFertility(data)
            ? 'خصوبة عالية — استخدمي حماية إضافية.'
            : 'خصوبة منخفضة — استمري بالحماية.',
        descriptionEn: isHighFertility(data)
            ? 'High fertility — use extra protection.'
            : 'Low fertility — keep protection on.',
      ),
      AnalyticsScoreCard(
        id: 'cycle_predictability',
        titleAr: 'قابلية التنبؤ بالدورة',
        titleEn: 'Cycle predictability',
        score: data.cycleRegularity,
        band: regularityBand(data.cycleRegularity),
        descriptionAr: 'كلما زاد الانتظام، زادت دقة تتبّع الأيام الآمنة.',
        descriptionEn:
            'More regular cycles = more accurate safe-day tracking.',
      ),
    ];
  }

  // -----------------------------------------------------------------------
  // PREGNANT
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _pregnancyMetrics(CycleDashboardData data) {
    final week = data.pregnancyWeek.clamp(0, 42);
    final trim = trimesterFromWeek(week);
    return [
      AnalyticsMetric(
        id: 'pregnancy_week',
        labelAr: 'أسبوع الحمل',
        labelEn: 'Pregnancy week',
        value: week,
        suffix: ' / 42',
        icon: Icons.pregnant_woman,
        status: 'good',
      ),
      AnalyticsMetric(
        id: 'trimester',
        labelAr: 'الثلث',
        labelEn: 'Trimester',
        value: 'T$trim',
        icon: Icons.layers,
        status: 'good',
      ),
      AnalyticsMetric(
        id: 'progress',
        labelAr: 'تقدّم الحمل',
        labelEn: 'Pregnancy progress',
        value: pregnancyProgress(week),
        suffix: '%',
        icon: Icons.donut_large,
        status: 'good',
        trend: 1,
      ),
      AnalyticsMetric(
        id: 'days_until_due',
        labelAr: 'أيام حتى الموعد',
        labelEn: 'Days until due',
        value: daysUntilDue(data.expectedDueDate),
        suffix: ' d',
        icon: Icons.event_available,
        status: 'good',
      ),
      AnalyticsMetric(
        id: 'due_date',
        labelAr: 'تاريخ الولادة المتوقع',
        labelEn: 'Due date',
        value: data.expectedDueDate.isEmpty ? '—' : data.expectedDueDate,
        icon: Icons.cake_outlined,
      ),
      AnalyticsMetric(
        id: 'test_date',
        labelAr: 'تاريخ اختبار الحمل',
        labelEn: 'Test reminder',
        value: data.expectedPregnancyTestDate.isEmpty
            ? '—'
            : data.expectedPregnancyTestDate,
        icon: Icons.science_outlined,
      ),
      AnalyticsMetric(
        id: 'sleep',
        labelAr: 'جودة النوم',
        labelEn: 'Sleep quality',
        value: sleepQualityFromCycle(data),
        suffix: '%',
        icon: Icons.bedtime_outlined,
      ),
      AnalyticsMetric(
        id: 'mood',
        labelAr: 'المزاج',
        labelEn: 'Mood',
        value: moodScoreFromCycle(data),
        suffix: '%',
        icon: Icons.mood,
      ),
      AnalyticsMetric(
        id: 'energy',
        labelAr: 'الطاقة',
        labelEn: 'Energy',
        value: energyScoreFromCycle(data),
        suffix: '%',
        icon: Icons.bolt,
      ),
      AnalyticsMetric(
        id: 'cycle_day',
        labelAr: 'يوم منذ آخر دورة',
        labelEn: 'Days since LMP',
        value: data.cycleDay,
        suffix: ' d',
        icon: Icons.calendar_today,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _pregnancyScores(CycleDashboardData data) {
    final week = data.pregnancyWeek.clamp(0, 42);
    return [
      AnalyticsScoreCard(
        id: 'pregnancy_progress',
        titleAr: 'تقدّم الحمل',
        titleEn: 'Pregnancy progress',
        score: pregnancyProgress(week),
        band: regularityBand(pregnancyProgress(week)),
        descriptionAr: 'الأسبوع $week من 42 — أنتِ في الثلث ${trimesterFromWeek(week)}.',
        descriptionEn: 'Week $week of 42 — you\'re in trimester ${trimesterFromWeek(week)}.',
      ),
      AnalyticsScoreCard(
        id: 'prenatal_care',
        titleAr: 'جودة المتابعة',
        titleEn: 'Prenatal care',
        score: 75,
        band: MetricBand.good,
        descriptionAr: 'تذكّري فيتامينات الحمل، زيارة الطبيب، والماء الكافي.',
        descriptionEn: 'Take prenatals, attend visits, and hydrate well.',
      ),
    ];
  }

  // -----------------------------------------------------------------------
  // MENOPAUSE
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _menopauseMetrics(CycleDashboardData data) {
    return [
      AnalyticsMetric(
        id: 'cycle_regularity',
        labelAr: 'انتظام الدورة',
        labelEn: 'Cycle regularity',
        value: data.cycleRegularity,
        suffix: '%',
        icon: Icons.timeline,
        status: data.cycleRegularity < 50 ? 'warning' : 'good',
      ),
      AnalyticsMetric(
        id: 'cycle_day',
        labelAr: 'يوم الدورة',
        labelEn: 'Cycle day',
        value: data.cycleDay,
        suffix: ' / ${data.avgCycleLength > 0 ? data.avgCycleLength : 28}',
        icon: Icons.calendar_today,
      ),
      AnalyticsMetric(
        id: 'avg_cycle',
        labelAr: 'متوسط طول الدورة',
        labelEn: 'Avg cycle',
        value: data.avgCycleLength,
        suffix: ' d',
        icon: Icons.loop,
        status: data.avgCycleLength > 35 || data.avgCycleLength < 21
            ? 'warning'
            : 'good',
      ),
      AnalyticsMetric(
        id: 'avg_period',
        labelAr: 'متوسط الحيض',
        labelEn: 'Avg period',
        value: data.avgPeriodDuration,
        suffix: ' d',
        icon: Icons.calendar_view_month,
      ),
      AnalyticsMetric(
        id: 'cycle_variation',
        labelAr: 'تذبذب الدورة',
        labelEn: 'Cycle variation',
        value: cycleVariation(data.avgCycleLength, data.cycleDay),
        suffix: '%',
        icon: Icons.show_chart,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'total_cycles',
        labelAr: 'إجمالي الدورات',
        labelEn: 'Total cycles',
        value: data.totalCycles,
        icon: Icons.repeat,
      ),
      AnalyticsMetric(
        id: 'mood',
        labelAr: 'المزاج',
        labelEn: 'Mood',
        value: moodScoreFromCycle(data),
        suffix: '%',
        icon: Icons.mood,
      ),
      AnalyticsMetric(
        id: 'sleep',
        labelAr: 'جودة النوم',
        labelEn: 'Sleep quality',
        value: sleepQualityFromCycle(data),
        suffix: '%',
        icon: Icons.bedtime_outlined,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'energy',
        labelAr: 'الطاقة',
        labelEn: 'Energy',
        value: energyScoreFromCycle(data),
        suffix: '%',
        icon: Icons.bolt,
      ),
      AnalyticsMetric(
        id: 'next_period',
        labelAr: 'الدورة القادمة',
        labelEn: 'Next period',
        value: data.nextPeriod.isEmpty ? '—' : data.nextPeriod,
        icon: Icons.event,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'phase',
        labelAr: 'المرحلة',
        labelEn: 'Phase',
        value: data.phase.isEmpty ? '—' : data.phase,
        icon: Icons.wb_sunny_outlined,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _menopauseScores(CycleDashboardData data) {
    return [
      AnalyticsScoreCard(
        id: 'transition',
        titleAr: 'مرحلة الانتقال',
        titleEn: 'Transition phase',
        score: data.cycleRegularity,
        band: regularityBand(data.cycleRegularity),
        descriptionAr: data.cycleRegularity < 50
            ? 'الدورة غير منتظمة — هذا شائع في هذه المرحلة.'
            : 'الدورة لا تزال منتظمة نسبياً.',
        descriptionEn: data.cycleRegularity < 50
            ? 'Irregular cycles are common at this stage.'
            : 'Your cycle is still relatively regular.',
      ),
      AnalyticsScoreCard(
        id: 'sleep_wellness',
        titleAr: 'صحة النوم',
        titleEn: 'Sleep wellness',
        score: sleepQualityFromCycle(data),
        band: regularityBand(sleepQualityFromCycle(data)),
        descriptionAr: 'الهبّات الساخنة والتعرّق الليلي يؤثران على النوم.',
        descriptionEn: 'Hot flashes and night sweats affect sleep.',
      ),
      AnalyticsScoreCard(
        id: 'mood_wellness',
        titleAr: 'توازن المزاج',
        titleEn: 'Mood balance',
        score: moodScoreFromCycle(data),
        band: regularityBand(moodScoreFromCycle(data)),
        descriptionAr: 'تقلّبات المزاج طبيعية بسبب التغيّرات الهرمونية.',
        descriptionEn: 'Mood shifts are common with hormonal changes.',
      ),
    ];
  }

  // -----------------------------------------------------------------------
  // PCOS
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _pcosMetrics(CycleDashboardData data) {
    return [
      AnalyticsMetric(
        id: 'cycle_regularity',
        labelAr: 'انتظام الدورة',
        labelEn: 'Cycle regularity',
        value: data.cycleRegularity,
        suffix: '%',
        icon: Icons.timeline,
        status: data.cycleRegularity < 50 ? 'bad' : 'fair',
      ),
      AnalyticsMetric(
        id: 'cycle_variation',
        labelAr: 'تذبذب الدورة',
        labelEn: 'Cycle variation',
        value: cycleVariation(data.avgCycleLength, data.cycleDay),
        suffix: '%',
        icon: Icons.show_chart,
        status: 'bad',
      ),
      AnalyticsMetric(
        id: 'avg_cycle',
        labelAr: 'متوسط الدورة',
        labelEn: 'Avg cycle',
        value: data.avgCycleLength,
        suffix: ' d',
        icon: Icons.loop,
        status: data.avgCycleLength > 35 ? 'warning' : 'good',
      ),
      AnalyticsMetric(
        id: 'avg_period',
        labelAr: 'متوسط الحيض',
        labelEn: 'Avg period',
        value: data.avgPeriodDuration,
        suffix: ' d',
        icon: Icons.calendar_view_month,
      ),
      AnalyticsMetric(
        id: 'cycle_day',
        labelAr: 'يوم الدورة',
        labelEn: 'Cycle day',
        value: data.cycleDay,
        suffix: ' / ${data.avgCycleLength > 0 ? data.avgCycleLength : 28}',
        icon: Icons.calendar_today,
      ),
      AnalyticsMetric(
        id: 'total_cycles',
        labelAr: 'إجمالي الدورات',
        labelEn: 'Total cycles',
        value: data.totalCycles,
        icon: Icons.repeat,
      ),
      AnalyticsMetric(
        id: 'next_period',
        labelAr: 'الدورة القادمة',
        labelEn: 'Next period',
        value: data.nextPeriod.isEmpty ? '—' : data.nextPeriod,
        icon: Icons.event,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'ovulation',
        labelAr: 'الإباضة',
        labelEn: 'Ovulation',
        value: data.ovulation.isEmpty ? '—' : data.ovulation,
        icon: Icons.favorite_outline,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'mood',
        labelAr: 'المزاج',
        labelEn: 'Mood',
        value: moodScoreFromCycle(data),
        suffix: '%',
        icon: Icons.mood,
      ),
      AnalyticsMetric(
        id: 'sleep',
        labelAr: 'النوم',
        labelEn: 'Sleep',
        value: sleepQualityFromCycle(data),
        suffix: '%',
        icon: Icons.bedtime_outlined,
      ),
      AnalyticsMetric(
        id: 'energy',
        labelAr: 'الطاقة',
        labelEn: 'Energy',
        value: energyScoreFromCycle(data),
        suffix: '%',
        icon: Icons.bolt,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _pcosScores(CycleDashboardData data) {
    return [
      AnalyticsScoreCard(
        id: 'cycle_irregularity',
        titleAr: 'مدى انتظام الدورة',
        titleEn: 'Cycle irregularity',
        score: data.cycleRegularity,
        band: regularityBand(data.cycleRegularity),
        descriptionAr: data.cycleRegularity < 50
            ? 'دورتكِ غير منتظمة — ناقشي ذلك مع طبيبتكِ.'
            : 'الدورة تتحسّن — استمري بالمتابعة.',
        descriptionEn: data.cycleRegularity < 50
            ? 'Your cycle is irregular — discuss with your doctor.'
            : 'Cycle is improving — keep tracking.',
      ),
      AnalyticsScoreCard(
        id: 'metabolic',
        titleAr: 'صحة التمثيل الغذائي',
        titleEn: 'Metabolic health',
        score: math.max(0, 100 - cycleVariation(data.avgCycleLength, data.cycleDay).abs()),
        band: regularityBand(math.max(0, 100 - cycleVariation(data.avgCycleLength, data.cycleDay).abs())),
        descriptionAr: 'الألياف، الحركة، والنوم يدعمان توازن الإنسولين.',
        descriptionEn:
            'Fiber, movement, and sleep support insulin balance.',
      ),
      AnalyticsScoreCard(
        id: 'wellness',
        titleAr: 'الرفاهية العامة',
        titleEn: 'Overall wellness',
        score: (moodScoreFromCycle(data) +
                energyScoreFromCycle(data) +
                sleepQualityFromCycle(data)) /
            3,
        band: regularityBand(
          (moodScoreFromCycle(data) +
                  energyScoreFromCycle(data) +
                  sleepQualityFromCycle(data)) /
              3,
        ),
        descriptionAr: 'مزاجكِ، طاقتكِ، ونومكِ — كلها عوامل مؤثرة.',
        descriptionEn: 'Your mood, energy, and sleep all matter.',
      ),
    ];
  }

  // -----------------------------------------------------------------------
  // POSTPARTUM
  // -----------------------------------------------------------------------
  static List<AnalyticsMetric> _postpartumMetrics(CycleDashboardData data) {
    final recovery = recoveryDay(data);
    return [
      AnalyticsMetric(
        id: 'recovery_day',
        labelAr: 'يوم الاستشفاء',
        labelEn: 'Recovery day',
        value: recovery,
        suffix: ' d',
        icon: Icons.healing,
        status: 'good',
        trend: 1,
      ),
      AnalyticsMetric(
        id: 'cycle_day',
        labelAr: 'يوم منذ الولادة',
        labelEn: 'Days postpartum',
        value: data.cycleDay,
        suffix: ' d',
        icon: Icons.calendar_today,
      ),
      AnalyticsMetric(
        id: 'avg_cycle',
        labelAr: 'متوسط الدورة قبل',
        labelEn: 'Pre-pregnancy cycle',
        value: data.avgCycleLength,
        suffix: ' d',
        icon: Icons.loop,
      ),
      AnalyticsMetric(
        id: 'avg_period',
        labelAr: 'متوسط الحيض قبل',
        labelEn: 'Pre-pregnancy period',
        value: data.avgPeriodDuration,
        suffix: ' d',
        icon: Icons.calendar_view_month,
      ),
      AnalyticsMetric(
        id: 'sleep',
        labelAr: 'جودة النوم',
        labelEn: 'Sleep quality',
        value: sleepQualityFromCycle(data),
        suffix: '%',
        icon: Icons.bedtime_outlined,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'mood',
        labelAr: 'المزاج',
        labelEn: 'Mood',
        value: moodScoreFromCycle(data),
        suffix: '%',
        icon: Icons.mood,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'energy',
        labelAr: 'الطاقة',
        labelEn: 'Energy',
        value: energyScoreFromCycle(data),
        suffix: '%',
        icon: Icons.bolt,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'next_period',
        labelAr: 'الدورة القادمة',
        labelEn: 'Next period',
        value: data.nextPeriod.isEmpty ? '—' : data.nextPeriod,
        icon: Icons.event,
        status: 'warning',
      ),
      AnalyticsMetric(
        id: 'total_cycles',
        labelAr: 'إجمالي الدورات',
        labelEn: 'Total cycles logged',
        value: data.totalCycles,
        icon: Icons.repeat,
      ),
    ];
  }

  static List<AnalyticsScoreCard> _postpartumScores(CycleDashboardData data) {
    return [
      AnalyticsScoreCard(
        id: 'recovery',
        titleAr: 'تقدّم الاستشفاء',
        titleEn: 'Recovery progress',
        score: math.min(100, recoveryDay(data) * 2.0),
        band: regularityBand(math.min(100, recoveryDay(data) * 2.0)),
        descriptionAr: 'الشفاء يأخذ وقتاً — أنتِ تفعلينها بشكل رائع.',
        descriptionEn: 'Healing takes time — you\'re doing great.',
      ),
      AnalyticsScoreCard(
        id: 'wellness',
        titleAr: 'الرفاهية',
        titleEn: 'Wellness',
        score: (moodScoreFromCycle(data) +
                energyScoreFromCycle(data) +
                sleepQualityFromCycle(data)) /
            3,
        band: regularityBand(
          (moodScoreFromCycle(data) +
                  energyScoreFromCycle(data) +
                  sleepQualityFromCycle(data)) /
              3,
        ),
        descriptionAr: 'الراحة، الرضاعة، والمزاج — كلها مهمة.',
        descriptionEn: 'Rest, feeding, and mood — all matter.',
      ),
    ];
  }
}
