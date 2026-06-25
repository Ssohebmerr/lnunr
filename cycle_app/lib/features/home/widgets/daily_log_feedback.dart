import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Floating snackbars for the daily log save / cancel flow.
class DailyLogFeedback {
  DailyLogFeedback._();

  static void showSaved(BuildContext context, AppLocalizations l10n) {
    _showMessenger(ScaffoldMessenger.of(context), context, l10n, saved: true);
  }

  static void showSavedOn(
    ScaffoldMessengerState messenger,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    _showMessenger(messenger, context, l10n, saved: true);
  }

  static void showDiscarded(BuildContext context, AppLocalizations l10n) {
    _showMessenger(ScaffoldMessenger.of(context), context, l10n, saved: false);
  }

  static void showError(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    messengerClearAndShow(
      ScaffoldMessenger.of(context),
      icon: Icons.error_outline,
      iconColor: Colors.red.shade700,
      title: l10n.errorGeneric,
      subtitle: l10n.logSaveFailedHint,
      theme: theme,
    );
  }

  static void _showMessenger(
    ScaffoldMessengerState messenger,
    BuildContext context,
    AppLocalizations l10n, {
    required bool saved,
  }) {
    final theme = Theme.of(context);
    messengerClearAndShow(
      messenger,
      icon: saved ? Icons.check_circle_outline : Icons.restart_alt_rounded,
      iconColor: saved ? Colors.green.shade700 : Colors.orange.shade800,
      title: saved ? l10n.logSaved : l10n.logChangesDiscarded,
      subtitle: saved ? l10n.logSavedHint : l10n.logChangesDiscardedHint,
      theme: theme,
    );
  }

  static void messengerClearAndShow(
    ScaffoldMessengerState messenger, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onInverseSurface
                          .withValues(alpha: 0.88),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
