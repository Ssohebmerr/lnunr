import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/cycle_bridge_service.dart';

class PredictedSymptomsCard extends StatelessWidget {
  const PredictedSymptomsCard({
    super.key,
    required this.today,
    this.tomorrow = const [],
  });

  final List<PredictedSymptom> today;
  final List<PredictedSymptom> tomorrow;

  @override
  Widget build(BuildContext context) {
    if (today.isEmpty && tomorrow.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.psychology_outlined,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.predictedSymptomsTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.predictedSymptomsDisclaimer,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          if (today.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.predictedSymptomsToday,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            ...today.take(5).map((s) => _SymptomRow(symptom: s)),
          ],
          if (tomorrow.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.predictedSymptomsTomorrow,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            ...tomorrow.take(5).map((s) => _SymptomRow(symptom: s)),
          ],
        ],
      ),
    );
  }
}

class _SymptomRow extends StatelessWidget {
  const _SymptomRow({required this.symptom});

  final PredictedSymptom symptom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pct = symptom.accuracy.clamp(0, 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(symptom.name, style: theme.textTheme.bodyMedium)),
          Text(
            l10n.predictedSymptomsLikelihood(pct),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
