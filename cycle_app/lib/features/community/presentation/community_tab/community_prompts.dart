import 'package:flutter/material.dart';

import '../../../../core/privacy/consent_dialogs.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/community_ui.dart';

class CommunityLoginPrompt extends StatelessWidget {
  const CommunityLoginPrompt({
    super.key,
    required this.l10n,
    required this.theme,
    required this.onSignIn,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.groups_rounded,
      title: l10n.communityTitle,
      subtitle: l10n.communityRequiresAccount,
      actionLabel: l10n.signInOptionalTitle,
      onAction: onSignIn,
    );
  }
}

class CommunityBirthYearOnlyPrompt extends StatelessWidget {
  const CommunityBirthYearOnlyPrompt({
    super.key,
    required this.l10n,
    required this.alias,
    required this.onSetup,
  });

  final AppLocalizations l10n;
  final String alias;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.cake_outlined,
      title: l10n.communityBirthYearLabel,
      subtitle:
          '${l10n.communityBirthYearWhy}\n\n${l10n.communityAliasLabel}: $alias',
      actionLabel: l10n.continueBtn,
      onAction: onSetup,
    );
  }
}

class CommunityProfileSetupPrompt extends StatelessWidget {
  const CommunityProfileSetupPrompt({
    super.key,
    required this.l10n,
    required this.onSetup,
  });

  final AppLocalizations l10n;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.badge_outlined,
      title: l10n.communitySetupTitle,
      subtitle: l10n.communitySetupSubtitle,
      actionLabel: l10n.communitySetupTitle,
      onAction: onSetup,
    );
  }
}

class CommunityConsentPrompt extends StatelessWidget {
  const CommunityConsentPrompt({
    super.key,
    required this.l10n,
    required this.theme,
    required this.onAccept,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CommunityEmptyState(
            icon: Icons.shield_outlined,
            title: l10n.consentCommunityTitle,
            subtitle: l10n.consentCommunityBody,
            actionLabel: l10n.consentAccept,
            onAction: onAccept,
          ),
        ),
        TextButton(
          onPressed: openPrivacyPolicy,
          child: Text(l10n.privacyPolicyLink),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class CommunityAdultsOnlyGate extends StatelessWidget {
  const CommunityAdultsOnlyGate({
    super.key,
    required this.l10n,
    required this.theme,
  });

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.lock_outline_rounded,
      title: l10n.communityAdultsOnlyTitle,
      subtitle: l10n.communityAdultsOnly,
    );
  }
}
