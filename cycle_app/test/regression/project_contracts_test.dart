import 'dart:io';

import 'package:cycle_aura/core/config/feature_flags.dart';
import 'package:cycle_aura/features/premium/data/play_billing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locks down cross-file contracts that broke during past restores.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FeatureFlags.refresh();
  });

  group('FeatureFlags registry', () {
    test('allFlags lists every declared flag exactly once', () {
      const declared = {
        FeatureFlags.dailyStreak,
        FeatureFlags.todaysInsight,
        FeatureFlags.smartPhaseNotifications,
        FeatureFlags.symptomInsightsEngine,
        FeatureFlags.moodJournal,
        FeatureFlags.voiceLogging,
        FeatureFlags.partnerSync,
        FeatureFlags.luneStories,
        FeatureFlags.aiChatEnabled,
      };
      expect(FeatureFlags.allFlags.toSet(), declared);
      expect(FeatureFlags.allFlags.length, declared.length);
    });

    test('production defaults match shipped features', () async {
      // If you change a default, update this test intentionally.
      final flags = await FeatureFlags.dump();
      expect(flags[FeatureFlags.dailyStreak], isTrue);
      expect(flags[FeatureFlags.todaysInsight], isTrue);
      expect(flags[FeatureFlags.smartPhaseNotifications], isTrue);
      expect(flags[FeatureFlags.symptomInsightsEngine], isTrue);
      expect(flags[FeatureFlags.partnerSync], isTrue);
      expect(flags[FeatureFlags.luneStories], isTrue);
      expect(flags[FeatureFlags.moodJournal], isFalse);
      expect(flags[FeatureFlags.voiceLogging], isFalse);
      expect(flags[FeatureFlags.aiChatEnabled], isTrue);
    });
  });

  group('Play Billing contract', () {
    test('Dart SKU matches Firebase play_billing.js', () {
      final jsPath = File(
        'firebase/functions/play_billing.js',
      );
      expect(jsPath.existsSync(), isTrue, reason: 'play_billing.js must exist');
      final js = jsPath.readAsStringSync();
      // Every Dart SKU must exist in the server's PREMIUM_PRODUCT_IDS set.
      for (final sku in PlayBillingService.productIds) {
        expect(js, contains("'$sku'"), reason: 'play_billing.js missing $sku');
      }
      expect(js, contains("'${PlayBillingService.monthlyProductId}'"));
      expect(js, contains("'${PlayBillingService.yearlyProductId}'"));
      expect(PlayBillingService.packageName, 'com.luneapp.cycle');
      expect(js, contains("'com.luneapp.cycle'"));
    });
  });

  group('Home shell wiring files', () {
    test('critical home widgets exist on disk', () {
      // Only widgets home_tab actually wires. home_ai_entry_card.dart used to
      // be listed here but home_tab stopped importing it in an earlier
      // refactor, leaving a file nothing rendered — the AI entry point on Home
      // is the header chip plus the explore rail. The file is gone; guarding a
      // path no screen imports just protects dead code.
      const widgets = [
        'lib/features/home/widgets/home_explore_rail.dart',
        'lib/features/home/widgets/home_updates_panel.dart',
        'lib/features/home/widgets/home_community_card.dart',
      ];
      for (final path in widgets) {
        expect(File(path).existsSync(), isTrue, reason: 'missing $path');
      }
    });

    test('home_tab imports wired widgets', () {
      final homeTab = File('lib/features/home/home_tab.dart').readAsStringSync();
      expect(homeTab, contains('home_explore_rail.dart'));
      expect(homeTab, contains('home_updates_panel.dart'));
      expect(homeTab, contains('home_community_card.dart'));
      expect(homeTab, contains('HomeTodayLogCard'));
      expect(homeTab, contains('DailyBriefingCard'));
      expect(homeTab, contains('HomeShellActions'));
    });
  });
}
