import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../premium/presentation/subscription_plans_screen.dart';
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

String _compactAccountId(String id) => id.length > 14
    ? '${id.substring(0, 8)}…${id.substring(id.length - 4)}'
    : id;

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  bool _premium = false;
  bool _notifications = true;
  String _localName = 'Guest';
  String? _username;
  int _avatarIndex = 0;
  String? _photoPath;
  String? _photoUrl;
  String? _accountUid;
  DateTime? _memberSince;
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

    localName = await _resolveDisplayName(localName, sessionUser);

    String? username;
    try {
      username = await GuestUserService().resolveUsername();
    } catch (e) {
      debugPrint('AccountTab resolveUsername: $e');
    }

    if (mounted) {
      setState(() {
        _localName = localName;
        _username = username;
        _avatarIndex = avatar;
        _photoPath = path;
        _photoUrl = url;
        _accountUid = uid;
        _memberSince = sessionUser?.metadata.creationTime;
        _premium = p;
        _notifications = prefs.getBool('notifications_enabled') ?? true;
      });
    }
  }

  void _copyText(String value) {
    Clipboard.setData(ClipboardData(text: value));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(l10n.accountCopied),
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

  /// Root path to the plans: the full-screen paywall with monthly + yearly
  /// cards. This is the ONLY premium entry point from the account hub, so the
  /// plans are always reachable (the old bottom sheet hid them entirely).
  void _openPlans() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SubscriptionPlansScreen()),
    );
  }

  /// Opens Google Play's subscription management for the current account.
  Future<void> _manageSubscription() async {
    final uri = Uri.parse(
      'https://play.google.com/store/account/subscriptions',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  Future<void> _sendEmailVerification(User user) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.accountVerificationSent)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    }
  }

  Future<void> _restorePurchases() async {
    final l10n = AppLocalizations.of(context)!;
    await PlayBillingCoordinator.instance.billing.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.restorePurchasesDone)));
    }
  }

  /// Re-reads the server-side entitlement (e.g. after an admin grant or a
  /// purchase on another device). Never grants premium from the client.
  Future<void> _refreshPremiumStatus() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await PremiumActivationService.refreshPremiumStatus(
      force: true,
    );
    if (!mounted) return;
    if (result.ok) {
      setState(() => _premium = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.premiumActivated)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.notPremium)));
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
            Icon(
              Icons.watch_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.accountWatchSheetTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(l10n.accountWatchSheetBody, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _WatchFeature(icon: Icons.sync, text: l10n.accountWatchFeatureSync),
            _WatchFeature(
              icon: Icons.circle_outlined,
              text: l10n.accountWatchFeatureRing,
            ),
            _WatchFeature(
              icon: Icons.water_drop,
              text: l10n.accountWatchFeatureLog,
            ),
            _WatchFeature(
              icon: Icons.calendar_today,
              text: l10n.accountWatchFeaturePhase,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final periodService = ctx.read<PeriodService>();
                        final synced = await periodService.syncWatch();
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                synced
                                    ? l10n.watchSyncSuccess
                                    : l10n.watchSyncFailed,
                              ),
                            ),
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
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      children: [
        _ProfileCard(
          user: user,
          premium: _premium,
          localName: _localName,
          username: _username,
          accountUid: _accountUid,
          avatarIndex: _avatarIndex,
          photoPath: _photoPath,
          photoUrl: _photoUrl,
          l10n: l10n,
          theme: theme,
          onCopyAccountId: _accountUid != null
              ? () => _copyText(_accountUid!)
              : null,
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
        const SizedBox(height: 16),
        AppSectionHeader(title: l10n.accountSectionPremium),
        _PremiumStatusCard(
          premium: _premium,
          l10n: l10n,
          theme: theme,
          onViewPlans: _openPlans,
          onManage: Platform.isAndroid ? _manageSubscription : null,
          onRestore: Platform.isAndroid ? _restorePurchases : null,
          onRefreshStatus: _refreshPremiumStatus,
        ),
        const SizedBox(height: 16),
        AppSectionHeader(title: l10n.accountSectionInfo),
        AccountMenuCard(
          children: [
            AccountMenuTile(
              icon: Icons.alternate_email_rounded,
              title: l10n.accountUsernameTitle,
              subtitle: (_username == null || _username!.isEmpty)
                  ? l10n.accountUsernameNotSet
                  : '@$_username',
              trailing: (_username == null || _username!.isEmpty)
                  ? null
                  : Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: theme.colorScheme.outline,
                    ),
              onTap: (_username == null || _username!.isEmpty)
                  ? null
                  : () => _copyText('@$_username'),
            ),
            AccountMenuTile(
              icon: Icons.email_outlined,
              title: l10n.accountEmailTitle,
              subtitle: hasEmail
                  ? user!.email!.trim()
                  : l10n.accountEmailNotLinked,
              trailing: hasEmail
                  ? _EmailVerifiedBadge(
                      verified: user!.emailVerified,
                      l10n: l10n,
                      theme: theme,
                    )
                  : null,
              onTap: hasEmail
                  ? (user!.emailVerified
                        ? null
                        : () => _sendEmailVerification(user))
                  : () => context.push('/register'),
            ),
            if (_accountUid != null && _accountUid!.isNotEmpty)
              AccountMenuTile(
                icon: Icons.badge_outlined,
                title: l10n.accountIdTitle,
                subtitle: _compactAccountId(_accountUid!),
                trailing: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
                onTap: () => _copyText(_accountUid!),
              ),
            AccountMenuTile(
              icon: Icons.verified_user_outlined,
              title: hasEmail ? l10n.accountTypeEmail : l10n.accountTypeGuest,
              subtitle: _memberSince != null
                  ? '${l10n.accountMemberSinceTitle} '
                        '${DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(_memberSince!)}'
                  : null,
              showDivider: false,
              trailing: const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppSectionHeader(title: l10n.accountSectionTools),
        AccountMenuCard(
          children: [
            AccountMenuTile(
              femIcon: FeminineIcon.insights,
              title: l10n.accountMenuInsights,
              onTap: () =>
                  _openSub(context, l10n.navInsights, const InsightsTab()),
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
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const PartnerPage())),
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
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AdminScreen())),
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
            if (FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled) &&
                kDebugMode)
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
                onTap: () async {
                  final router = GoRouter.of(context);
                  final authBloc = context.read<AuthBloc>();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.signOutConfirmTitle),
                      content: Text(l10n.signOutConfirmBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.signOut),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                  authBloc.add(SignOutRequested());
                  router.go('/welcome');
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
    this.username,
    this.accountUid,
    required this.avatarIndex,
    this.photoPath,
    this.photoUrl,
    required this.l10n,
    required this.theme,
    required this.onEditProfile,
    this.onCopyAccountId,
    this.onLinkEmail,
  });

  final User? user;
  final bool premium;
  final String localName;
  final String? username;
  final String? accountUid;
  final int avatarIndex;
  final String? photoPath;
  final String? photoUrl;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onEditProfile;
  final VoidCallback? onCopyAccountId;
  final VoidCallback? onLinkEmail;

  bool get _hasEmail {
    final email = user?.email?.trim();
    return email != null && email.isNotEmpty && user?.isAnonymous != true;
  }

  String _subtitleLine() {
    if (_hasEmail) return user!.email!.trim();
    return l10n.accountEmailNotLinked;
  }

  @override
  Widget build(BuildContext context) {
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
      username: username,
      subtitle: _subtitleLine(),
      premium: premium,
      l10n: l10n,
      theme: theme,
      accountUid: accountUid,
      shortId: accountUid != null ? _compactAccountId(accountUid!) : null,
      onCopyAccountId: onCopyAccountId,
      onLinkEmail: (!_hasEmail && onLinkEmail != null) ? onLinkEmail : null,
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
    this.username,
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
  final String? username;
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
    return AppFloatingGlassPanel(
      padding: const EdgeInsets.all(18),
      radius: AppRadius.xl,
      tint: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (username != null && username!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: subtitle.contains('@')
                          ? TextDirection.ltr
                          : null,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AccountStatusPill(
                premium: premium,
                label: premium ? l10n.premiumActive : l10n.notPremium,
                theme: theme,
              ),
              if (accountUid != null && accountUid!.isNotEmpty)
                _AccountIdPill(
                  label: l10n.accountUserId(shortId ?? ''),
                  theme: theme,
                  onTap: onCopyAccountId,
                ),
            ],
          ),
          if (onLinkEmail != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: onLinkEmail,
                icon: const Icon(Icons.email_outlined, size: 18),
                label: Text(l10n.accountLinkEmail),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountStatusPill extends StatelessWidget {
  const _AccountStatusPill({
    required this.premium,
    required this.label,
    required this.theme,
  });

  final bool premium;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: premium ? AuraDecorations.ctaGradient : null,
        color: premium
            ? null
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: premium ? AppShadows.softRose(opacity: 0.18) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            premium ? Icons.workspace_premium_rounded : Icons.lock_open_rounded,
            size: 15,
            color: premium ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: premium
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountIdPill extends StatelessWidget {
  const _AccountIdPill({required this.label, required this.theme, this.onTap});

  final String label;
  final ThemeData theme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
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
              const SizedBox(width: 5),
              Text(
                label,
                textDirection: TextDirection.ltr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                Icons.copy_rounded,
                size: 13,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Premium status card in the account hub.
///
/// Free users get a gradient upsell whose CTA opens [SubscriptionPlansScreen]
/// (monthly + yearly plans). Premium users get their active status with
/// "manage subscription" and a server-side status refresh.
class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({
    required this.premium,
    required this.l10n,
    required this.theme,
    required this.onViewPlans,
    this.onManage,
    this.onRestore,
    this.onRefreshStatus,
  });

  final bool premium;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onViewPlans;
  final VoidCallback? onManage;
  final VoidCallback? onRestore;
  final VoidCallback? onRefreshStatus;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return AppFloatingGlassPanel(
      padding: const EdgeInsets.all(20),
      radius: AppRadius.xl,
      tint: premium ? AuraColors.accentDeep : theme.colorScheme.primary,
      gradient: LinearGradient(
        begin: AlignmentDirectional.topStart,
        end: AlignmentDirectional.bottomEnd,
        colors: premium
            ? [
                const Color(0xFF8F2F62).withValues(alpha: 0.90),
                AuraColors.accentDeep.withValues(alpha: 0.86),
                const Color(0xFF7652A8).withValues(alpha: 0.84),
              ]
            : [
                theme.colorScheme.surface.withValues(
                  alpha: isDark ? 0.76 : 0.72,
                ),
                AuraColors.rose.withValues(alpha: isDark ? 0.16 : 0.14),
                AuraColors.lavenderSoft.withValues(alpha: isDark ? 0.12 : 0.14),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: premium
                      ? Colors.white.withValues(alpha: 0.18)
                      : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: premium
                      ? const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 28,
                        )
                      : const PremiumBadge(size: 27),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      premium ? l10n.premiumActive : l10n.premiumTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: premium ? Colors.white : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      premium
                          ? l10n.accountPremiumThanks
                          : l10n.premiumSubtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: premium
                            ? Colors.white.withValues(alpha: 0.88)
                            : theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PremiumBenefitChip(
                icon: Icons.chat_bubble_outline_rounded,
                label: l10n.premiumFeature1,
                premium: premium,
                theme: theme,
              ),
              _PremiumBenefitChip(
                icon: Icons.cloud_done_outlined,
                label: l10n.premiumFeature2,
                premium: premium,
                theme: theme,
              ),
              _PremiumBenefitChip(
                icon: Icons.support_agent_rounded,
                label: l10n.premiumFeature3,
                premium: premium,
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (premium) ...[
            if (onManage != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AuraColors.accentDeep,
                  ),
                  onPressed: onManage,
                  icon: const Icon(Icons.manage_accounts_outlined, size: 20),
                  label: Text(l10n.accountManageSubscription),
                ),
              ),
            if (onRefreshStatus != null)
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: onRefreshStatus,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.premiumRefreshStatus),
                ),
              ),
          ] else ...[
            AppGradientButton(
              label: l10n.accountViewPlans,
              icon: Icons.diamond_rounded,
              onPressed: onViewPlans,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRestore != null)
                  Flexible(
                    child: TextButton(
                      onPressed: onRestore,
                      child: Text(l10n.restorePurchases),
                    ),
                  ),
                if (onRefreshStatus != null)
                  Flexible(
                    child: TextButton(
                      onPressed: onRefreshStatus,
                      child: Text(l10n.premiumRefreshStatus),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PremiumBenefitChip extends StatelessWidget {
  const _PremiumBenefitChip({
    required this.icon,
    required this.label,
    required this.premium,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final bool premium;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: premium
            ? Colors.white.withValues(alpha: 0.14)
            : theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: premium
              ? Colors.white.withValues(alpha: 0.18)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: premium ? Colors.white : theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 210),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: premium ? Colors.white : null,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "verified / not verified" pill next to the email row.
class _EmailVerifiedBadge extends StatelessWidget {
  const _EmailVerifiedBadge({
    required this.verified,
    required this.l10n,
    required this.theme,
  });

  final bool verified;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final color = verified ? AuraColors.success : theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.error_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            verified ? l10n.accountEmailVerified : l10n.accountEmailNotVerified,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
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
