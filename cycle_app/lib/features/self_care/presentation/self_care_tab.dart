import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel_integration/wellness_hub_page.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../cycle/data/cycle_sync_service.dart';
import '../../goals/data/goal_mode_content.dart';
import '../../pregnancy/data/pregnancy_self_care_content.dart';
import '../../gamification/data/gamification_service.dart';
import '../../gamification/presentation/challenges_page.dart';
import '../data/self_care_content.dart';
import 'affirmations_screen.dart';
import 'breathing_screen.dart';
import 'journal_screen.dart';

class SelfCareTab extends StatefulWidget {
  const SelfCareTab({super.key});

  @override
  State<SelfCareTab> createState() => _SelfCareTabState();
}

class _SelfCareTabState extends State<SelfCareTab> {
  final _bridge = CycleBridgeService();
  final _sync = CycleSyncService();
  final _gamification = GamificationService();
  int _streak = 0;
  String _phase = '';
  UserGoalTypes _goal = UserGoalTypes.general;
  int _pregnancyWeek = 20;
  int _gestationalDay = 0;
  CycleDashboardData? _dashboard;
  final _rituals = <String, bool>{
    'water': false,
    'rest': false,
    'stretch': false,
    'mindful': false,
  };

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
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _streak = gami.streak;
          _dashboard = data;
          _phase = data?.phase ?? '';
          _goal = goal;
          _pregnancyWeek = data?.pregnancyWeek ?? 20;
          _gestationalDay = data?.cycleDay ?? 0;
          _rituals['water'] = prefs.getBool('ritual_water') ?? false;
          _rituals['rest'] = prefs.getBool('ritual_rest') ?? false;
          _rituals['stretch'] = prefs.getBool('ritual_stretch') ?? false;
          _rituals['mindful'] = prefs.getBool('ritual_mindful') ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleRitual(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ritual_$key', value);
    setState(() => _rituals[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final isPregnant = _goal.isPregnancyMode;
    final displayGoal =
        _goal == UserGoalTypes.sexual ? UserGoalTypes.general : _goal;
    final String tipText;
    if (isPregnant) {
      tipText =
          PregnancySelfCareContent.tipForWeek(_pregnancyWeek, lang).forLocale(lang);
    } else if (_dashboard != null) {
      tipText = GoalModeContent.dailyTip(displayGoal, _dashboard!, lang)
          .forLang(lang);
    } else {
      tipText = SelfCareContent.tipForPhase(_phase, lang).forLocale(lang);
    }
    final rituals = isPregnant
        ? PregnancySelfCareContent.ritualsForWeek(_pregnancyWeek)
        : GoalModeContent.rituals(displayGoal)
            .map((t) => SelfCareTip(en: t.en, ar: t.ar))
            .toList();

    String sectionTitle() {
      if (isPregnant) return l10n.pregnancySelfCareTitle;
      return switch (displayGoal) {
        UserGoalTypes.conceive => l10n.goalModeConceiveSelfCare,
        UserGoalTypes.avoid => l10n.goalModeAvoidSelfCare,
        _ => l10n.goalModeGeneralSelfCare,
      };
    }

    final isFirstTime = _dashboard == null && _streak == 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                    child: Icon(Icons.spa_rounded, size: 36, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.selfCareWelcomeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
            const SizedBox(height: 16),
          ],
          AppSectionHeader(title: sectionTitle()),
          const SizedBox(height: 12),
          AppGlassCard(
            blur: false,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.selfCareTodayTip, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                if (isPregnant)
                  Text(
                    l10n.pregnancyWeekDay(
                      _pregnancyWeek.clamp(4, 42),
                      _gestationalDay,
                    ),
                    style: theme.textTheme.labelLarge,
                  )
                else if (_phase.isNotEmpty)
                  Text(_phase, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(tipText),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                      MaterialPageRoute(builder: (_) => const AffirmationsScreen()),
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
                    label: l10n.selfCareStretch,
                    color: const Color(0xFF26A69A),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.selfCareStretchTip)),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppGlassCard(
              blur: false,
              padding: EdgeInsets.zero,
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Icon(
                    Icons.spa_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    l10n.selfCareMoreTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    l10n.selfCareMoreSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    AppGlassCard(
                      blur: false,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ChallengesPage()),
                        );
                        _load();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.deepOrange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n.challengesTitle,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (_streak > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Text(
                                l10n.challengeStreakValue(_streak),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.selfCareRituals, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...rituals.asMap().entries.map(
                          (e) => _RitualTile(
                            title: e.value.forLocale(lang),
                            value: _rituals['goal_${e.key}'] ?? false,
                            onChanged: (v) => _toggleRitual('goal_${e.key}', v),
                          ),
                        ),
                    const SizedBox(height: 12),
                    AppHubCard(
                      blur: false,
                      icon: Icons.health_and_safety_outlined,
                      title: l10n.wellnessHubTitle,
                      subtitle: l10n.selfCareHealthToolsDesc,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WellnessHubPage()),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium,
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
