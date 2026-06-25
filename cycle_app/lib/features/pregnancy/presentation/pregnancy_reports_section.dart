import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../data/pregnancy_development_content.dart';
import 'pregnancy_tracking_section.dart';
import 'fetal_week_illustration.dart';
import '../../home/widgets/reports_ui.dart';

/// Pregnancy-first reports — Lume identity, readable typography.
class PregnancyReportsSection extends StatelessWidget {
  const PregnancyReportsSection({
    super.key,
    required this.data,
  });

  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final week = data.pregnancyWeek.clamp(4, 42);
    final info = PregnancyDevelopmentContent.forWeek(week, lang);
    final daysToDue = _daysUntilDue(data.expectedDueDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGlassCard(
          blur: false,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.18),
                  theme.colorScheme.secondary.withValues(alpha: 0.12),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                FetalWeekIllustration(week: week, size: 88),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pregnancyWeekDay(week, data.cycleDay),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.pregnancyTrimester(data.trimester),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (daysToDue != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.pregnancyDaysToDue(daysToDue),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AppSectionHeader(title: l10n.pregnancyReportOverview),
        ReportsMetricGrid(
          children: [
            ReportsMetricTile(
              icon: Icons.pregnant_woman_rounded,
              label: l10n.reportPregnancyWeek,
              value: '$week',
              accent: theme.colorScheme.primary,
            ),
            ReportsMetricTile(
              icon: Icons.layers_outlined,
              label: l10n.reportTrimester,
              value: '${data.trimester}',
              accent: theme.colorScheme.secondary,
            ),
            ReportsMetricTile(
              icon: Icons.event_available_outlined,
              label: l10n.reportDueDate,
              value: data.expectedDueDate,
              accent: AuraColors.peachGold,
            ),
            ReportsMetricTile(
              icon: Icons.straighten_rounded,
              label: l10n.pregnancyLengthLabel,
              value: info.lengthDisplay(lang),
              accent: theme.colorScheme.tertiary,
            ),
            ReportsMetricTile(
              icon: Icons.monitor_weight_outlined,
              label: l10n.pregnancyWeightLabel,
              value: info.weightDisplay(lang),
              accent: AuraColors.lavenderSoft,
            ),
          ],
        ),
        const SizedBox(height: 14),
        ReportsInsightCard(
          icon: Icons.child_care_rounded,
          title: l10n.pregnancyBabyThisWeek,
          body: info.bodyFor(lang),
        ),
        const SizedBox(height: 12),
        ReportsInsightCard(
          icon: Icons.favorite_outline,
          title: l10n.pregnancyYourBody,
          body: info.maternalFor(lang),
        ),
        const SizedBox(height: 12),
        const PregnancyTrackingSection(compact: true),
        const SizedBox(height: 12),
        ReportsExpansionPanel(
          icon: Icons.checklist_rounded,
          title: l10n.pregnancyReportChecklist,
          subtitle: l10n.reportsChecklistHint,
          children: _checklistForTrimester(data.trimester, l10n)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  int? _daysUntilDue(String dueStr) {
    if (dueStr.isEmpty || dueStr == '—' || dueStr == '-') return null;
    try {
      final due = DateTime.parse(dueStr.replaceAll('/', '-'));
      return due.difference(DateTime.now()).inDays.clamp(0, 300);
    } catch (_) {
      return null;
    }
  }

  List<String> _checklistForTrimester(int trimester, AppLocalizations l10n) {
    return switch (trimester) {
      1 => [
          l10n.pregnancyCheckFirstVisit,
          l10n.pregnancyCheckPrenatalVitamins,
          l10n.pregnancyCheckRest,
        ],
      2 => [
          l10n.pregnancyCheckAnatomyScan,
          l10n.pregnancyCheckMovement,
          l10n.pregnancyCheckHydration,
        ],
      _ => [
          l10n.pregnancyCheckBirthPlan,
          l10n.pregnancyCheckHospitalBag,
          l10n.pregnancyCheckKickCounts,
        ],
    };
  }
}
