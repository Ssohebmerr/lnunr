import 'package:shared_preferences/shared_preferences.dart';

/// Shared preference keys for Cycle Aura + Menstrudel notification gating.
class NotificationPrefs {
  NotificationPrefs._();

  static const masterKey = 'notifications_enabled';
  static const periodKey = 'period_reminder_enabled';
  static const dailyLogKey = 'daily_log_reminder_enabled';
  static const ovulationKey = 'ovulation_reminder_enabled';
  static const communityKey = 'community_notifications_enabled';
  static const permissionPromptedKey = 'notification_permission_prompted';

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

  /// Pills, sanitary, LARC — follow master toggle only.
  static Future<bool> wellnessEnabled() => masterEnabled();

  static Future<bool> communityEnabled() async {
    if (!await masterEnabled()) return false;
    final p = await SharedPreferences.getInstance();
    return p.getBool(communityKey) ?? true;
  }
}
