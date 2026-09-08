import 'package:flutter/material.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel_integration/menstrudel_bootstrap.dart';
import '../../../menstrudel_integration/wellness_hub_launcher.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../cycle/data/cycle_sync_service.dart';
import '../../goals/data/goal_mode_content.dart';
import '../../pregnancy/data/pregnancy_self_care_content.dart';
import '../../gamification/data/gamification_service.dart';
import '../../gamification/presentation/challenges_page.dart';
import '../data/movement_content.dart';
import '../data/mood_service.dart';
import '../data/ritual_service.dart';
import '../data/self_care_content.dart';
import 'affirmations_screen.dart';
import 'breathing_screen.dart';
import 'journal_screen.dart';
import 'movement_screen.dart';
import 'self_care_library_screen.dart';
import 'widgets/mood_check_in_card.dart';
import 'widgets/self_care_briefing_card.dart';

class SelfCareTab extends StatefulWidget {
  const SelfCareTab({super.key});

  @override
  State<SelfCareTab> createState() => _SelfCareTabState();
}

class _SelfCareTabState extends State<SelfCareTab> {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();
  final _gamification = GamificationService();
  int _challengeStreak = 0;
  int _ritualStreak = 0;
  String _phase = '';
  UserGoalTypes _goal = UserGoalTypes.general;
  int _pregnancyWeek = 20;
  int _gestationalDay = 0;
  CycleDashboardData? _dashboard;
  String? _moodKey;
  List<({String date, String mood})> _moodHistory = const [];
  List<bool> _ritualStates = List<bool>.filled(8, false);

