import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../menstrudel/services/notification_service.dart' as md;
import 'app_notifications.dart';
import 'notification_prefs.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin get _plugin => AppNotifications.plugin;
  static const _periodId = 1001;
  static const _dailyId = 1002;
  static const _ovulationId = 1003;
  static const _periodTodayId = 1004;

  static Future<bool> _isArabic() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('app_locale') ?? 'ar') == 'ar';
  }

  static Future<void> initialize() => AppNotifications.initialize();

  static Future<bool> requestPermission() => AppNotifications.requestPermission();

  /// System permission prompt once after install (onboarding or first home open).
  static Future<void> ensureInitialPermission() async {
    if (await NotificationPrefs.hasPromptedForPermission()) return;
    await NotificationPrefs.markPermissionPrompted();

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(NotificationPrefs.masterKey) ?? true)) {
      await prefs.setBool(NotificationPrefs.masterKey, true);
    }

    await requestPermission();
    await scheduleFromPrefs();
  }

  static Future<void> scheduleFromPrefs() async {
    if (!await NotificationPrefs.masterEnabled()) {
      await cancelAll();
      await _cancelMenstrudelReminders();
      return;
    }

    if (await NotificationPrefs.periodEnabled()) {
      await _schedulePeriodReminder();
      await _schedulePeriodStartToday();
    } else {
      await _plugin.cancel(_periodId);
      await _plugin.cancel(_periodTodayId);
      await md.NotificationService.cancelPeriodDueNotification();
      await md.NotificationService.cancelPeriodOverdueNotification();
    }

    if (await NotificationPrefs.dailyLogEnabled()) {
      await _scheduleDailyLogReminder();
    } else {
      await _plugin.cancel(_dailyId);
    }

    if (await NotificationPrefs.ovulationEnabled()) {
      await _scheduleOvulationReminder();
    } else {
      await _plugin.cancel(_ovulationId);
      await md.NotificationService.cancelFertileWindowNotification();
      await md.NotificationService.cancelOvulationNotification();
    }
  }

  static Future<void> _cancelMenstrudelReminders() async {
    await md.NotificationService.cancelPeriodDueNotification();
    await md.NotificationService.cancelPeriodOverdueNotification();
    await md.NotificationService.cancelFertileWindowNotification();
    await md.NotificationService.cancelOvulationNotification();
    await md.NotificationService.cancelPillReminder();
    await md.NotificationService.cancelSanitaryProductReminder();
    await md.NotificationService.cancelReversibleContraceptiveReminder();
  }

  static Future<void> _schedulePeriodReminder() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;

    final nextDateStr = await api.getNextPredictedPeriodDate();
    if (nextDateStr.isEmpty) return;

    try {
      final next = DateTime.parse(nextDateStr);
      final reminder = next.subtract(const Duration(days: 1));
      if (reminder.isBefore(DateTime.now())) return;

      final ar = await _isArabic();
      await _plugin.zonedSchedule(
        _periodId,
        'Lune',
        ar
            ? 'قد تبدأ دورتك غدًا. جهزي نفسك واحرصي على الراحة.'
            : 'Your period may start tomorrow. Check your calendar.',
        tz.TZDateTime.from(reminder, tz.local),
        _details(high: true),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> _schedulePeriodStartToday() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;
    if (!await api.isPeriodStartFromToday()) {
      await _plugin.cancel(_periodTodayId);
      return;
    }

    try {
      final now = DateTime.now();
      var at = DateTime(now.year, now.month, now.day, 8, 0);
      if (at.isBefore(now)) return;

      final ar = await _isArabic();
      await _plugin.zonedSchedule(
        _periodTodayId,
        'Lune',
        ar
            ? 'دورتك متوقعة اليوم. اعتني بنفسك.'
            : 'Your period is expected today. Take care of yourself.',
        tz.TZDateTime.from(at, tz.local),
        _details(high: true),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> _scheduleOvulationReminder() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;

    try {
      final dateStr = await api.getNextOvulationDate();
      if (dateStr.isEmpty) return;

      final ovulation = DateTime.parse(dateStr);
      final reminder =
          DateTime(ovulation.year, ovulation.month, ovulation.day, 9, 0);
      if (reminder.isBefore(DateTime.now())) return;

      final ar = await _isArabic();
      await _plugin.zonedSchedule(
        _ovulationId,
        'Lune',
        ar
            ? 'اليوم هو يوم الإباضة المتوقع لديك.'
            : 'Today is your predicted ovulation day.',
        tz.TZDateTime.from(reminder, tz.local),
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {}
  }

  static Future<void> _scheduleDailyLogReminder() async {
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, 20, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final prefs = await SharedPreferences.getInstance();
    final ar = await _isArabic();
    final streak = prefs.getInt('gami_streak') ?? 0;
    final String body;
    if (streak >= 2) {
      body = ar
          ? 'كيف تشعرين اليوم؟ سجلي يومك وحافظي على سلسلة الـ $streak أيام!'
          : 'How are you feeling today? Log your day and keep your $streak-day streak alive!';
    } else {
      body = ar
          ? 'كيف تشعرين اليوم؟ سجلي أعراضك ومزاجك.'
          : 'How are you feeling today? Log your symptoms.';
    }

    await _plugin.zonedSchedule(
      _dailyId,
      'Lune',
      body,
      tz.TZDateTime.from(scheduled, tz.local),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static NotificationDetails _details({bool high = false}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cycle_aura_reminders',
          'Cycle Reminders',
          importance: high ? Importance.high : Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  static Future<void> cancelAll() async {
    await _plugin.cancel(_periodId);
    await _plugin.cancel(_dailyId);
    await _plugin.cancel(_ovulationId);
    await _plugin.cancel(_periodTodayId);
  }
}
