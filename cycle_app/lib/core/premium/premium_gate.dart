import 'package:shared_preferences/shared_preferences.dart';

import '../privacy/consent_manager.dart';
import '../storage/user_prefs.dart';

enum PremiumAiAccess { allowed, needsConsent, needsPremium, limitReached }

/// Central checks for Premium-gated features (Play Console / honest pricing).
class PremiumGate {
  PremiumGate._();

  static const freeAiMessagesPerDay = 5;
  static const freeReportsTotal = 1;
  static const _aiCountPrefix = 'ai_msg_count_';
  static const _reportCountKey = 'doctor_report_count';

  static Future<bool> hasPremium() => UserPrefs.isPremium();

  static Future<bool> canUseCloudSync() async =>
      await hasPremium() && await ConsentManager.hasCloudSyncConsent();

  static Future<bool> canUseAdvancedAi() async =>
      await hasPremium() && await ConsentManager.hasAiConsent();

  static Future<PremiumAiAccess> checkAiChat() async {
    if (!await ConsentManager.hasAiConsent()) {
      return PremiumAiAccess.needsConsent;
    }
    if (await hasPremium()) return PremiumAiAccess.allowed;
    final count = await _todayAiCount();
    if (count >= freeAiMessagesPerDay) {
      return PremiumAiAccess.limitReached;
    }
    return PremiumAiAccess.allowed;
  }

  static Future<void> recordAiMessage() async {
    if (await hasPremium()) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _aiCountKey();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  static Future<int> remainingFreeAiMessages() async {
    if (await hasPremium()) return -1;
    final used = await _todayAiCount();
    return (freeAiMessagesPerDay - used).clamp(0, freeAiMessagesPerDay);
  }

  /// Check if user can generate a doctor report (1 free, then premium).
  static Future<bool> canGenerateDoctorReport() async {
    if (await hasPremium()) return true;
    final count = await _reportCount();
    return count < freeReportsTotal;
  }

  /// Get remaining free reports count.
  static Future<int> remainingFreeReports() async {
    if (await hasPremium()) return -1;
    final used = await _reportCount();
    return (freeReportsTotal - used).clamp(0, freeReportsTotal);
  }

  /// Record a doctor report generation.
  static Future<void> recordDoctorReport() async {
    if (await hasPremium()) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _reportCountKey,
      (prefs.getInt(_reportCountKey) ?? 0) + 1,
    );
  }

  static Future<int> _reportCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reportCountKey) ?? 0;
  }

  static Future<int> _todayAiCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_aiCountKey()) ?? 0;
  }

  static String _aiCountKey() {
    final today = DateTime.now();
    final d = '${today.year}-${today.month}-${today.day}';
    return '$_aiCountPrefix$d';
  }
}
