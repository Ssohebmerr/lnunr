import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/privacy/privacy_constants.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../privacy/presentation/privacy_policy_screen.dart';
import '../../privacy/presentation/terms_of_service_screen.dart';
import '../../privacy/presentation/trust_hub_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: AppMeshBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppGlassCard(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AuraDecorations.primaryGradient,
                    ),
                    child: const Icon(Icons.spa, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(PrivacyConstants.appName,
                      style: theme.textTheme.headlineSmall),
                  if (_version.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.aboutVersion(_version),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.aboutTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppGlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
                    title: Text(l10n.trustHubLink),
                    subtitle: Text(l10n.trustHubSubtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TrustHubScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l10n.privacyPolicyLink),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l10n.termsOfServiceLink),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: Text(l10n.contactSupport),
                    subtitle: Text(PrivacyConstants.supportEmail),
                    onTap: () => openSupportEmail(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.privacyMedicalDisclaimer,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
