import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../core/ai/models/ai_insight.dart';
import '../../core/ai/widgets/ai_insight_card.dart';
import '../../core/app_home_refresh.dart';
import '../../core/config/feature_flags.dart';
import '../../core/navigation/home_shell_actions.dart';
import '../../core/notifications/graph_export_helper.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../analytics/analytics_sections.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/data/cycle_sync_service.dart';
import '../cycle/presentation/widgets/conditional_graph_card.dart';
import '../cycle/presentation/widgets/cycle_history_table.dart';
import '../cycle/presentation/widgets/cycle_score_section.dart';
import '../cycle/presentation/widgets/hormone_indicators_section.dart';
import '../goals/presentation/goal_mode_reports_section.dart';
import '../insights/presentation/symptom_insights_page.dart';
import '../pregnancy/presentation/pregnancy_reports_section.dart';
import 'doctor_report_screen.dart';
import 'widgets/reports_ui.dart';
import 'widgets/weekly_recap_card.dart';

/// Single destination for everything the app knows about the user's data.
///
/// Replaces the three overlapping screens that used to exist — Insights,
/// Reports, and Analytics — which all loaded the same dashboard and showed
/// heavily overlapping cards under three names a user could not tell apart
/// (in Arabic two of them were even called "التحليلات"). The content now
/// splits along the only axis that is self-evident to a reader:
///
///   * **Overview** — how am I doing right now (scores, averages, AI reading)
///   * **Charts**   — show me the trends behind it
///   * **History**  — show me the raw record, and export it
///
/// Everything loads once here and is shared by all three tabs, instead of
/// each screen re-fetching the same dashboard on its own.
class InsightsHub extends StatefulWidget {
  const InsightsHub({super.key});

  @override
  State<InsightsHub> createState() => _InsightsHubState();
}

class _InsightsHubState extends State<InsightsHub>
    with SingleTickerProviderStateMixin {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();

  late final TabController _tabs;

  CycleDashboardData? _dashboard;
  CycleReportData? _report;
  GraphAvailability? _graphs;
  AnalyticsHistory _history = AnalyticsHistory.empty;
  UserGoalTypes _goal = UserGoalTypes.general;
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    HomeRefreshScope.notifier.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_load);
    _tabs.dispose();
    super.dispose();
  }

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

    if (mounted) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }

    // Each source is awaited independently so one failure never blanks the
    // whole hub — the old Insights screen used to lose every graph when the
    // dashboard threw.
    final dashboard = await _bridge.tryLoadDashboard();
    final report = await _bridge.tryLoadStructuredReport();
    final goal = await _sync.getUserGoal();
    final history = await _bridge.tryLoadAnalyticsHistory();
    GraphAvailability? graphs;
    try {
      graphs = await _bridge.loadGraphAvailability();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _dashboard = dashboard;
      _report = report;
      _graphs = graphs;
      _history = history;
      _goal = goal;
      _loading = false;
      _loadFailed = dashboard == null && report == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (MenstrualCycleWidget.instance == null) {
      return _HubMessage(
        icon: Icons.settings_suggest_outlined,
        message: l10n.reportsSetupRequired,
        actionLabel: l10n.retry,
        onAction: _load,
      );
    }

    if (_loading && _dashboard == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _HubHeader(tabs: _tabs),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OverviewTab(
                data: _dashboard,
                goal: _goal,
                loadFailed: _loadFailed,
                onRefresh: _load,
                onOpenLog: () => HomeShellActions.openLog?.call(),
              ),
              _ChartsTab(
                data: _dashboard,
                goal: _goal,
                history: _history,
                graphs: _graphs,
                onRefresh: _load,
              ),
              _HistoryTab(
                data: _dashboard,
                report: _report,
                graphs: _graphs,
                goal: _goal,
                onRefresh: _load,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Title, one-line intro, and the tab strip that names the three lenses.
class _HubHeader extends StatelessWidget {
  const _HubHeader({required this.tabs});

  final TabController tabs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.insightsHubSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          AppGlassCard(
            blur: false,
            padding: const EdgeInsets.all(4),
            radius: AppRadius.pill,
            child: TabBar(
              controller: tabs,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: EdgeInsets.zero,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              labelColor: theme.colorScheme.onPrimary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: theme.textTheme.labelLarge,
              tabs: [
                Tab(text: l10n.insightsHubTabOverview, height: 38),
                Tab(text: l10n.insightsHubTabCharts, height: 38),
                Tab(text: l10n.insightsHubTabHistory, height: 38),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────── Overview ───────────────────────────────

/// "How am I doing" — the goal-aware headline, headline averages, the AI
/// reading, and the week's recap. Nothing here repeats on the other tabs.
class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.data,
    required this.goal,
    required this.loadFailed,
    required this.onRefresh,
    required this.onOpenLog,
  });

  final CycleDashboardData? data;
  final UserGoalTypes goal;
  final bool loadFailed;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenLog;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = data;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (loadFailed)
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
          if (d == null) ...[
            const SizedBox(height: 24),
            _HubMessage(
              icon: Icons.analytics_outlined,
              message: l10n.reportsEmpty,
              actionLabel: l10n.navLog,
              onAction: onOpenLog,
            ),
          ] else ...[
            _goalHeadline(d),
            const SizedBox(height: 12),
            if (!goal.isPregnancyMode) ...[
              _AvgStatsRow(data: d),
              const SizedBox(height: 12),
            ],
            const AiInsightCard(
              type: AiInsightType.cycleHealth,
              margin: EdgeInsets.only(bottom: 12),
            ),
            const WeeklyRecapCard(),
            if (!goal.isPregnancyMode) ...[
              const SizedBox(height: 14),
              const HormoneIndicatorsSection(),
            ],
          ],
        ],
      ),
    );
  }

  /// Goal-aware summary block — the same one Reports used to open with.
  Widget _goalHeadline(CycleDashboardData d) {
    if (goal.isPregnancyMode) return PregnancyReportsSection(data: d);
    if (goal.isCycleGoalMode || goal.hasCustomHomeBody) {
      return GoalModeReportsSection(
        goal: goal == UserGoalTypes.sexual ? UserGoalTypes.general : goal,
        data: d,
      );
    }
    return CycleScoreSection(data: d);
  }
}

