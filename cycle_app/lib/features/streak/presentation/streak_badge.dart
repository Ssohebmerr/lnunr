import 'package:flutter/material.dart';

import '../data/streak_service.dart';

/// A compact "🔥 12-day streak" pill used in the home header and the
/// post-log confirmation toast. Reads the current + longest counts on
/// every build so the UI stays in sync after the user logs activity.
class StreakBadge extends StatelessWidget {
  const StreakBadge({
    super.key,
    StreakService? service,
    this.compact = false,
  }) : _serviceOverride = service;

  /// Optional injected service for tests. Production callers leave this null
  /// and we fall back to a fresh [StreakService] every build.
  final StreakService? _serviceOverride;

  /// When true, render a smaller chip suitable for the home tab bar.
  final bool compact;

  StreakService get _service => _serviceOverride ?? StreakService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = _service;
    return FutureBuilder<_StreakSnapshot>(
      future: _load(svc),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final data = snap.data!;
        if (data.current == 0 && data.longest == 0) {
          return const SizedBox.shrink();
        }
        final isAlive = data.current > 0;
        return _BadgeBody(
          current: data.current,
          longest: data.longest,
          compact: compact,
          alive: isAlive,
          theme: theme,
        );
      },
    );
  }

  static Future<_StreakSnapshot> _load(StreakService s) async {
    return _StreakSnapshot(
      current: await s.currentCount(),
      longest: await s.longestCount(),
    );
  }
}

class _StreakSnapshot {
  _StreakSnapshot({required this.current, required this.longest});
  final int current;
  final int longest;
}

/// Lets us inject a custom service in tests; in production we use the
/// default constructor of [StreakService] which is stateless.
// (Removed `_DefaultService` — the previous attempt at a const wrapper hit
// `StreakService`'s non-const constructor. We just take a nullable service
// in StreakBadge directly.)

class _BadgeBody extends StatelessWidget {
  const _BadgeBody({
    required this.current,
    required this.longest,
    required this.compact,
    required this.alive,
    required this.theme,
  });

  final int current;
  final int longest;
  final bool compact;
  final bool alive;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = alive
        ? const Color(0xFFFF7A45) // warm orange (flame)
        : theme.colorScheme.outline;
    final label = current > 0 ? '$current' : '—';
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 8);

    return Semantics(
      label: alive
          ? 'Streak: $current day${current == 1 ? "" : "s"}, longest ever $longest'
          : 'Streak broken. Longest ever $longest',
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              alive ? Icons.local_fire_department_rounded : Icons.bedtime_outlined,
              size: compact ? 14 : 18,
              color: color,
            ),
            SizedBox(width: compact ? 4 : 6),
            Text(
              label,
              style: (compact
                      ? theme.textTheme.labelMedium
                      : theme.textTheme.titleMedium)
                  ?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (longest > current && current > 0) ...[
              const SizedBox(width: 6),
              Text(
                'best $longest',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color.withValues(alpha: 0.75),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}