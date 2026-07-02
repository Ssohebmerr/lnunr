import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../l10n/app_localizations.dart';

/// Prominent estrogen / progesterone chart for Home and Reports.
class HormoneIndicatorsSection extends StatelessWidget {
  const HormoneIndicatorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (MenstrualCycleWidget.instance == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.hormoneIndicatorsTitle),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            l10n.hormoneIndicatorsSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        AppGlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.hormoneIndicatorsCaption,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 280,
                child: EstrogenProgesteroneGraph(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
