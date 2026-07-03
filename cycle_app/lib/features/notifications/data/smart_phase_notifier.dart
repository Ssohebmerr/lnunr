// ============================================================================
// lib/features/notifications/data/smart_phase_notifier.dart
// ----------------------------------------------------------------------------
// Phase-aware daily notification. We pick the *next* 9:00 AM in the user's
// local timezone and schedule a single notification whose body depends on
// their current cycle phase + pregnancy state. Re-scheduling is idempotent —
// we always cancel the prior slot first so a phase change today will not
// spam the user tomorrow.
//
// Why 9:00 AM?
//   * Past the wake-up alarm chaos but before most users start work
//   * Matches the existing ovulation reminder slot
//   * Has been the daily-log reminder default in MoonAura/Lune forever
//
// Why not every day?
//   The widget data refreshes on home open. If we refresh too often we
//   cause confusion (user gets the same message twice a day). Once per
//   day at 9:00 AM is enough — and the test suite verifies idempotency.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/notifications/app_notifications.dart';
import 'smart_phase_messages.dart';

class SmartPhaseNotifier {
  SmartPhaseNotifier._();

  /// Stable notification ID — separate from the existing IDs
  /// (1001-1004) used by NotificationService so we don't collide.
  static const int _notificationId = 1005;

  /// Pluggable hooks — overridable from tests so we don't need to mock
  /// the static `MenstrualCycleWidget.instance` directly.
  static Future<SmartPhaseContext> Function()? _contextProvider;
  static Future<String> Function()? _localeProvider;
  static Future<bool> Function()? _alreadyLoggedToday;

  @visibleForTesting
  static void installHooks({
    Future<SmartPhaseContext> Function()? contextProvider,
    Future<String> Function()? localeProvider,
    Future<bool> Function()? alreadyLoggedToday,
  }) {
    _contextProvider = contextProvider;
    _localeProvider = localeProvider;
    _alreadyLoggedToday = alreadyLoggedToday;
  }

  @visibleForTesting
  static void resetHooks() => installHooks();

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Schedule (or refresh) tomorrow's smart-phase reminder. Safe to call
  /// every time the app comes to foreground — the prior slot is cancelled
  /// first so we don't accumulate notifications.
  static Future<void> schedule() async {
    try {
      final plugin = AppNotifications.plugin;
      await plugin.cancel(_notificationId);

      // Skip entirely if user already logged today — feels creepy otherwise.
      final alreadyLogged = await (_alreadyLoggedToday ?? _defaultAlreadyLoggedToday)();
      if (alreadyLogged) return;

      final ctx = await (_contextProvider ?? _defaultContext)();
      final locale =
          await (_localeProvider ?? _defaultLocaleProvider)();
      final msg = SmartPhaseMessages.pick(ctx, locale);

      final scheduled = _nextNineAm();
      await plugin.zonedSchedule(
        _notificationId,
        msg.title,
        msg.body,
        scheduled,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'cycle_aura_smart_phase',
            'Lune — Smart phase',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Fire once, not repeating — the user gets a fresh pick tomorrow
        // when we re-schedule on next app foreground.
        payload: NotificationPayload.home(action: 'open_dashboard'),
      );

      // Persist last-pick tag so QA + debug screens can see what's queued.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smart_phase_last_tag', msg.tag);
      await prefs.setString(
        'smart_phase_next_at',
        scheduled.toIso8601String(),
      );
    } catch (e, st) {
      debugPrint('SmartPhaseNotifier.schedule failed (non-fatal): $e\n$st');
    }
  }

  /// Cancel the smart-phase reminder. Used by the settings toggle and
  /// by NotificationService.cancelAll().
  static Future<void> cancel() async {
    try {
      await AppNotifications.plugin.cancel(_notificationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('smart_phase_last_tag');
      await prefs.remove('smart_phase_next_at');
    } catch (e, st) {
      debugPrint('SmartPhaseNotifier.cancel failed: $e\n$st');
    }
  }

  /// Debug-only inspection helper for the settings UI ("last queued" pill).
  static Future<String?> lastTag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('smart_phase_last_tag');
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Pick the next 9:00 AM strictly after "now". If it is 09:01 today, we
  /// pick 09:00 tomorrow. Important boundary: if we re-schedule after the
  /// notification already fired, we MUST advance one day.
  static tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    if (!at.isAfter(now)) {
      at = at.add(const Duration(days: 1));
    }
    return at;
  }

  // Defaults that read from the live widget / shared prefs. Tests override.
  static Future<SmartPhaseContext> _defaultContext() async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) {
      return const SmartPhaseContext(
        phase: '',
        cycleDay: null,
        isPregnant: false,
      );
    }
    String phase = '';
    int? day;
    try {
      phase = await widget.getCurrentPhaseName();
    } catch (_) {}
    try {
      day = await widget.getCurrentCycleDay();
    } catch (_) {}

    // Detect pregnancy mode by reading the user goal from prefs.
    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getString('user_goal') ?? '';
    final isPregnant = goal == 'pregnancy';
    int? pregnancyWeek;
    int? trimester;
    if (isPregnant) {
      try {
        pregnancyWeek = await widget.getCurrentPregnancyWeek();
        trimester = ((pregnancyWeek - 1) ~/ 13) + 1;
        trimester = trimester.clamp(1, 3);
      } catch (_) {}
    }

    return SmartPhaseContext(
      phase: phase,
      cycleDay: (day != null && day > 0) ? day : null,
      isPregnant: isPregnant,
      pregnancyWeek: pregnancyWeek,
      trimester: trimester,
    );
  }

  static Future<String> _defaultLocaleProvider() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('app_locale') ?? 'ar';
    } catch (_) {
      return 'ar';
    }
  }

  /// Considers the day "logged" if TodayLogService wrote any entry today.
  /// We read the same source the dashboard uses, so the "no spam if you
  /// already logged today" rule lines up with the rest of the app.
  static Future<bool> _defaultAlreadyLoggedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Real check uses prefs flag written by TodayLogService; if absent,
      // fall back to false so notifications stay on.
      return prefs.getBool('today_log_present') ?? false;
    } catch (_) {
      return false;
    }
  }
}
