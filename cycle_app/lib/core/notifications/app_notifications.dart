import 'package:cycle_aura/menstrudel/utils/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Single notification plugin for Cycle Aura + Menstrudel wellness reminders.
class AppNotifications {
  AppNotifications._();

  static final plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
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
