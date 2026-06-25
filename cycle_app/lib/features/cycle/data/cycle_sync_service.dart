import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../menstrudel_integration/menstrudel_init.dart';
import '../../../menstrudel/models/app/user_entry.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../../menstrudel/database/repositories/user_repository.dart';
import '../../../menstrudel/services/widget_controller.dart';
import 'cycle_bridge_service.dart';
import 'period_bridge_service.dart';

/// Central orchestrator — keeps cycle data, profile, wellness, AI, and UI in sync.
class CycleSyncService {
  CycleSyncService({CycleBridgeService? bridge})
      : _bridge = bridge ?? CycleBridgeService();

  final CycleBridgeService _bridge;

  static const _syncTimeout = Duration(seconds: 15);

  /// Full onboarding: widget cycle config + Menstrudel profile + notifications + home widget.
  Future<void> completeOnboarding({
    required int cycleLength,
    required int periodDuration,
    required DateTime lastPeriodDate,
    required String languageCode,
    DateFormats dateFormat = DateFormats.dmy,
    required String displayName,
    DateTime? birthDate,
    required UserGoalTypes goal,
  }) async {
    await _bridge.configure(
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      lastPeriodDate: lastPeriodDate,
      languageCode: languageCode,
      dateFormat: dateFormat,
    );

    final name = displayName.trim().isEmpty ? 'User' : displayName.trim();
    await ConsentManager.acceptPrivacyPolicy();
    await UserPrefs.setProfile(name: name, goal: goal.dbName);
    await UserPrefs.setOnboardingDone();

    try {
      await _upsertMenstrudelProfile(
        name: name,
        birthDate: birthDate,
        goal: goal,
      ).timeout(_syncTimeout);
    } catch (e, st) {
      debugPrint('Menstrudel profile sync failed (non-fatal): $e\n$st');
    }

    try {
      await onCycleDataChanged().timeout(_syncTimeout);
    } catch (e, st) {
      debugPrint('Post-onboarding sync failed (non-fatal): $e\n$st');
    }
  }

  /// Update cycle configuration from settings — propagates everywhere.
  Future<void> updateCycleConfig({
    required int cycleLength,
    required int periodDuration,
    required DateTime lastPeriodDate,
    required String languageCode,
    DateFormats dateFormat = DateFormats.dmy,
  }) async {
    await _bridge.configure(
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      lastPeriodDate: lastPeriodDate,
      languageCode: languageCode,
      dateFormat: dateFormat,
    );
    await onCycleDataChanged().timeout(_syncTimeout);
  }

  /// Call after any cycle log, backup import, or cloud restore.
  Future<void> onCycleDataChanged() async {
    // Mirror widget period days into the Menstrudel store.
    final bridge = PeriodBridgeService.instance;
    final menstrudelChanged = await bridge.syncWidgetToMenstrudel();
    if (menstrudelChanged) {
      await bridge.onMenstrudelDataChanged?.call();
    }

    await NotificationService.scheduleFromPrefs();
    await syncHomeWidget();
    HomeRefreshScope.refresh();
  }

  Future<void> onAuthChanged(User? user) async {
    await _bridge.linkAuthenticatedUser(user);
    if (user != null) {
      await UserPrefs.saveUid(user.uid);
      final name = await getDisplayName();
      if (name != 'User') {
        try {
          await _upsertMenstrudelProfile(
            name: name,
            goal: await getUserGoal(),
          ).timeout(_syncTimeout);
        } catch (e, st) {
          debugPrint('Auth profile sync failed (non-fatal): $e\n$st');
        }
      }
    } else {
      await UserPrefs.clearUid();
    }
    try {
      await onCycleDataChanged().timeout(_syncTimeout);
    } catch (e, st) {
      debugPrint('Post-auth cycle sync failed (non-fatal): $e\n$st');
    }
  }

  Future<String> getDisplayName() async {
    final local = await LocalProfile.displayName();
    if (local.isNotEmpty && local != 'Guest') return local;

    final userService = MenstrudelInit.userService;
    if (userService?.user != null && userService!.user!.name.isNotEmpty) {
      return userService.user!.name;
    }
    final cached = await UserPrefs.getProfileName();
    if (cached != null && cached.isNotEmpty) return cached;

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return local;
  }

  Future<UserGoalTypes> getUserGoal() async {
    final userService = MenstrudelInit.userService;
    if (userService?.user != null) {
      return userService!.user!.primaryGoal;
    }
    final cached = await UserPrefs.getProfileGoal();
    if (cached != null) {
      return UserGoalTypes.fromDbName(cached);
    }
    return UserGoalTypes.general;
  }

  /// Switch primary goal — home, reports, self-care, and AI refresh immediately.
  Future<void> setUserGoal(UserGoalTypes goal) async {
    final name = await getDisplayName();
    await UserPrefs.setProfile(name: name, goal: goal.dbName);

    try {
      await _upsertMenstrudelProfile(name: name, goal: goal);
    } catch (e, st) {
      debugPrint('setUserGoal profile sync failed: $e\n$st');
    }

    final userService = MenstrudelInit.userService;
    final settings = MenstrudelInit.settingsService;
    if (settings != null) {
      if (userService != null && userService.user != null) {
        await userService.setPrimaryGoal(goal, settings);
      } else {
        await settings.applySettingsForGoal(goal);
      }
    }

    await onCycleDataChanged();
  }

  Future<CycleDashboardData?> loadDashboard() async {
    try {
      return await _bridge.loadDashboard();
    } catch (_) {
      return null;
    }
  }

  Future<void> syncHomeWidget() async {
    try {
      final data = await _bridge.loadDashboard();
      final api = MenstrualCycleWidget.instance;
      if (api == null) return;

      await WidgetController().saveAndAndUpdateCircle(
        currentValue: data.cycleDay,
        maxValue: api.getCycleLength(),
        largeText: data.phase,
        smallText: 'Day ${data.cycleDay}',
        predictionDate: data.nextPeriod,
      );
    } catch (_) {}
  }

  Future<void> _upsertMenstrudelProfile({
    required String name,
    DateTime? birthDate,
    required UserGoalTypes goal,
  }) async {
    final settings = MenstrudelInit.settingsService;
    if (settings == null) return;

    final repo = UserRepository();
    final existing = await repo.getUser();
    final entry = UserEntry(
      name: name,
      birthDate: birthDate ?? existing?.birthDate,
      primaryGoal: goal,
    );

    if (existing == null) {
      await repo.createUser(entry);
    } else {
      await repo.updateUser(entry);
    }
    await repo.setOnboardingComplete();
    await settings.applySettingsForGoal(goal);
    await MenstrudelInit.userService?.loadUser();
  }

}
