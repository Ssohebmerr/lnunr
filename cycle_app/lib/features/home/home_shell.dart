import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/feminine_icon.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../community/presentation/community_tab.dart';
import '../community/data/community_notification_listener.dart';
import '../../../core/premium/premium_sync_listener.dart';
import '../self_care/presentation/self_care_tab.dart';
import 'account_tab.dart';
import 'home_tab.dart';
import '../chat/presentation/ai_chat_page.dart';
import '../premium/presentation/subscription_plans_screen.dart';
import 'log_tab.dart';
import 'reports_tab.dart';
import 'sub_feature_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  String _displayName = '';
  int _avatarIndex = 0;
  String? _photoPath;
  String? _photoUrl;
  String _authKey = 'guest';
  bool _isPremium = false;
  bool _stealthEnabled = false;
  StreamSubscription<User?>? _authSub;
  bool _communityEnabled = true;

  final Set<int> _visitedTabs = {0};

  // 0:Home  1:Community  2:SelfCare  3:Account
  // Reports lives as a Home header shortcut (not a bottom tab) so the + log
  // button sits perfectly centred between two balanced pairs of tabs.
  static const _navIcons = [
    FeminineIcon.home,
    FeminineIcon.community,
    FeminineIcon.selfCare,
    FeminineIcon.account,
  ];

  @override
  void initState() {
    super.initState();
    HomeShellActions.switchTab = _onTabSelected;
    HomeShellActions.openLog = _openLog;
    if (FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled)) {
      HomeShellActions.openAiChat = _openAiChat;
    }
    HomeShellActions.openReports = _openReports;
    _authKey = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final next = user?.uid ?? 'guest';
      if (next != _authKey && mounted) {
        setState(() => _authKey = next);
      }
    });
    _loadProfile();
    _loadAppSettings();
    _loadStealth();
    PremiumStatusNotifier.instance.addListener(_onPremiumChanged);
    PremiumStatusNotifier.instance.loadFromPrefs().then((_) {
      if (mounted) {
        setState(() => _isPremium = PremiumStatusNotifier.instance.isPremium);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService.ensureInitialPermission(context);
      } else {
        NotificationService.ensureInitialPermission();
      }
    });
  }

  @override
  void dispose() {
    if (HomeShellActions.switchTab == _onTabSelected) {
      HomeShellActions.switchTab = null;
    }
    if (HomeShellActions.openLog == _openLog) {
      HomeShellActions.openLog = null;
    }
    if (HomeShellActions.openAiChat == _openAiChat) {
      HomeShellActions.openAiChat = null;
    }
    if (HomeShellActions.openReports == _openReports) {
      HomeShellActions.openReports = null;
    }
    _authSub?.cancel();
    PremiumStatusNotifier.instance.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() => _isPremium = PremiumStatusNotifier.instance.isPremium);
  }

  Future<void> _loadAppSettings() async {
    final settings = await AppSettingsRepository().fetch();
    if (!mounted) return;
    setState(() {
      _communityEnabled = settings.communityEnabled;
      if (!_communityEnabled && _index == 1) _index = 0;
    });
  }

  Future<void> _loadStealth() async {
    final enabled = await UserPrefs.isStealthModeEnabled();
    if (mounted) setState(() => _stealthEnabled = enabled);
  }

  Future<void> _loadProfile() async {
    final name = await LocalProfile.displayName();
    final avatar = await LocalProfile.avatarIndex();
    final path = await LocalProfile.customPhotoPath();
    final url = await LocalProfile.customPhotoUrl();
    if (mounted) {
      setState(() {
        _displayName = name;
        _avatarIndex = avatar;
        _photoPath = path;
        _photoUrl = url;
      });
    }
  }

  void _onTabSelected(int i) {
    if (i == 1 && !_communityEnabled) return;
    if (i != _index) HapticFeedback.selectionClick();
    if (i == 0 && _index != 0) {
      HomeRefreshScope.refresh();
    }
    if (i == 3) _loadProfile();
    if (i == 0) _loadStealth();
    setState(() {
      _visitedTabs.add(i);
      _index = i;
    });
  }

  void _openAiChat() {
    if (!FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled)) return;
    if (!_isPremium) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const SubscriptionPlansScreen(),
        ),
      );
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AiChatPage()));
  }

  void _openLog() {
    final l10n = AppLocalizations.of(context)!;
    final homeMessenger = ScaffoldMessenger.of(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubFeaturePage(
          title: l10n.navLog,
          child: LogTab(popOnSave: true, homeMessenger: homeMessenger),
        ),
      ),
    );
  }

  void _openReports() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SubFeaturePage(title: l10n.navReports, child: const ReportsTab()),
      ),
    );
  }

  Widget _tabChild(int i) {
    if (i == 1 && !_communityEnabled) return const SizedBox.shrink();
    if (!_visitedTabs.contains(i)) return const SizedBox.shrink();
    final child = switch (i) {
      0 => const HomeTab(key: ValueKey('tab-home')),
      1 => CommunityTab(key: ValueKey('tab-community')),
      2 => const SelfCareTab(key: ValueKey('tab-selfcare')),
      3 => const AccountTab(key: ValueKey('tab-account')),
      _ => const SizedBox.shrink(),
    };
    if (i != _index) {
      return TickerMode(enabled: false, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAccount = _index == 3;

    final labels = [
      l10n.navHome,
      l10n.navCommunity,
      l10n.navSelfCare,
      l10n.navAccount,
    ];

    final greeting = _displayName.isNotEmpty && _displayName != 'Guest'
        ? l10n.homeGreetingName(_displayName)
        : l10n.homeGreeting;

    return PremiumSyncListener(
      child: CommunityNotificationListener(
        child: AppMeshBackground(
          child: Scaffold(
            // The tab content must scroll BEHIND the bottom pill for the
            // frosted-glass blur to have anything to sample — with false the
            // bar sat on a dead strip and always rendered as a flat slab.
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isAccount)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        AppSpacing.sm,
                        12,
                        10,
                      ),
                      child: _HomeGlassHeader(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.navAccount,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (FeatureFlags.isEnabledSync(
                              FeatureFlags.aiChatEnabled,
                            ))
                              _AiHeaderChip(
                                label: l10n.homeAiChipLabel,
                                onTap: _openAiChat,
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        12,
                        AppSpacing.sm,
                        12,
                        10,
                      ),
                      child: _HomeGlassHeader(
                        child: Row(
                          children: [
                            GestureDetector(
                              onDoubleTap: () async {
                                if (_stealthEnabled) {
                                  UserPrefs.setSessionUnlocked(false);
                                  if (mounted) {
                                    context.go('/stealth');
                                  }
                                }
                              },
                              child: AppAvatar(
                                radius: 22,
                                avatarIndex: _avatarIndex,
                                photoPath: _photoPath,
                                networkUrl: _photoUrl,
                                isPremium: _isPremium,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    greeting,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    labels[_index],
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (FeatureFlags.isEnabledSync(
                              FeatureFlags.aiChatEnabled,
                            ))
                              _AiHeaderChip(
                                label: l10n.homeAiChipLabel,
                                onTap: _openAiChat,
                              ),
                            if (_index == 0)
                              _HeaderIconButton(
                                tooltip: l10n.navReports,
                                onPressed: _openReports,
                                icon: FeminineIconView(
                                  FeminineIcon.reports,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            if (_stealthEnabled)
                              _HeaderIconButton(
                                tooltip: l10n.stealthHideNow,
                                onPressed: () => context.push('/stealth'),
                                icon: Icon(
                                  Icons.visibility_off_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            if (_index == 0)
                              _HeaderIconButton(
                                tooltip: l10n.retry,
                                onPressed: HomeRefreshScope.refresh,
                                icon: Icon(
                                  Icons.refresh_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: IndexedStack(
                      index: _index,
                      sizing: StackFit.expand,
                      children: List.generate(4, _tabChild),
                    ),
                  ),
                ],
              ),
            ),

            bottomNavigationBar: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: SizedBox(
                height: 64,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Frosted-glass pill — translucent fill over the app
                    // gradient with a real blur, no glow/shadow halo. The
                    // glass layer is clipped separately so the centred +
                    // button can still overhang above the bar.
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              // 62% fill so the blurred content actually shows
                              // through; the light border is the glass edge —
                              // deliberately zero shadow around the bar.
                              color: isDark
                                  ? AuraColors.darkCard.withValues(alpha: 0.62)
                                  : Colors.white.withValues(alpha: 0.62),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.10)
                                    : Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: _bottomNavItems(
                        context: context,
                        labels: labels,
                        selectedIndex: _index,
                        communityEnabled: _communityEnabled,
                        onSelect: _onTabSelected,
                        onLog: _openLog,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Four tabs with the log (+) perfectly centered between two pairs:
  /// LTR: Home · Community | + | SelfCare · Account
  /// RTL: Account · SelfCare | + | Community · Home
  List<Widget> _bottomNavItems({
    required BuildContext context,
    required List<String> labels,
    required int selectedIndex,
    required bool communityEnabled,
    required ValueChanged<int> onSelect,
    required VoidCallback onLog,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    Widget nav(int index) => _NavItem(
      icon: _navIcons[index],
      label: labels[index],
      selected: selectedIndex == index,
      onTap: () => onSelect(index),
    );

    if (!communityEnabled) {
      // Home | + | SelfCare · Account
      final beforeLog = [nav(0)];
      final afterLog = [nav(2), nav(3)];
      final leading = isRtl ? afterLog.reversed.toList() : beforeLog;
      final trailing = isRtl ? beforeLog : afterLog;
      return [...leading, _BottomBarLogSlot(onPressed: onLog), ...trailing];
    }

    // LTR: Home · Community | + | SelfCare · Account
    final beforeLog = [nav(0), nav(1)];
    final afterLog = [nav(2), nav(3)];

    final leading = isRtl ? afterLog.reversed.toList() : beforeLog;
    final trailing = isRtl ? beforeLog.reversed.toList() : afterLog;

    return [...leading, _BottomBarLogSlot(onPressed: onLog), ...trailing];
  }
}

/// Premium frosted header shared by every main tab.
///
/// The translucent gradient keeps the app background visible while a crisp
/// highlight, restrained shadow, and two soft colour blooms give the bar real
/// depth in both themes. All header actions remain outside the decorative
/// layers, so their touch targets and semantics are unchanged.
class _HomeGlassHeader extends StatelessWidget {
  const _HomeGlassHeader({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const radius = AppRadius.lg;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AuraColors.plum).withValues(
                alpha: isDark ? 0.26 : 0.10,
              ),
              blurRadius: 22,
              offset: const Offset(0, 9),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF443047).withValues(alpha: 0.62),
                                AuraColors.darkCard.withValues(alpha: 0.46),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.62),
                                const Color(0xFFFFEDF5).withValues(alpha: 0.36),
                              ],
                      ),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.13)
                            : Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: -38,
                  end: -22,
                  child: IgnorePointer(
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AuraColors.rose.withValues(
                              alpha: isDark ? 0.18 : 0.24,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: -46,
                  start: 52,
                  child: IgnorePointer(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AuraColors.lavenderSoft.withValues(
                              alpha: isDark ? 0.12 : 0.18,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 62),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: icon,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary.withValues(
            alpha: isDark ? 0.13 : 0.09,
          ),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.75),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }
}

/// Log action embedded in the bottom bar so it stays in its own slot.
class _BottomBarLogSlot extends StatelessWidget {
  const _BottomBarLogSlot({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(top: -14, child: _LogFabButton(onPressed: onPressed)),
        ],
      ),
    );
  }
}

class _LogFabButton extends StatelessWidget {
  const _LogFabButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AuraDecorations.ctaGradient,
        // A tight berry lift instead of the wide rose halo that used to bleed
        // over the glass bar.
        boxShadow: [
          BoxShadow(
            color: AuraColors.accent.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onPressed();
          },
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _AiHeaderChip extends StatelessWidget {
  const _AiHeaderChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: AppShadows.softRose(opacity: 0.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FeminineIcon icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: FeminineIconView(
                    icon,
                    size: 23,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
