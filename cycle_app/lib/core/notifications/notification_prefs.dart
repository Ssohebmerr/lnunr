import 'package:shared_preferences/shared_preferences.dart';

/// Shared preference keys for Cycle Aura + Menstrudel notification gating.
class NotificationPrefs {
  NotificationPrefs._();

  static const masterKey = 'notifications_enabled';
  static const periodKey = 'period_reminder_enabled';
  static const dailyLogKey = 'daily_log_reminder_enabled';
  static const ovulationKey = 'ovulation_reminder_enabled';
  static const latePeriodKey = 'late_period_reminder_enabled';
  static const communityKey = 'community_notifications_enabled';
  static const permissionPromptedKey = 'notification_permission_prompted';

  /// Smart phase-based daily reminder — body is picked from the user's
  /// current cycle phase / pregnancy trimester at schedule-time.
  static const smartPhaseKey = 'smart_phase_reminder_enabled';

  /// Morning basal body temperature reminder. Unlike every other reminder this
  /// one is time-critical: BBT is only valid taken before getting out of bed,
  /// so it fires at the user's wake time rather than a convenient hour.
  static const temperatureKey = 'temperature_reminder_enabled';

  /// Wake-up hour/minute the temperature reminder fires at (default 07:00).
  static const temperatureHourKey = 'temperature_reminder_hour';
  static const temperatureMinuteKey = 'temperature_reminder_minute';

  static Future<bool> hasPromptedForPermission() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(permissionPromptedKey) ?? false;
  }

  static Future<void> markPermissionPrompted() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(permissionPromptedKey, true);
  }

  static Future<bool> masterEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(masterKey) ?? true;
  }

  static Future<bool> periodEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(periodKey) ?? true;
  }

  static Future<bool> dailyLogEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(dailyLogKey) ?? true;
  }

  static Future<bool> ovulationEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(ovulationKey) ?? true;
  }

  /// Late/overdue-period warning. ON by default so users are gently told when
  /// a period is running behind — the most-requested "warning" notification.
  static Future<bool> latePeriodEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(latePeriodKey) ?? true;
  }

  /// Smart-phase reminder — follows the master toggle. ON by default so the
  /// user gets the new value immediately after opt-in.
  static Future<bool> smartPhaseEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(smartPhaseKey) ?? true;
  }

  /// Morning temperature reminder. OFF by default — it only helps users who
  /// have opted into temperature tracking, and a daily 7am alert nobody asked
  /// for is the fastest way to get all notifications muted.
  static Future<bool> temperatureEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(temperatureKey) ?? false;
  }

  /// (hour, minute) the temperature reminder fires at.
  static Future<(int, int)> temperatureTime() async {
    final p = await SharedPreferences.getInstance();
    return (
      p.getInt(temperatureHourKey) ?? 7,
      p.getInt(temperatureMinuteKey) ?? 0,
    );
  }

  static Future<void> setTemperatureTime(int hour, int minute) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(temperatureHourKey, hour.clamp(0, 23));
    await p.setInt(temperatureMinuteKey, minute.clamp(0, 59));
  }

  /// Pills, sanitary, LARC — follow master toggle only.
  static Future<bool> wellnessEnabled() => masterEnabled();

  static Future<bool> communityEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(communityKey) ?? true;
  }
}
