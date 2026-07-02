import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/premium/premium_status_notifier.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/feminine_icon.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../community/presentation/community_tab.dart';
import '../community/data/community_notification_listener.dart';
import '../../../core/premium/premium_sync_listener.dart';
import '../self_care/presentation/self_care_tab.dart';
import 'account_tab.dart';
import 'home_tab.dart';
import '../chat/presentation/ai_chat_page.dart';
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

  final Set<int> _visitedTabs = {0, 1};

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
    HomeShellActions.openAiChat = _openAiChat;
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AiChatPage()),
    );
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
        builder: (_) => SubFeaturePage(
          title: l10n.navReports,
          child: const ReportsTab(),
        ),
      ),
    );
  }

  Widget _tabChild(int i) {
    if (i == 1 && !_communityEnabled) return const SizedBox.shrink();
    if (!_visitedTabs.contains(i)) return const SizedBox.shrink();
    return switch (i) {
      0 => const HomeTab(key: ValueKey('tab-home')),
      1 => CommunityTab(key: ValueKey('tab-community')),
      2 => const SelfCareTab(key: ValueKey('tab-selfcare')),
      3 => const AccountTab(key: ValueKey('tab-account')),
      _ => const SizedBox.shrink(),
    };
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
      child: Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.gradientBackground(context),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAccount)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
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
                      _AiHeaderChip(
                        label: l10n.homeAiChipLabel,
                        onTap: _openAiChat,
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
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
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
                      _AiHeaderChip(
                        label: l10n.homeAiChipLabel,
                        onTap: _openAiChat,
                      ),
                      if (_index == 0)
                        IconButton(
                          tooltip: l10n.navReports,
                          onPressed: _openReports,
                          icon: FeminineIconView(
                            FeminineIcon.reports,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                      if (_stealthEnabled)
                        IconButton(
                          tooltip: l10n.stealthHideNow,
                          onPressed: () => context.push('/stealth'),
                          icon: Icon(
                            Icons.visibility_off_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      if (_index == 0)
                        IconButton(
                          tooltip: l10n.retry,
                          onPressed: HomeRefreshScope.refresh,
                          icon: Icon(
                            Icons.refresh_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
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
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 68,
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            color: isDark
                ? AuraColors.darkCard.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.88),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.04),
            ),
            boxShadow: AppShadows.navFloat(isDark),
          ),
          child: Row(
            children: _bottomNavItems(
              context: context,
              labels: labels,
              selectedIndex: _index,
              communityEnabled: _communityEnabled,
              onSelect: _onTabSelected,
              onLog: _openLog,
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
      return [
        ...leading,
        _BottomBarLogSlot(onPressed: onLog),
        ...trailing,
      ];
    }

    // LTR: Home · Community | + | SelfCare · Account
    final beforeLog = [nav(0), nav(1)];
    final afterLog = [nav(2), nav(3)];

    final leading = isRtl ? afterLog.reversed.toList() : beforeLog;
    final trailing = isRtl ? beforeLog.reversed.toList() : afterLog;

    return [
      ...leading,
      _BottomBarLogSlot(onPressed: onLog),
      ...trailing,
    ];
  }
}

/// Log action embedded in the bottom bar so it stays in its own slot.
class _BottomBarLogSlot extends StatelessWidget {
  const _BottomBarLogSlot({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: 120,
        child: Transform.translate(
          offset: const Offset(0, -20),
          child: _LogFabButton(onPressed: onPressed),
        ),
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
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AuraDecorations.primaryGradient,
        boxShadow: AppShadows.softRose(opacity: 0.35),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _AiHeaderChip extends StatelessWidget {
  const _AiHeaderChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 4),
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
            height: 68,
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
