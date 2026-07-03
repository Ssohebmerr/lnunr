// ============================================================================
// test/core/notifications/notification_payload_test.dart
// ----------------------------------------------------------------------------
// Tests the JSON payload contract used by every scheduled notification so the
// HomeShell tab routing in NotificationRouter stays in sync with the data
// each reminder schedules with.
// ============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_aura/core/notifications/app_notifications.dart';

void main() {
  group('NotificationPayload', () {
    test('home() encodes tab 0 with no action', () {
      final decoded =
          jsonDecode(NotificationPayload.home()) as Map<String, dynamic>;
      expect(decoded['tab'], 0);
      expect(decoded.containsKey('action'), isFalse);
    });

    test('home(action: "open_log") encodes both tab and action', () {
      final decoded = jsonDecode(NotificationPayload.home(action: 'open_log'))
          as Map<String, dynamic>;
      expect(decoded['tab'], 0);
      expect(decoded['action'], 'open_log');
    });

    test('community() encodes tab 1', () {
      final decoded =
          jsonDecode(NotificationPayload.community()) as Map<String, dynamic>;
      expect(decoded['tab'], 1);
    });

    test('selfCare() encodes tab 2', () {
      final decoded =
          jsonDecode(NotificationPayload.selfCare()) as Map<String, dynamic>;
      expect(decoded['tab'], 2);
    });

    test('account(action: "open_pill") encodes tab 3 with action', () {
      final decoded = jsonDecode(
              NotificationPayload.account(action: 'open_pill'))
          as Map<String, dynamic>;
      expect(decoded['tab'], 3);
      expect(decoded['action'], 'open_pill');
    });

    test('reports() routes to Home tab with page=reports', () {
      final decoded =
          jsonDecode(NotificationPayload.reports()) as Map<String, dynamic>;
      // Reports is opened as a sub-page from the Home tab, so the tab field
      // points at Home (0) and the page field tells the router to push the
      // reports sub-page via HomeShellActions.openReports.
      expect(decoded['tab'], 0);
      expect(decoded['page'], 'reports');
    });

    test('every HomeShell tab index is reachable via the typed helpers', () {
      // HomeShell has exactly four tabs (indices 0..3):
      // 0=Home, 1=Community, 2=SelfCare, 3=Account.
      // Reports is not a tab — it's a sub-page (see reports() test above).
      const expected = [0, 1, 2, 3];
      final got = [
        jsonDecode(NotificationPayload.home())['tab'],
        jsonDecode(NotificationPayload.community())['tab'],
        jsonDecode(NotificationPayload.selfCare())['tab'],
        jsonDecode(NotificationPayload.account())['tab'],
      ];
      expect(got, expected);
    });
  });
}
