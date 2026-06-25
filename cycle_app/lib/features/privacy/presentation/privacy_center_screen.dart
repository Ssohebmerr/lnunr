import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/privacy/consent_data_service.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/privacy/privacy_constants.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/data_deletion_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _cloudSync = false;
  bool _ai = false;
  bool _communities = false;
  bool _loading = true;
  bool _purging = false;
  final _consentData = ConsentDataService();

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    final cloud = await ConsentManager.hasCloudSyncConsent();
    final ai = await ConsentManager.hasAiConsent();
    final communities = await ConsentManager.hasCommunitiesConsent();
    if (mounted) {
      setState(() {
        _cloudSync = cloud;
        _ai = ai;
        _communities = communities;
        _loading = false;
      });
    }
  }

  Future<void> _revokeCloudSync(bool value) async {
    if (!value) {
      final ok = await _confirmRevoke();
      if (!ok) return;
      setState(() => _purging = true);
      try {
        await _consentData.purgeCloudBackups();
      } finally {
        if (mounted) setState(() => _purging = false);
      }
    }
    await ConsentManager.setCloudSyncConsent(value);
    if (!value) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cloud_sync_enabled', false);
    }
    if (mounted) {
      setState(() => _cloudSync = value);
      if (!value) _showPurgedSnackBar();
    }
  }

  Future<bool> _confirmRevoke() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.consentRevokeTitle),
            content: Text(l10n.consentRevokeBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n.consentRevokeConfirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showPurgedSnackBar() {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.consentDataPurged)),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await DataDeletionService().deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.deleteAccountDone)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        final message = e is AccountDeletionReauthRequired
            ? l10n.deleteAccountReauth
            : l10n.deleteAccountFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.privacyCenterTitle),
      ),
      body: AppMeshBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(l10n.privacyTitle, style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.privacyCenterIntro, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionTitle(l10n.privacyDataLocal),
            _Bullet(l10n.privacyBulletLocal),
            _Bullet(l10n.privacyBulletEncrypt),
            const SizedBox(height: 12),
            _SectionTitle(l10n.privacyDataOptional),
            _Bullet(l10n.privacyBulletCloud),
            _Bullet(l10n.privacyBulletAi),
            _Bullet(l10n.privacyBulletCommunity),
            const SizedBox(height: 12),
            _SectionTitle(l10n.privacyDataNotCollected),
            _Bullet(l10n.privacyBulletNoSell),
            _Bullet(l10n.privacyBulletNoTrack),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else
              AppGlassCard(
                child: Column(
                  children: [
                    Text(l10n.consentManageTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(l10n.consentManageBody, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.cloudSync),
                      subtitle: Text(l10n.consentCloudTitle),
                      value: _cloudSync,
                      onChanged: _purging ? null : _revokeCloudSync,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.consentAiTitle),
                      value: _ai,
                      onChanged: _purging
                          ? null
                          : (v) async {
                              if (!v) {
                                final ok = await _confirmRevoke();
                                if (!ok) return;
                                setState(() => _purging = true);
                                try {
                                  await _consentData.purgeAiChats();
                                } finally {
                                  if (mounted) setState(() => _purging = false);
                                }
                              }
                              await ConsentManager.setAiConsent(v);
                              if (mounted) {
                                setState(() => _ai = v);
                                if (!v) _showPurgedSnackBar();
                              }
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.consentCommunityTitle),
                      value: _communities,
                      onChanged: _purging
                          ? null
                          : (v) async {
                              if (!v) {
                                final ok = await _confirmRevoke();
                                if (!ok) return;
                                setState(() => _purging = true);
                                try {
                                  await _consentData.purgeCommunityPresence();
                                } finally {
                                  if (mounted) setState(() => _purging = false);
                                }
                              }
                              await ConsentManager.setCommunitiesConsent(v);
                              if (mounted) {
                                setState(() => _communities = v);
                                if (!v) _showPurgedSnackBar();
                              }
                            },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            AppGlassCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.policy_outlined),
                    title: Text(l10n.privacyPolicyLink),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.gavel_outlined),
                    title: Text(l10n.termsOfServiceLink),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.mail_outline),
                    title: Text(l10n.contactSupport),
                    subtitle: Text(PrivacyConstants.supportEmail),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: openSupportEmail,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                    title: Text(l10n.deleteAccountTitle),
                    subtitle: Text(l10n.deleteAccountSubtitle),
                    onTap: () => _deleteAccount(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyMedicalDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
