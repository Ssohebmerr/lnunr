import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/privacy/consent_data_service.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/privacy/privacy_constants.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/data_deletion_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'trust_hub_screen.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({super.key});

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  bool _cloudSync = false;
  bool _ai = false;
  bool _communities = false;
  bool _stealthMode = false;
  bool _loading = true;
  bool _purging = false;
  final _consentData = ConsentDataService();

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _exportLocalData() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final db = await MenstrualCycleDbHelper.instance.database;
      final List<Map<String, dynamic>> allRows = await db!.query(
        'tblDailyLogs',
      );

      final p = await SharedPreferences.getInstance();
      final Map<String, dynamic> prefsMap = {};
      for (final key in p.getKeys()) {
        if (key == 'uid' ||
            key.contains('token') ||
            key.contains('fcm') ||
            key.contains('key') ||
            key == 'stealth_mode_pin' ||
            key == 'cycle_secret_key' ||
            key == 'cycle_iv_key' ||
            key == 'stealth_pin_hash' ||
            key == 'stealth_pin_salt') {
          continue;
        }
        final val = p.get(key);
        if (val is String ||
            val is int ||
            val is double ||
            val is bool ||
            val is List<String>) {
          prefsMap[key] = val;
        }
      }

      final backupData = {
        'version': 1,
        'dailyLogs': allRows,
        'preferences': prefsMap,
      };

      final jsonStr = jsonEncode(backupData);
      await Clipboard.setData(ClipboardData(text: jsonStr));

      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isAr ? 'تم تصدير البيانات' : 'Data Exported'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isAr
                        ? 'تم نسخ رمز النسخة الاحتياطية بنجاح إلى الحافظة. يمكنك حفظه في مكان آمن لاستعادته لاحقاً.'
                        : 'Backup code copied to clipboard successfully. You can save it somewhere safe to restore later.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    constraints: const BoxConstraints(maxHeight: 120),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        jsonStr,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'موافق' : 'OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'فشل تصدير البيانات: $e' : 'Export failed: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _importLocalData() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final inputController = TextEditingController();

    final String? pasteStr = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'استيراد البيانات' : 'Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAr
                  ? 'ألصق رمز النسخة الاحتياطية الذي قمت بتصديره سابقاً لتتم استعادتها.'
                  : 'Paste the backup code you exported earlier to restore your data.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: inputController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: isAr
                    ? 'ألصق الرمز هنا...'
                    : 'Paste backup code here...',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, inputController.text.trim());
            },
            child: Text(isAr ? 'استيراد' : 'Import'),
          ),
        ],
      ),
    );

    if (pasteStr == null || pasteStr.isEmpty) return;

    try {
      final Map<String, dynamic> decoded = jsonDecode(pasteStr);
      final List<dynamic>? logs = decoded['dailyLogs'];
      final Map<String, dynamic>? prefs = decoded['preferences'];

      if (logs == null) {
        throw Exception('No dailyLogs key found');
      }

      final db = await MenstrualCycleDbHelper.instance.database;
      await db!.transaction((txn) async {
        await txn.delete('tblDailyLogs');
        for (final row in logs) {
          if (row is Map<String, dynamic>) {
            await txn.insert('tblDailyLogs', row);
          }
        }
      });

      if (prefs != null) {
        final p = await SharedPreferences.getInstance();
        for (final key in prefs.keys) {
          final val = prefs[key];
          if (val is bool) {
            await p.setBool(key, val);
          } else if (val is int) {
            await p.setInt(key, val);
          } else if (val is double) {
            await p.setDouble(key, val);
          } else if (val is String) {
            await p.setString(key, val);
          } else if (val is List) {
            await p.setStringList(key, List<String>.from(val));
          }
        }
      }

      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(isAr ? 'تم استيراد البيانات' : 'Data Imported'),
            content: Text(
              isAr
                  ? 'تمت استعادة البيانات والخيارات بنجاح. يرجى إعادة تشغيل التطبيق لتطبيق كافة التغييرات.'
                  : 'Data and preferences successfully restored. Please restart the app to apply all changes.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadConsents();
                },
                child: Text(isAr ? 'موافق' : 'OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(isAr ? 'خطأ في الاستيراد' : 'Import Error'),
            content: Text(
              isAr
                  ? 'رمز النسخة الاحتياطية غير صالح أو تالف. يرجى التأكد من نسخ الرمز بالكامل.'
                  : 'The backup code is invalid or corrupted. Please make sure you copied the entire code.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'موافق' : 'OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _loadConsents() async {
    final cloud = await ConsentManager.hasCloudSyncConsent();
    final ai = await ConsentManager.hasAiConsent();
    final communities = await ConsentManager.hasCommunitiesConsent();
    final stealth = await UserPrefs.isStealthModeEnabled();
    if (mounted) {
      setState(() {
        _cloudSync = cloud;
        _ai = ai;
        _communities = communities;
        _stealthMode = stealth;
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.consentDataPurged)));
  }

  Future<String?> _showPinDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.stealthSetPin),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.stealthPinHint),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.stealthPin,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.stealthConfirmPin,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.stealthCancel),
          ),
          FilledButton(
            onPressed: () {
              final pin = pinController.text;
              final confirm = confirmController.text;
              if (pin.length >= 4 && pin == confirm) {
                Navigator.pop(ctx, pin);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(l10n.stealthPinMismatch)),
                );
              }
            },
            child: Text(l10n.stealthSave),
          ),
        ],
      ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        final message = e is AccountDeletionReauthRequired
            ? l10n.deleteAccountReauth
            : l10n.deleteAccountFailed;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.privacyCenterTitle),
      ),
      body: AppMeshBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            16,
          ),
          children: [
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.privacyTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.privacyCenterIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              AppGlassCard(
                child: Column(
                  children: [
                    Text(
                      l10n.consentManageTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.consentManageBody,
                      style: theme.textTheme.bodySmall,
                    ),
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
                                  await _consentData.purgeAiData();
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

            // Stealth Mode
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.stealthTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.stealthDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.stealthEnable),
                    value: _stealthMode,
                    onChanged: (v) async {
                      if (v) {
                        final messenger = ScaffoldMessenger.of(context);
                        final pin = await _showPinDialog();
                        if (pin == null || pin.length < 4) return;
                        await UserPrefs.setStealthModePin(pin);
                        await UserPrefs.setStealthModeEnabled(true);
                        if (!mounted) return;
                        setState(() => _stealthMode = true);
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.stealthActivated)),
                        );
                      } else {
                        await UserPrefs.setStealthModeEnabled(false);
                        if (mounted) setState(() => _stealthMode = false);
                      }
                    },
                  ),
                  if (_stealthMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.stealthUnlockHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Quick emergency hide — instantly shows the calculator.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push('/stealth'),
                        icon: const Icon(Icons.visibility_off_rounded),
                        label: Text(l10n.stealthHideNow),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.stealthHideNowHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Local Backup & Restore
            Builder(
              builder: (context) {
                final isAr =
                    Localizations.localeOf(context).languageCode == 'ar';
                return AppGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.backup_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAr
                                ? 'النسخ الاحتياطي المحلي'
                                : 'Local Backup & Restore',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'قم بتصدير أو استيراد بيانات دورتك وعافيتك محلياً بشكل آمن وبخصوصية تامة.'
                            : 'Export or import your cycle and wellness data locally. Your data remains fully private.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _exportLocalData,
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 18,
                              ),
                              label: Text(
                                isAr ? 'تصدير البيانات' : 'Export Data',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importLocalData,
                              icon: const Icon(Icons.upload_rounded, size: 18),
                              label: Text(
                                isAr ? 'استيراد البيانات' : 'Import Data',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            AppGlassCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: Text(l10n.trustHubLink),
                subtitle: Text(
                  l10n.trustHubSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TrustHubScreen(),
                  ),
                ),
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
                    onTap: () => openSupportEmail(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: theme.colorScheme.error,
                    ),
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
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
