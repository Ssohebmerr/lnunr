import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_design_tokens.dart';
import '../widgets/aura_scaffold.dart';
import 'consent_manager.dart';
import 'privacy_constants.dart';

/// Glass-styled consent bottom sheet used by all consent dialogs.
Future<bool> _showGlassConsentSheet({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String body,
  required String acceptLabel,
  String? cancelLabel,
}) async {
  final theme = Theme.of(context);

  final accepted = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => AppMeshBackground(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AuraDecorations.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppShadows.softRose(opacity: 0.2),
              ),
              child: Icon(icon, size: 26, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppGlassCard(
              onTap: () => Navigator.pop(ctx, true),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    acceptLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                cancelLabel ?? 'Cancel',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return accepted ?? false;
}

Future<bool> showCloudSyncConsentDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final accepted = await _showGlassConsentSheet(
    context: context,
    icon: Icons.cloud_upload_outlined,
    title: l10n.consentCloudTitle,
    body: l10n.consentCloudBody,
    acceptLabel: l10n.consentAccept,
    cancelLabel: l10n.cancel,
  );
  if (accepted) {
    await ConsentManager.setCloudSyncConsent(true);
    return true;
  }
  return false;
}

Future<bool> showAiConsentDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final accepted = await _showGlassConsentSheet(
    context: context,
    icon: Icons.auto_awesome_outlined,
    title: l10n.consentAiTitle,
    body: l10n.consentAiBody,
    acceptLabel: l10n.consentAccept,
    cancelLabel: l10n.cancel,
  );
  if (accepted) {
    await ConsentManager.setAiConsent(true);
    return true;
  }
  return false;
}

Future<bool> showCommunitiesConsentDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final accepted = await _showGlassConsentSheet(
    context: context,
    icon: Icons.people_outline,
    title: l10n.consentCommunityTitle,
    body: l10n.consentCommunityBody,
    acceptLabel: l10n.consentAccept,
    cancelLabel: l10n.cancel,
  );
  if (accepted) {
    await ConsentManager.setCommunitiesConsent(true);
    return true;
  }
  return false;
}

Future<void> openPrivacyPolicy() async {
  final uri = Uri.parse(PrivacyConstants.privacyPolicyUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openTermsOfService() async {
  final uri = Uri.parse(PrivacyConstants.termsOfServiceUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> openSupportEmail() async {
  final uri = PrivacyConstants.supportMailto;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
