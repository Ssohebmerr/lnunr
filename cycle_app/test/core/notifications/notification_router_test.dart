import 'package:cycle_aura/core/navigation/home_shell_actions.dart';
import 'package:cycle_aura/core/notifications/app_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    HomeShellActions.switchTab = null;
    HomeShellActions.openLog = null;
    HomeShellActions.openAiChat = null;
    HomeShellActions.openReports = null;
    HomeShellActions.openReminders = null;
  });

  group('NotificationRouter.navigateFromMap', () {
    test('switches tab from int', () {
      int? tab;
      HomeShellActions.switchTab = (i) => tab = i;
      NotificationRouter.navigateFromMap({'tab': 3});
      expect(tab, 3);
    });

    test('switches tab from string', () {
      int? tab;
      HomeShellActions.switchTab = (i) => tab = i;
      NotificationRouter.navigateFromMap({'tab': '1'});
      expect(tab, 1);
    });
  });

  group('NotificationRouter.dispatchDeepLink', () {
    test('open_log', () {
      var called = false;
      HomeShellActions.openLog = () => called = true;
      NotificationRouter.dispatchDeepLink({'action': 'open_log'});
      expect(called, isTrue);
    });

    test('open_pill and open_reminders', () {
      for (final action in ['open_pill', 'open_reminders']) {
        var called = false;
        HomeShellActions.openReminders = () => called = true;
        NotificationRouter.dispatchDeepLink({'action': action});
        expect(called, isTrue, reason: action);
      }
    });

    test('open_ai', () {
      var called = false;
      HomeShellActions.openAiChat = () => called = true;
      NotificationRouter.dispatchDeepLink({'action': 'open_ai'});
      expect(called, isTrue);
    });

    test('page reports', () {
      var called = false;
      HomeShellActions.openReports = () => called = true;
      NotificationRouter.dispatchDeepLink({'page': 'reports'});
      expect(called, isTrue);
    });
  });
}
