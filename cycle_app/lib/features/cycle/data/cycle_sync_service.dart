import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/notifications/notification_service.dart';
import '../../user/data/guest_user_service.dart';
import '../../../core/security/cycle_encryption_keys.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../menstrudel_integration/menstrudel_init.dart';
import '../../../menstrudel/models/app/user_entry.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../../menstrudel/database/repositories/user_repository.dart';
import '../../../menstrudel/services/widget_controller.dart';
import 'cycle_bridge_service.dart';
import 'period_bridge_service.dart';

/// Central orchestrator — keeps cycle data, profile, wellness, AI, and UI in sync.
///
/// TWO-STORE ARCHITECTURE (intentional — not a bug):
/// The app keeps two on-device stores that own DIFFERENT data domains:
///   1. `menstrual_cycle_widget` (encrypted): the prediction engine + period &
///      symptom logs (ovulation, fertile window, next-period math, cloud backup).
///   2. `menstrudel` (sqflite): the Wellness Hub — pills, sanitary products, sex,
///      LARC — plus its own period logs used by daily logs and the smartwatch.
///
/// They overlap ONLY on bleeding days. [PeriodBridgeService] is the SINGLE
/// boundary where the two stores are reconciled. Never mirror period data
/// between the stores anywhere else — always route through that bridge so the
/// re-entrancy guard and equality checks keep the two sides from ping-ponging.
///
/// Direction wiring:
///   • widget → menstrudel: [onCycleDataChanged] (this class).
///   • menstrudel → widget: `DataRefreshCoordinator.onLogsSynced` (set up in
///     `menstrudel_providers.dart`).
class CycleSyncService {
  CycleSyncService({CycleBridgeService? bridge})
      : _bridge = bridge ?? CycleBridgeService();

  final CycleBridgeService _bridge;

  static const _syncTimeout = Duration(seconds: 15);

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _ensureCycleWidgetReady() async {
    if (MenstrualCycleWidget.instance != null) return;
    final keys = await CycleEncryptionKeys.loadOrCreate();
    MenstrualCycleWidget.init(
      secretKey: keys['secretKey'],
      ivKey: keys['ivKey'],
    );
  }

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
    final name = displayName.trim().isEmpty ? 'User' : displayName.trim();

    // Persist consent + onboarding completion first so the user can always
    // enter the app even if cycle DB sync fails on this device.
    await ConsentManager.acceptPrivacyPolicy();
    await UserPrefs.setProfile(name: name, goal: goal.dbName);
    await UserPrefs.setOnboardingDone();
    await _applyGoalSettings(goal);

    await _ensureCycleWidgetReady();
    try {
      await _bridge.configure(
        cycleLength: cycleLength,
        periodDuration: periodDuration,
        lastPeriodDate: _dateOnly(lastPeriodDate),
        languageCode: languageCode,
        dateFormat: dateFormat,
      );
    } catch (e, st) {
      debugPrint('Cycle bridge configure failed (non-fatal): $e\n$st');
    }

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

    if (birthDate != null) {
      try {
        await GuestUserService().registerProfile(
          name: name,
          birthDate: birthDate,
        );
      } catch (e, st) {
        debugPrint('Guest user Firestore sync failed (non-fatal): $e\n$st');
      }
    }
  }

  /// Update cycle configuration from settings — propagates everywhere.
  /// Returns `true` when the cycle store accepted the new dates.
  Future<bool> updateCycleConfig({
    required int cycleLength,
    required int periodDuration,
    required DateTime lastPeriodDate,
    required String languageCode,
    DateFormats dateFormat = DateFormats.dmy,
  }) async {
    await _ensureCycleWidgetReady();
    try {
      await _bridge.configure(
        cycleLength: cycleLength,
        periodDuration: periodDuration,
        lastPeriodDate: _dateOnly(lastPeriodDate),
        languageCode: languageCode,
        dateFormat: dateFormat,
      );
    } catch (e, st) {
      debugPrint('updateCycleConfig bridge configuration failed: $e\n$st');
      return false;
    }
    try {
      await onCycleDataChanged().timeout(_syncTimeout);
    } catch (e, st) {
      debugPrint('updateCycleConfig onCycleDataChanged failed: $e\n$st');
    }
    return true;
  }

  /// Call after any cycle log, backup import, or cloud restore.
  Future<void> onCycleDataChanged() async {
    // Mirror widget period days into the Menstrudel store.
    try {
      final bridge = PeriodBridgeService.instance;
      final menstrudelChanged = await bridge.syncWidgetToMenstrudel();
      if (menstrudelChanged) {
        await bridge.onMenstrudelDataChanged?.call();
      }
    } catch (e, st) {
      debugPrint('syncWidgetToMenstrudel failed (non-fatal): $e\n$st');
    }

    try {
      await NotificationService.scheduleFromPrefs();
    } catch (e, st) {
      debugPrint('scheduleFromPrefs failed (non-fatal): $e\n$st');
    }

    try {
      await syncHomeWidget();
    } catch (e, st) {
      debugPrint('syncHomeWidget failed (non-fatal): $e\n$st');
    }

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
    final cached = await UserPrefs.getProfileGoal();
    UserGoalTypes? prefsGoal;
    if (cached != null && cached.isNotEmpty) {
      prefsGoal = UserGoalTypes.fromDbName(cached);
    }

    final userService = MenstrudelInit.userService;
    final dbGoal = userService?.user?.primaryGoal;

    // UserPrefs is written by onboarding + settings — treat it as source of truth.
    if (prefsGoal != null) {
      if (dbGoal != prefsGoal) {
        unawaited(_reconcileGoalToMenstrudel(prefsGoal));
      }
      return prefsGoal;
    }

    if (dbGoal != null) return dbGoal;
    return UserGoalTypes.general;
  }

  Future<void> _applyGoalSettings(UserGoalTypes goal) async {
    final settings = MenstrudelInit.settingsService;
    if (settings != null) {
      await settings.applySettingsForGoal(goal);
    }
    HomeRefreshScope.refresh();
  }

  Future<void> _reconcileGoalToMenstrudel(UserGoalTypes goal) async {
    try {
      final settings = MenstrudelInit.settingsService;
      final userService = MenstrudelInit.userService;
      if (settings == null) return;

      if (userService?.user != null) {
        if (userService!.user!.primaryGoal == goal) {
          await settings.applySettingsForGoal(goal);
          return;
        }
        await userService.setPrimaryGoal(goal, settings);
        return;
      }

      final repo = UserRepository();
      final existing = await repo.getUser();
      if (existing != null) {
        final updated = existing.copyWith(primaryGoal: goal);
        await repo.updateUser(updated);
        await settings.applySettingsForGoal(goal);
        await userService?.loadUser();
      } else {
        await settings.applySettingsForGoal(goal);
      }
    } catch (e, st) {
      debugPrint('Goal reconcile failed (non-fatal): $e\n$st');
    }
  }

  /// Switch primary goal — home, reports, self-care, and AI refresh immediately.
  Future<void> setUserGoal(UserGoalTypes goal) async {
    final name = await getDisplayName();
    await UserPrefs.setProfile(name: name, goal: goal.dbName);
    await _applyGoalSettings(goal);

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
