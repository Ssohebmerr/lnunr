import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../../menstrudel_integration/menstrudel_init.dart';

/// Gates app content behind biometric authentication when enabled in settings.
class AppLockController extends ChangeNotifier {
  bool _locked = false;

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

  Future<bool> authenticateIfNeeded({String? localizedReason}) async {
    final settings = MenstrudelInit.settingsService;
    if (settings == null || !settings.areBiometricsEnabled) {
      unlock();
      return true;
    }

    final auth = LocalAuthentication();
    if (!await auth.isDeviceSupported()) {
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
  }
}