class _AvgStatsRow extends StatelessWidget {
  const _AvgStatsRow({required this.data});

  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: AppStatCard(
            icon: Icons.loop,
            label: l10n.reportAvgCycle,
            value: '${data.avgCycleLength}${l10n.homeDayShort}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppStatCard(
            icon: Icons.water_drop_outlined,
            label: l10n.reportAvgPeriod,
            value: '${data.avgPeriodDuration}${l10n.homeDayShort}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppStatCard(
            icon: Icons.format_list_numbered,
            label: l10n.reportTotalCycles,
            value: '${data.totalCycles}',
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────── Charts ────────────────────────────────

/// Every trend in one place: the goal-aware analytics section that used to
/// live behind a second "Full analytics" tap, followed by the raw graphs the
/// old Insights screen owned.
class _ChartsTab extends StatelessWidget {
  const _ChartsTab({
    required this.data,
    required this.goal,
    required this.history,
    required this.graphs,
    required this.onRefresh,
  });

  final CycleDashboardData? data;
  final UserGoalTypes goal;
  final AnalyticsHistory history;
  final GraphAvailability? graphs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = data;
    final g = graphs;
    void shareExport(dynamic file) => shareGraphExport(context, file);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (d != null) ...[
            _goalAnalytics(d),
            const SizedBox(height: 18),
          ],
          AppSectionHeader(title: l10n.insightsHubChartsTitle),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l10n.insightsHubChartsSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (g == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            ConditionalGraphCard(
              hasData: g.trends,
              child: MenstrualCycleTrendsGraph(
                themeColor: AuraColors.roseDeep,
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
            ConditionalGraphCard(
              hasData: g.periods,
              child: MenstrualCyclePeriodsGraph(
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
            ConditionalGraphCard(
              hasData: g.temperature,
              child: MenstrualBodyTemperatureGraph(
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
            ConditionalGraphCard(
              hasData: g.weight,
              child: MenstrualWeightGraph(
                graphColor: AuraColors.roseDeep,
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
            ConditionalGraphCard(
              hasData: g.sleep,
              child: MenstrualSleepGraph(
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
            ConditionalGraphCard(
              hasData: g.water,
              child: MenstrualCycleWaterGraph(
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
            ConditionalGraphCard(
              hasData: g.meditation,
              child: MenstrualMeditationGraph(
                isShowMoreOptions: true,
                onImageDownloadCallback: shareExport,
                onPdfDownloadCallback: shareExport,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _goalAnalytics(CycleDashboardData d) {
    switch (goal) {
      case UserGoalTypes.pregnant:
        return AnalyticsPregnancySection(
            data: d, goal: goal, history: history);
      case UserGoalTypes.menopause:
        return AnalyticsMenopauseSection(
            data: d, goal: goal, history: history);
      case UserGoalTypes.pcos:
        return AnalyticsPcosSection(data: d, goal: goal, history: history);
      case UserGoalTypes.postpartum:
        return AnalyticsPostpartumSection(
            data: d, goal: goal, history: history);
      case UserGoalTypes.conceive:
        return AnalyticsConceiveSection(
            data: d, goal: goal, history: history);
      case UserGoalTypes.avoid:
        return AnalyticsAvoidSection(data: d, goal: goal, history: history);
      case UserGoalTypes.general:
      case UserGoalTypes.sexual:
        return AnalyticsGeneralSection(data: d, goal: goal, history: history);
    }
  }
}

// ──────────────────────────────── History ───────────────────────────────

/// The raw record: per-cycle numbers, the cycle log, symptom patterns, and
/// the doctor-ready export that used to be duplicated on two screens.
class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.data,
    required this.report,
    required this.graphs,
    required this.goal,
    required this.onRefresh,
  });

  final CycleDashboardData? data;
  final CycleReportData? report;
  final GraphAvailability? graphs;
  final UserGoalTypes goal;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final d = data;
    final r = report;
    final g = graphs;
    final hasCycles = r != null && r.cycles.isNotEmpty;
    final hasPatterns = r != null && r.symptomPatterns.isNotEmpty;
    final showCycleGrid = d != null && !goal.isPregnancyMode;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          ReportsDoctorExportCard(
            title: l10n.doctorReportButton,
            subtitle: l10n.doctorReportDisclaimer,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DoctorReportScreen()),
            ),
          ),
          const SizedBox(height: 16),
          // Cycle-day / regularity numbers. The averages deliberately stay on
          // Overview instead of being repeated here.
          if (showCycleGrid) ...[
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
          if (d != null && !goal.isPregnancyMode && !goal.isCycleGoalMode) ...[
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
          if (hasCycles && !goal.isPregnancyMode) ...[
            CycleHistoryTable(cycles: r.cycles),
            const SizedBox(height: 14),
          ],
          if (!goal.isPregnancyMode) ...[
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
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
          ],
          if (FeatureFlags.isEnabledSync(FeatureFlags.symptomInsightsEngine)) ...[
            const SizedBox(height: 4),
            const _SymptomPatternsCard(),
            const SizedBox(height: 8),
          ],
          if (hasPatterns) ...[
            AppSectionHeader(title: l10n.reportSymptomPatterns),
            ...r.symptomPatterns.take(10).map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppGlassCard(
                      blur: false,
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
                          l10n.reportPercentOfCycles(p.percentageOfCycles ?? 0),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

/// Entry point into the deeper per-symptom timing analysis.
class _SymptomPatternsCard extends StatelessWidget {
  const _SymptomPatternsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      blur: false,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SymptomInsightsPage()),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.timeline_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.reportSymptomPatterns,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.insightsHubSymptomPatternsCta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: theme.colorScheme.outline,
          ),
        ],
      ),
    );
  }
}

class _HubMessage extends StatelessWidget {
  const _HubMessage({
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
          mainAxisSize: MainAxisSize.min,
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
