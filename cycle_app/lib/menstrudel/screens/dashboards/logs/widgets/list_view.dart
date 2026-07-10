import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cycle_aura/menstrudel/models/period_logs/log_day.dart';
import 'package:cycle_aura/menstrudel/models/period_logs/symptom.dart';
import 'package:cycle_aura/menstrudel/models/periods/period.dart';
import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart';
import 'package:cycle_aura/menstrudel/models/flows/flow_enum.dart';
import 'package:cycle_aura/menstrudel/services/log_service.dart';
import 'package:cycle_aura/menstrudel/services/period_service.dart';
import 'package:cycle_aura/core/theme/app_design_tokens.dart';
import 'package:cycle_aura/core/widgets/app_surface.dart';
import 'package:provider/provider.dart';

class PeriodListView extends StatelessWidget {
  final Function(LogDay) onLogTapped;

  const PeriodListView({super.key, required this.onLogTapped});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final periodService = context.watch<PeriodService>();
    final logService = context.watch<LogService>();

    final isPeriodServiceLoading = periodService.isLoading;
    final isLogServiceLoading = logService.isLoading;

    final periodLogEntries = logService.logs;
    final periodEntries = periodService.periodEntries;

    if (isPeriodServiceLoading || isLogServiceLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (periodEntries.isEmpty && periodLogEntries.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 44,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.listViewWidget_noPeriodsLogged,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final items = periodService.timelineItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.map((item) {
            if (item is DateTime) {
              return _buildMonthHeader(item, context);
            } else if (item is Period) {
              return _buildPeriodHeader(item, context);
            } else if (item is LogDay) {
              return _buildPeriodLog(item, context);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(DateTime month, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Text(
        DateFormat('MMMM yyyy').format(month),
        style: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildPeriodHeader(Period period, BuildContext context) {
    final duration = period.endDate.difference(period.startDate).inDays + 1;
    final isOngoing = DateUtils.isSameDay(period.endDate, DateTime.now());
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AuraColors.roseDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${DateFormat('d MMM').format(period.startDate)} – ${isOngoing ? l10n.ongoing : DateFormat('d MMM').format(period.endDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AuraColors.rose.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              l10n.dayCount(duration),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodLog(LogDay entry, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppGlassCard(
        blur: false,
        onTap: () => onLogTapped(entry),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Text(
                    DateFormat('d').format(entry.date),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    DateFormat('EEE').format(entry.date).toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (entry.flow.intValue > 0)
                    Row(
                      children: List.generate(
                        entry.flow.intValue,
                        (index) => Icon(
                          Icons.water_drop,
                          size: 18,
                          color: colorScheme.primary.withAlpha(200),
                        ),
                      ),
                    ),
                  if (entry.flow.intValue > 0 && entry.symptoms.isNotEmpty)
                    const SizedBox(height: 6),
                  if (entry.symptoms.isNotEmpty)
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: entry.symptoms.map((symptom) {
                        return Chip(
                          label: Text(symptom.getDisplayName(l10n)),
                          side: BorderSide.none,
                          padding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(
                            horizontal: 0,
                            vertical: -4,
                          ),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        );
                      }).toList(),
                    ),
                  if (entry.flow.intValue == 0 && entry.symptoms.isEmpty)
                    Text(
                      DateFormat('d MMM').format(entry.date),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
