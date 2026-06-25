import 'package:cycle_aura/menstrudel/l10n/app_localizations.dart'
    as menstrudel_l10n;
import 'package:cycle_aura/menstrudel_integration/menstrudel_init.dart';
import 'package:cycle_aura/menstrudel_integration/menstrudel_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

import 'core/ai/ai_context_engine.dart';
import 'core/ai/ai_gateway.dart';
import 'core/ai/ai_insights_service.dart';
import 'core/ai/direct_gemini_service.dart';
import 'core/ai/firebase_ai_service.dart';
import 'core/config/app_secrets.dart';
import 'core/firebase/app_bootstrap.dart';
import 'core/locale/locale_cubit.dart';
import 'core/notifications/notification_service.dart';
import 'core/privacy/consent_manager.dart';
import 'core/privacy/privacy_constants.dart';
import 'core/security/cycle_encryption_keys.dart';
import 'core/storage/user_prefs.dart';
import 'core/theme/app_design_tokens.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/aura_scaffold.dart';
import 'core/theme/theme_cubit.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppBootstrap.initialize();

  // Load Gemini API key from build-time --dart-define only.
  // Does NOT overwrite any key the user has saved in Settings > Gemini key.
  if (AppSecrets.geminiApiKey.isNotEmpty) {
    final geminiService = DirectGeminiService();
    await geminiService.setKey(AppSecrets.geminiApiKey);
    if (kDebugMode) debugPrint('[Main] Gemini API key set from --dart-define');
  }

  tz_data.initializeTimeZones();
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
  } catch (_) {
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  await NotificationService.initialize();
  await MenstrudelInit.initialize();

  final keys = await CycleEncryptionKeys.loadOrCreate();
  MenstrualCycleWidget.init(
    secretKey: keys['secretKey'],
    ivKey: keys['ivKey'],
  );

  final localeCubit = LocaleCubit();
  await localeCubit.load();

  final themeCubit = ThemeCubit();
  await themeCubit.load();

  await NotificationService.scheduleFromPrefs();

  final bridge = CycleBridgeService();
  await bridge.applyLocale(localeCubit.locale.languageCode);
  await bridge.linkAuthenticatedUser(FirebaseAuth.instance.currentUser);
  await CycleSyncService().onCycleDataChanged();

  runApp(MenstrudelProviders(
    sharedPreferences: MenstrudelInit.prefs!,
    settingsService: MenstrudelInit.settingsService!,
    userService: MenstrudelInit.userService!,
    symptomService: MenstrudelInit.symptomService!,
    watchService: MenstrudelInit.watchService!,
    logsRepository: MenstrudelInit.logsRepository!,
    child: LuneApp(
      localeCubit: localeCubit,
      themeCubit: themeCubit,
    ),
  ));
}

class LuneApp extends StatefulWidget {
  const LuneApp({
    super.key,
    required this.localeCubit,
    required this.themeCubit,
  });

  final LocaleCubit localeCubit;
  final ThemeCubit themeCubit;

  @override
  State<LuneApp> createState() => _LuneAppState();
}

class _LuneAppState extends State<LuneApp> {
  @override
  void initState() {
    super.initState();
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetLaunch);
    HomeWidget.widgetClicked.listen(_handleWidgetLaunch);
  }

  void _handleWidgetLaunch(Uri? uri) {
    if (uri != null && mounted) {
      _router.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCubit = widget.localeCubit;
    final themeCubit = widget.themeCubit;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeCubit),
        ChangeNotifierProvider.value(value: themeCubit),
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
            listenable: Listenable.merge([localeCubit, themeCubit]),
            builder: (context, _) {
              final locale = localeCubit.locale;
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
                themeMode: themeCubit.themeMode,
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

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final done = await UserPrefs.isOnboardingDone();
    final path = state.matchedLocation;
    final stealthEnabled = await UserPrefs.isStealthModeEnabled();

    // Stealth mode: show calculator as the first screen.
    // The calculator internally navigates to /home when PIN is entered.
    if (stealthEnabled && done && path == '/') return '/stealth';

    // Auth screens are optional — never block them.
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
