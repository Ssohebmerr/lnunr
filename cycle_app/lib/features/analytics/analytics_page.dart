import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../core/app_home_refresh.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../core/widgets/app_surface.dart';
import '../../l10n/app_localizations.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/data/cycle_sync_service.dart';
import '../home/doctor_report_screen.dart';
import 'analytics_data.dart';
import 'analytics_sections.dart';

/// Full Analytics page — adapts to the user's primary goal.
///
/// Each goal surfaces a tailored set of metrics, headline score cards,
/// optional phase ring, and bar charts. Falls back to a friendly empty
/// state when no dashboard data is available yet.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();

  CycleDashboardData? _data;
  AnalyticsHistory _history = AnalyticsHistory.empty;
  UserGoalTypes _goal = UserGoalTypes.general;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    HomeRefreshScope.notifier.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => _load();

  Future<void> _load() async {
    if (MenstrualCycleWidget.instance == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final goal = await _sync.getUserGoal();
      final data = await _bridge.tryLoadDashboard();
      final history = await _bridge.tryLoadAnalyticsHistory();
      if (mounted) {
        setState(() {
          _goal = goal;
          _data = data;
          _history = history;
          _loading = false;
          _failed = data == null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final ar = lang.startsWith('ar');
    final accent = AnalyticsData.accentFor(_goal);
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 4;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(ar ? 'التحليلات' : 'Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  ar ? 'مؤشرات شاملة' : 'Full metrics',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AppMeshBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, topInset, 16, 100),
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed || _data == null)
                _EmptyState(
                  message: ar
                      ? 'ابدئي بتسجيل دورتكِ لتري المؤشرات.'
                      : 'Log your cycle to unlock analytics.',
                  onRetry: _load,
                )
              else
                _buildSection(_data!),
              const SizedBox(height: 20),
              _DoctorExportBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(CycleDashboardData data) {
    switch (_goal) {
      case UserGoalTypes.pregnant:
        return AnalyticsPregnancySection(
            data: data, goal: _goal, history: _history);
      case UserGoalTypes.menopause:
        return AnalyticsMenopauseSection(
            data: data, goal: _goal, history: _history);
      case UserGoalTypes.pcos:
        return AnalyticsPcosSection(
            data: data, goal: _goal, history: _history);
      case UserGoalTypes.postpartum:
        return AnalyticsPostpartumSection(
            data: data, goal: _goal, history: _history);
      case UserGoalTypes.conceive:
        return AnalyticsConceiveSection(
            data: data, goal: _goal, history: _history);
      case UserGoalTypes.avoid:
        return AnalyticsAvoidSection(
            data: data, goal: _goal, history: _history);
      case UserGoalTypes.general:
      case UserGoalTypes.sexual:
        return AnalyticsGeneralSection(
            data: data, goal: _goal, history: _history);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _DoctorExportBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppGlassCard(
      blur: false,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DoctorReportScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: LinearGradient(
            colors: [
              AuraColors.roseDeep.withValues(alpha: 0.18),
              AuraColors.roseDeep.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: AuraColors.roseDeep,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.doctorReportButton,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.doctorReportDisclaimer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
