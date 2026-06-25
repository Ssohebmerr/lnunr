import 'package:firebase_auth/firebase_auth.dart';
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/locale/locale_cubit.dart';
import '../../../core/notifications/notification_prefs.dart';
import '../../../core/premium/premium_upsell_dialog.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/theme_cubit.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../../community/presentation/blocked_users_screen.dart';
import '../../cycle/data/cycle_sync_service.dart';
import '../../cycle/data/local_backup_service.dart';
import '../../cycle/presentation/cycle_settings_sheet.dart';
import '../../cycle/presentation/widget_language_picker.dart';
import '../../goals/presentation/goal_change_flow.dart';
import '../../home/widgets/account_menu_tile.dart';
import '../../privacy/presentation/privacy_center_screen.dart';
import '../../sync/data/cloud_sync_service.dart';

/// Language, backup, sync, cycle settings — opened from account hub.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _premium = false;
  bool _cloudSync = false;
  bool _communityNotif = true;
  UserGoalTypes _goal = UserGoalTypes.general;
  final _sync = CycleSyncService();
  final _syncService = CloudSyncService();
  final _localBackup = LocalBackupService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final p = await UserPrefs.isPremium();
    final syncPref = prefs.getBool('cloud_sync_enabled') ?? false;
    final syncConsent = await ConsentManager.hasCloudSyncConsent();
    final communityNotif = await NotificationPrefs.communityEnabled();
    final goal = await _sync.getUserGoal();
    if (mounted) {
      setState(() {
        _premium = p;
        _cloudSync = syncPref && syncConsent;
        _communityNotif = communityNotif;
        _goal = goal;
      });
    }
  }

  String _goalLabel(AppLocalizations l10n) =>
      GoalChangeFlow.labelFor(context, _goal);

  Future<void> _changeGoal() async {
    final picked = await GoalChangeFlow.run(context, current: _goal, sync: _sync);
    if (picked == null || !mounted) return;
    setState(() => _goal = picked);
  }

  Future<void> _restoreCloud() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_premium) {
      await showPremiumUpsellDialog(context, feature: PremiumUpsellFeature.cloud);
      return;
    }
    final ok = await _syncService.restoreLatest();
    if (ok) await CycleSyncService().onCycleDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? l10n.syncSuccess : l10n.syncFailed)),
      );
    }
  }

  Future<void> _syncNow() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_premium) {
      await showPremiumUpsellDialog(context, feature: PremiumUpsellFeature.cloud);
      return;
    }
    final ok = await _syncService.syncBackup();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? l10n.syncSuccess : l10n.syncFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final themeCubit = context.watch<ThemeCubit>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountMenuSettings),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: AppMeshBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AccountMenuCard(
                children: [
                  AccountMenuTile(
                    icon: Icons.language_rounded,
                    title: l10n.language,
                    trailing: Text(
                      context.watch<LocaleCubit>().isArabic ? 'AR' : 'EN',
                      style: theme.textTheme.labelLarge,
                    ),
                    onTap: () => context.read<LocaleCubit>().toggle(),
                  ),
                  AccountMenuTile(
                    icon: Icons.palette_outlined,
                    title: l10n.theme,
                    trailing: Text(
                      switch (themeCubit.mode) {
                        AppThemeMode.light => l10n.themeLight,
                        AppThemeMode.dark => l10n.themeDark,
                        AppThemeMode.system => l10n.themeSystem,
                      },
                      style: theme.textTheme.labelLarge,
                    ),
                    onTap: () => context.read<ThemeCubit>().cycle(),
                  ),
                  AccountMenuTile(
                    icon: Icons.tune_rounded,
                    title: l10n.cycleSettingsTitle,
                    subtitle: l10n.cycleSettingsSubtitle,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final updated = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => const CycleSettingsSheet(),
                      );
                      if (updated == true && mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.syncSuccess)),
                        );
                      }
                    },
                  ),
                  AccountMenuTile(
                    icon: Icons.widgets_outlined,
                    title: l10n.widgetLanguageLabel,
                    showDivider: false,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: WidgetLanguagePicker(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AccountMenuCard(
                children: [
                  AccountMenuTile(
                    icon: Icons.upload_file_rounded,
                    title: l10n.accountExportBackup,
                    onTap: () => _localBackup.exportAndShare(),
                  ),
                  AccountMenuTile(
                    icon: Icons.download_rounded,
                    title: l10n.accountImportBackup,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await _localBackup.importFromFile();
                      if (ok) await CycleSyncService().onCycleDataChanged();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? l10n.syncSuccess : l10n.syncFailed,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  if (user != null)
                    AccountMenuTile(
                      icon: Icons.cloud_download_rounded,
                      title: l10n.accountRestoreCloud,
                      onTap: _restoreCloud,
                    ),
                  AccountMenuTile(
                    icon: Icons.cloud_upload_outlined,
                    title: l10n.cloudSyncEnable,
                    subtitle: l10n.cloudSync,
                    trailing: Switch(
                      value: _cloudSync,
                      onChanged: user == null
                          ? null
                          : (v) async {
                              if (v) {
                                if (!_premium) {
                                  await showPremiumUpsellDialog(
                                    context,
                                    feature: PremiumUpsellFeature.cloud,
                                  );
                                  return;
                                }
                                final ok =
                                    await showCloudSyncConsentDialog(context);
                                if (!ok) return;
                              } else {
                                await ConsentManager.setCloudSyncConsent(false);
                              }
                              setState(() => _cloudSync = v);
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('cloud_sync_enabled', v);
                              if (v) await _syncNow();
                            },
                    ),
                    showDivider: user != null,
                  ),
                  if (user != null)
                    AccountMenuTile(
                      icon: Icons.sync_rounded,
                      title: l10n.syncNow,
                      showDivider: false,
                      onTap: _syncNow,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (user != null)
                AccountMenuCard(
                  children: [
                    AccountMenuTile(
                      icon: Icons.block_outlined,
                      title: l10n.accountBlockedUsers,
                      subtitle: l10n.communityBlockedUsersSubtitle,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BlockedUsersScreen(),
                        ),
                      ),
                    ),
                    AccountMenuTile(
                      icon: Icons.notifications_active_outlined,
                      title: l10n.communityNotifTitle,
                      subtitle: l10n.communityNotifSubtitle,
                      showDivider: false,
                      trailing: Switch(
                        value: _communityNotif,
                        onChanged: (v) async {
                          setState(() => _communityNotif = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(NotificationPrefs.communityKey, v);
                        },
                      ),
                    ),
                  ],
                ),
              if (user != null) const SizedBox(height: 12),
              AccountMenuCard(
                children: [
                  AccountMenuTile(
                    icon: Icons.flag_outlined,
                    title: l10n.accountChangeGoal,
                    subtitle: _goalLabel(l10n),
                    onTap: _changeGoal,
                  ),
                  AccountMenuTile(
                    icon: Icons.restart_alt_rounded,
                    title: l10n.accountRerunSetup,
                    subtitle: l10n.accountRerunSetupSubtitle,
                    showDivider: false,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.rerunSetupConfirmTitle),
                          content: Text(l10n.rerunSetupConfirmBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: Text(l10n.rerunSetupConfirmCancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: Text(l10n.rerunSetupConfirmYes),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await UserPrefs.clearOnboardingDone();
                        if (context.mounted) context.go('/onboarding');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AccountMenuCard(
                children: [
                  AccountMenuTile(
                    icon: Icons.shield_outlined,
                    title: l10n.privacyTitle,
                    subtitle: l10n.privacyBody,
                    showDivider: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PrivacyCenterScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
