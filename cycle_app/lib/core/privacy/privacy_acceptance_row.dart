import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'consent_dialogs.dart';

/// Privacy policy + terms checkbox used before sign-in / sign-up.
class PrivacyAcceptanceRow extends StatelessWidget {
  const PrivacyAcceptanceRow({
    super.key,
    required this.accepted,
    required this.onChanged,
  });

  final bool accepted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxListTile(
          value: accepted,
          onChanged: (v) => onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            l10n.onboardingPrivacyAgree,
            style: theme.textTheme.bodySmall,
          ),
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          children: [
            TextButton(
              onPressed: openPrivacyPolicy,
              child: Text(l10n.privacyPolicyLink),
            ),
            Text('·', style: theme.textTheme.bodySmall),
            TextButton(
              onPressed: openTermsOfService,
              child: Text(l10n.termsOfServiceLink),
            ),
          ],
        ),
      ],
    );
  }
}
