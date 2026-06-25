import 'package:flutter/material.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../l10n/app_localizations.dart';

/// Shows a friendly rationale before the OS notification permission prompt.
/// Returns true if the user tapped "Allow", false otherwise.
Future<bool> showNotificationRationale(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final theme = Theme.of(context);

  final allow = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.notifications_active_outlined,
              color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(l10n.notifRationaleTitle),
        ],
      ),
      content: Text(
        l10n.notifRationaleBody,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.notifRationaleSkip),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.notifRationaleAllow),
        ),
      ],
    ),
  );

  if (allow == true) {
    return await NotificationService.requestPermission();
  }
  return false;
}
