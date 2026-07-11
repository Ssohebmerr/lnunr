import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/profile/local_profile.dart';
import '../../../core/storage/user_prefs.dart';
import 'guest_user_repository.dart';

/// Ensures a stable device id + Firebase anonymous session and syncs profile.
class GuestUserService {
  GuestUserService({
    FirebaseAuth? auth,
    GuestUserRepository? repository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _repository = repository ?? GuestUserRepository();

  final FirebaseAuth _auth;
  final GuestUserRepository _repository;

  /// Returns Firebase Auth uid when online; otherwise last cached uid or device id.
  Future<String> ensureSession() async {
    await UserPrefs.getOrCreateDeviceId();
    var user = _auth.currentUser;
    if (user != null) {
      await UserPrefs.saveUid(user.uid);
      return user.uid;
    }

    final cachedUid = await UserPrefs.getUid();
    if (cachedUid != null && cachedUid.isNotEmpty) {
      return cachedUid;
    }

    try {
      final cred = await _auth.signInAnonymously().timeout(
        const Duration(seconds: 5),
      );
      user = cred.user;
    } catch (e, st) {
      debugPrint('GuestUserService signInAnonymously failed (offline?): $e\n$st');
    }

    if (user != null) {
      await UserPrefs.saveUid(user.uid);
      return user.uid;
    }

    // Offline: local device id is enough for cycle tracking on this phone.
    final deviceId = await UserPrefs.getOrCreateDeviceId();
    await UserPrefs.saveUid(deviceId);
    return deviceId;
  }

  Future<String> getDeviceId() => UserPrefs.getOrCreateDeviceId();

  /// Creates or updates Firestore `users/{uid}` after onboarding.
  Future<void> registerProfile({
    required String name,
    DateTime? birthDate,
  }) async {
    final uid = await ensureSession();
    final deviceId = await getDeviceId();
    final trimmed = name.trim().isEmpty ? 'User' : name.trim();

    if (birthDate != null) {
      await UserPrefs.setProfileBirthDate(birthDate);
    }

    final existing = await _repository.fetch(uid);
    if (existing == null) {
      await _repository.createProfile(
        uid: uid,
        name: trimmed,
        birthDate: birthDate,
        deviceId: deviceId,
      );
    } else {
      await _repository.updateProfile(
        uid: uid,
        name: trimmed,
        birthDate: birthDate ?? existing.birthDate,
        deviceId: deviceId,
      );
    }
  }

  /// Saves the handle locally, then best-effort to Firestore (offline-safe).
  Future<void> saveUsername(String username) async {
    final normalized = LocalProfile.normalizeUsername(username);
    await LocalProfile.saveUsername(normalized);
    try {
      final uid = await ensureSession();
      await _repository.saveUsername(uid: uid, username: normalized);
    } catch (e) {
      debugPrint('GuestUserService saveUsername: $e');
    }
  }

  /// Local handle first; falls back to Firestore, then generates a default.
  Future<String> resolveUsername() async {
    final local = await LocalProfile.username();
    if (local != null && local.isNotEmpty) return local;

    final uid = _auth.currentUser?.uid ?? await UserPrefs.getUid();
    if (uid != null && uid.isNotEmpty) {
      try {
        final remote = (await _repository.fetch(uid))?.username?.trim();
        if (remote != null && remote.isNotEmpty) {
          await LocalProfile.saveUsername(remote);
          return remote;
        }
      } catch (_) {}
    }

    final generated = await LocalProfile.ensureUsername(uid: uid);
    if (uid != null && uid.isNotEmpty) {
      try {
        await _repository.saveUsername(uid: uid, username: generated);
      } catch (_) {}
    }
    return generated;
  }

  /// Best-effort sync for returning users who already finished onboarding.
  Future<void> syncLocalProfileIfNeeded() async {
    if (!await UserPrefs.isOnboardingDone()) return;

    final name = await UserPrefs.getProfileName();
    if (name == null || name.trim().isEmpty) return;

    final birthDate = await UserPrefs.getProfileBirthDate();

    try {
      await registerProfile(name: name, birthDate: birthDate);
    } catch (e, st) {
      debugPrint('GuestUserService syncLocalProfileIfNeeded: $e\n$st');
    }
  }
}
