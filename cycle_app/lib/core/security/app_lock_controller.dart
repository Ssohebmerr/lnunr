import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../menstrudel_integration/menstrudel_init.dart';

/// Gates app content behind biometric authentication when enabled in settings.
class AppLockController extends ChangeNotifier {
  bool _locked = false;

  /// Guards against overlapping prompts: the system sheet backgrounds the app,
  /// which fires a lifecycle `resumed` that would otherwise start a second
  /// authenticate while the first is still showing (`auth_in_progress`).
  bool _authInFlight = false;

  bool get isLocked => _locked;

  void lock() {
    if (_locked) return;
    _locked = true;
    notifyListeners();
  }

  void unlock() {
    if (!_locked) return;
    _locked = false;
    notifyListeners();
  }

  /// Whether this device can actually show an unlock prompt (biometric or
  /// device credential). Used by the settings toggle before enabling.
  static Future<bool> isDeviceSupported() async {
    try {
      return await LocalAuthentication().isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateIfNeeded({String? localizedReason}) async {
    final settings = MenstrudelInit.settingsService;
    if (settings == null || !settings.areBiometricsEnabled) {
      unlock();
      return true;
    }

    // Already open — never re-prompt. Without this, the lifecycle `resumed`
    // that follows a successful unlock kicked off another prompt, looping
    // the fingerprint sheet forever.
    if (!_locked) return true;

    if (_authInFlight) return false;
    _authInFlight = true;
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) {
        // No biometric AND no device credential left — never brick the app.
        unlock();
        return true;
      }

      final ok = await auth.authenticate(
        localizedReason: localizedReason ?? 'Unlock Lune to continue',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
      if (ok) unlock();
      return ok;
    } on PlatformException catch (e) {
      // Canceled sheet, lockout after failed tries, etc. — stay locked; the
      // overlay's Unlock button lets the user retry.
      debugPrint('[AppLock] authenticate failed: ${e.code} ${e.message}');
      return false;
    } finally {
      _authInFlight = false;
    }
  }
}
