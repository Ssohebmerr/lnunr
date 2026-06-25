import 'package:flutter/material.dart';

import '../../../../core/privacy/consent_dialogs.dart';
import '../../../../l10n/app_localizations.dart';

Future<void> showModerationRejectedDialog(
  BuildContext context, {
  required String reason,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.shield_outlined, color: Theme.of(ctx).colorScheme.error),
      title: Text(l10n.moderationRejectedTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.moderationRejectedBody),
            const SizedBox(height: 12),
            Text(
              reason,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.moderationRejectedTips,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            openSupportEmail();
          },
          child: Text(l10n.moderationContactSupport),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.moderationTryAgain),
        ),
      ],
    ),
  );
}
