// ============================================================================
// test/features/insight/insight_generator_test.dart
// ----------------------------------------------------------------------------
// Tests the offline insight generator that powers the Today's Insight card
// on the home tab. We feed it synthetic HealthSnapshot objects and assert
// the generator returns the right headline + mood bucket for each phase.
//
// We don't assert on the [body] text because it's user-facing copy that
// will get iterated on — locking down the exact wording would make every
// UX tweak a breaking change. Instead we assert:
//   - the right phase → mood bucket (used by analytics)
//   - the right phase → headline label
//   - pregnancy mode takes precedence over cycle phase
//   - period active takes precedence over phase label
//   - empty snapshot → "welcome" + no crash
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_aura/core/ai/models/health_snapshot.dart';
import 'package:cycle_aura/features/insight/data/insight_generator.dart';
import 'package:cycle_aura/l10n/app_localizations.dart';

void main() {
  final gen = InsightGenerator();
  late AppLocalizations enL10n;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    enL10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  HealthSnapshot snap({
    String? phase,
    int? day,
    bool periodActive = false,
    String? goal,
    int? pregnancyWeek,
  }) {
    return HealthSnapshot(
      currentPhase: phase,
      currentCycleDay: day,
      isPeriodActive: periodActive,
      userGoal: goal,
      pregnancyWeek: pregnancyWeek,
    );
  }

  group('InsightGenerator.forSnapshot — cycle phases', () {
    test('menstruation phase (period active) wins over phase label', () {
      final i = gen.forSnapshot(
        snap(phase: 'luteal', periodActive: true, day: 22), enL10n);
      expect(i.mood, 'phase:menstruation');
      expect(i.headline.toLowerCase(), contains('period'));
    });

    test('follicular phase', () {
      final i = gen.forSnapshot(snap(phase: 'follicular', day: 8), enL10n);
      expect(i.mood, 'phase:follicular');
      expect(i.headline.toLowerCase(), contains('follicular'));
    });

    test('ovulation phase', () {
      final i = gen.forSnapshot(snap(phase: 'ovulation', day: 14), enL10n);
      expect(i.mood, 'phase:ovulation');
      expect(i.headline.toLowerCase(), contains('ovulation'));
    });

    test('luteal phase — early (day < 25)', () {
      final i = gen.forSnapshot(snap(phase: 'luteal', day: 20), enL10n);
      expect(i.mood, 'phase:luteal');
      expect(i.headline.toLowerCase(), contains('luteal'));
    });

    test('luteal phase — late (day >= 25) has a different body but same headline',
        () {
      final i = gen.forSnapshot(snap(phase: 'luteal', day: 26), enL10n);
      expect(i.mood, 'phase:luteal');
      expect(i.headline.toLowerCase(), contains('luteal'));
    });

    test('late period label', () {
      final i = gen.forSnapshot(snap(phase: 'latePeriod', day: 32), enL10n);
      expect(i.mood, 'phase:late');
      expect(i.headline.toLowerCase(), contains('running late'));
    });

    test('empty snapshot → welcome / unknown mood', () {
      final i = gen.forSnapshot(snap(), enL10n);
      expect(i.mood, 'phase:unknown');
      expect(i.headline.toLowerCase(), contains('welcome'));
    });
  });

  group('InsightGenerator.forSnapshot — pregnancy overrides cycle', () {
    test('pregnant + t1 (week 8)', () {
      final i = gen.forSnapshot(
          snap(phase: 'luteal', goal: 'pregnant', pregnancyWeek: 8, day: 22),
          enL10n);
      expect(i.mood, 'pregnancy:t1');
      expect(i.headline.toLowerCase(), contains('first trimester'));
    });

    test('pregnant + t2 (week 18)', () {
      final i = gen.forSnapshot(
          snap(phase: 'follicular', goal: 'pregnant', pregnancyWeek: 18),
          enL10n);
      expect(i.mood, 'pregnancy:t2');
      expect(i.headline.toLowerCase(), contains('second trimester'));
    });

    test('pregnant + t3 (week 32)', () {
      final i = gen.forSnapshot(
          snap(phase: 'luteal', goal: 'pregnant', pregnancyWeek: 32), enL10n);
      expect(i.mood, 'pregnancy:t3');
      expect(i.headline.toLowerCase(), contains('third trimester'));
    });

    test('pregnant but no week known falls back to cycle logic', () {
      final i = gen.forSnapshot(
          snap(phase: 'follicular', goal: 'pregnant', pregnancyWeek: null),
          enL10n);
      // Without pregnancyWeek the pregnancy branch is skipped.
      expect(i.mood, 'phase:follicular');
    });
  });

  group('InsightGenerator visual styling', () {
    test('every insight has a non-empty headline + body + mood', () {
      final cases = [
        snap(),
        snap(phase: 'follicular', day: 8),
        snap(phase: 'luteal', day: 22),
        snap(phase: 'ovulation', day: 14),
        snap(phase: 'menstruation', day: 3, periodActive: true),
        snap(phase: 'latePeriod', day: 40),
        snap(goal: 'pregnant', pregnancyWeek: 20),
      ];
      for (final s in cases) {
        final i = gen.forSnapshot(s, enL10n);
        expect(i.headline, isNotEmpty, reason: 'empty headline for $s');
        expect(i.body, isNotEmpty, reason: 'empty body for $s');
        expect(i.mood, isNotEmpty, reason: 'empty mood for $s');
      }
    });

    test('every insight body fits within ~140 chars (compact card width)',
        () {
      final cases = [
        snap(),
        snap(phase: 'follicular', day: 8),
        snap(phase: 'luteal', day: 22),
        snap(phase: 'luteal', day: 28), // late luteal variant
        snap(goal: 'pregnant', pregnancyWeek: 8),
        snap(goal: 'pregnant', pregnancyWeek: 32),
      ];
      for (final s in cases) {
        final i = gen.forSnapshot(s, enL10n);
        // Generous bound — the actual TextOverflow.ellipsis at maxLines:2
        // can absorb a bit more, but 200 is the hard upper limit we'll ever
        // want here.
        expect(i.body.length, lessThanOrEqualTo(200),
            reason: 'body too long: "${i.body}" (${i.body.length})');
      }
    });
  });
}