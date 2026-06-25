import 'package:flutter/foundation.dart';

import '../storage/user_prefs.dart';

/// App-wide premium flag — kept in sync with Firestore `users/{uid}.isPremium`.
class PremiumStatusNotifier extends ChangeNotifier {
  PremiumStatusNotifier._();

  static final PremiumStatusNotifier instance = PremiumStatusNotifier._();

  bool _isPremium = false;

  bool get isPremium => _isPremium;

  Future<void> loadFromPrefs() async {
    final value = await UserPrefs.isPremium();
    _set(value, persist: false);
  }

  Future<void> applyRemote(bool value) async {
    await UserPrefs.setPremium(value);
    _set(value, persist: false);
  }

  void _set(bool value, {required bool persist}) {
    if (_isPremium == value) return;
    _isPremium = value;
    if (persist) {
      UserPrefs.setPremium(value);
    }
    notifyListeners();
  }
}
