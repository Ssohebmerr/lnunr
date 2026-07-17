import 'package:shared_preferences/shared_preferences.dart';

import '../age/age_gate.dart';
import '../privacy/consent_manager.dart';
import '../storage/user_prefs.dart';

enum PremiumAiAccess { allowed, needsConsent, needsPremium, needsAdult, limitReached }

/// Central checks for Premium-gated features (Play Console / honest pricing).
class PremiumGate {
  PremiumGate._();

  static const freeReportsTotal = 1;

  static Future<bool> hasPremium() => UserPrefs.isPremium();

  static Future<bool> canUseCloudSync() async =>
      await hasPremium() && await ConsentManager.hasCloudSyncConsent();

  static Future<bool> canUseAdvancedAi() async =>
      !(await blocksAiByAgeGate()) &&
      await hasPremium() &&
      await ConsentManager.hasAiConsent();

  static Future<PremiumAiAccess> checkAiChat() async {
    if (await blocksAiByAgeGate()) {
      return PremiumAiAccess.needsAdult;
    }
    if (!await hasPremium()) {
      return PremiumAiAccess.needsPremium;
    }
    if (!await ConsentManager.hasAiConsent()) {
      return PremiumAiAccess.needsConsent;
    }
    return PremiumAiAccess.allowed;
  }

  /// Check if user can generate a doctor report (1 free per month, then premium).
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
    final key = _reportCountKey();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }

  static Future<int> _reportCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_reportCountKey()) ?? 0;
  }

  static String _reportCountKey() {
    final today = DateTime.now();
    return 'doctor_report_count_${today.year}_${today.month}';
  }
}
