import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/app_home_refresh.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/presentation/widgets/conditional_graph_card.dart';
import '../cycle/presentation/widgets/cycle_history_table.dart';
import '../cycle/presentation/widgets/cycle_score_section.dart';
import '../cycle/data/cycle_sync_service.dart';
import '../goals/presentation/goal_mode_reports_section.dart';
import '../pregnancy/presentation/pregnancy_reports_section.dart';
import 'doctor_report_screen.dart';
import 'widgets/reports_ui.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();
  CycleDashboardData? _dashboard;
  CycleReportData? _report;
  GraphAvailability? _graphs;
  UserGoalTypes _goal = UserGoalTypes.general;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    HomeRefreshScope.notifier.addListener(_onExternalRefresh);
    _load();
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_onExternalRefresh);
    super.dispose();
  }

  void _onExternalRefresh() => _load();

  Future<void> _load() async {
    if (MenstrualCycleWidget.instance == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadFailed = true;
        });
      }
      return;
    }

    setState(() {
      _loading = true;
      _loadFailed = false;
    });

    final dashboard = await _bridge.tryLoadDashboard();
    final report = await _bridge.tryLoadStructuredReport();
    final goal = await _sync.getUserGoal();
    GraphAvailability? graphs;
    try {
      graphs = await _bridge.loadGraphAvailability();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _dashboard = dashboard;
        _report = report;
        _graphs = graphs;
        _goal = goal;
        _loading = false;
        _loadFailed = dashboard == null && report == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (MenstrualCycleWidget.instance == null) {
      return _ReportsMessage(
        icon: Icons.settings_suggest_outlined,
        message: l10n.reportsSetupRequired,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }

    final d = _dashboard;
    final r = _report;
    final g = _graphs;
    final hasStats = d != null;
    final hasCycles = r != null && r.cycles.isNotEmpty;
    final hasPatterns = r != null && r.symptomPatterns.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          ReportsDoctorExportCard(
            title: l10n.doctorReportButton,
            subtitle: l10n.doctorReportDisclaimer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoctorReportScreen()),
            ),
          ),
          if (_loadFailed) ...[
            const SizedBox(height: 12),
            AppGlassCard(
              blur: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.reportsLoadPartial,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!hasStats && !hasCycles && !hasPatterns) ...[
            const SizedBox(height: 24),
            _ReportsMessage(
              icon: Icons.analytics_outlined,
              message: l10n.reportsEmpty,
              actionLabel: l10n.navLog,
              onAction: () => HomeShellActions.openLog?.call(),
            ),
          ],
          if (hasStats && _goal.isPregnancyMode) ...[
            const SizedBox(height: 4),
            PregnancyReportsSection(data: d),
          ] else if (hasStats && _goal.isCycleGoalMode) ...[
            const SizedBox(height: 4),
            GoalModeReportsSection(
              goal: _goal == UserGoalTypes.sexual
                  ? UserGoalTypes.general
                  : _goal,
              data: d,
            ),
          ] else if (hasStats) ...[
            const SizedBox(height: 4),
            CycleScoreSection(data: d),
          ],
          if (hasStats &&
              (hasCycles || hasPatterns || !_goal.isPregnancyMode)) ...[
            const SizedBox(height: 14),
            ReportsExpansionPanel(
              icon: Icons.bar_chart_rounded,
              title: l10n.reportsMoreTitle,
              subtitle: l10n.reportsMoreSubtitle,
              children: [
                if (hasStats &&
                    !_goal.isPregnancyMode &&
                    !_goal.isCycleGoalMode) ...[
                  AppSectionHeader(title: l10n.reportCycleHealth),
                  ReportsMetricGrid(
                    children: [
                      ReportsMetricTile(
                        icon: Icons.today_rounded,
                        label: l10n.reportCycleDay,
                        value: '${d.cycleDay}',
                        accent: theme.colorScheme.primary,
                      ),
                      ReportsMetricTile(
                        icon: Icons.water_drop_outlined,
                        label: l10n.reportPeriodDay,
                        value: '${d.periodDay}',
                        accent: theme.colorScheme.secondary,
                      ),
                      ReportsMetricTile(
                        icon: Icons.loop_rounded,
                        label: l10n.reportAvgCycle,
                        value: '${d.avgCycleLength} ${l10n.homeDayShort}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.calendar_view_month_rounded,
                        label: l10n.reportAvgPeriod,
                        value: '${d.avgPeriodDuration} ${l10n.homeDayShort}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.repeat_rounded,
                        label: l10n.reportTotalCycles,
                        value: '${d.totalCycles}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.timeline_rounded,
                        label: l10n.reportRegularity,
                        value:
                            '${d.cycleRegularity.round()}% · ${d.cycleRegularityStatus}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.insights_rounded,
                        label: l10n.insightsPeriodRegularityScore,
                        value:
                            '${d.periodRegularity.round()}% · ${d.periodRegularityStatus}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (hasStats &&
                    !_goal.isPregnancyMode &&
                    !_goal.isCycleGoalMode) ...[
                  AppSectionHeader(title: l10n.reportFertility),
                  ReportsMetricGrid(
                    children: [
                      ReportsMetricTile(
                        icon: Icons.favorite_outline,
                        label: l10n.reportOvulation,
                        value: d.ovulation,
                        accent: theme.colorScheme.secondary,
                      ),
                      ReportsMetricTile(
                        icon: Icons.child_friendly_outlined,
                        label: l10n.reportPregnancyChance,
                        value: d.pregnancyChances,
                      ),
                      ReportsMetricTile(
                        icon: Icons.event_available_outlined,
                        label: l10n.reportDueDate,
                        value: d.expectedDueDate,
                      ),
                      ReportsMetricTile(
                        icon: Icons.pregnant_woman_rounded,
                        label: l10n.reportPregnancyWeek,
                        value: '${d.pregnancyWeek}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.layers_outlined,
                        label: l10n.reportTrimester,
                        value: '${d.trimester}',
                      ),
                      if (d.expectedPregnancyTestDate.isNotEmpty &&
                          d.expectedPregnancyTestDate != '—')
                        ReportsMetricTile(
                          icon: Icons.science_outlined,
                          label: l10n.reportPregnancyTestDate,
                          value: d.expectedPregnancyTestDate,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (hasStats && _goal.isCycleGoalMode) ...[
                  AppSectionHeader(title: l10n.reportCycleHealth),
                  ReportsMetricGrid(
                    children: [
                      ReportsMetricTile(
                        icon: Icons.today_rounded,
                        label: l10n.reportCycleDay,
                        value: '${d.cycleDay}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.water_drop_outlined,
                        label: l10n.reportPeriodDay,
                        value: '${d.periodDay}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.loop_rounded,
                        label: l10n.reportAvgCycle,
                        value: '${d.avgCycleLength} ${l10n.homeDayShort}',
                      ),
                      ReportsMetricTile(
                        icon: Icons.calendar_view_month_rounded,
                        label: l10n.reportAvgPeriod,
                        value: '${d.avgPeriodDuration} ${l10n.homeDayShort}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (hasCycles && !_goal.isPregnancyMode) ...[
                  CycleHistoryTable(cycles: r.cycles),
                  const SizedBox(height: 14),
                ],
                if (!_goal.isPregnancyMode) ...[
                  AppSectionHeader(title: l10n.reportFullHistory),
                  if (g != null)
                    ConditionalGraphCard(
                      hasData: g.history,
                      child: const MenstrualCycleHistoryGraph(
                        viewCycleHistoryLength: 6,
                        appBarBackgroundColor: AuraColors.roseDeep,
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        height: 120,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
                if (hasPatterns) ...[
                  const SizedBox(height: 8),
                  AppSectionHeader(title: l10n.reportSymptomPatterns),
                  ...r.symptomPatterns.take(10).map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppGlassCard(
                            blur: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.healing_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                title: Text(
                                  p.name ?? l10n.reportPatternFallback,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  l10n.reportPercentOfCycles(
                                    p.percentageOfCycles ?? 0,
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportsMessage extends StatelessWidget {
  const _ReportsMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
