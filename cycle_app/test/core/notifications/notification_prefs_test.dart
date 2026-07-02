// ============================================================================
// test/core/notifications/notification_prefs_test.dart
// ----------------------------------------------------------------------------
// Tests the gating logic: each per-channel toggle (period / daily log /
// ovulation / community) must respect the master switch and have sane
// defaults. Wellness reminders follow the master only.
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_aura/core/notifications/notification_prefs.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences between tests so defaults are deterministic.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('NotificationPrefs — defaults', () {
    test('master toggle defaults to enabled', () async {
      expect(await NotificationPrefs.masterEnabled(), isTrue);
    });

    test('per-channel toggles default to enabled', () async {
      expect(await NotificationPrefs.periodEnabled(), isTrue);
      expect(await NotificationPrefs.dailyLogEnabled(), isTrue);
      expect(await NotificationPrefs.ovulationEnabled(), isTrue);
      expect(await NotificationPrefs.communityEnabled(), isTrue);
    });

    test('wellness follows master', () async {
      expect(await NotificationPrefs.wellnessEnabled(), isTrue);
    });
  });

  group('NotificationPrefs — master gating', () {
    test('disabling master turns off every per-channel toggle', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(NotificationPrefs.masterKey, false);

      expect(await NotificationPrefs.periodEnabled(), isFalse);
      expect(await NotificationPrefs.dailyLogEnabled(), isFalse);
      expect(await NotificationPrefs.ovulationEnabled(), isFalse);
      expect(await NotificationPrefs.communityEnabled(), isFalse);
      expect(await NotificationPrefs.wellnessEnabled(), isFalse);
    });

    test('wellness is gated by master even if a per-channel toggle is on',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(NotificationPrefs.masterKey, false);
      // Even if we explicitly turn a wellness channel on, the master
      // gate wins because wellnessEnabled() returns masterEnabled().
      await prefs.setBool(NotificationPrefs.periodKey, true);
      expect(await NotificationPrefs.wellnessEnabled(), isFalse);
    });
  });

  group('NotificationPrefs — per-channel independence', () {
    test('disabling period does NOT affect ovulation or daily log', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(NotificationPrefs.periodKey, false);

      expect(await NotificationPrefs.periodEnabled(), isFalse);
      expect(await NotificationPrefs.dailyLogEnabled(), isTrue);
      expect(await NotificationPrefs.ovulationEnabled(), isTrue);
      expect(await NotificationPrefs.communityEnabled(), isTrue);
    });
  });

  group('NotificationPrefs — permission prompt tracking', () {
    test('hasPromptedForPermission defaults to false', () async {
      expect(await NotificationPrefs.hasPromptedForPermission(), isFalse);
    });

    test('markPermissionPrompted persists across reads', () async {
      await NotificationPrefs.markPermissionPrompted();
      expect(await NotificationPrefs.hasPromptedForPermission(), isTrue);
    });
  });
}
