import 'package:flutter/material.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';

class EmptyPillsState extends StatelessWidget {
  const EmptyPillsState({super.key, this.onSetup});

  final VoidCallback? onSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medication_liquid_outlined,
              size: 60,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.emptyPillStateWidget_noPillRegimenFound,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.emptyPillStateWidget_noPillRegimenFoundDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onSetup != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onSetup,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(l10n.regimenSetupWidget_setUpPillRegimen),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
