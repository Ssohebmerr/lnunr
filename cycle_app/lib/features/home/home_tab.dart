import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/data/cycle_sync_service.dart';
import '../cycle/presentation/widgets/predicted_symptoms_card.dart';
import '../goals/presentation/goal_cycle_mode_section.dart';
import '../pregnancy/presentation/home_pregnancy_section.dart';
import 'cycle_calendar_page.dart';
import 'sub_feature_page.dart';
import 'widgets/daily_briefing_card.dart';
import 'widgets/home_today_log_card.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();
  CycleDashboardData? _data;
  List<PredictedSymptom> _symptomsToday = [];
  List<PredictedSymptom> _symptomsTomorrow = [];
  bool _loading = true;
  bool _failed = false;
  UserGoalTypes _goal = UserGoalTypes.general;
  bool _loadInFlight = false;

  @override
  void initState() {
    super.initState();
    _load();
    HomeRefreshScope.notifier.addListener(_onExternalRefresh);
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_onExternalRefresh);
    super.dispose();
  }

  void _onExternalRefresh() => _load();

  Future<void> _load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    if (mounted) setState(() => _loading = true);
    try {
      final goal = await _sync.getUserGoal();
      await AppSettingsRepository().fetch();
      final data = await _bridge.tryLoadDashboard();
      List<PredictedSymptom> today = [];
      List<PredictedSymptom> tomorrow = [];
      if (!goal.isPregnancyMode) {
        today = await _bridge.loadPredictedSymptoms();
        tomorrow = await _bridge.loadPredictedSymptoms(tomorrow: true);
      }
      if (mounted) {
        setState(() {
          _goal = goal;
          _data = data;
          _symptomsToday = today;
          _symptomsTomorrow = tomorrow;
          _failed = data == null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    } finally {
      _loadInFlight = false;
    }
  }

  void _openSub(BuildContext context, String title, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubFeaturePage(title: title, child: child),
      ),
    );
  }

  void _openFullCalendar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _openSub(context, l10n.homeCycleView, const CycleCalendarPage());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final d = _data;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          _HeroHeader(
            l10n: l10n,
            loading: _loading,
            failed: _failed,
            data: d,
            isPregnancyMode: _goal.isPregnancyMode,
            goal: _goal,
            onRetry: _load,
          ),
          const SizedBox(height: 12),
          const DailyBriefingCard(),
          const SizedBox(height: 12),
          const HomeTodayLogCard(),
          if (_symptomsToday.isNotEmpty || _symptomsTomorrow.isNotEmpty) ...[
            const SizedBox(height: 12),
            PredictedSymptomsCard(
              today: _symptomsToday,
              tomorrow: _symptomsTomorrow,
            ),
          ],
          if (d != null) ...[
            const SizedBox(height: 12),
            if (_goal.isPregnancyMode)
              HomePregnancySection(
                data: d,
                onOpenCalendar: () => _openFullCalendar(context),
              )
            else
              GoalModeHomeSection(
                data: d,
                goal: _goal == UserGoalTypes.sexual
                    ? UserGoalTypes.general
                    : _goal,
                showRing: true,
                showWeekCalendar: false,
                onOpenCalendar: () => _openFullCalendar(context),
              ),
          ],
          if (_loading && d == null)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_failed && d == null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 8),
                    Text(l10n.homeStatsError, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          if (d == null && !_loading && !_failed)
            _EmptyStateHeader(goal: _goal, l10n: l10n, theme: theme),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.l10n,
    required this.loading,
    required this.failed,
    required this.data,
    required this.isPregnancyMode,
    required this.goal,
    required this.onRetry,
  });

  final AppLocalizations l10n;
  final bool loading;
  final bool failed;
  final CycleDashboardData? data;
  final bool isPregnancyMode;
  final UserGoalTypes goal;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cycleData = data;

    return AppGlassCard(
      blur: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (failed)
                  Text(l10n.homeStatsError, style: theme.textTheme.bodySmall)
                else if (cycleData != null) ...[
                  if (isPregnancyMode) ...[
                    Text(
                      l10n.pregnancyWeekDay(
                        cycleData.pregnancyWeek.clamp(1, 42),
                        cycleData.cycleDay,
                      ),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.pregnancyTrimester(cycleData.trimester),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ] else ...[
                    Text(
                      cycleData.phase,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _heroSubtitle(goal, l10n, cycleData),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ] else if (loading)
                  Text(l10n.homeLoadingStats, style: theme.textTheme.bodySmall),
                if (failed) ...[
                  const SizedBox(height: 10),
                  AppGradientButton(
                    label: l10n.retry,
                    icon: Icons.refresh,
                    expanded: false,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
          if (cycleData != null) ...[
            const SizedBox(width: 12),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AuraDecorations.primaryGradient,
                boxShadow: AppShadows.softRose(opacity: 0.25),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isPregnancyMode
                          ? '${cycleData.pregnancyWeek.clamp(1, 42)}'
                          : '${cycleData.cycleDay}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    Text(
                      isPregnancyMode ? l10n.pregnancyWeekShort : l10n.homeDayShort,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _heroSubtitle(
    UserGoalTypes goal,
    AppLocalizations l10n,
    CycleDashboardData data,
  ) {
    if (goal.isConceiveMode && data.isOvulationDay) {
      return l10n.goalModeOvulationToday;
    }
    if (data.nextPeriod.isNotEmpty && data.nextPeriod != '—') {
      return '${l10n.nextPeriod}: ${data.nextPeriod}';
    }
    return l10n.homeCycleDay(data.cycleDay);
  }
}

class _EmptyStateHeader extends StatelessWidget {
  const _EmptyStateHeader({
    required this.goal,
    required this.l10n,
    required this.theme,
  });
  final UserGoalTypes goal;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isPregnant = goal.isPregnancyMode;
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AuraDecorations.primaryGradient,
            ),
            child: Icon(
              isPregnant ? Icons.pregnant_woman_rounded : Icons.spa_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isPregnant ? 'تهانينا! 🌸' : 'أهلاً بكِ في Lune',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isPregnant
                  ? 'ابدئي رحلة الحمل مع متابعة أسبوعية وطبية'
                  : 'سجّلي أول دورة شهرية لبدء التوقعات والتوصيات',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!isPregnant)
            Column(
              children: [
                _EmptyAction(
                  icon: Icons.edit_calendar_rounded,
                  text: l10n.homeQuickLog,
                  theme: theme,
                ),
                const SizedBox(height: 8),
                _EmptyAction(
                  icon: Icons.auto_awesome_rounded,
                  text: l10n.homeQuickAi,
                  theme: theme,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({required this.icon, required this.text, required this.theme});
  final IconData icon;
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
