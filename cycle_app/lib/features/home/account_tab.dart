import 'dart:async';
import 'dart:io';

import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../profile/presentation/profile_edit_sheet.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../admin/data/admin_repository.dart';
import '../admin/presentation/admin_screen.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/bloc/auth_event.dart';
import '../auth/presentation/auth_navigation.dart';
import '../premium/data/paypal_service.dart';
import '../premium/data/play_billing_service.dart';
import '../education/presentation/education_hub_page.dart';
import '../partner/presentation/partner_page.dart';
import '../cycle/data/cycle_sync_service.dart';
import '../goals/presentation/goal_change_flow.dart';
import '../settings/presentation/about_screen.dart';
import '../settings/presentation/account_reminders_sheet.dart';
import '../settings/presentation/account_settings_screen.dart';
import 'insights_tab.dart';
import 'sub_feature_page.dart';
import 'widgets/account_menu_tile.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> with WidgetsBindingObserver {
  bool _premium = false;
  bool _notifications = true;
  bool _paypalActivating = false;
  bool _paypalPending = false;
  final _playBilling = PlayBillingService();
  final _paypal = PayPalService();
  String _localName = 'Guest';
  int _avatarIndex = 0;
  String? _photoPath;
  String? _photoUrl;
  UserGoalTypes _goal = UserGoalTypes.general;
  final _cycleSync = CycleSyncService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    _loadAll();
    HomeRefreshScope.notifier.addListener(_onHomeRefresh);
    _refreshPayPalPending();
    _playBilling.startListening(onPremiumGranted: () {
      if (mounted) _loadAll();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryCapturePayPal(silent: true);
      _checkAdmin();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HomeRefreshScope.notifier.removeListener(_onHomeRefresh);
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    _playBilling.dispose();
    super.dispose();
  }

  void _onHomeRefresh() => _loadGoal();

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() => _premium = PremiumStatusNotifier.instance.isPremium);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _tryCapturePayPal(silent: true);
    }
  }

  Future<void> _refreshPayPalPending() async {
    final pending = await _paypal.hasPendingOrder();
    if (mounted) setState(() => _paypalPending = pending);
  }

  Future<void> _loadGoal() async {
    final goal = await _cycleSync.getUserGoal();
    if (mounted) setState(() => _goal = goal);
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    await PremiumStatusNotifier.instance.loadFromPrefs();
    final p = PremiumStatusNotifier.instance.isPremium;
    final localName = await LocalProfile.displayName();
    final avatar = await LocalProfile.avatarIndex();
    final path = await LocalProfile.customPhotoPath();
    final url = await LocalProfile.customPhotoUrl();
    final goal = await _cycleSync.getUserGoal();
    if (mounted) {
      setState(() {
        _localName = localName;
        _avatarIndex = avatar;
        _photoPath = path;
        _photoUrl = url;
        _premium = p;
        _goal = goal;
        _notifications = prefs.getBool('notifications_enabled') ?? true;
      });
    }
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

  Future<void> _tryCapturePayPal({bool silent = false}) async {
    if (_premium || _paypalActivating) return;
    if (!await _paypal.hasPendingOrder()) return;
    if (!mounted) return;

    setState(() => _paypalActivating = true);

    try {
      final ok = await _paypal.capturePendingOrder();
      await _refreshPayPalPending();
      if (ok) {
        await _loadAll();
        if (mounted && !silent) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.premiumPayPalActivated)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _paypalActivating = false);
    }
  }

  Future<void> _subscribePayPal() async {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (user == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.loginRequiredPremium)));
      await openLoginScreen(context);
      return;
    }

    final checkout = await _paypal.startCheckout();
    if (checkout == null) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.premiumPayPalUnavailable)),
        );
      }
      return;
    }

    final launched = await _paypal.launchApprovalPage(checkout.approvalUrl);
    await _refreshPayPalPending();
    if (!mounted) return;

    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      return;
    }

    messenger.showSnackBar(
      SnackBar(content: Text(l10n.premiumPayPalReturn)),
    );
  }

  Future<void> _subscribe() async {
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequiredPremium)),
      );
      await openLoginScreen(context);
      return;
    }

    if (!Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.premiumPlayOnly)),
      );
      return;
    }

    final product = await _playBilling.loadProduct();
    if (product == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.premiumProductUnavailable)),
        );
      }
      return;
    }

    final started = await _playBilling.subscribe(product);
    if (!started && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }

  Future<void> _restorePurchases() async {
    final l10n = AppLocalizations.of(context)!;
    await _playBilling.restorePurchases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.restorePurchasesDone)),
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
            const Text('Smart Watch Sync', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text(
              'Your cycle data is automatically synced to your paired smart watch. '
              'You can view your cycle progress and log your period directly from your watch.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _WatchFeature(icon: Icons.sync, text: 'Auto-syncs cycle data to watch'),
            _WatchFeature(icon: Icons.circle_outlined, text: 'Cycle ring on watch face'),
            _WatchFeature(icon: Icons.water_drop, text: 'Log period from watch'),
            _WatchFeature(icon: Icons.calendar_today, text: 'Current phase display'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
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
          paypalPending: _paypalPending,
          paypalActivating: _paypalActivating,
          onSubscribePayPal: _subscribePayPal,
          onActivatePayPal: () => _tryCapturePayPal(silent: false),
          onSubscribePlayStore: Platform.isAndroid ? _subscribe : null,
          onRestore: Platform.isAndroid ? _restorePurchases : null,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _ProfileCard(
          user: user,
          premium: _premium,
          localName: _localName,
          avatarIndex: _avatarIndex,
          photoPath: _photoPath,
          photoUrl: _photoUrl,
          l10n: l10n,
          theme: theme,
          centered: true,
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
        if (user == null) ...[
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
                icon: Icons.workspace_premium_outlined,
                title: l10n.accountUpgradePro,
                onTap: _showPremiumSheet,
              ),
            AccountMenuTile(
              icon: Icons.insights_rounded,
              title: l10n.accountMenuInsights,
              onTap: () => _openSub(
                context,
                l10n.navInsights,
                const InsightsTab(),
              ),
            ),
            AccountMenuTile(
              icon: Icons.menu_book_rounded,
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
            AccountMenuTile(
              icon: Icons.favorite_outline,
              title: l10n.partnerTitle,
              subtitle: l10n.partnerSubtitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PartnerPage()),
              ),
            ),
            AccountMenuTile(
              icon: Icons.watch_outlined,
              title: 'Smart Watch',
              subtitle: Platform.isIOS ? 'Apple Watch support' : 'Wear OS support',
              showDivider: false,
              onTap: () => _showWatchInfo(context),
            ),
            if (_isAdmin)
              AccountMenuTile(
                icon: Icons.admin_panel_settings_rounded,
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
              icon: Icons.notifications_outlined,
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
              icon: Icons.settings_outlined,
              title: l10n.accountMenuSettings,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountSettingsScreen(),
                ),
              ),
            ),
            AccountMenuTile(
              icon: Icons.help_outline_rounded,
              title: 'Anonymous Q&A',
              subtitle: 'Ask health questions privately',
              onTap: () => context.push('/ask'),
            ),
            AccountMenuTile(
              icon: Icons.info_outline_rounded,
              title: l10n.aboutTitle,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
            ),
            AccountMenuTile(
              icon: Icons.mail_outline_rounded,
              title: l10n.contactSupport,
              showDivider: user != null,
              onTap: openSupportEmail,
            ),
            if (user == null)
              AccountMenuTile(
                icon: Icons.login_rounded,
                title: l10n.signInOptionalTitle,
                showDivider: false,
                onTap: () => openLoginScreen(context),
              )
            else
              AccountMenuTile(
                icon: Icons.logout_rounded,
                title: l10n.signOut,
                showDivider: false,
                onTap: () => context.read<AuthBloc>().add(SignOutRequested()),
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
    required this.avatarIndex,
    this.photoPath,
    this.photoUrl,
    required this.l10n,
    required this.theme,
    required this.onEditProfile,
    this.centered = false,
  });

  final User? user;
  final bool premium;
  final String localName;
  final int avatarIndex;
  final String? photoPath;
  final String? photoUrl;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onEditProfile;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    if (centered) {
      return Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppAvatar(
                radius: 44,
                avatarIndex: avatarIndex,
                photoPath: photoPath,
                networkUrl: photoUrl,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: theme.colorScheme.primaryContainer,
                  shape: const CircleBorder(),
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
          const SizedBox(height: 12),
          Text(
            localName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? l10n.guestModeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (premium) ...[
            const SizedBox(height: 6),
            Text(
              l10n.premiumActive,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localName, style: theme.textTheme.titleMedium),
                Text(
                  user?.email ?? l10n.guestModeLabel,
                  style: theme.textTheme.bodySmall,
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

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.l10n,
    required this.theme,
    required this.premium,
    required this.onSubscribePayPal,
    this.onActivatePayPal,
    this.onSubscribePlayStore,
    this.onRestore,
    this.paypalPending = false,
    this.paypalActivating = false,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final bool premium;
  final VoidCallback onSubscribePayPal;
  final VoidCallback? onActivatePayPal;
  final VoidCallback? onSubscribePlayStore;
  final VoidCallback? onRestore;
  final bool paypalPending;
  final bool paypalActivating;

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
              Text(l10n.premiumTitle,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (premium)
                Text(l10n.premiumActive, style: theme.textTheme.titleSmall)
              else ...[
                Text(l10n.premiumSubtitle),
                const SizedBox(height: 8),
                Text(
                  l10n.premiumPayPalHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureRow(text: l10n.premiumFeature1),
                _FeatureRow(text: l10n.premiumFeature2),
                _FeatureRow(text: l10n.premiumFeature3),
                const SizedBox(height: 16),
                AppGradientButton(
                  label: paypalActivating ? l10n.premiumPayPalActivating : l10n.subscribePayPal,
                  icon: Icons.payment_outlined,
                  loading: paypalActivating,
                  onPressed: paypalActivating ? null : onSubscribePayPal,
                ),
                if (paypalPending && onActivatePayPal != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: paypalActivating ? null : onActivatePayPal,
                    child: Text(l10n.premiumActivatePayPal),
                  ),
                ],
                if (onSubscribePlayStore != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onSubscribePlayStore,
                    child: Text(l10n.subscribePlayStore),
                  ),
                ],
                if (onRestore != null) ...[
                  TextButton(
                    onPressed: onRestore,
                    child: Text(l10n.restorePurchases),
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