  @override
  void initState() {
    super.initState();
    _load();
    HomeRefreshScope.notifier.addListener(_onExternalRefresh);
    // Ensure the Menstrudel care-center services (default user, localization)
    // are ready so the Wellness Hub tools open instantly from this tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) MenstrudelBootstrap.prepare(context);
    });
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_onExternalRefresh);
    super.dispose();
  }

  void _onExternalRefresh() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      final gami = await _gamification.getState();
      final data = await _bridge.tryLoadDashboard();
      final goal = await _sync.getUserGoal();
      final mood = await MoodService.todayMood();
      final moodHistory = await MoodService.recent(days: 7);
      final ritualStates = await RitualService.loadToday(8);
      final ritualStreak = await RitualService.streak();
      if (mounted) {
        setState(() {
          _challengeStreak = gami.streak;
          _dashboard = data;
          _phase = data?.phase ?? '';
          _goal = goal;
          _pregnancyWeek = data?.pregnancyWeek ?? 20;
          _gestationalDay = data?.cycleDay ?? 0;
          _moodKey = mood;
          _moodHistory = moodHistory;
          _ritualStates = ritualStates;
          _ritualStreak = ritualStreak;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleRitual(int index, bool value) async {
    await RitualService.setToday(index, value);
    final streak = await RitualService.streak();
    if (mounted) {
      setState(() {
        _ritualStates[index] = value;
        _ritualStreak = streak;
      });
    }
  }

  Future<void> _selectMood(String key) async {
    await MoodService.setTodayMood(key);
    final history = await MoodService.recent(days: 7);
    if (mounted) {
      setState(() {
        _moodKey = key;
        _moodHistory = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isPregnant = _goal.isPregnancyMode;
    final displayGoal = _goal == UserGoalTypes.sexual
        ? UserGoalTypes.general
        : _goal;

    final String tipText;
    if (isPregnant) {
      tipText = PregnancySelfCareContent.tipForWeek(
        _pregnancyWeek,
        lang,
      ).forLocale(lang);
    } else if (_dashboard != null) {
      tipText = GoalModeContent.dailyTip(
        displayGoal,
        _dashboard!,
        lang,
      ).forLang(lang);
    } else {
      tipText = SelfCareContent.tipForPhase(_phase, lang).forLocale(lang);
    }

    final rituals = isPregnant
        ? PregnancySelfCareContent.ritualsForWeek(_pregnancyWeek)
        : GoalModeContent.rituals(
            displayGoal,
          ).map((t) => SelfCareTip(en: t.en, ar: t.ar)).toList();

    final ritualsDone = List.generate(
      rituals.length,
      (i) => _ritualStates[i],
    ).where((v) => v).length;

    String sectionTitle() {
      if (isPregnant) return l10n.pregnancySelfCareTitle;
      return switch (displayGoal) {
        UserGoalTypes.conceive => l10n.goalModeConceiveSelfCare,
        UserGoalTypes.avoid => l10n.goalModeAvoidSelfCare,
        _ => l10n.goalModeGeneralSelfCare,
      };
    }

    final String? phaseLabel = isPregnant
        ? l10n.pregnancyWeekDay(_pregnancyWeek.clamp(4, 42), _gestationalDay)
        : (_phase.isNotEmpty ? _phase : null);

    final isFirstTime = _dashboard == null && _challengeStreak == 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        primary: false,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          if (isFirstTime) ...[
            const SizedBox(height: 16),
            AppGlassCard(
              blur: false,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: 36,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.selfCareWelcomeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selfCareWelcomeSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          AppSectionHeader(title: sectionTitle()),

          // ── AI whisper of the day (personal, mood + phase aware) ──────────
          SelfCareBriefingCard(
            fallbackTip: tipText,
            phase: _phase,
            cycleDay: _dashboard?.cycleDay,
            moodKey: _moodKey,
            phaseLabel: phaseLabel,
          ),
          const SizedBox(height: 12),

          // ── Daily mood check-in ───────────────────────────────────────────
          MoodCheckInCard(
            selected: _moodKey,
            onSelect: _selectMood,
            history: _moodHistory,
          ),
          const SizedBox(height: 20),

          // ── Quick self-care activities ────────────────────────────────────
          AppSectionHeader(title: l10n.selfCareActivities),
          Row(
            children: [
              Expanded(
                child: AppQuickTile(
                  icon: Icons.air,
                  label: l10n.selfCareBreathe,
                  color: theme.colorScheme.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BreathingScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppQuickTile(
                  icon: Icons.favorite_border,
                  label: l10n.selfCareAffirmations,
                  color: theme.colorScheme.secondary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AffirmationsScreen(phase: _phase),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppQuickTile(
                  icon: Icons.menu_book_outlined,
                  label: l10n.selfCareJournal,
                  color: AppColors.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JournalScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppQuickTile(
                  icon: Icons.self_improvement_outlined,
                  label: l10n.selfCareMovement,
                  color: const Color(0xFF26A69A),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MovementScreen(
                        routine: MovementContent.forPhase(_phase),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Daily rituals (reset every day) with progress + streak ────────
          AppSectionHeader(
            title: l10n.selfCareRituals,
            trailing: _ritualStreak > 0
                ? _StreakPill(days: _ritualStreak)
                : null,
          ),
          if (rituals.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RitualProgress(done: ritualsDone, total: rituals.length),
            ),
          ...rituals.asMap().entries.map(
            (e) => _RitualTile(
              title: e.value.forLocale(lang),
              value: e.key < _ritualStates.length && _ritualStates[e.key],
              onChanged: (v) => _toggleRitual(e.key, v),
            ),
          ),
          const SizedBox(height: 20),

          // ── Phase-based self-care library ─────────────────────────────────
          AppSectionHeader(title: l10n.selfCareLibraryTitle),
          AppHubCard(
            blur: false,
            icon: Icons.auto_stories_rounded,
            title: l10n.selfCareLibraryTitle,
            subtitle: l10n.selfCareLibrarySubtitle,
            color: AuraColors.lavenderSoft,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelfCareLibraryScreen(currentPhase: _phase),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Wellness Hub: the powerful health-tracking centre ─────────────
          AppSectionHeader(title: l10n.wellnessHubTitle),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.wellnessHubSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _WellnessGroup(
            rows: [
              // The daily log is the app's own log screen (the + button),
              // not the Menstrudel one this hub used to open — there is a
              // single daily log now, writing to a single store.
              _WellnessRowData(
                icon: Icons.edit_calendar_outlined,
                title: l10n.wellnessDailyLog,
                subtitle: l10n.wellnessDailyLogDesc,
                color: theme.colorScheme.primary,
                onTap: () => HomeShellActions.openLog?.call(),
              ),
              _WellnessRowData(
                icon: Icons.medication_outlined,
                title: l10n.wellnessPills,
                subtitle: l10n.wellnessPillsDesc,
                color: theme.colorScheme.secondary,
                onTap: () => WellnessHubLauncher.openPills(context),
              ),
              _WellnessRowData(
                icon: Icons.sanitizer_outlined,
                title: l10n.wellnessSanitary,
                subtitle: l10n.wellnessSanitaryDesc,
                color: AppColors.accent,
                onTap: () => WellnessHubLauncher.openSanitary(context),
              ),
              _WellnessRowData(
                icon: Icons.favorite_outline,
                title: l10n.wellnessSex,
                subtitle: l10n.wellnessSexDesc,
                color: const Color(0xFFE57373),
                onTap: () => WellnessHubLauncher.openSex(context),
              ),
              _WellnessRowData(
                icon: Icons.shield_outlined,
                title: l10n.wellnessLarc,
                subtitle: l10n.wellnessLarcDesc,
                color: const Color(0xFF26A69A),
                onTap: () => WellnessHubLauncher.openLarc(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Challenges ────────────────────────────────────────────────────
          AppSectionHeader(title: l10n.challengesTitle),
          AppGlassCard(
            blur: false,
            onTap: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChallengesPage()));
              _load();
            },
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AuraColors.ember.withValues(alpha: 0.3),
                        AuraColors.ember.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: AuraColors.ember,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.challengesTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.challengesToday,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_challengeStreak > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      l10n.challengeStreakValue(_challengeStreak),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AuraColors.ember,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small streak pill shown next to the rituals header.
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AuraColors.ember.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 14,
            color: AuraColors.ember,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.selfCareRitualStreak(days),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AuraColors.ember,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RitualProgress extends StatelessWidget {
  const _RitualProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : done / total;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          l10n.selfCareRitualsProgress(done, total),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Plain data holder for one Wellness Hub entry.
class _WellnessRowData {
  const _WellnessRowData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

/// The Wellness Hub tools grouped into a single premium card with dividers —
/// calmer and less repetitive than five stacked hub cards.
class _WellnessGroup extends StatelessWidget {
  const _WellnessGroup({required this.rows});

  final List<_WellnessRowData> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      blur: false,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _WellnessRow(
              data: rows[i],
              first: i == 0,
              last: i == rows.length - 1,
            ),
            if (i != rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 68,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

class _WellnessRow extends StatelessWidget {
  const _WellnessRow({
    required this.data,
    required this.first,
    required this.last,
  });

  final _WellnessRowData data;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = Radius.circular(AppRadius.lg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.vertical(
          top: first ? radius : Radius.zero,
          bottom: last ? radius : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.color.withValues(alpha: 0.28),
                      data.color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RitualTile extends StatelessWidget {
  const _RitualTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      blur: false,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: value ? TextDecoration.lineThrough : null,
                color: value
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
