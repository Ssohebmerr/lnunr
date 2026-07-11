import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    HapticFeedback.lightImpact();

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
    final state = _state;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight + 4;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.challengesTitle),
      ),
      body: AppMeshBackground(
        child: state == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(16, topInset, 16, 40),
                children: [
                  _HeroHeader(state: state),
                  const SizedBox(height: 24),
                  AppSectionHeader(title: l10n.challengesToday),
                  const SizedBox(height: 4),
                  ...gami.Challenge.all.map((c) {
                    final done = state.completedToday.contains(c.id);
                    return _ChallengeTile(
                      icon: c.icon,
                      title: _challengeName(l10n, c.id),
                      points: c.points,
                      done: done,
                      onTap: done ? null : () => _complete(c),
                    );
                  }),
                  const SizedBox(height: 24),
                  AppSectionHeader(title: l10n.badgesTitle),
                  const SizedBox(height: 4),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: gami.Badge.all.map((b) {
                      return _BadgeChip(
                        icon: b.icon,
                        label: _badgeName(l10n, b.id),
                        earned: state.earnedBadges.contains(b.id),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Hero card: streak + points + today's completion progress ring.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.state});

  final gami.GamificationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = gami.Challenge.all.length;
    final done = state.completedToday.length;
    final allDone = done >= total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AuraDecorations.heroSurface(isDark),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(done: done, total: total),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroStat(
                      icon: Icons.local_fire_department_rounded,
                      color: AuraColors.ember,
                      value: '${state.streak}',
                      label: l10n.challengeStreakLabel,
                    ),
                    const SizedBox(height: 14),
                    _HeroStat(
                      icon: Icons.auto_awesome_rounded,
                      color: AuraColors.gold,
                      value: '${state.points}',
                      label: l10n.challengePointsLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (allDone) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AuraColors.success.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.celebration_rounded,
                      size: 18, color: AuraColors.success),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.challengesAllDone,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AuraColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular ring showing today's completed-challenge ratio.
class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = total == 0 ? 0.0 : done / total;
    final accent = theme.colorScheme.primary;

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 7,
              valueColor:
                  AlwaysStoppedAnimation(accent.withValues(alpha: 0.12)),
            ),
          ),
          SizedBox(
            width: 84,
            height: 84,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 7,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done/$total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One inline stat (fire streak / points) inside the hero.
class _HeroStat extends StatelessWidget {
  const _HeroStat({
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
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A single daily challenge row.
class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.icon,
    required this.title,
    required this.points,
    required this.done,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int points;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final leadColor = done ? AuraColors.success : accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppGlassCard(
        blur: false,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    leadColor.withValues(alpha: done ? 0.22 : 0.28),
                    leadColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: leadColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AuraColors.gold.withValues(alpha: done ? 0.1 : 0.16),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '+$points',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AuraColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              done
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: done
                  ? AuraColors.success
                  : theme.colorScheme.outline.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

/// An achievement badge tile — glows when earned, muted when locked.
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.earned,
  });

  final IconData icon;
  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.outline.withValues(alpha: 0.5);

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: earned
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AuraColors.rose, AuraColors.lavenderSoft],
                    )
                  : null,
              color: earned
                  ? null
                  : theme.colorScheme.outline.withValues(alpha: 0.08),
              boxShadow: earned
                  ? [
                      BoxShadow(
                        color: AuraColors.rose.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              earned ? icon : Icons.lock_outline_rounded,
              size: 26,
              color: earned ? Colors.white : mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: earned ? FontWeight.w700 : FontWeight.w500,
              color: earned ? theme.colorScheme.onSurface : mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
