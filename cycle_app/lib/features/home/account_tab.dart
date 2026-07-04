import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../profile/presentation/profile_edit_sheet.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/premium/premium_badge.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../admin/data/admin_repository.dart';
import '../admin/presentation/admin_screen.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../../../core/premium/premium_activation_service.dart';
import '../../../core/premium/play_billing_coordinator.dart';
import '../user/data/guest_user_service.dart';
import '../user/data/guest_user_repository.dart';
import '../education/presentation/education_hub_page.dart';
import '../partner/presentation/partner_page.dart';
import '../settings/presentation/about_screen.dart';
import '../settings/presentation/ai_diagnostic_screen.dart';
import '../support/presentation/support_sheet.dart';
import '../../core/widgets/feminine_icon.dart';
import '../settings/presentation/account_reminders_sheet.dart';
import '../settings/presentation/account_settings_screen.dart';
import 'insights_tab.dart';
import 'sub_feature_page.dart';
import 'widgets/account_menu_tile.dart';

import '../../menstrudel/services/period_service.dart';

bool _hasEmailAccount(User? user) {
  if (user == null) return false;
  final email = user.email?.trim();
  return email != null && email.isNotEmpty && !user.isAnonymous;
}

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool _premium = false;
  bool _notifications = true;
  String _localName = 'Guest';
  int _avatarIndex = 0;
  String? _photoPath;
  String? _photoUrl;
  String? _accountUid;
  String? _deviceId;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    HomeShellActions.openReminders = _openRemindersFromDeepLink;
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    _loadAll();
    HomeRefreshScope.notifier.addListener(_onHomeRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdmin();
    });
  }

  @override
  void dispose() {
    if (HomeShellActions.openReminders == _openRemindersFromDeepLink) {
      HomeShellActions.openReminders = null;
    }
    HomeRefreshScope.notifier.removeListener(_onHomeRefresh);
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onHomeRefresh() => _loadAll();

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() => _premium = PremiumStatusNotifier.instance.isPremium);
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    await PremiumStatusNotifier.instance.loadFromPrefs();
    final p = PremiumStatusNotifier.instance.isPremium;
    var localName = await LocalProfile.displayName();
    final avatar = await LocalProfile.avatarIndex();
    final path = await LocalProfile.customPhotoPath();
    final url = await LocalProfile.customPhotoUrl();
    final user = FirebaseAuth.instance.currentUser;

    if (await UserPrefs.isOnboardingDone()) {
      try {
        await GuestUserService().ensureSession();
        await GuestUserService().syncLocalProfileIfNeeded();
      } catch (e) {
        debugPrint('AccountTab session sync: $e');
      }
    }

    final sessionUser = FirebaseAuth.instance.currentUser ?? user;
    final uid = sessionUser?.uid;
    String? deviceId;
    if (uid != null) {
      try {
        final profile = await GuestUserRepository().fetch(uid);
        deviceId = profile?.deviceId;
      } catch (_) {}
      deviceId ??= await GuestUserService().getDeviceId();
    }

    localName = await _resolveDisplayName(localName, sessionUser);

    if (mounted) {
      setState(() {
        _localName = localName;
        _avatarIndex = avatar;
        _photoPath = path;
        _photoUrl = url;
        _accountUid = uid;
        _deviceId = deviceId;
        _premium = p;
        _notifications = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  void _copyAccountId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.accountTapToCopyId),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Picks the best available display name: local prefs → Firestore → Auth.
  Future<String> _resolveDisplayName(String current, User? user) async {
    if (current != 'Guest' && current.trim().isNotEmpty) return current;

    final uid = user?.uid ?? await UserPrefs.getUid();
    if (uid != null && uid.isNotEmpty) {
      try {
        final profile = await GuestUserRepository().fetch(uid);
        final firestoreName = profile?.name.trim();
        if (firestoreName != null && firestoreName.isNotEmpty) {
          await LocalProfile.saveDisplayName(firestoreName);
          return firestoreName;
        }
      } catch (_) {}
    }

    final authName = user?.displayName?.trim();
    if (authName != null && authName.isNotEmpty) {
      await LocalProfile.saveDisplayName(authName);
      return authName;
    }

    final email = user?.email?.trim();
    if (email != null && email.contains('@')) {
      final fromEmail = email.split('@').first;
      if (fromEmail.isNotEmpty) {
        await LocalProfile.saveDisplayName(fromEmail);
        return fromEmail;
      }
    }

    return current;
  }

  Future<void> _checkAdmin() async {
    final ok = await AdminRepository().isAdmin();
    if (mounted) setState(() => _isAdmin = ok);
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    await NotificationService.scheduleFromPrefs();
  }

  Future<void> _subscribe() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await GuestUserService().ensureSession();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
      return;
    }

    if (!Platform.isAndroid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.premiumPlayOnly)),
        );
      }
      return;
    }

    final billing = PlayBillingCoordinator.instance.billing;
    final product = await billing.loadProduct();
    if (product == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.premiumProductUnavailable)),
        );
      }
      return;
    }

    final started = await billing.subscribe(product);
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  Future<void> _restorePurchases() async {
    final l10n = AppLocalizations.of(context)!;
    await PlayBillingCoordinator.instance.billing.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.restorePurchasesDone)),
      );
    }
  }

  /// Re-reads the server-side entitlement (e.g. after an admin grant or a
  /// purchase on another device). Never grants premium from the client.
  Future<void> _refreshPremiumStatus() async {
    final l10n = AppLocalizations.of(context)!;
    final result =
        await PremiumActivationService.refreshPremiumStatus(force: true);
    if (!mounted) return;
    if (result.ok) {
      setState(() => _premium = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.premiumActivated)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.notPremium)),
      );
    }
  }

  /// DEBUG builds only — grants premium via the QA-gated server endpoint.
  Future<void> _activateTestPremium() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await PremiumActivationService.activateTesterPremium();
    if (!mounted) return;
    if (result.ok) {
      setState(() => _premium = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.premiumActivated)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  void _openSub(BuildContext context, String title, Widget child) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubFeaturePage(title: title, child: child),
      ),
    );
  }

  void _showWatchInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.watch_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              l10n.accountWatchSheetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.accountWatchSheetBody,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _WatchFeature(icon: Icons.sync, text: l10n.accountWatchFeatureSync),
            _WatchFeature(icon: Icons.circle_outlined, text: l10n.accountWatchFeatureRing),
            _WatchFeature(icon: Icons.water_drop, text: l10n.accountWatchFeatureLog),
            _WatchFeature(icon: Icons.calendar_today, text: l10n.accountWatchFeaturePhase),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final periodService = ctx.read<PeriodService>();
                        await periodService.syncWatch();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.watchSyncSuccess)),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.watchSyncFailed)),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.sync_rounded),
                    label: Text(l10n.watchSyncNow),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.gotIt),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumSheet() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PremiumCard(
          l10n: l10n,
          theme: theme,
          premium: _premium,
          onSubscribePlayStore: Platform.isAndroid ? _subscribe : null,
          onRestore: Platform.isAndroid ? _restorePurchases : null,
          onRefreshStatus: !_premium ? _refreshPremiumStatus : null,
          onActivateTest: (kDebugMode && !_premium) ? _activateTestPremium : null,
        ),
      ),
    );
  }

  void _showRemindersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AccountRemindersSheet(),
    ).then((_) => _loadAll());
  }

  void _openRemindersFromDeepLink() {
    if (!mounted) return;
    _showRemindersSheet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final hasEmail = _hasEmailAccount(user);

    return ListView(
      primary: false,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _ProfileCard(
          user: user,
          premium: _premium,
          localName: _localName,
          accountUid: _accountUid,
          deviceId: _deviceId,
          avatarIndex: _avatarIndex,
          photoPath: _photoPath,
          photoUrl: _photoUrl,
          l10n: l10n,
          theme: theme,
          centered: true,
          onCopyAccountId: _accountUid != null ? () => _copyAccountId(_accountUid!) : null,
          onLinkEmail: !hasEmail ? () => context.push('/register') : null,
          onEditProfile: () async {
            final updated = await showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const ProfileEditSheet(),
            );
            if (updated == true) await _loadAll();
          },
        ),
        if (user == null && _accountUid == null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.guestModeBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppSectionHeader(title: l10n.accountSectionTools),
        AccountMenuCard(
          children: [
            if (!_premium)
              AccountMenuTile(
                femIcon: FeminineIcon.premium,
                title: l10n.accountUpgradePro,
                onTap: _showPremiumSheet,
              ),
            AccountMenuTile(
              femIcon: FeminineIcon.insights,
              title: l10n.accountMenuInsights,
              onTap: () => _openSub(
                context,
                l10n.navInsights,
                const InsightsTab(),
              ),
            ),
            AccountMenuTile(
              femIcon: FeminineIcon.education,
              title: l10n.accountMenuEducation,
              onTap: () async {
                final settings = await AppSettingsRepository().fetch();
                if (!context.mounted) return;
                if (!settings.aiEducationEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.educationNotAvailable)),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EducationHubPage()),
                );
              },
            ),
            if (FeatureFlags.isEnabledSync(FeatureFlags.partnerSync))
              AccountMenuTile(
                femIcon: FeminineIcon.partner,
                title: l10n.partnerTitle,
                subtitle: l10n.partnerSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PartnerPage()),
                ),
              ),
            AccountMenuTile(
              femIcon: FeminineIcon.watch,
              title: l10n.smartWatch,
              subtitle: Platform.isIOS
                  ? l10n.accountWatchAppleSubtitle
                  : l10n.accountWatchWearSubtitle,
              showDivider: false,
              onTap: () => _showWatchInfo(context),
            ),
            if (_isAdmin)
              AccountMenuTile(
                femIcon: FeminineIcon.settings,
                title: l10n.adminTitle,
                showDivider: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionHeader(title: l10n.accountSectionPersonal),
        AccountMenuCard(
          children: [
            AccountMenuTile(
              femIcon: FeminineIcon.notifications,
              title: l10n.accountMenuReminders,
              showDivider: false,
              trailing: Switch(
                value: _notifications,
                onChanged: (v) async {
                  setState(() => _notifications = v);
                  if (v) await NotificationService.requestPermission();
                  await _savePref('notifications_enabled', v);
                },
              ),
              onTap: _showRemindersSheet,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionHeader(title: l10n.accountSectionSupport),
        AccountMenuCard(
          children: [
            AccountMenuTile(
              femIcon: FeminineIcon.settings,
              title: l10n.accountMenuSettings,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              ),
            ),
            AccountMenuTile(
              femIcon: FeminineIcon.help,
              title: l10n.anonymousQa,
              subtitle: l10n.anonymousQaDesc,
              onTap: () => context.push('/ask'),
            ),
            AccountMenuTile(
              femIcon: FeminineIcon.about,
              title: l10n.aboutTitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
            ),
            AccountMenuTile(
              femIcon: FeminineIcon.support,
              title: l10n.accountMenuFeedback,
              subtitle: l10n.accountMenuFeedbackSubtitle,
              onTap: () => SupportSheet.show(context),
            ),
            if (FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled))
              AccountMenuTile(
                femIcon: FeminineIcon.ai,
                title: l10n.accountMenuAiDiagnostic,
                subtitle: l10n.accountMenuAiDiagnosticSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AiDiagnosticScreen(),
                  ),
                ),
              ),
            AccountMenuTile(
              femIcon: FeminineIcon.support,
              title: l10n.contactSupport,
              showDivider: user != null,
              onTap: () => openSupportEmail(context),
            ),
            if (user == null)
              AccountMenuTile(
                icon: Icons.login_rounded,
                title: l10n.signIn,
                showDivider: false,
                onTap: () => context.push('/login'),
              )
            else
              AccountMenuTile(
                icon: Icons.logout_rounded,
                title: l10n.signOut,
                showDivider: false,
                onTap: () {
                  context.read<AuthBloc>().add(SignOutRequested());
                  context.go('/welcome');
                },
              ),
          ],
        ),
        const SizedBox(height: 20),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            return Center(
              child: Text(
                'v ${snap.data!.version}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.premium,
    required this.localName,
    this.accountUid,
    this.deviceId,
    required this.avatarIndex,
    this.photoPath,
    this.photoUrl,
    required this.l10n,
    required this.theme,
    required this.onEditProfile,
    this.onCopyAccountId,
    this.onLinkEmail,
    this.centered = false,
  });

  final User? user;
  final bool premium;
  final String localName;
  final String? accountUid;
  final String? deviceId;
  final int avatarIndex;
  final String? photoPath;
  final String? photoUrl;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onEditProfile;
  final VoidCallback? onCopyAccountId;
  final VoidCallback? onLinkEmail;
  final bool centered;

  bool get _hasEmail {
    final email = user?.email?.trim();
    return email != null && email.isNotEmpty && user?.isAnonymous != true;
  }

  String _shortId(String id) =>
      id.length > 14 ? '${id.substring(0, 10)}…${id.substring(id.length - 4)}' : id;

  String _subtitleLine() {
    if (_hasEmail) return user!.email!.trim();
    return l10n.accountEmailNotLinked;
  }

  @override
  Widget build(BuildContext context) {
    if (centered) {
      return _AccountHeroCard(
        avatar: Stack(
          clipBehavior: Clip.none,
          children: [
            AppAvatar(
              radius: 44,
              avatarIndex: avatarIndex,
              photoPath: photoPath,
              networkUrl: photoUrl,
              isPremium: premium,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: theme.colorScheme.primaryContainer,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  onTap: onEditProfile,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        name: localName,
        subtitle: _subtitleLine(),
        premium: premium,
        l10n: l10n,
        theme: theme,
        accountUid: accountUid,
        shortId: accountUid != null ? _shortId(accountUid!) : null,
        onCopyAccountId: onCopyAccountId,
        onLinkEmail: (!_hasEmail && onLinkEmail != null) ? onLinkEmail : null,
      );
    }

    return AppGlassCard(
      onTap: onEditProfile,
      child: Row(
        children: [
          AppAvatar(
            radius: 28,
            avatarIndex: avatarIndex,
            photoPath: photoPath,
            networkUrl: photoUrl,
            isPremium: premium,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localName, style: theme.textTheme.titleMedium),
                Text(_subtitleLine(), style: theme.textTheme.bodySmall),
                if (accountUid != null && accountUid!.isNotEmpty)
                  Text(
                    l10n.accountUserId(_shortId(accountUid!)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                if (deviceId != null && deviceId!.isNotEmpty)
                  Text(
                    l10n.accountDeviceId(_shortId(deviceId!)),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                Text(premium ? l10n.premiumActive : l10n.notPremium),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: theme.colorScheme.outline),
        ],
      ),
    );
  }
}

/// Polished profile header — gradient hero, name, status pill, and a subtle
/// copyable account-ID chip for support. The raw device id is intentionally
/// not surfaced here (it stays internal); professional apps don't show it.
class _AccountHeroCard extends StatelessWidget {
  const _AccountHeroCard({
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.premium,
    required this.l10n,
    required this.theme,
    required this.accountUid,
    required this.shortId,
    this.onCopyAccountId,
    this.onLinkEmail,
  });

  final Widget avatar;
  final String name;
  final String subtitle;
  final bool premium;
  final AppLocalizations l10n;
  final ThemeData theme;
  final String? accountUid;
  final String? shortId;
  final VoidCallback? onCopyAccountId;
  final VoidCallback? onLinkEmail;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.10),
              theme.colorScheme.secondary.withValues(alpha: 0.04),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          children: [
            avatar,
            const SizedBox(height: 14),
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            // Status pill — Premium (gradient) or Free (muted).
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                gradient: premium ? AuraDecorations.primaryGradient : null,
                color: premium
                    ? null
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow:
                    premium ? AppShadows.softRose(opacity: 0.25) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    premium
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_open_rounded,
                    size: 16,
                    color: premium
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    premium ? l10n.premiumActive : l10n.notPremium,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: premium
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (onLinkEmail != null) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: onLinkEmail,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text(l10n.accountLinkEmail),
              ),
            ],
            if (accountUid != null && accountUid!.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Subtle copyable ID chip — for support, not front-and-center.
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onCopyAccountId,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.accountUserId(shortId ?? ''),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.copy_rounded,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.l10n,
    required this.theme,
    required this.premium,
    this.onSubscribePlayStore,
    this.onRestore,
    this.onRefreshStatus,
    this.onActivateTest,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool premium;
  final VoidCallback? onSubscribePlayStore;
  final VoidCallback? onRestore;
  final VoidCallback? onRefreshStatus;
  final VoidCallback? onActivateTest;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            colors: [
              AuraColors.peachGold.withValues(alpha: 0.2),
              AuraColors.rose.withValues(alpha: 0.15),
              AuraColors.lavenderSoft.withValues(alpha: 0.12),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PremiumBadge(size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.premiumTitle,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (premium)
                Text(l10n.premiumActive, style: theme.textTheme.titleSmall)
              else ...[
                Text(l10n.premiumSubtitle),
                const SizedBox(height: 8),
                Text(
                  l10n.premiumPlayHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureRow(text: l10n.premiumFeature1),
                _FeatureRow(text: l10n.premiumFeature2),
                _FeatureRow(text: l10n.premiumFeature3),
                const SizedBox(height: 16),
                if (onSubscribePlayStore != null)
                  AppGradientButton(
                    label: l10n.subscribePlayStore,
                    icon: Icons.shop_rounded,
                    onPressed: onSubscribePlayStore,
                  )
                else
                  Text(
                    l10n.premiumPlayOnly,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (onRestore != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRestore,
                    child: Text(l10n.restorePurchases),
                  ),
                ],
                if (onRefreshStatus != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onRefreshStatus,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.premiumRefreshStatus),
                  ),
                ],
                // Debug-only tester activation (never shown in release builds).
                if (onActivateTest != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onActivateTest,
                    icon: const Icon(Icons.bug_report_outlined),
                    label: Text(l10n.activatePremiumTest),
                  ),
                ],
              ],
            ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _WatchFeature extends StatelessWidget {
  const _WatchFeature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
