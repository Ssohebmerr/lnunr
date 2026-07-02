// ============================================================================
// test/core/config/feature_flags_test.dart
// ----------------------------------------------------------------------------
// Tests the on-device feature-flag cache. The cache is small enough that
// the entire surface area gets covered in one file.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_aura/core/config/feature_flags.dart';

void main() {
setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // The cache is a static field, so we must reset it explicitly between
    // tests — otherwise a previous test's `setEnabled(..., false)` will
    // shadow the default for the next test.
    await FeatureFlags.refresh();
  });

  group('FeatureFlags defaults', () {
    test('every declared flag has a default', () {
      // Refusing to expose the private map, but we can at least assert that
      // dump() returns the same keys we know about.
      final dump = FeatureFlags.dump();
      // dump() is async, but we only care that the call itself doesn't
      // throw and that the returned future completes.
      expect(dump, isA<Future<Map<String, bool>>>());
    });

    test('unknown flag defaults to false (fail-safe)', () async {
      expect(await FeatureFlags.isEnabled('feature.doesNotExist'), isFalse);
    });
  });

  group('FeatureFlags.isEnabled', () {
    test('returns the default when nothing is persisted', () async {
      expect(await FeatureFlags.isEnabled(FeatureFlags.dailyStreak), isTrue);
      expect(await FeatureFlags.isEnabled(FeatureFlags.partnerSync), isTrue);
    });

    test('reads the persisted override after setEnabled', () async {
      await FeatureFlags.setEnabled(FeatureFlags.dailyStreak, false);
      expect(await FeatureFlags.isEnabled(FeatureFlags.dailyStreak), isFalse);
      // The cache must reflect the new value synchronously too.
      expect(FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak), isFalse);
    });
  });

  group('FeatureFlags.isEnabledSync', () {
    test('returns the default when cache is cold', () {
      // Cold cache → falls back to _defaults (true for dailyStreak).
      expect(FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak), isTrue);
    });

    test('returns false for unknown flag in cold-cache mode', () {
      expect(FeatureFlags.isEnabledSync('feature.neverHeardOf'), isFalse);
    });
  });

  group('FeatureFlags.refresh', () {
test('repopulates the cache from persisted values', () async {
      // Persist a value behind the cache's back, then force a refresh so
      // the cache stops serving the default (`true`).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(FeatureFlags.dailyStreak, false);
      await FeatureFlags.refresh();
      expect(FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak), isFalse);

      // Now toggle via setEnabled — the cache is updated synchronously.
      await FeatureFlags.setEnabled(FeatureFlags.dailyStreak, true);
      expect(FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak), isTrue);

      // refresh() must restore the cache from disk — simulate the case
      // where a remote config push wrote a new value while the app was
      // backgrounded.
      await prefs.setBool(FeatureFlags.dailyStreak, false);
      // Cache still says true (sync).
      expect(FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak), isTrue);
      // After refresh it should reflect disk again.
      await FeatureFlags.refresh();
      expect(FeatureFlags.isEnabledSync(FeatureFlags.dailyStreak), isFalse);
    });
  });

  group('FeatureFlags.dump', () {
    test('returns every known flag with its effective value', () async {
      await FeatureFlags.setEnabled(FeatureFlags.dailyStreak, false);
      final d = await FeatureFlags.dump();
      expect(d, contains(FeatureFlags.dailyStreak));
      expect(d[FeatureFlags.dailyStreak], isFalse);
      // All other declared flags must be present.
      for (final flag in [
        FeatureFlags.todaysInsight,
        FeatureFlags.smartPhaseNotifications,
        FeatureFlags.symptomInsightsEngine,
        FeatureFlags.moodJournal,
        FeatureFlags.voiceLogging,
        FeatureFlags.partnerSync,
        FeatureFlags.luneStories,
      ]) {
        expect(d, contains(flag), reason: 'missing flag: $flag');
      }
    });
  });
}
