import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/notifications/graph_export_helper.dart';
import '../../../core/ai/models/ai_insight.dart';
import '../../../core/ai/widgets/ai_insight_card.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/presentation/widgets/conditional_graph_card.dart';
import '../cycle/presentation/widgets/cycle_score_section.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  final _bridge = CycleBridgeService();
  CycleDashboardData? _dashboard;
  GraphAvailability? _graphs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final dashboard = await _bridge.loadDashboard();
      final graphs = await _bridge.loadGraphAvailability();
      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _graphs = graphs;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final d = _dashboard;
    final g = _graphs;
    void shareExport(dynamic file) => shareGraphExport(context, file);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (d != null) ...[
            CycleScoreSection(data: d),
            const SizedBox(height: 12),
            _AvgStatsRow(data: d),
            const SizedBox(height: 12),
          ],
          const AiInsightCard(
            type: AiInsightType.cycleHealth,
            margin: EdgeInsets.only(bottom: 12),
          ),
          if (g != null) ...[
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
              hasData: g.history,
              child: const MenstrualCycleHistoryGraph(),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppGlassCard(
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: 260,
                  child: const EstrogenProgesteroneGraph(),
                ),
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
            value: '${data.avgCycleLength}d',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AppStatCard(
            icon: Icons.water_drop_outlined,
            label: l10n.reportAvgPeriod,
            value: '${data.avgPeriodDuration}d',
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
