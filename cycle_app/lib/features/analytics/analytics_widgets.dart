import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../cycle/data/cycle_bridge_service.dart';
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

/// Annual basal body-temperature (BBT) indicator — a monthly-average curve
/// over the last 12 months, drawn from the user's own logged temperatures.
class AnalyticsTemperatureChart extends StatelessWidget {
  const AnalyticsTemperatureChart({
    super.key,
    required this.points,
    this.accent,
  });

  final List<MonthlyTemperature> points;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ar = lang.startsWith('ar');
    final color = accent ?? theme.colorScheme.primary;

    final values = points.map((p) => p.avgCelsius).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final avgV = values.reduce((a, b) => a + b) / values.length;

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.device_thermostat, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  ar
                      ? 'المؤشر الحراري السنوي (متوسط شهري)'
                      : 'Annual temperature (monthly avg)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _tempStat(theme, ar ? 'الأدنى' : 'Min', minV, color),
              const SizedBox(width: 8),
              _tempStat(theme, ar ? 'المتوسط' : 'Avg', avgV, color),
              const SizedBox(width: 8),
              _tempStat(theme, ar ? 'الأعلى' : 'Max', maxV, color),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: CustomPaint(
              painter: _TemperatureLinePainter(values: values, color: color),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: points
                .map(
                  (p) => Expanded(
                    child: Text(
                      AnalyticsData.monthShort(p.month, lang),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _tempStat(ThemeData theme, String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${value.toStringAsFixed(1)}°',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the temperature curve: gradient fill under a smooth line, with a dot
/// on each monthly point. Points are centered in equal slots so they align
/// with the month labels rendered below the chart.
class _TemperatureLinePainter extends CustomPainter {
  _TemperatureLinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = math.max(0.4, maxV - minV); // avoid a flat, edge-hugging line
    const topPad = 8.0;
    const bottomPad = 8.0;
    final usableH = size.height - topPad - bottomPad;
    final slot = size.width / values.length;

    Offset pointAt(int i) {
      final x = slot * (i + 0.5);
      final norm = (values[i] - minV) / range;
      final y = topPad + (1 - norm) * usableH;
      return Offset(x, y);
    }

    final pts = [for (var i = 0; i < values.length; i++) pointAt(i)];

    // Single sample: just a labelled dot in the middle.
    if (pts.length == 1) {
      canvas.drawCircle(
        pts.first,
        4,
        Paint()..color = color,
      );
      return;
    }

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }

    // Gradient fill under the curve.
    final fill = Path.from(line)
      ..lineTo(pts.last.dx, size.height)
      ..lineTo(pts.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    // The line itself.
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dots on each point.
    final dot = Paint()..color = color;
    final dotCore = Paint()..color = Colors.white;
    for (final p in pts) {
      canvas.drawCircle(p, 3.5, dot);
      canvas.drawCircle(p, 1.6, dotCore);
    }
  }

  @override
  bool shouldRepaint(covariant _TemperatureLinePainter old) =>
      old.values != values || old.color != color;
}

/// Compact prompt shown in place of the temperature curve when the user hasn't
/// logged any body-temperature readings yet.
class AnalyticsTemperatureHint extends StatelessWidget {
  const AnalyticsTemperatureHint({super.key, this.accent});

  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode.startsWith('ar');
    final color = accent ?? theme.colorScheme.primary;

    return AppGlassCard(
      blur: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.device_thermostat, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ar ? 'المؤشر الحراري السنوي' : 'Annual temperature',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ar
                      ? 'سجّلي درجة حرارتكِ يومياً لرؤية المنحنى الحراري عبر السنة.'
                      : 'Log your temperature daily to unlock the yearly curve.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
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
