import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daily self-care challenges. IDs are stable — they are stored in prefs.
class Challenge {
  const Challenge({
    required this.id,
    required this.icon,
    required this.points,
  });

  final String id;
  final IconData icon;
  final int points;

  static const all = [
    Challenge(id: 'hydrate', icon: Icons.local_drink_outlined, points: 10),
    Challenge(id: 'stretch', icon: Icons.self_improvement_outlined, points: 10),
    Challenge(id: 'walk', icon: Icons.directions_walk_outlined, points: 15),
    Challenge(id: 'mindful', icon: Icons.spa_outlined, points: 10),
    Challenge(id: 'log_today', icon: Icons.edit_note_outlined, points: 20),
    Challenge(id: 'sleep_early', icon: Icons.bedtime_outlined, points: 15),
  ];
}

/// Achievement badges, earned once and kept forever.
class Badge {
  const Badge({required this.id, required this.icon});

  final String id;
  final IconData icon;

  static const all = [
    Badge(id: 'first_step', icon: Icons.emoji_events_outlined),
    Badge(id: 'streak_3', icon: Icons.local_fire_department_outlined),
    Badge(id: 'streak_7', icon: Icons.whatshot_outlined),
    Badge(id: 'streak_30', icon: Icons.military_tech_outlined),
    Badge(id: 'points_100', icon: Icons.star_outline),
    Badge(id: 'points_500', icon: Icons.auto_awesome_outlined),
    Badge(id: 'all_in_a_day', icon: Icons.workspace_premium_outlined),
  ];
}

class GamificationState {
  const GamificationState({
    required this.points,
    required this.streak,
    required this.completedToday,
    required this.earnedBadges,
  });

  final int points;
  final int streak;
  final Set<String> completedToday;
  final Set<String> earnedBadges;
}

/// Local gamification engine: points, daily streak, challenges, badges.
/// Everything is stored on-device (SharedPreferences) — nothing leaves
/// the phone.
class GamificationService {
  static const _pointsKey = 'gami_points';
  static const _streakKey = 'gami_streak';
  static const _lastDayKey = 'gami_last_day';
  static const _badgesKey = 'gami_badges';
  static const _dailyPrefix = 'gami_daily_';

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }

  Future<GamificationState> getState() async {
    final prefs = await SharedPreferences.getInstance();
    return GamificationState(
      points: prefs.getInt(_pointsKey) ?? 0,
      streak: _effectiveStreak(prefs),
      completedToday: _completedToday(prefs),
      earnedBadges: _earnedBadges(prefs),
    );
  }

  /// Marks [challengeId] done for today. Returns newly earned badge ids.
  Future<List<String>> completeChallenge(String challengeId) async {
    final prefs = await SharedPreferences.getInstance();
    final done = _completedToday(prefs);
    if (done.contains(challengeId)) return const [];

    final challenge =
        Challenge.all.where((c) => c.id == challengeId).firstOrNull;
    if (challenge == null) return const [];

    done.add(challengeId);
    await prefs.setString('$_dailyPrefix${_today()}', jsonEncode(done.toList()));

    final points = (prefs.getInt(_pointsKey) ?? 0) + challenge.points;
    await prefs.setInt(_pointsKey, points);

    final streak = await _bumpStreak(prefs);
    return _checkBadges(prefs,
        points: points, streak: streak, doneToday: done.length);
  }

  /// Streak counts only if the chain reaches today or yesterday.
  int _effectiveStreak(SharedPreferences prefs) {
    final last = prefs.getString(_lastDayKey);
    final streak = prefs.getInt(_streakKey) ?? 0;
    if (last == _today() || last == _yesterday()) return streak;
    return 0;
  }

  Future<int> _bumpStreak(SharedPreferences prefs) async {
    final last = prefs.getString(_lastDayKey);
    final today = _today();
    if (last == today) return prefs.getInt(_streakKey) ?? 1;

    final streak =
        last == _yesterday() ? (prefs.getInt(_streakKey) ?? 0) + 1 : 1;
    await prefs.setInt(_streakKey, streak);
    await prefs.setString(_lastDayKey, today);
    return streak;
  }

  Set<String> _completedToday(SharedPreferences prefs) {
    final raw = prefs.getString('$_dailyPrefix${_today()}');
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as List).cast<String>().toSet();
    } catch (_) {
      return {};
    }
  }

  Set<String> _earnedBadges(SharedPreferences prefs) =>
      (prefs.getStringList(_badgesKey) ?? const []).toSet();

  Future<List<String>> _checkBadges(
    SharedPreferences prefs, {
    required int points,
    required int streak,
    required int doneToday,
  }) async {
    final earned = _earnedBadges(prefs);
    final newly = <String>[];

    void award(String id, bool condition) {
      if (condition && !earned.contains(id)) {
        earned.add(id);
        newly.add(id);
      }
    }

    award('first_step', true);
    award('streak_3', streak >= 3);
    award('streak_7', streak >= 7);
    award('streak_30', streak >= 30);
    award('points_100', points >= 100);
    award('points_500', points >= 500);
    award('all_in_a_day', doneToday >= Challenge.all.length);

    if (newly.isNotEmpty) {
      await prefs.setStringList(_badgesKey, earned.toList());
    }
    return newly;
  }
}
