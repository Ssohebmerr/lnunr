import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import 'analytics_data.dart';

/// Big headline score card — used at the top of each goal section.
/// Renders a radial progress, a band label, and an optional description.
class AnalyticsHeadlineScore extends StatelessWidget {
  const AnalyticsHeadlineScore({
    super.key,
    required this.card,
    required this.accent,
  });

  final AnalyticsScoreCard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final percent = card.score.clamp(0.0, 100.0) / 100.0;

    return AppGlassCard(
      blur: false,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 8,
                      backgroundColor: accent.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  Text(
                    '${card.score.round()}%',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.title(lang),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _bandLabel(card.band, lang),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (card.description(lang) != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      card.description(lang)!,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _bandLabel(MetricBand band, String lang) {
    if (lang.startsWith('ar')) {
      switch (band) {
        case MetricBand.excellent:
          return 'ممتاز';
        case MetricBand.good:
          return 'جيد';
        case MetricBand.fair:
          return 'مقبول';
        case MetricBand.poor:
          return 'ضعيف';
        case MetricBand.unknown:
          return 'غير معروف';
      }
    }
    return band.label;
  }
}

/// 2-column grid of metric tiles.
class AnalyticsMetricsGrid extends StatelessWidget {
  const AnalyticsMetricsGrid({
    super.key,
    required this.metrics,
    required this.accent,
  });

  final List<AnalyticsMetric> metrics;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxis = constraints.maxWidth > 540 ? 3 : 2;
        return GridView.count(
          crossAxisCount: crossAxis,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: metrics
              .map(
                (m) => AnalyticsMetricCard(
                  metric: m,
                  accent: accent,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

/// Single metric tile — icon, label, value, status dot.
class AnalyticsMetricCard extends StatelessWidget {
  const AnalyticsMetricCard({
    super.key,
    required this.metric,
    required this.accent,
  });

  final AnalyticsMetric metric;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final color = _statusColor(metric.status, accent);

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  metric.icon ?? Icons.insights_outlined,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              if (metric.trend != null)
                Icon(
                  metric.trend! > 0
                      ? Icons.trending_up
                      : metric.trend! < 0
                          ? Icons.trending_down
                          : Icons.trending_flat,
                  size: 16,
                  color: metric.trend! > 0
                      ? Colors.green.shade600
                      : metric.trend! < 0
                          ? Colors.red.shade400
                          : theme.colorScheme.outline,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.label(lang),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.value is num
                ? metric.displayValue(lang)
                : '${metric.value}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status, Color accent) {
    switch (status) {
      case 'good':
      case 'excellent':
        return Colors.green.shade600;
      case 'warning':
      case 'fair':
        return Colors.orange.shade400;
      case 'bad':
      case 'poor':
        return Colors.red.shade400;
      default:
        return accent;
    }
  }
}

/// Vertical bar chart of recent values.
class AnalyticsBarChart extends StatelessWidget {
  const AnalyticsBarChart({
    super.key,
    required this.titleAr,
    required this.titleEn,
    required this.values,
    this.accent,
    this.suffix = '',
  });

  final String titleAr;
  final String titleEn;
  final List<num> values;
  final Color? accent;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final color = accent ?? theme.colorScheme.primary;
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).toDouble();
    final minV = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b).toDouble();
    final range = math.max(1.0, maxV - minV);

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.startsWith('ar') ? titleAr : titleEn,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: values.map((v) {
                final h = ((v.toDouble() - minV) / range);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 6 + 90 * h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                color,
                                color.withValues(alpha: 0.55),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$v$suffix',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Phase distribution ring/donut.
class AnalyticsPhaseRing extends StatelessWidget {
  const AnalyticsPhaseRing({
    super.key,
    required this.titleAr,
    required this.titleEn,
    required this.phaseAr,
    required this.phaseEn,
    required this.percent,
    this.accent,
  });

  final String titleAr;
  final String titleEn;
  final String phaseAr;
  final String phaseEn;
  final double percent;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final color = accent ?? theme.colorScheme.primary;

    return AppGlassCard(
      blur: false,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: percent.clamp(0.0, 1.0),
                    strokeWidth: 7,
                    backgroundColor: color.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.startsWith('ar') ? titleAr : titleEn,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang.startsWith('ar') ? phaseAr : phaseEn,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Goal-mode header for the analytics page.
class AnalyticsSectionHeader extends StatelessWidget {
  const AnalyticsSectionHeader({
    super.key,
    required this.goal,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.accent,
  });

  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final Color accent;

  /// Convenience for icon + accent by goal.
  final dynamic goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return AppGlassCard(
      blur: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.22),
              accent.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(goal.icon, color: accent, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.startsWith('ar') ? titleAr : titleEn,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang.startsWith('ar') ? subtitleAr : subtitleEn,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
