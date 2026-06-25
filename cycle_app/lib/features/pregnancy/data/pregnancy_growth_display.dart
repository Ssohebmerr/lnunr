import 'package:flutter/material.dart';

import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import 'pregnancy_development_content.dart';
/// Length + weight chips — medical-style growth stats (no food comparisons).
class PregnancyGrowthStatsRow extends StatelessWidget {
  const PregnancyGrowthStatsRow({
    super.key,
    required this.info,
    required this.lang,
    this.spacing = 8,
  });

  final PregnancyWeekInfo info;
  final String lang;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        AppStatChip(
          icon: Icons.straighten_rounded,
          label: '${l10n.pregnancyLengthLabel}: ${info.lengthDisplay(lang)}',
          highlight: true,
        ),
        AppStatChip(
          icon: Icons.monitor_weight_outlined,
          label: '${l10n.pregnancyWeightLabel}: ${info.weightDisplay(lang)}',
        ),
      ],
    );
  }
}
