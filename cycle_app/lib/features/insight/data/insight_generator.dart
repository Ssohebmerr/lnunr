import 'package:flutter/material.dart';

import '../../../core/ai/models/health_snapshot.dart';
import '../../../l10n/app_localizations.dart';

/// Generates a short, *offline* wellness line for the home header.
///
/// We deliberately do NOT call Gemini here — this widget must be instant
/// (no loading spinner, no quota cost, no flakiness on bad networks) and
/// must work even before the user has logged anything. The on-device AI
/// path is layered on top in a future iteration.
///
/// The output is a [Insight] tuple of:
///   - [headline]:  one short sentence (max ~8 words), localized.
///   - [body]:      one actionable tip or observation (≤140 chars).
///   - [accent]:    phase color used to tint the card.
///   - [icon]:      small leading icon.
///   - [mood]:      free-form mood bucket used by analytics ('phase:follicular').
class InsightGenerator {
  const InsightGenerator();

  Insight forSnapshot(HealthSnapshot snap, AppLocalizations l10n) {
    final phase = (snap.currentPhase ?? '').toLowerCase();
    final day = snap.currentCycleDay ?? 0;
    final periodActive = snap.isPeriodActive == true;
    final pregnant = snap.userGoal == 'pregnant';

    // Pregnancy mode wins — no cycle math, just gestational messaging.
    if (pregnant && snap.pregnancyWeek != null) {
      final w = snap.pregnancyWeek!;
      if (w <= 12) {
        return Insight(
          headline: l10n.insightHeadlineFirstTrimester,
          body: l10n.insightBodyFirstTrimester,
          mood: 'pregnancy:t1',
          accent: const Color(0xFFE8A0BF),
          icon: Icons.eco_outlined,
        );
      }
      if (w <= 27) {
        return Insight(
          headline: l10n.insightHeadlineSecondTrimester,
          body: l10n.insightBodySecondTrimester,
          mood: 'pregnancy:t2',
          accent: const Color(0xFFB1C97A),
          icon: Icons.directions_walk_outlined,
        );
      }
      return Insight(
        headline: l10n.insightHeadlineThirdTrimester,
        body: l10n.insightBodyThirdTrimester,
        mood: 'pregnancy:t3',
        accent: const Color(0xFFE49393),
        icon: Icons.nightlight_outlined,
      );
    }

    if (periodActive) {
      return Insight(
        headline: l10n.insightHeadlinePeriodDay,
        body: l10n.insightBodyPeriodDay,
        mood: 'phase:menstruation',
        accent: const Color(0xFFE06C75),
        icon: Icons.water_drop_outlined,
      );
    }

    switch (phase) {
      case 'follicular':
        return Insight(
          headline: l10n.insightHeadlineFollicular,
          body: l10n.insightBodyFollicular,
          mood: 'phase:follicular',
          accent: const Color(0xFF7FB069),
          icon: Icons.bolt_outlined,
        );
      case 'ovulation':
        return Insight(
          headline: l10n.insightHeadlineOvulation,
          body: l10n.insightBodyOvulation,
          mood: 'phase:ovulation',
          accent: const Color(0xFFE8B647),
          icon: Icons.favorite_outline,
        );
      case 'luteal':
        final tip = (day >= 25)
            ? l10n.insightBodyLutealLate
            : l10n.insightBodyLutealEarly;
        return Insight(
          headline: l10n.insightHeadlineLuteal,
          body: tip,
          mood: 'phase:luteal',
          accent: const Color(0xFFA685E2),
          icon: Icons.spa_outlined,
        );
      case 'lateperiod':
        return Insight(
          headline: l10n.insightHeadlineLatePeriod,
          body: l10n.insightBodyLatePeriod,
          mood: 'phase:late',
          accent: const Color(0xFFD17A22),
          icon: Icons.hourglass_bottom_outlined,
        );
      default:
        // No data yet (no last period set).
        return Insight(
          headline: l10n.insightHeadlineWelcome,
          body: l10n.insightBodyWelcome,
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
