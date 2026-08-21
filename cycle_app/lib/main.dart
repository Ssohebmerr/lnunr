import 'dart:async';

import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart'
    as menstrudel_l10n;
import 'package:cycle_aura/menstrudel_integration/menstrudel_init.dart';
import 'package:cycle_aura/menstrudel_integration/menstrudel_providers.dart';
import 'package:cycle_aura/menstrudel/database/repositories/logs_repository.dart';
import 'package:cycle_aura/menstrudel/database/repositories/user_repository.dart';
import 'package:cycle_aura/menstrudel/services/settings_service.dart';
import 'package:cycle_aura/menstrudel/services/symptom_service.dart';
import 'package:cycle_aura/menstrudel/services/user_service.dart';
import 'package:cycle_aura/menstrudel/services/wear_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/security/app_lock_controller.dart';
import 'core/security/app_lock_overlay.dart';
import 'core/push/push_registration_service.dart';
import 'core/notifications/app_notifications.dart';

import 'core/ai/ai_context_engine.dart';
import 'core/ai/ai_gateway.dart';
import 'core/ai/ai_insights_service.dart';
import 'core/ai/direct_gemini_service.dart';
import 'core/ai/firebase_ai_service.dart';
import 'core/config/feature_flags.dart';
import 'core/firebase/app_bootstrap.dart';
import 'features/user/data/guest_user_service.dart';
import 'core/ai/lune_personality.dart';
import 'core/analytics/active_ping_service.dart';
import 'core/locale/locale_controller.dart';
import 'core/navigation/home_shell_actions.dart';
import 'core/notifications/notification_service.dart';
import 'core/privacy/privacy_constants.dart';
import 'core/premium/play_billing_coordinator.dart';
import 'core/security/cycle_encryption_keys.dart';
import 'core/storage/user_prefs.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/chat/data/chat_repository.dart';
import 'features/community/data/community_repository.dart';
import 'features/community/data/community_story_repository.dart';
import 'features/cycle/data/cycle_bridge_service.dart';
import 'features/cycle/data/cycle_sync_service.dart';
import 'features/admin/presentation/admin_screen.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/education/presentation/anonymous_qa_screen.dart';
import 'features/privacy/presentation/stealth_calculator_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/sync/data/cloud_sync_service.dart';
import 'l10n/app_localizations.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM Background] ${message.notification?.title}');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await AppBootstrap.initialize();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(PushRegistrationService().registerIfPossible());
      }
    });
    unawaited(PushRegistrationService().registerIfPossible());
  } catch (e, st) {
    debugPrint('[Main] AppBootstrap initialize failed: $e\n$st');
  }

  // Guest session — must not block cold start when offline.
  if (await UserPrefs.isOnboardingDone()) {
    unawaited(_bootstrapGuestSession());
  }

  tz_data.initializeTimeZones();
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  try {
    await NotificationService.initialize();
    // Wire the root navigator so notification taps can deep-link to a tab.
    AppNotifications.globalNavigatorKey = _rootNavigatorKey;
  } catch (e) {
    debugPrint('[Main] NotificationService initialize failed: $e');
  }

  // FCM registration handled via authStateChanges + PushRegistrationService. — show local notification when app is open
  FirebaseMessaging.onMessage.listen((message) {
    final title = message.notification?.title;
    final body = message.notification?.body;
    if (title != null && body != null) {
      AppNotifications.plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cycle_aura_reminders',
            'Cycle Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  void handleFcmLaunch(RemoteMessage message) {
    if (message.data.isEmpty) return;
    NotificationRouter.navigateFromMap(message.data);
  }

  FirebaseMessaging.onMessageOpenedApp.listen(handleFcmLaunch);
  RemoteMessage? initialFcm;
  try {
    initialFcm = await FirebaseMessaging.instance
        .getInitialMessage()
        .timeout(const Duration(seconds: 3));
  } catch (e) {
    if (kDebugMode) debugPrint('[Main] getInitialMessage skipped: $e');
  }
  final launchMessage = initialFcm;
  if (launchMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleFcmLaunch(launchMessage);
    });
  }

  try {
    await MenstrudelInit.initialize();
  } catch (e, st) {
    debugPrint('[Main] MenstrudelInit failed: $e\n$st');
  }

  try {
    final keys = await CycleEncryptionKeys.loadOrCreate();
    MenstrualCycleWidget.init(
      secretKey: keys['secretKey'],
      ivKey: keys['ivKey'],
    );
    CycleBridgeService.wireOvulationCalibration();
  } catch (e, st) {
    debugPrint('[Main] MenstrualCycleWidget init failed: $e\n$st');
  }

  final localeController = LocaleController();
  await localeController.load();

  final themeController = ThemeController();
  await themeController.load();

  // Warm up the feature-flag cache so the first frame can read flags
  // synchronously (see FeatureFlags.isEnabledSync).
  await FeatureFlags.refresh();

  try {
    await LunePersonalityPrefs.load();
  } catch (e) {
    debugPrint('[Main] LunePersonalityPrefs load failed: $e');
  }

  try {
    await NotificationService.scheduleFromPrefs();
  } catch (e, st) {
    debugPrint('[Main] Notification schedule skipped: $e\n$st');
  }

  // DAU heartbeat — best-effort, non-blocking
  unawaited(ActivePingService.pingIfNeeded());

  // Google Play Billing listener (Android) — must run app-wide for checkout.
  unawaited(PlayBillingCoordinator.instance.initialize());

  final bridge = CycleBridgeService();
  try {
    await bridge.applyLocale(localeController.locale.languageCode);
    await bridge.linkAuthenticatedUser(FirebaseAuth.instance.currentUser);
    unawaited(
      CycleSyncService()
          .onCycleDataChanged()
          .timeout(const Duration(seconds: 10))
          .catchError((Object e, StackTrace st) {
        debugPrint('Initial cycle sync skipped (non-fatal): $e\n$st');
      }),
    );
  } catch (e, st) {
    debugPrint('Initial cycle sync skipped (non-fatal): $e\n$st');
  }

  final prefs = MenstrudelInit.prefs ?? await SharedPreferences.getInstance();
  MenstrudelInit.prefs ??= prefs;
  MenstrudelInit.settingsService ??= SettingsService(prefs);
  MenstrudelInit.userService ??= UserService(UserRepository());
  MenstrudelInit.symptomService ??= SymptomService(prefs);
  MenstrudelInit.logsRepository ??= LogsRepository();
  MenstrudelInit.watchService ??= WatchSyncService();

  runApp(
    MenstrudelProviders(
      sharedPreferences: prefs,
      settingsService: MenstrudelInit.settingsService!,
      userService: MenstrudelInit.userService!,
      symptomService: MenstrudelInit.symptomService!,
      watchService: MenstrudelInit.watchService!,
      logsRepository: MenstrudelInit.logsRepository!,
      child: LuneApp(
        localeController: localeController,
        themeController: themeController,
      ),
    ),
  );
}

