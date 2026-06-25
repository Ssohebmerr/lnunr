import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/gamification_service.dart' as gami;

/// Daily challenges, streak, points, and achievement badges.
class ChallengesPage extends StatefulWidget {
  const ChallengesPage({super.key});

  @override
  State<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends State<ChallengesPage> {
  final _service = gami.GamificationService();
  gami.GamificationState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await _service.getState();
    if (mounted) setState(() => _state = state);
  }

  Future<void> _complete(gami.Challenge challenge) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final newBadges = await _service.completeChallenge(challenge.id);
    await _load();

    messenger.showSnackBar(
      SnackBar(content: Text('+${challenge.points} • ${l10n.challengeDone}')),
    );
    for (final id in newBadges) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${l10n.badgeEarned}: ${_badgeName(l10n, id)}'),
          backgroundColor: AuraColors.roseDeep,
        ),
      );
    }
  }

  String _challengeName(AppLocalizations l10n, String id) => switch (id) {
        'hydrate' => l10n.challengeHydrate,
        'stretch' => l10n.challengeStretch,
        'walk' => l10n.challengeWalk,
        'mindful' => l10n.challengeMindful,
        'log_today' => l10n.challengeLogToday,
        'sleep_early' => l10n.challengeSleepEarly,
        _ => id,
      };

  String _badgeName(AppLocalizations l10n, String id) => switch (id) {
        'first_step' => l10n.badgeFirstStep,
        'streak_3' => l10n.badgeStreak3,
        'streak_7' => l10n.badgeStreak7,
        'streak_30' => l10n.badgeStreak30,
        'points_100' => l10n.badgePoints100,
        'points_500' => l10n.badgePoints500,
        'all_in_a_day' => l10n.badgeAllInADay,
        _ => id,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = _state;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.challengesTitle)),
      body: state == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppGlassCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.local_fire_department,
                          color: Colors.deepOrange,
                          value: '${state.streak}',
                          label: l10n.challengeStreakLabel,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _HeaderStat(
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                          value: '${state.points}',
                          label: l10n.challengePointsLabel,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppSectionHeader(title: l10n.challengesToday),
                if (state.completedToday.length >= gami.Challenge.all.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.challengesAllDone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ...gami.Challenge.all.map((c) {
                  final done = state.completedToday.contains(c.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppGlassCard(
                      onTap: done ? null : () => _complete(c),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            c.icon,
                            color: done
                                ? theme.colorScheme.outline
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _challengeName(l10n, c.id),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                decoration:
                                    done ? TextDecoration.lineThrough : null,
                                color: done ? theme.colorScheme.outline : null,
                              ),
                            ),
                          ),
                          Text(
                            '+${c.points}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: done
                                ? Colors.green
                                : theme.colorScheme.outline,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
                AppSectionHeader(title: l10n.badgesTitle),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: gami.Badge.all.map((b) {
                    final earned = state.earnedBadges.contains(b.id);
                    return AppGlassCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            b.icon,
                            size: 32,
                            color: earned
                                ? AuraColors.roseDeep
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _badgeName(l10n, b.id),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: earned
                                  ? null
                                  : theme.colorScheme.outline
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}
