import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_lock_controller.dart';

/// Full-screen shield shown while the app awaits biometric unlock.
class AppLockOverlay extends StatelessWidget {
  const AppLockOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockController>(
      builder: (context, lock, _) {
        return Stack(
          children: [
            child,
            if (lock.isLocked)
              Positioned.fill(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 56,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _title(context),
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _subtitle(context),
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            FilledButton.icon(
                              onPressed: () => lock.authenticateIfNeeded(
                                localizedReason: _reason(context),
                              ),
                              icon: const Icon(Icons.fingerprint),
                              label: Text(_button(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static bool _isAr(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }

  static String _title(BuildContext context) =>
      _isAr(context) ? 'التطبيق مقفل' : 'App locked';

  static String _subtitle(BuildContext context) => _isAr(context)
      ? 'استخدمي بصمة الإصبع أو رمز الجهاز لفتح Lune.'
      : 'Use your fingerprint or device passcode to open Lune.';

  static String _button(BuildContext context) =>
      _isAr(context) ? 'فتح القفل' : 'Unlock';

  static String _reason(BuildContext context) => _isAr(context)
      ? 'افتحي Lune للمتابعة'
      : 'Unlock Lune to continue';
}
