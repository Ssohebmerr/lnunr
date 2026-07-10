import 'dart:convert';

import 'package:cycle_aura/core/navigation/home_shell_actions.dart';
import 'package:cycle_aura/menstrudel/utils/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Single notification plugin for Cycle Aura + Menstrudel wellness reminders.
class AppNotifications {
  AppNotifications._();

  static final plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Set this to your root `MaterialApp.navigatorKey` so notification taps
  /// can route the user to the right tab. Wired in `main.dart`.
  static GlobalKey<NavigatorState>? globalNavigatorKey;

  /// Optional callback for tap routing. Defaults to [NotificationRouter.handleTap]
  /// which honours JSON payloads of the form `{"tab":<int>}`.
  static void Function(NotificationResponse response)? onTapCallback;

  /// Standard launcher icon and Darwin defaults. iOS permission request is
  /// handled by [requestPermission] below.
  static Future<void> initialize({
    void Function(NotificationResponse response)? onTap,
  }) async {
    if (_initialized) return;

    onTapCallback = onTap ?? NotificationRouter.handleTap;

    const android = AndroidInitializationSettings('ic_stat_lune');
    const ios = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidImpl = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const channels = [
      AndroidNotificationChannel(
        'cycle_aura_reminders',
        'Cycle Reminders',
        description: 'Period and daily log reminders',
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'cycle_aura_smart_phase',
        'Lune — Smart phase',
        description: 'Daily phase-aware motivation and wellness tips',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        periodNotificationChannelId,
        periodNotificationChannelName,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        cyclePhaseReminderChannelId,
        cyclePhaseReminderChannelName,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        pillReminderChannelId,
        pillReminderChannelName,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        sanitaryProductChannelId,
        sanitaryProductChannelName,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        reversibleContraceptivesReminderChannelId,
        reversibleContraceptivesReminderChannelName,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        loggingReminderChannelId,
        loggingReminderChannelName,
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await androidImpl?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  static void _onTap(NotificationResponse response) {
    final cb = onTapCallback;
    if (cb == null) {
      if (kDebugMode) {
        debugPrint(
            '[AppNotifications] tap on "${response.payload}" but no callback set');
      }
      return;
    }
    try {
      cb(response);
    } catch (e, st) {
      debugPrint('[AppNotifications] tap callback failed: $e\n$st');
    }
  }

  /// Whether the per-app notification switch is currently ON at the OS level.
  /// Returns true on platforms without an explicit query so we don't warn
  /// spuriously.
  static Future<bool> areEnabled() async {
    await initialize();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    return true;
  }

  static Future<bool> requestPermission() async {
    await initialize();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }
}

/// Routes notification taps to the relevant app tab/screen.
///
/// Payload contract: JSON string `{"tab":<int>,"action":<string?>}`
/// - `tab`: index of the HomeShell tab (0..3) to land on
/// - `action`: optional deep action (e.g. "open_log", "open_pill")
/// - `page`: optional sub-page on Home tab (e.g. "reports")
class NotificationRouter {
  NotificationRouter._();

  static void handleTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final nav = AppNotifications.globalNavigatorKey;
    if (nav == null) return;
    final ctx = nav.currentContext;
    if (ctx == null) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      navigateFromMap(data);
    } catch (e, st) {
      debugPrint('[NotificationRouter] bad payload "$payload": $e\n$st');
    }
  }

  /// Shared routing for local notifications, FCM taps, and widget launches.
  static void navigateFromMap(Map<String, dynamic> data) {
    final tab = data['tab'];
    if (tab is int) {
      HomeShellActions.switchTab?.call(tab);
    } else if (tab is String) {
      final parsed = int.tryParse(tab);
      if (parsed != null) HomeShellActions.switchTab?.call(parsed);
    }

    final page = data['page'];
    final action = data['action'];
    final hasDeepLink =
        page == 'reports' || (action is String && action.isNotEmpty);
    if (hasDeepLink) {
      _afterFrame(() => dispatchDeepLink(data));
    }
  }

  /// Synchronous deep-link dispatch — used by tests and [_afterFrame].
  @visibleForTesting
  static void dispatchDeepLink(Map<String, dynamic> data) {
    final page = data['page'];
    if (page == 'reports') {
      HomeShellActions.openReports?.call();
      return;
    }

    final action = data['action'];
    if (action is! String || action.isEmpty) return;

    switch (action) {
      case 'open_log':
        HomeShellActions.openLog?.call();
      case 'open_pill':
      case 'open_reminders':
        HomeShellActions.openReminders?.call();
      case 'open_ai':
        HomeShellActions.openAiChat?.call();
    }
  }

  static void _afterFrame(VoidCallback? action) {
    if (action == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 320), action);
    });
  }
}

/// Builds the JSON payload string attached to each scheduled notification.
/// Kept as a tiny helper so callers can express intent (`home()`,
/// `community()`) without hand-writing JSON every time.
class NotificationPayload {
  NotificationPayload._();

  static const _homeTab = 0;
  static const _communityTab = 1;
  static const _selfCareTab = 2;
  static const _accountTab = 3;

  static String _encode(int tab, {String? action, String? page}) {
    final map = <String, dynamic>{'tab': tab};
    if (action != null) map['action'] = action;
    if (page != null) map['page'] = page;
    return jsonEncode(map);
  }

  /// Home tab (cycle + period + log). Optional action e.g. `open_log`.
  static String home({String? action}) => _encode(_homeTab, action: action);

  /// Community tab (likes, replies, mentions).
  static String community({String? action}) =>
      _encode(_communityTab, action: action);

  /// Self-care tab (rituals, water, rest, stretches).
  static String selfCare({String? action}) =>
      _encode(_selfCareTab, action: action);

  /// Reports sub-page (opened from Home tab).
  static String reports({String? action}) =>
      _encode(_homeTab, action: action, page: 'reports');

  /// Account / settings tab (pill, sanitary, larc reminders).
  static String account({String? action}) =>
      _encode(_accountTab, action: action);
}
