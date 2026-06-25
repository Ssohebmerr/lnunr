import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/utils/model/periods_date_range.dart';

import '../../../../core/widgets/app_surface.dart';
import '../../../../l10n/app_localizations.dart';

class CycleHistoryTable extends StatelessWidget {
  const CycleHistoryTable({super.key, required this.cycles});

  final List<PeriodsDateRange> cycles;

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.primary,
    );
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      height: 1.35,
    );

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.reportCycleHistoryTable,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(l10n.reportCycleHistoryStart, style: headerStyle),
              ),
              Expanded(
                child: Text(
                  l10n.reportCycleHistoryCycle,
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  l10n.reportCycleHistoryPeriod,
                  style: headerStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
          ...cycles.take(8).map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          c.periodStartDate ?? '—',
                          style: cellStyle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${c.cycleLength ?? 0}d',
                          style: cellStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${c.periodDuration ?? 0}d',
                          style: cellStyle,
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
