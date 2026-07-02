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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'core/analytics/active_ping_service.dart';
import 'core/premium/play_billing_coordinator.dart';
import 'core/notifications/app_notifications.dart';

import 'core/ai/ai_context_engine.dart';
import 'core/ai/ai_gateway.dart';
import 'core/ai/ai_insights_service.dart';
import 'core/ai/direct_gemini_service.dart';
import 'core/ai/firebase_ai_service.dart';
import 'core/config/app_secrets.dart';
import 'core/config/feature_flags.dart';
import 'core/firebase/app_bootstrap.dart';
import 'core/ai/lune_personality.dart';
import 'core/locale/locale_controller.dart';
import 'core/navigation/home_shell_actions.dart';
import 'core/notifications/notification_service.dart';
import 'core/privacy/consent_manager.dart';
import 'core/privacy/privacy_constants.dart';
import 'core/security/cycle_encryption_keys.dart';
import 'core/storage/user_prefs.dart';
import 'core/theme/app_design_tokens.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/aura_scaffold.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/forgot_password_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
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
import 'features/sync/data/cloud_sync_service.dart';
import 'l10n/app_localizations.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await AppBootstrap.initialize();
  } catch (e, st) {
    debugPrint('[Main] AppBootstrap initialize failed: $e\n$st');
  }

  // Load Gemini API key from build-time --dart-define, but never overwrite a
  // user-supplied key already stored in SecureStorage. This prevents a stale
  // or invalid embedded default from wiping a working key entered via the
  // AI Diagnostic screen.
  try {
    if (AppSecrets.geminiApiKey.isNotEmpty) {
      final geminiService = DirectGeminiService();
      final alreadyHasKey = await geminiService.hasKey();
      if (!alreadyHasKey) {
        await geminiService.setKey(AppSecrets.geminiApiKey);
        if (kDebugMode) {
          debugPrint('[Main] Gemini API key seeded from --dart-define');
        }
      } else if (kDebugMode) {
        debugPrint('[Main] Gemini API key already present — keeping stored value');
      }
    }
  } catch (e) {
    debugPrint('[Main] Gemini key seeding failed: $e');
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

  // FCM token sync must not block startup when offline.
  try {
    unawaited(_registerFcmTokenIfSignedIn());
  } catch (e) {
    debugPrint('[Main] FCM registration trigger failed: $e');
  }

  // FCM foreground listener — show local notification when app is open
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
  final initialFcm = await FirebaseMessaging.instance.getInitialMessage();
  if (initialFcm != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleFcmLaunch(initialFcm);
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
    await CycleSyncService()
        .onCycleDataChanged()
        .timeout(const Duration(seconds: 10));
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

  runApp(MenstrudelProviders(
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
  ));
}

/// Registers FCM token in background — never blocks app launch.
Future<void> _registerFcmTokenIfSignedIn() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    final fcmToken = await FirebaseMessaging.instance
        .getToken()
        .timeout(const Duration(seconds: 8));
    if (fcmToken == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
          {
            'fcmToken': fcmToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        )
        .timeout(const Duration(seconds: 8));
  } catch (e) {
    if (kDebugMode) debugPrint('[Main] FCM token sync skipped: $e');
  }
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Pick up any "log period" request the watch sent while we were away.
      MenstrudelInit.watchService?.processPendingWatchLog().then((_) {
        CycleSyncService().onCycleDataChanged();
      });
    }
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
      ],
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider(create: (_) => AuthRepository()),
          RepositoryProvider(create: (_) => FirebaseAiService()),
          RepositoryProvider(create: (_) => DirectGeminiService()),
          RepositoryProvider(
            create: (c) => AiGateway(
              directGemini: c.read<DirectGeminiService>(),
            ),
          ),
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
              create: (c) => AuthBloc(c.read<AuthRepository>())
                ..add(CheckAuthStatus()),
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

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final done = await UserPrefs.isOnboardingDone();
    final path = state.matchedLocation;
    final stealthEnabled = await UserPrefs.isStealthModeEnabled();
    final isUnlocked = UserPrefs.isSessionUnlocked();

    // Stealth mode: redirect to calculator screen if enabled and session is locked.
    if (stealthEnabled && done && !isUnlocked) {
      if (path != '/stealth' &&
          path != '/login' &&
          path != '/register' &&
          path != '/forgot-password') {
        return '/stealth';
      }
    }

    // Auth screens and stealth screen are optional — never block them.
    if (path == '/login' ||
        path == '/register' ||
        path == '/forgot-password' ||
        path == '/stealth') {
      return null;
    }

    final privacyAccepted = await ConsentManager.hasAcceptedPrivacyPolicy();

    // First launch: go straight to onboarding (no splash wait).
    if (!done && path != '/onboarding') return '/onboarding';

    // Onboarding done but privacy never accepted — return to onboarding.
    if (done && !privacyAccepted && path != '/onboarding') {
      return '/onboarding';
    }

    // Already set up: skip splash/onboarding.
    if (done && (path == '/' || path == '/onboarding')) return '/home';

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, _) => const _SplashScreen()),
    GoRoute(path: '/stealth', builder: (_, _) => const StealthCalculatorScreen()),
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

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Redirect in GoRouter handles routing; splash is a brief branded moment only.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final done = await UserPrefs.isOnboardingDone();
      if (!mounted) return;
      context.go(done ? '/home' : '/onboarding');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppMeshBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecorations.primaryGradient,
                  boxShadow: AppShadows.softRose(opacity: 0.35),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.06, 1.06),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 24),
              Text(
                PrivacyConstants.appName,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 8),
              Text(
                'Your wellness, your rhythm',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
              const SizedBox(height: 32),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
