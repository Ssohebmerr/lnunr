import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  /// Returns Firebase Auth uid (anonymous when no email account).
  Future<String> ensureSession() async {
    await UserPrefs.getOrCreateDeviceId();
    var user = _auth.currentUser;
    if (user == null) {
      try {
        final cred = await _auth.signInAnonymously();
        user = cred.user;
      } catch (e, st) {
        debugPrint('GuestUserService signInAnonymously failed: $e\n$st');
        rethrow;
      }
    }
    if (user == null) {
      throw StateError('Anonymous sign-in returned no user');
    }
    await UserPrefs.saveUid(user.uid);
    return user.uid;
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