class LuneApp extends StatefulWidget {
  const LuneApp({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<LuneApp> createState() => _LuneAppState();
}

class _LuneAppState extends State<LuneApp> with WidgetsBindingObserver {
  late final AppLockController _appLock;

  /// Throttle for the on-resume notification refresh. The daily-motivation
  /// runway only needs topping up occasionally, so we skip re-laying it on
  /// every quick app switch.
  DateTime? _lastReminderRefresh;
  static const _reminderRefreshEvery = Duration(hours: 4);

  @override
  void initState() {
    super.initState();
    _appLock = AppLockController();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
      HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (MenstrudelInit.settingsService?.areBiometricsEnabled == true) {
        _appLock.lock();
        unawaited(_appLock.authenticateIfNeeded());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final path = _router.state.matchedLocation;
    // Lock only when the app truly leaves the foreground. `inactive` also
    // fires on transient focus loss — including the biometric sheet ITSELF,
    // the notification shade, and permission dialogs — and re-locking there
    // made the fingerprint prompt reappear in a loop after every success.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (MenstrudelInit.settingsService?.areBiometricsEnabled == true) {
        _appLock.lock();
      }
    }
    if (state == AppLifecycleState.resumed) {
      if (path != '/stealth' &&
          MenstrudelInit.settingsService?.areBiometricsEnabled == true) {
        unawaited(_appLock.authenticateIfNeeded());
      }
      // Pick up any "log period" request the watch sent while we were away.
      MenstrudelInit.watchService?.processPendingWatchLog().then((_) {
        CycleSyncService().onCycleDataChanged();
      });
      _refreshRemindersOnResume();
    }
  }

  /// Re-lay the notification runway when returning to the app so the daily
  /// reminders keep extending 14 days out and reflect the latest cycle data.
  /// Throttled so rapid foreground/background cycling doesn't thrash.
  void _refreshRemindersOnResume() {
    final now = DateTime.now();
    final last = _lastReminderRefresh;
    if (last != null && now.difference(last) < _reminderRefreshEvery) return;
    _lastReminderRefresh = now;
    unawaited(NotificationService.scheduleFromPrefs());
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (!mounted) return;
    _router.go('/home');
    if (uri == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final path = uri.path.toLowerCase();
      if (path.contains('log')) {
        HomeShellActions.openLog?.call();
      } else if (path.contains('ai') || path.contains('chat')) {
        HomeShellActions.openAiChat?.call();
      } else if (path.contains('report')) {
        HomeShellActions.openReports?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeController = widget.localeController;
    final themeController = widget.themeController;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: themeController),
        ChangeNotifierProvider<AppLockController>.value(value: _appLock),
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => AuthRepository()),
          RepositoryProvider(create: (_) => FirebaseAiService()),
          RepositoryProvider(create: (_) => DirectGeminiService()),
          RepositoryProvider(create: (_) => AiGateway()),
          RepositoryProvider(create: (_) => AiContextEngine()),
          RepositoryProvider(
            create: (c) => AiInsightsService(
              contextEngine: c.read<AiContextEngine>(),
              gateway: c.read<AiGateway>(),
            ),
          ),
          RepositoryProvider(
            create: (c) => ChatRepository(gateway: c.read<AiGateway>()),
          ),
          RepositoryProvider(create: (_) => CycleBridgeService()),
          RepositoryProvider(create: (_) => CycleSyncService()),
          RepositoryProvider(create: (_) => CloudSyncService()),
          RepositoryProvider(create: (_) => CommunityRepository()),
          RepositoryProvider(create: (_) => CommunityStoryRepository()),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (c) =>
                  AuthBloc(c.read<AuthRepository>())..add(CheckAuthStatus()),
            ),
          ],
          child: ListenableBuilder(
            listenable: Listenable.merge([localeController, themeController]),
            builder: (context, _) {
              final locale = localeController.locale;
              syncWidgetLanguage(locale);

              return MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: PrivacyConstants.appName,
                locale: locale,
                localizationsDelegates: [
                  ...AppLocalizations.localizationsDelegates,
                  ...menstrudel_l10n.AppLocalizations.localizationsDelegates,
                ],
                supportedLocales: {
                  ...AppLocalizations.supportedLocales,
                  ...menstrudel_l10n.AppLocalizations.supportedLocales,
                }.toList(),
                theme: AppTheme.light(locale),
                darkTheme: AppTheme.dark(locale),
                themeMode: themeController.themeMode,
                routerConfig: _router,
                builder: (context, child) =>
                    AppLockOverlay(child: child ?? const SizedBox.shrink()),
              );
            },
          ),
        ),
      ),
    );
  }
}

