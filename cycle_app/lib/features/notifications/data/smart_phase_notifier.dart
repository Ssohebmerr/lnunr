// ============================================================================
// lib/features/notifications/data/smart_phase_notifier.dart
// ----------------------------------------------------------------------------
// Phase-aware daily motivation — scheduled as a *rolling runway*.
//
// The old design scheduled a SINGLE notification for the next 9:00 AM and
// relied on the app being re-opened to queue the following day. That silently
// broke the promise of a "daily" reminder: a user who stopped opening the app
// received exactly one notification and then nothing — the precise moment we
// most want to re-engage them.
//
// Instead we now pre-schedule the next [_runwayDays] mornings in one shot, each
// with a message computed for THAT day's predicted cycle phase and a rotating
// body so consecutive days never repeat. Every app foreground re-lays the
// runway (see NotificationService.scheduleFromPrefs) so it always extends
// [_runwayDays] out and reflects the latest cycle data. Result: the reminder
// keeps arriving every morning even if the app is never opened for two weeks,
// and it self-corrects the instant the user returns.
//
// Why 9:00 AM?
//   * Past the wake-up alarm chaos but before most users start work
//   * Matches the existing ovulation reminder slot
//   * Has been the daily reminder default in MoonAura/Lune forever
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

  /// Legacy single-shot ID (pre-runway). Still cancelled on every schedule so
  /// upgrading users don't keep a stale notification queued.
  static const int _legacyId = 1005;

  /// Runway occupies a contiguous block starting here. Kept clear of the
  /// 1001-1005 IDs used by NotificationService.
  static const int _runwayBaseId = 1010;

  /// How many mornings to pre-schedule. 14 days survives a two-week silence
  /// while staying well under the Android pending-alarm budget.
  static const int _runwayDays = 14;

  static const _channelId = 'cycle_aura_smart_phase';
  static const _channelName = 'Lune — Smart phase';

  // ---------------------------------------------------------------------------
  // Scheduling
  // ---------------------------------------------------------------------------

  /// Schedule (or refresh) the daily-motivation runway. Safe to call every time
  /// the app comes to foreground — each slot ID is overwritten, so we never
  /// accumulate duplicates.
  static Future<void> schedule() async {
    try {
      final plugin = AppNotifications.plugin;
      // Retire the old single-shot slot from previous app versions.
      await plugin.cancel(_legacyId);

      final snap = await _defaultSnapshot();
      final locale = await _defaultLocale();
      final base = _nextNineAm();

      for (var d = 0; d < _runwayDays; d++) {
        final when = base.add(Duration(days: d));
        final ctx = snap.contextForOffset(d);
        final msg = SmartPhaseMessages.pick(ctx, locale, rotation: d);
        await plugin.zonedSchedule(
          _runwayBaseId + d,
          msg.title,
          msg.body,
          when,
          _details,
          // Inexact is deliberate: a daily motivational tip doesn't need
          // minute precision, and it sidesteps the SCHEDULE_EXACT_ALARM
          // permission (revocable on Android 13+) so delivery stays reliable
          // even when exact alarms are denied.
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: NotificationPayload.home(),
        );
      }

      // Persist today's pick so QA + debug screens can see what's queued.
      final today = SmartPhaseMessages.pick(snap.contextForOffset(0), locale);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('smart_phase_last_tag', today.tag);
      await prefs.setString('smart_phase_next_at', base.toIso8601String());
    } catch (e, st) {
      debugPrint('SmartPhaseNotifier.schedule failed (non-fatal): $e\n$st');
    }
  }

  /// Cancel the whole runway. Used by the settings toggle and
  /// NotificationService.cancelAll().
  static Future<void> cancel() async {
    try {
      final plugin = AppNotifications.plugin;
      await plugin.cancel(_legacyId);
      for (var d = 0; d < _runwayDays; d++) {
        await plugin.cancel(_runwayBaseId + d);
      }
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
  // Projection — pure + testable
  // ---------------------------------------------------------------------------

  /// Build the [SmartPhaseContext] for the morning [dayOffset] days from now.
  ///
  /// Day 0 uses the widget's own current phase string so "today" is always
  /// pixel-perfect (including a genuine late-period state). Future days project
  /// the cycle forward and wrap at [cycleLength] — i.e. we assume the predicted
  /// period arrives on schedule and a fresh cycle begins — which is the best
  /// forecast we have without a logged period.
  @visibleForTesting
  static SmartPhaseContext contextForOffset({
    required int dayOffset,
    required int currentCycleDay,
    required int cycleLength,
    required int periodDuration,
    required String currentPhase,
    bool isPregnant = false,
    int? pregnancyWeek,
  }) {
    if (isPregnant) {
      final week = (pregnancyWeek ?? 1) + (dayOffset ~/ 7);
      var trimester = ((week - 1) ~/ 13) + 1;
      trimester = trimester.clamp(1, 3);
      return SmartPhaseContext(
        phase: '',
        cycleDay: null,
        isPregnant: true,
        pregnancyWeek: week,
        trimester: trimester,
      );
    }

    if (currentCycleDay <= 0) {
      return const SmartPhaseContext(
        phase: '',
        cycleDay: null,
        isPregnant: false,
      );
    }

    if (dayOffset == 0) {
      return SmartPhaseContext(
        phase: currentPhase,
        cycleDay: currentCycleDay,
        isPregnant: false,
      );
    }

    final len = cycleLength > 0 ? cycleLength : 28;
    final effDay = ((currentCycleDay - 1 + dayOffset) % len) + 1;
    return SmartPhaseContext(
      phase: _phaseStringForDay(effDay, len, periodDuration),
      cycleDay: effDay,
      isPregnant: false,
    );
  }

  /// Canonical (English) phase label for a projected cycle day. Mirrors the
  /// thresholds in `MenstrualCycleWidgetBase.getCurrentPhaseName` so our
  /// forecast matches what the app itself would report. The returned strings
  /// are the ones [SmartPhaseMessages] classifies against, not user-facing.
  static String _phaseStringForDay(int day, int cycleLength, int periodDuration) {
    final period = periodDuration > 0 ? periodDuration : 5;
    final follicularEnd = period + defaultFollicularDay;
    final ovulationEnd = follicularEnd + defaultOvulationDay;
    if (day <= 0) return '';
    if (day <= period) return 'menstruation';
    if (day <= follicularEnd) return 'follicular';
    if (day <= ovulationEnd) return 'ovulation';
    if (day <= cycleLength) return 'luteal';
    return 'late';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      );

  /// Next 9:00 AM strictly after "now". If it is already 09:01 today we pick
  /// 09:00 tomorrow, so a re-schedule after the slot fired advances a day.
  static tz.TZDateTime _nextNineAm() {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    if (!at.isAfter(now)) {
      at = at.add(const Duration(days: 1));
    }
    return at;
  }

  static Future<_RunwaySnapshot> _defaultSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final isPregnant = (prefs.getString('user_goal') ?? '') == 'pregnancy';

    final widget = MenstrualCycleWidget.instance;
    if (widget == null) {
      return _RunwaySnapshot(
        cycleDay: 0,
        cycleLength: 28,
        periodDuration: 5,
        currentPhase: '',
        isPregnant: isPregnant,
        pregnancyWeek: isPregnant ? 1 : null,
      );
    }

    int cycleDay = 0;
    String phase = '';
    int cycleLength = 28;
    int periodDuration = 5;
    try {
      cycleDay = await widget.getCurrentCycleDay();
    } catch (_) {}
    try {
      phase = await widget.getCurrentPhaseName();
    } catch (_) {}
    try {
      cycleLength = widget.getCycleLength();
    } catch (_) {}
    try {
      periodDuration = widget.getPeriodDuration();
    } catch (_) {}
    if (cycleLength <= 0) cycleLength = 28;
    if (periodDuration <= 0) periodDuration = 5;

    int? pregnancyWeek;
    if (isPregnant) {
      try {
        pregnancyWeek = await widget.getCurrentPregnancyWeek();
      } catch (_) {}
    }

    return _RunwaySnapshot(
      cycleDay: cycleDay,
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      currentPhase: phase,
      isPregnant: isPregnant,
      pregnancyWeek: pregnancyWeek,
    );
  }

  static Future<String> _defaultLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('app_locale') ?? 'ar';
    } catch (_) {
      return 'ar';
    }
  }
}

/// One-time read of the cycle/pregnancy signals we need to lay a full runway.
/// Captured once per schedule so all 14 slots share a consistent view.
class _RunwaySnapshot {
  const _RunwaySnapshot({
    required this.cycleDay,
    required this.cycleLength,
    required this.periodDuration,
    required this.currentPhase,
    required this.isPregnant,
    required this.pregnancyWeek,
  });

  final int cycleDay;
  final int cycleLength;
  final int periodDuration;
  final String currentPhase;
  final bool isPregnant;
  final int? pregnancyWeek;

  SmartPhaseContext contextForOffset(int dayOffset) =>
      SmartPhaseNotifier.contextForOffset(
        dayOffset: dayOffset,
        currentCycleDay: cycleDay,
        cycleLength: cycleLength,
        periodDuration: periodDuration,
        currentPhase: currentPhase,
        isPregnant: isPregnant,
        pregnancyWeek: pregnancyWeek,
      );
}
