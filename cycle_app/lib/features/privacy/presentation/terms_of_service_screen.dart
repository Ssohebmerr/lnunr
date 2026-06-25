import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/privacy/privacy_constants.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.termsOfServiceLink),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 20),
            tooltip: l10n.privacyOpenExternal,
            onPressed: () async {
              final uri = Uri.parse(PrivacyConstants.termsOfServiceUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: AppMeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _PolicyHeader(
                icon: Icons.gavel_outlined,
                title: l10n.termsTitle,
                effectiveDate: PrivacyConstants.effectiveDate,
              ),
              const SizedBox(height: 20),
              _buildSection(theme, l10n.termsP1Title, l10n.termsP1Body),
              _buildSection(theme, l10n.termsP2Title, l10n.termsP2Body),
              _buildSection(theme, l10n.termsP3Title, l10n.termsP3Body),
              _buildSection(theme, l10n.termsP4Title, l10n.termsP4Body),
              _buildSection(theme, l10n.termsP5Title, l10n.termsP5Body),
              _buildSection(theme, l10n.termsP6Title, l10n.termsP6Body),
              _buildSection(theme, l10n.termsP7Title, l10n.termsP7Body),
              _buildSection(theme, l10n.termsP8Title, l10n.termsP8Body),
              _buildSection(theme, l10n.termsP9Title, l10n.termsP9Body),
              _buildSection(theme, l10n.termsP10Title, l10n.termsP10Body),
              _buildSection(theme, l10n.termsP11Title, l10n.termsP11Body),
              const SizedBox(height: 20),
              _ContactCard(l10n: l10n, theme: theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader({
    required this.icon,
    required this.title,
    required this.effectiveDate,
  });

  final IconData icon;
  final String title;
  final String effectiveDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.08),
            theme.colorScheme.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${l10n.privacyEffectiveDate}: $effectiveDate',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.l10n, required this.theme});

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.mail_outline, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                l10n.privacyContactTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyContactBody(PrivacyConstants.supportEmail),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
