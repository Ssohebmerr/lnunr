import 'package:flutter/material.dart';

import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

class ConditionalGraphCard extends StatelessWidget {
  const ConditionalGraphCard({
    super.key,
    required this.hasData,
    required this.child,
  });

  final bool hasData;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!hasData) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppGlassCard(
          child: Row(
            children: [
              Icon(
                Icons.bar_chart_outlined,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.insightsGraphEmpty,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: EdgeInsets.zero,
        child: SizedBox(height: 260, child: child),
      ),
    );
  }
}
