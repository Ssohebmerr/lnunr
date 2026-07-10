import 'dart:math' as math;

import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/cms/app_settings.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/feminine_icons_custom.dart';
import '../../../l10n/app_localizations.dart';
import '../insight/presentation/insight_card.dart';
import '../streak/presentation/streak_badge.dart';
import '../cycle/data/cycle_bridge_service.dart';
import '../cycle/data/cycle_sync_service.dart';
import '../cycle/presentation/widgets/predicted_symptoms_card.dart';
import '../goals/presentation/goal_cycle_mode_section.dart';
import '../pregnancy/presentation/home_pregnancy_section.dart';
import 'cycle_calendar_page.dart';
import 'home_menopause_section.dart';
import 'home_pcos_section.dart';
import 'home_postpartum_section.dart';
import 'sub_feature_page.dart';
import 'widgets/daily_briefing_card.dart';
import 'widgets/home_community_card.dart';
import 'widgets/home_explore_rail.dart';
import 'widgets/home_today_log_card.dart';
import 'widgets/home_updates_panel.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();
  final _scrollController = ScrollController();
  CycleDashboardData? _data;
  List<PredictedSymptom> _symptomsToday = [];
  List<PredictedSymptom> _symptomsTomorrow = [];
  bool _loading = true;
  bool _failed = false;
  UserGoalTypes _goal = UserGoalTypes.general;
  AppSettings _settings = const AppSettings();
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onExternalRefresh() => _load();

  Future<void> _load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    final showLoadingSpinner = _data == null;
    if (mounted && showLoadingSpinner) setState(() => _loading = true);
    try {
      final goal = await _sync.getUserGoal();
      final settings = await AppSettingsRepository().fetch();
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
          _settings = settings;
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
    final sections = _sectionBuilders(context, l10n, d, theme);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scrollController,
        primary: false,
        cacheExtent: 400,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.paddingOf(context).bottom + 120,
        ),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < sections.length - 1 ? 12 : 0,
            ),
            child: sections[index](),
          );
        },
      ),
    );
  }

  List<Widget Function()> _sectionBuilders(
    BuildContext context,
    AppLocalizations l10n,
    CycleDashboardData? d,
    ThemeData theme,
  ) {
    final builders = <Widget Function()>[
      () => _HeroHeader(
        l10n: l10n,
        loading: _loading,
        failed: _failed,
        data: d,
        isPregnancyMode: _goal.isPregnancyMode,
        goal: _goal,
        onRetry: _load,
      ),
    ];

    // ── Personal daily data first (what happened today / what to expect) ──
    builders.add(() => const HomeTodayLogCard());

    if (_symptomsToday.isNotEmpty || _symptomsTomorrow.isNotEmpty) {
      builders.add(
        () => PredictedSymptomsCard(
          today: _symptomsToday,
          tomorrow: _symptomsTomorrow,
        ),
      );
    }

    // ── Daily insights & engagement ──
    if (FeatureFlags.isEnabledSync(FeatureFlags.todaysInsight)) {
      builders.add(() => const InsightCard());
    }
    if (FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak)) {
      builders.add(() => const StreakBadge());
    }

    if (FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled)) {
      builders.add(() => const DailyBriefingCard());
    }

    // ── Goal / cycle section ──
    if (d != null) {
      builders.add(() => _goalSection(context, d));
    }

    // Social, reading, and announcements are valuable, but they should not
    // compete with today's health information on first load. Keep them one
    // deliberate tap away instead of stacking three more large cards.
    builders.add(
      () => _HomeMoreSection(
        settings: _settings,
        showCommunity: _settings.communityEnabled,
      ),
    );

    // ── State indicators (loading / error / empty) ──
    if (_loading && d == null) {
      builders.add(
        () => const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_failed && d == null) {
      builders.add(
        () => Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(l10n.homeStatsError, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
    }

    if (d == null && !_loading && !_failed) {
      builders.add(
        () => _EmptyStateHeader(goal: _goal, l10n: l10n, theme: theme),
      );
    }

    return builders;
  }

  Widget _goalSection(BuildContext context, CycleDashboardData d) {
    if (_goal.isPregnancyMode) {
      return HomePregnancySection(
        data: d,
        onOpenCalendar: () => _openFullCalendar(context),
      );
    }
    if (_goal.isMenopauseMode) {
      return HomeMenopauseSection(
        data: d,
        onOpenCalendar: () => _openFullCalendar(context),
      );
    }
    if (_goal.isPcosMode) {
      return HomePcosSection(
        data: d,
        onOpenCalendar: () => _openFullCalendar(context),
      );
    }
    if (_goal.isPostpartumMode) {
      return HomePostpartumSection(
        data: d,
        onOpenCalendar: () => _openFullCalendar(context),
      );
    }
    return GoalModeHomeSection(
      data: d,
      goal: _goal == UserGoalTypes.sexual ? UserGoalTypes.general : _goal,
      showRing: true,
      showWeekCalendar: false,
      onOpenCalendar: () => _openFullCalendar(context),
    );
  }
}

/// A quiet, collapsed home section for optional discovery. It prevents the
/// main dashboard from becoming an endless feed while preserving every card.
class _HomeMoreSection extends StatefulWidget {
  const _HomeMoreSection({required this.settings, required this.showCommunity});

  final AppSettings settings;
  final bool showCommunity;

  @override
  State<_HomeMoreSection> createState() => _HomeMoreSectionState();
}

class _HomeMoreSectionState extends State<_HomeMoreSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.homeMoreThisWeek,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  if (widget.showCommunity) ...[
                    const HomeCommunityCard(),
                    const SizedBox(height: 12),
                  ],
                  HomeExploreRail(settings: widget.settings),
                  const SizedBox(height: 12),
                  HomeUpdatesPanel(settings: widget.settings),
                ],
              ),
            ),
          ),
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
    final isDark = theme.brightness == Brightness.dark;
    final cycleData = data;

    return Container(
      decoration: AuraDecorations.heroSurface(isDark),
      padding: const EdgeInsets.all(20),
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
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
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _heroSubtitle(
                        goal,
                        l10n,
                        cycleData,
                        Localizations.localeOf(context).languageCode,
                      ),
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
            const SizedBox(width: 18),
            _CycleProgressRing(
              cycleDay: isPregnancyMode
                  ? cycleData.pregnancyWeek.clamp(1, 42)
                  : cycleData.cycleDay,
              total: isPregnancyMode
                  ? 42
                  : (cycleData.avgCycleLength <= 0
                        ? 28
                        : cycleData.avgCycleLength),
              label: isPregnancyMode
                  ? l10n.pregnancyWeekShort
                  : l10n.homeDayShort,
              isPregnancy: isPregnancyMode,
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
    String lang,
  ) {
    if (goal.isConceiveMode && data.isOvulationDay) {
      return l10n.goalModeOvulationToday;
    }
    if (goal == UserGoalTypes.menopause) {
      return lang.startsWith('ar')
          ? 'الهبّات، النوم، والمزاج — دلّليني اليوم.'
          : 'Hot flashes, sleep, mood — be gentle with yourself today.';
    }
    if (goal == UserGoalTypes.pcos) {
      return lang.startsWith('ar')
          ? 'الانتظام، البشرة، والمزاج — أنماط تساعد.'
          : 'Regularity, skin, mood — patterns help.';
    }
    if (goal == UserGoalTypes.postpartum) {
      return lang.startsWith('ar')
          ? 'الشفاء، الرضاعة، والمزاج — كل يوم أفضل.'
          : 'Healing, feeding, mood — every day is progress.';
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
    final lang = Localizations.localeOf(context).languageCode;
    final (title, subtitle, gradient) = _emptyCopy(goal, lang);
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 8),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
            ),
            child: FeminineIconView(
              goal.femIcon,
              size: 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              subtitle,
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
                  onTap: () => HomeShellActions.openLog?.call(),
                ),
                if (FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled)) ...[
                  const SizedBox(height: 8),
                  _EmptyAction(
                    icon: Icons.auto_awesome_rounded,
                    text: l10n.homeQuickAi,
                    theme: theme,
                    onTap: () => HomeShellActions.openAiChat?.call(),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  (String, String, LinearGradient) _emptyCopy(UserGoalTypes goal, String lang) {
    if (goal.isPregnancyMode) {
      return (
        lang.startsWith('ar') ? 'تهانينا! 🌸' : 'Congratulations! 🌸',
        lang.startsWith('ar')
            ? 'ابدئي رحلة الحمل مع متابعة أسبوعية وطبية'
            : 'Start your pregnancy journey with weekly medical tracking',
        const LinearGradient(colors: [Color(0xFFEC407A), Color(0xFFC2185B)]),
      );
    }
    if (goal == UserGoalTypes.menopause) {
      return (
        lang.startsWith('ar') ? 'مرحباً بكِ 🌿' : 'Welcome 🌿',
        lang.startsWith('ar')
            ? 'تتبّعي الهبّات الساخنة، النوم، والمزاج بسهولة.'
            : 'Track hot flashes, sleep, and mood with ease.',
        const LinearGradient(colors: [Color(0xFF8D6E63), Color(0xFF5D4037)]),
      );
    }
    if (goal == UserGoalTypes.pcos) {
      return (
        lang.startsWith('ar') ? 'لستِ وحدكِ 🌸' : 'You\'re not alone 🌸',
        lang.startsWith('ar')
            ? 'إدارة تكيس المبايض تبدأ بمعرفة أنماط جسمكِ.'
            : 'PCOS management starts with knowing your body\'s patterns.',
        const LinearGradient(colors: [Color(0xFF26A69A), Color(0xFF00897B)]),
      );
    }
    if (goal == UserGoalTypes.postpartum) {
      return (
        lang.startsWith('ar') ? 'أهلاً بكِ 🤍' : 'Welcome 🤍',
        lang.startsWith('ar')
            ? 'الاستشفاء رحلة — شجّعي نفسكِ كل يوم.'
            : 'Recovery is a journey — be kind to yourself daily.',
        const LinearGradient(colors: [Color(0xFFEC407A), Color(0xFFC2185B)]),
      );
    }
    return (
      lang.startsWith('ar') ? 'أهلاً بكِ في Lune' : 'Welcome to Lune',
      lang.startsWith('ar')
          ? 'سجّلي أول دورة شهرية لبدء التوقعات والتوصيات'
          : 'Log your first period to start predictions and tips.',
      AuraDecorations.primaryGradient,
    );
  }
}

/// Premium animated progress ring around the cycle day number — gives the
/// Home hero a clear "you are here" visual without taking too much vertical
/// space. Animates on first build (and on day changes) for a polished feel.
class _CycleProgressRing extends StatefulWidget {
  const _CycleProgressRing({
    required this.cycleDay,
    required this.total,
    required this.label,
    this.isPregnancy = false,
  });

  final int cycleDay;
  final int total;
  final String label;
  final bool isPregnancy;

  static const double size = 108;

  @override
  State<_CycleProgressRing> createState() => _CycleProgressRingState();
}

class _CycleProgressRingState extends State<_CycleProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _previousTarget = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0,
      end: _target,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _previousTarget = _target;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _CycleProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = _target;
    if ((newTarget - _previousTarget).abs() > 0.001) {
      _anim = Tween<double>(
        begin: _previousTarget,
        end: newTarget,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _previousTarget = newTarget;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  double get _target {
    if (widget.total <= 0) return 0;
    return (widget.cycleDay / widget.total).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _CycleProgressRing.size,
      height: _CycleProgressRing.size,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, _) {
            return CustomPaint(
              painter: _RingPainter(
                progress: _anim.value,
                track: theme.colorScheme.primary.withValues(alpha: 0.12),
                gradient: AuraDecorations.primaryGradient,
              ),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AuraDecorations.primaryGradient,
                    boxShadow: AppShadows.softRose(opacity: 0.3),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.cycleDay}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.track,
    required this.gradient,
  });

  final double progress;
  final Color track;
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 6.5;
    final rect = Offset.zero & size;
    final inset = rect.deflate(stroke / 2 + 1);
    final center = inset.center;
    final radius = inset.shortestSide / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.track != track;
}

class _EmptyAction extends StatelessWidget {
  const _EmptyAction({
    required this.icon,
    required this.text,
    required this.theme,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      blur: false,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
