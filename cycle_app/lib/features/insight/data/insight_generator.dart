import 'package:flutter/material.dart';

import '../../../core/ai/models/health_snapshot.dart';

/// Generates a short, *offline* wellness line for the home header.
///
/// We deliberately do NOT call Gemini here — this widget must be instant
/// (no loading spinner, no quota cost, no flakiness on bad networks) and
/// must work even before the user has logged anything. The on-device AI
/// path is layered on top in a future iteration.
///
/// The output is a [Insight] tuple of:
///   - [headline]:  one short sentence (max ~8 words), localizable later.
///   - [body]:      one actionable tip or observation (≤140 chars).
///   - [accent]:    phase color used to tint the card.
///   - [icon]:      small leading icon.
///   - [mood]:      free-form mood bucket used by analytics ('phase:follicular').
class InsightGenerator {
  const InsightGenerator();

  Insight forSnapshot(HealthSnapshot snap) {
    final phase = (snap.currentPhase ?? '').toLowerCase();
    final day = snap.currentCycleDay ?? 0;
    final periodActive = snap.isPeriodActive == true;
    final pregnant = snap.userGoal == 'pregnant';

    // Pregnancy mode wins — no cycle math, just gestational messaging.
    if (pregnant && snap.pregnancyWeek != null) {
      final w = snap.pregnancyWeek!;
      if (w <= 12) {
        return Insight(
          headline: 'First trimester',
          body: 'Gentle movement, hydration, and rest are your best friends this week.',
          mood: 'pregnancy:t1',
          accent: const Color(0xFFE8A0BF),
          icon: Icons.eco_outlined,
        );
      }
      if (w <= 27) {
        return Insight(
          headline: 'Second trimester',
          body: 'Energy usually picks up here — great time for light walks and stretching.',
          mood: 'pregnancy:t2',
          accent: const Color(0xFFB1C97A),
          icon: Icons.directions_walk_outlined,
        );
      }
      return Insight(
        headline: 'Third trimester',
        body: 'Rest often, hydrate, and reach out to your provider with any concerns.',
        mood: 'pregnancy:t3',
        accent: const Color(0xFFE49393),
        icon: Icons.nightlight_outlined,
      );
    }

    if (periodActive) {
      return Insight(
        headline: 'Period day',
        body: 'Warm drinks + magnesium-rich foods can ease cramps. Be gentle with yourself today.',
        mood: 'phase:menstruation',
        accent: const Color(0xFFE06C75),
        icon: Icons.water_drop_outlined,
      );
    }

    switch (phase) {
      case 'follicular':
        return Insight(
          headline: 'Follicular phase',
          body: 'Energy tends to climb — try a new workout or tackle a tough task today.',
          mood: 'phase:follicular',
          accent: const Color(0xFF7FB069),
          icon: Icons.bolt_outlined,
        );
      case 'ovulation':
        return Insight(
          headline: 'Ovulation',
          body: 'Peak energy + confidence. Good day for a hard workout or a social plan.',
          mood: 'phase:ovulation',
          accent: const Color(0xFFE8B647),
          icon: Icons.favorite_outline,
        );
      case 'luteal':
        final tip = (day >= 25)
            ? 'Luteal week — complex carbs + earlier bedtime can really help mood right now.'
            : 'Luteal phase — crave calm: less caffeine, more rest, gentle movement.';
        return Insight(
          headline: 'Luteal phase',
          body: tip,
          mood: 'phase:luteal',
          accent: const Color(0xFFA685E2),
          icon: Icons.spa_outlined,
        );
      case 'lateperiod':
        return Insight(
          headline: 'Cycle is running late',
          body: 'Stress or sleep changes can shift things. Give it 2-3 days — log any symptoms.',
          mood: 'phase:late',
          accent: const Color(0xFFD17A22),
          icon: Icons.hourglass_bottom_outlined,
        );
      default:
        // No data yet (no last period set).
        return Insight(
          headline: 'Welcome 🌸',
          body: 'Set your last period date to unlock personalised daily insights.',
          mood: 'phase:unknown',
          accent: const Color(0xFFB388C7),
          icon: Icons.spa_outlined,
        );
    }
  }
}

/// Immutable insight payload. Each factory call below sets the per-phase
/// accent + icon explicitly — the defaults below are the "we don't know
/// yet" fallback used by callers that just want the headline + body.
class Insight {
  const Insight({
    required this.headline,
    required this.body,
    required this.mood,
    this.accent = const Color(0xFFB388C7),
    this.icon = Icons.spa_outlined,
  });

  final String headline;
  final String body;
  final String mood;
  final Color accent;
  final IconData icon;
}