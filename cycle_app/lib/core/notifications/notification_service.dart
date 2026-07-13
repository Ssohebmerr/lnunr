import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../features/notifications/data/smart_phase_notifier.dart';
import '../config/feature_flags.dart';
import '../../menstrudel/services/notification_service.dart' as md;
import 'app_notifications.dart';
import 'notification_prefs.dart';
import 'notification_rationale_dialog.dart';

class NotificationService {
  static FlutterLocalNotificationsPlugin get _plugin => AppNotifications.plugin;
  static const _periodId = 1001;
  static const _dailyId = 1002;
  static const _ovulationId = 1003;
  static const _periodTodayId = 1004;
  static const _lateId = 1006;
  static const _fertileId = 1007;
  static const _testId = 1999;

  static Future<bool> _isArabic() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('app_locale') ?? 'ar') == 'ar';
  }

  static Future<bool> _isPregnant() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('user_goal') ?? '') == 'pregnancy';
  }

  static Future<void> initialize() => AppNotifications.initialize();

  static Future<bool> requestPermission() =>
      AppNotifications.requestPermission();

  /// Whether the OS will actually surface our notifications right now (i.e. the
  /// per-app notification switch is on). Lets the UI warn when everything is
  /// scheduled but the system is silently dropping it.
  static Future<bool> areNotificationsEnabled() =>
      AppNotifications.areEnabled();

  /// Fire an immediate notification so the user can confirm the whole delivery
  /// pipeline (permission → channel → display) works — decoupled from the
  /// scheduled 9 AM / 8 PM slots, which is why "nothing shows right after
  /// install" is usually just timing, not a failure. Returns whether the OS
  /// granted permission to show it.
  static Future<bool> sendTestNotification() async {
    await initialize();
    final granted = await requestPermission();
    if (!granted) return false;

    final ar = await _isArabic();
    await _plugin.show(
      _testId,
      'Lune',
      ar
          ? 'إشعار تجريبي — الإشعارات تعمل بنجاح! 🌙'
          : 'Test notification — everything works! 🌙',
      _details(high: true),
      payload: NotificationPayload.home(),
    );

    if (!await AppNotifications.canScheduleExactNotifications()) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] test OK but exact alarms denied — '
          'scheduled reminders may be delayed',
        );
      }
    }
    return true;
  }

  /// Returns how many local reminders are queued (best-effort).
  static Future<int> pendingReminderCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  /// Earliest upcoming reminder we know about (daily log, smart phase, cycle).
  static Future<DateTime?> nextScheduledReminderAt() async {
    if (!await _canScheduleNow()) return null;
    if (!await NotificationPrefs.masterEnabled()) return null;

    final now = DateTime.now();
    final candidates = <DateTime>[];
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('daily_log_reminder_enabled') ?? true) {
      var daily = DateTime(now.year, now.month, now.day, 20, 0);
      if (!daily.isAfter(now)) {
        daily = daily.add(const Duration(days: 1));
      }
      candidates.add(daily);
    }

    final smartNext = prefs.getString('smart_phase_next_at');
    if (smartNext != null && smartNext.isNotEmpty) {
      try {
        final dt = DateTime.parse(smartNext);
        if (dt.isAfter(now)) candidates.add(dt);
      } catch (_) {}
    }

    if (prefs.getBool('period_reminder_enabled') ?? true) {
      final api = MenstrualCycleWidget.instance;
      if (api != null) {
        try {
          final nextDateStr = await api.getNextPredictedPeriodDate();
          if (nextDateStr.isNotEmpty) {
            final next = DateTime.parse(nextDateStr);
            final reminderDay = next.subtract(const Duration(days: 1));
            final at = DateTime(
              reminderDay.year,
              reminderDay.month,
              reminderDay.day,
              9,
              0,
            );
            if (at.isAfter(now)) candidates.add(at);
          }
        } catch (_) {}
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.first;
  }

  /// System permission prompt once after install (onboarding or first home open).
  /// When a [BuildContext] is supplied we show the friendly in-app rationale
  /// first; otherwise we fall back to a direct OS prompt (e.g. from
  /// background callbacks that don't have a UI context).
  static Future<void> ensureInitialPermission([BuildContext? context]) async {
    if (await NotificationPrefs.hasPromptedForPermission()) return;

    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(NotificationPrefs.masterKey) ?? true)) {
      await prefs.setBool(NotificationPrefs.masterKey, true);
    }

    var granted = false;
    if (context != null && context.mounted) {
      granted = await showNotificationRationale(context);
    } else {
      granted = await requestPermission();
    }

    await NotificationPrefs.markPermissionPrompted();

    if (granted) {
      await scheduleFromPrefs();
    }
  }

  static Future<bool> _canScheduleNow() async {
    await initialize();
    final enabled = await areNotificationsEnabled();
    if (!enabled) {
      if (kDebugMode) {
        debugPrint(
          '[NotificationService] OS notifications disabled — skipping schedule',
        );
      }
      return false;
    }
    return true;
  }

  static Future<AndroidScheduleMode> _scheduleMode() =>
      AppNotifications.resolveScheduleMode();

  static Future<void> scheduleFromPrefs() async {
    try {
      if (!await _canScheduleNow()) return;

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
        await _scheduleFertileWindowHeadsUp();
      } else {
        await _plugin.cancel(_ovulationId);
        await _plugin.cancel(_fertileId);
        await md.NotificationService.cancelFertileWindowNotification();
        await md.NotificationService.cancelOvulationNotification();
      }

      if (await NotificationPrefs.latePeriodEnabled()) {
        await _scheduleLatePeriodWarning();
      } else {
        await _plugin.cancel(_lateId);
      }

      if (await NotificationPrefs.smartPhaseEnabled() &&
          FeatureFlags.isEnabledSync(FeatureFlags.smartPhaseNotifications)) {
        await SmartPhaseNotifier.schedule();
      } else {
        await SmartPhaseNotifier.cancel();
      }
    } catch (e, st) {
      debugPrint('scheduleFromPrefs failed (non-fatal): $e\n$st');
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
      final reminderDay = next.subtract(const Duration(days: 1));
      var at = DateTime(
        reminderDay.year,
        reminderDay.month,
        reminderDay.day,
        9,
        0,
      );
      if (at.isBefore(DateTime.now())) return;

      final ar = await _isArabic();
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _periodId,
        'Lune',
        ar
            ? 'قد تبدأ دورتك غدًا. جهزي نفسك واحرصي على الراحة.'
            : 'Your period may start tomorrow. Check your calendar.',
        tz.TZDateTime.from(at, tz.local),
        _details(high: true),
        androidScheduleMode: mode,
        payload: NotificationPayload.home(),
      );
    } catch (e, st) {
      debugPrint('_schedulePeriodReminder failed: $e\n$st');
    }
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
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _periodTodayId,
        'Lune',
        ar
            ? 'دورتك متوقعة اليوم. اعتني بنفسك.'
            : 'Your period is expected today. Take care of yourself.',
        tz.TZDateTime.from(at, tz.local),
        _details(high: true),
        androidScheduleMode: mode,
        payload: NotificationPayload.home(action: 'open_log'),
      );
    } catch (e, st) {
      debugPrint('_schedulePeriodStartToday failed: $e\n$st');
    }
  }

  static Future<void> _scheduleOvulationReminder() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;

    try {
      final dateStr = await api.getNextOvulationDate();
      if (dateStr.isEmpty) return;

      final ovulation = DateTime.parse(dateStr);
      final reminder = DateTime(
        ovulation.year,
        ovulation.month,
        ovulation.day,
        9,
        0,
      );
      if (reminder.isBefore(DateTime.now())) return;

      final ar = await _isArabic();
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _ovulationId,
        'Lune',
        ar
            ? 'اليوم هو يوم الإباضة المتوقع لديك.'
            : 'Today is your predicted ovulation day.',
        tz.TZDateTime.from(reminder, tz.local),
        _details(),
        androidScheduleMode: mode,
        payload: NotificationPayload.home(),
      );
    } catch (e, st) {
      debugPrint('_scheduleOvulationReminder failed: $e\n$st');
    }
  }

  /// Warning notification when a period is running behind the prediction.
  /// Fires a couple of days after the predicted start if no new period has been
  /// logged — the cycle data (and thus the predicted date) advances the moment
  /// the user logs, and re-scheduling on foreground moves this slot with it.
  static Future<void> _scheduleLatePeriodWarning() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;
    // Pregnancy mode has no "late period" concept — suppress the warning.
    if (await _isPregnant()) {
      await _plugin.cancel(_lateId);
      return;
    }

    try {
      final prediction = await api.getCurrentPeriodPrediction();
      if (prediction == null) {
        await _plugin.cancel(_lateId);
        return;
      }

      // Wait until the full personalized window has passed before using the
      // word "late". This stays aligned with the date card on Home.
      final end = prediction.windowEnd;
      final at = DateTime(
        end.year,
        end.month,
        end.day,
        9,
        0,
      ).add(const Duration(days: 1));
      if (at.isBefore(DateTime.now())) {
        await _plugin.cancel(_lateId);
        return;
      }

      final ar = await _isArabic();
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _lateId,
        'Lune',
        ar
            ? 'انتهى نطاق دورتك المتوقع دون تسجيل جديد. قد يحدث هذا طبيعيًا — راجعي التقويم وسجّلي ما تشعرين به.'
            : 'Your expected period window passed without a new log. This can happen naturally — review your calendar and log how you feel.',
        tz.TZDateTime.from(at, tz.local),
        _details(high: true),
        androidScheduleMode: mode,
        payload: NotificationPayload.home(action: 'open_log'),
      );
    } catch (e, st) {
      debugPrint('_scheduleLatePeriodWarning failed: $e\n$st');
    }
  }

  /// Heads-up a few days before ovulation so fertility-aware users know the
  /// fertile window is opening. Gated by the same toggle as the ovulation
  /// reminder.
  static Future<void> _scheduleFertileWindowHeadsUp() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return;
    if (await _isPregnant()) {
      await _plugin.cancel(_fertileId);
      return;
    }

    try {
      final dateStr = await api.getNextOvulationDate();
      if (dateStr.isEmpty) {
        await _plugin.cancel(_fertileId);
        return;
      }

      final ovulation = DateTime.parse(dateStr);
      // Fertile window opens ~4 days before ovulation; nudge at 9:00 AM.
      final at = DateTime(
        ovulation.year,
        ovulation.month,
        ovulation.day,
        9,
        0,
      ).subtract(const Duration(days: 4));
      if (at.isBefore(DateTime.now())) {
        await _plugin.cancel(_fertileId);
        return;
      }

      final ar = await _isArabic();
      final mode = await _scheduleMode();
      await _plugin.zonedSchedule(
        _fertileId,
        'Lune',
        ar
            ? 'نافذة الخصوبة المقدّرة تبدأ قريبًا. أكّديها بإشارات جسمكِ إن كنتِ تخططين للحمل.'
            : "Your estimated fertile window is opening soon. Confirm it with body signals if you're trying to conceive.",
        tz.TZDateTime.from(at, tz.local),
        _details(),
        androidScheduleMode: mode,
        payload: NotificationPayload.home(),
      );
    } catch (e, st) {
      debugPrint('_scheduleFertileWindowHeadsUp failed: $e\n$st');
    }
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
      androidScheduleMode: await _scheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: NotificationPayload.home(action: 'open_log'),
    );
  }

  static NotificationDetails _details({bool high = false}) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cycle_aura_reminders',
          'Lune',
          importance: high ? Importance.high : Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  static Future<void> cancelAll() async {
    await _plugin.cancel(_periodId);
    await _plugin.cancel(_dailyId);
    await _plugin.cancel(_ovulationId);
    await _plugin.cancel(_periodTodayId);
    await _plugin.cancel(_lateId);
    await _plugin.cancel(_fertileId);
    await SmartPhaseNotifier.cancel();
  }
}
