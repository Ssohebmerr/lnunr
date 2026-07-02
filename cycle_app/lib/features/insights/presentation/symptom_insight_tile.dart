import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../data/insight_message_builder.dart';
import '../data/symptom_insight_analyzer.dart';

/// One card per [SymptomInsight]. Designed for the "Insights" tab —
/// shows the headline, the cycle sample count, and (optionally) a
/// actionable tip. The per-phase bars are drawn inline.
class SymptomInsightTile extends StatelessWidget {
  const SymptomInsightTile({
    super.key,
    required this.insight,
    required this.isArabic,
    this.builder = const InsightMessageBuilder(),
  });

  final SymptomInsight insight;
  final bool isArabic;
  final InsightMessageBuilder builder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(insight.dominantPhase, theme);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: AppShadows.softPlum(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconFor(insight.dominantPhase),
                    size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  builder.buildHeadline(insight, isArabic: isArabic),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              _ConfidencePill(confidence: insight.confidence, color: accent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            builder.buildSubtitle(insight, isArabic: isArabic),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          _PhaseBars(insight: insight, accent: accent),
          if (builder.buildTip(insight, isArabic: isArabic) != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 14, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      builder.buildTip(insight, isArabic: isArabic)!,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String phase) {
    switch (phase) {
      case 'menstruation':
        return Icons.water_drop_outlined;
      case 'ovulation':
        return Icons.favorite_outline;
      case 'luteal':
        return Icons.nightlight_outlined;
      case 'follicular':
        return Icons.bolt_outlined;
      case 'late':
        return Icons.hourglass_bottom_outlined;
      default:
        return Icons.spa_outlined;
    }
  }

  Color _accentFor(String phase, ThemeData theme) {
    switch (phase) {
      case 'menstruation':
        return const Color(0xFFE06C75);
      case 'follicular':
        return const Color(0xFF7FB069);
      case 'ovulation':
        return const Color(0xFFE8B647);
      case 'luteal':
        return const Color(0xFFA685E2);
      case 'late':
        return const Color(0xFFD17A22);
      default:
        return theme.colorScheme.primary;
    }
  }
}

class _ConfidencePill extends StatelessWidget {
  const _ConfidencePill({required this.confidence, required this.color});

  final int confidence;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$confidence%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Renders one thin bar per phase showing the percentage of occurrences.
class _PhaseBars extends StatelessWidget {
  const _PhaseBars({required this.insight, required this.accent});

  final SymptomInsight insight;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    for (final p in insight.phases) {
      final pct = (p.percentage ?? 0).clamp(0, 100).toDouble();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  p.phaseName ?? '—',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '${pct.toInt()}%',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}