void syncWidgetLanguage(Locale locale) {
  CycleBridgeService().applyLocale(locale.languageCode);
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _hasEmailAccount(User? user) {
  if (user == null) return false;
  final email = user.email?.trim();
  return email != null && email.isNotEmpty && !user.isAnonymous;
}

bool _canEnterHome(bool onboardingDone, User? user) {
  if (_hasEmailAccount(user)) return true;
  return onboardingDone;
}

Future<void> _bootstrapGuestSession() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final hasEmail = _hasEmailAccount(user);
    if (!hasEmail || user == null) {
      await GuestUserService().ensureSession().timeout(
        const Duration(seconds: 6),
      );
    }
    await GuestUserService().syncLocalProfileIfNeeded().timeout(
      const Duration(seconds: 6),
    );
    await PushRegistrationService().registerIfPossible();
  } catch (e, st) {
    debugPrint('[Main] Guest session bootstrap failed (non-fatal): $e\n$st');
  }
}

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final done = await UserPrefs.isOnboardingDone();
    final path = state.matchedLocation;
    final user = FirebaseAuth.instance.currentUser;
    final stealthEnabled = await UserPrefs.isStealthModeEnabled();
    final isUnlocked = UserPrefs.isSessionUnlocked();

    // Stealth mode: redirect to calculator screen if enabled and session is locked.
    if (stealthEnabled && _canEnterHome(done, user) && !isUnlocked) {
      if (path != '/stealth' &&
          path != '/login' &&
          path != '/register' &&
          path != '/forgot-password' &&
          path != '/welcome') {
        return '/stealth';
      }
    }

    // The web app enters its destination directly. Native platforms keep the
    // branded splash, which owns the destination decision after its intro.
    if (path == '/') {
      if (kIsWeb) {
        return _canEnterHome(done, user) ? '/home' : '/welcome';
      }
      return null;
    }

    // Auth + welcome screens are always reachable.
    if (path == '/login' ||
        path == '/register' ||
        path == '/forgot-password' ||
        path == '/stealth' ||
        path == '/welcome' ||
        path == '/onboarding') {
      if (path == '/welcome' && _hasEmailAccount(user)) {
        return '/home';
      }
      return null;
    }

    if (_canEnterHome(done, user)) {
      if (path == '/onboarding') return '/home';
      return null;
    }

    if (path == '/home') return '/welcome';

    // First-time users land on welcome hub (not home, not forced onboarding).
    return '/welcome';
  },
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
    GoRoute(
      path: '/stealth',
      builder: (_, _) => const StealthCalculatorScreen(),
    ),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/home', builder: (context, _) => _buildHome(context)),
    GoRoute(path: '/admin', builder: (_, _) => const AdminScreen()),
    GoRoute(path: '/ask', builder: (_, _) => const AnonymousQAScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: '/forgot-password',
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
  ],
);

Widget _buildHome(BuildContext context) {
  return const HomeShell();
}
