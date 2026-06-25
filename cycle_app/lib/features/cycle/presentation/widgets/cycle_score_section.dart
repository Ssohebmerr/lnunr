import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/app_surface.dart';
import '../../data/cycle_bridge_service.dart';

/// CRS + PRS regularity scores — Lume styling, readable labels.
class CycleScoreSection extends StatelessWidget {
  const CycleScoreSection({super.key, required this.data});

  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.reportCycleHealth),
        _ScoreCard(
          title: l10n.insightsCycleRegularityScore,
          score: data.cycleRegularity,
          status: data.cycleRegularityStatus,
        ),
        const SizedBox(height: 10),
        _ScoreCard(
          title: l10n.insightsPeriodRegularityScore,
          score: data.periodRegularity,
          status: data.periodRegularityStatus,
        ),
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.title,
    required this.score,
    required this.status,
  });

  final String title;
  final double score;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = score.clamp(0, 100);

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
              Text(
                '${clamped.round()}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 10,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
