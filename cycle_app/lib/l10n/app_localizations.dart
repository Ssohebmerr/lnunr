import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get navLog;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get navWellness;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @navAi.
  ///
  /// In en, this message translates to:
  /// **'Lune AI'**
  String get navAi;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cycle has phases — like the moon'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your cycle locally. Cloud & AI are optional and encrypted.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lune'**
  String get welcomeHubTitle;

  /// No description provided for @welcomeHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start privately with your name, or sign in with your email if you already have an account.'**
  String get welcomeHubSubtitle;

  /// No description provided for @welcomeNewUser.
  ///
  /// In en, this message translates to:
  /// **'New user — set up privately'**
  String get welcomeNewUser;

  /// No description provided for @welcomeHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get welcomeHaveAccount;

  /// No description provided for @welcomeCreateEmailAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account with email'**
  String get welcomeCreateEmailAccount;

  /// No description provided for @accountLinkEmail.
  ///
  /// In en, this message translates to:
  /// **'Link email to account'**
  String get accountLinkEmail;

  /// No description provided for @accountEmailNotLinked.
  ///
  /// In en, this message translates to:
  /// **'No email linked yet'**
  String get accountEmailNotLinked;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @cycleLength.
  ///
  /// In en, this message translates to:
  /// **'Cycle length (days)'**
  String get cycleLength;

  /// No description provided for @periodDuration.
  ///
  /// In en, this message translates to:
  /// **'Period duration (days)'**
  String get periodDuration;

  /// No description provided for @lastPeriodDate.
  ///
  /// In en, this message translates to:
  /// **'Last period start date'**
  String get lastPeriodDate;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueBtn;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in for cloud features'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — your data stays on device by default'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account with email or Google — your data stays on your device by default'**
  String get registerSubtitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send a reset link.'**
  String get forgotPasswordHint;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetPassword;

  /// No description provided for @resetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent.'**
  String get resetSent;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatch;

  /// No description provided for @registerFieldsRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password.'**
  String get registerFieldsRequired;

  /// No description provided for @authPrivacyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the Privacy Policy and Terms to continue.'**
  String get authPrivacyRequired;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled.'**
  String get authErrorCancelled;

  /// No description provided for @authErrorGoogleConfig.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In is not configured on this build. Reinstall the latest app version.'**
  String get authErrorGoogleConfig;

  /// No description provided for @consentDataPurged.
  ///
  /// In en, this message translates to:
  /// **'Cloud data for this feature was removed.'**
  String get consentDataPurged;

  /// No description provided for @consentRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Turn off this feature?'**
  String get consentRevokeTitle;

  /// No description provided for @consentRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'Your consent will be withdrawn and cloud data for this feature will be deleted from our servers. Local data on your device stays.'**
  String get consentRevokeBody;

  /// No description provided for @consentRevokeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn off & delete cloud data'**
  String get consentRevokeConfirm;

  /// No description provided for @communityBirthYearTooYoung.
  ///
  /// In en, this message translates to:
  /// **'Community access is for adults 18+. Choose an earlier birth year.'**
  String get communityBirthYearTooYoung;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signUp;

  /// No description provided for @signInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get signInGoogle;

  /// No description provided for @signInApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get signInApple;

  /// No description provided for @skipLogin.
  ///
  /// In en, this message translates to:
  /// **'Continue without account'**
  String get skipLogin;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @aiTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune AI'**
  String get aiTitle;

  /// No description provided for @aiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lune means moon — ask about your phases, symptoms, or self-care. Not medical advice.'**
  String get aiSubtitle;

  /// No description provided for @aiWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hi! I\'m Lune — your moon-phase wellness companion.'**
  String get aiWelcome;

  /// No description provided for @aiWelcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Short, helpful answers about your cycle, mood, and self-care.'**
  String get aiWelcomeHint;

  /// No description provided for @aiSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'What helps with period cramps?'**
  String get aiSuggestion1;

  /// No description provided for @aiSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'What should I eat in my current phase?'**
  String get aiSuggestion2;

  /// No description provided for @aiSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'How is my cycle looking?'**
  String get aiSuggestion3;

  /// No description provided for @aiAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze my cycle'**
  String get aiAnalyze;

  /// No description provided for @aiPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message Lune...'**
  String get aiPlaceholder;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'Lune is thinking...'**
  String get aiThinking;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock advanced AI analysis & cloud backup'**
  String get premiumSubtitle;

  /// No description provided for @premiumFeature1.
  ///
  /// In en, this message translates to:
  /// **'Unlimited Lune chat & cycle analysis'**
  String get premiumFeature1;

  /// No description provided for @premiumFeature2.
  ///
  /// In en, this message translates to:
  /// **'Encrypted cloud backup'**
  String get premiumFeature2;

  /// No description provided for @premiumFeature3.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get premiumFeature3;

  /// No description provided for @premiumPlayHint.
  ///
  /// In en, this message translates to:
  /// **'Payment is handled securely by Google Play. Manage or cancel your subscription anytime in Play Store settings.'**
  String get premiumPlayHint;

  /// No description provided for @premiumPlayOnly.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are available on Android via Google Play.'**
  String get premiumPlayOnly;

  /// No description provided for @premiumProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product unavailable. Set up the subscription in Play Console first.'**
  String get premiumProductUnavailable;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @restorePurchasesDone.
  ///
  /// In en, this message translates to:
  /// **'Your purchases were checked.'**
  String get restorePurchasesDone;

  /// No description provided for @restorePurchasesChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking your purchases…'**
  String get restorePurchasesChecking;

  /// No description provided for @postpartumRecoveryWeek.
  ///
  /// In en, this message translates to:
  /// **'Recovery · week {week}'**
  String postpartumRecoveryWeek(int week);

  /// No description provided for @postpartumTodayFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s focus'**
  String get postpartumTodayFocus;

  /// No description provided for @postpartumYourBody.
  ///
  /// In en, this message translates to:
  /// **'Your body this stage'**
  String get postpartumYourBody;

  /// No description provided for @postpartumYourBaby.
  ///
  /// In en, this message translates to:
  /// **'Your baby this stage'**
  String get postpartumYourBaby;

  /// No description provided for @postpartumDailyRituals.
  ///
  /// In en, this message translates to:
  /// **'Daily rituals'**
  String get postpartumDailyRituals;

  /// No description provided for @postpartumWellbeingTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you, really?'**
  String get postpartumWellbeingTitle;

  /// No description provided for @postpartumWellbeingBody.
  ///
  /// In en, this message translates to:
  /// **'Mood swings in the early weeks are common. But if sadness, anxiety, or emptiness lasts more than two weeks, please reach out to your doctor — postpartum depression is real and treatable.'**
  String get postpartumWellbeingBody;

  /// No description provided for @postpartumSetDateTitle.
  ///
  /// In en, this message translates to:
  /// **'When was your baby born?'**
  String get postpartumSetDateTitle;

  /// No description provided for @postpartumSetDatePrompt.
  ///
  /// In en, this message translates to:
  /// **'Set your baby\'s birth date so we can guide your recovery week by week.'**
  String get postpartumSetDatePrompt;

  /// No description provided for @postpartumSetDateCta.
  ///
  /// In en, this message translates to:
  /// **'Set birth date'**
  String get postpartumSetDateCta;

  /// No description provided for @postpartumBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s birth date'**
  String get postpartumBirthDateLabel;

  /// No description provided for @conditionWhatToTrack.
  ///
  /// In en, this message translates to:
  /// **'What to track'**
  String get conditionWhatToTrack;

  /// No description provided for @conditionUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Understanding your body'**
  String get conditionUnderstanding;

  /// No description provided for @conditionDailyRituals.
  ///
  /// In en, this message translates to:
  /// **'Daily rituals'**
  String get conditionDailyRituals;

  /// No description provided for @conditionWhenToSeeDoctor.
  ///
  /// In en, this message translates to:
  /// **'When to see a doctor'**
  String get conditionWhenToSeeDoctor;

  /// No description provided for @goalMenopauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Menopause journey'**
  String get goalMenopauseTitle;

  /// No description provided for @goalPcosTitle.
  ///
  /// In en, this message translates to:
  /// **'PCOS management'**
  String get goalPcosTitle;

  /// No description provided for @conditionHowAreYouToday.
  ///
  /// In en, this message translates to:
  /// **'How are you today?'**
  String get conditionHowAreYouToday;

  /// No description provided for @conditionTapToLog.
  ///
  /// In en, this message translates to:
  /// **'Tap what you feel — it\'s saved for today.'**
  String get conditionTapToLog;

  /// No description provided for @conditionLoggedNamed.
  ///
  /// In en, this message translates to:
  /// **'Logged: {name}'**
  String conditionLoggedNamed(String name);

  /// No description provided for @conditionRemovedNamed.
  ///
  /// In en, this message translates to:
  /// **'Removed: {name}'**
  String conditionRemovedNamed(String name);

  /// No description provided for @conditionRitualsDoneToday.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done today'**
  String conditionRitualsDoneToday(int done, int total);

  /// No description provided for @conditionTrendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your trends'**
  String get conditionTrendsTitle;

  /// No description provided for @conditionTrendsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet — track your symptoms and rituals from the Home screen and your trends will appear here.'**
  String get conditionTrendsEmpty;

  /// No description provided for @conditionTrendLast14Days.
  ///
  /// In en, this message translates to:
  /// **'Last 14 days'**
  String get conditionTrendLast14Days;

  /// No description provided for @conditionTrendLast30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get conditionTrendLast30Days;

  /// No description provided for @conditionTrendLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get conditionTrendLast7Days;

  /// No description provided for @conditionTrendToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get conditionTrendToday;

  /// No description provided for @conditionTrendHotFlashes.
  ///
  /// In en, this message translates to:
  /// **'Hot flashes'**
  String get conditionTrendHotFlashes;

  /// No description provided for @conditionTrendMood.
  ///
  /// In en, this message translates to:
  /// **'Mood check-ins'**
  String get conditionTrendMood;

  /// No description provided for @conditionTrendSymptomsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Symptoms per day'**
  String get conditionTrendSymptomsPerDay;

  /// No description provided for @conditionTopSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Most frequent symptoms'**
  String get conditionTopSymptoms;

  /// No description provided for @conditionDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'Days logged'**
  String get conditionDaysLogged;

  /// No description provided for @conditionRitualCompletion.
  ///
  /// In en, this message translates to:
  /// **'Rituals done'**
  String get conditionRitualCompletion;

  /// No description provided for @conditionDoctorReportCta.
  ///
  /// In en, this message translates to:
  /// **'Doctor report (PDF)'**
  String get conditionDoctorReportCta;

  /// No description provided for @conditionReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Doctor summary report'**
  String get conditionReportTitle;

  /// No description provided for @conditionReportOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get conditionReportOverview;

  /// No description provided for @conditionReportGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Health focus'**
  String get conditionReportGoalLabel;

  /// No description provided for @conditionReportConsistency.
  ///
  /// In en, this message translates to:
  /// **'Tracking consistency'**
  String get conditionReportConsistency;

  /// No description provided for @conditionReportNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No daily logs in the last 30 days — track symptoms from the Home screen to enrich this report.'**
  String get conditionReportNoLogs;

  /// No description provided for @conditionReportTimes.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String conditionReportTimes(int count);

  /// No description provided for @conditionStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{days}-day logging streak'**
  String conditionStreakDays(int days);

  /// No description provided for @menopauseHotFlashesToday.
  ///
  /// In en, this message translates to:
  /// **'Hot flashes today'**
  String get menopauseHotFlashesToday;

  /// No description provided for @menopauseHotFlashHint.
  ///
  /// In en, this message translates to:
  /// **'Tap − / + each time one hits'**
  String get menopauseHotFlashHint;

  /// No description provided for @menopauseDaysSincePeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Since your last period'**
  String get menopauseDaysSincePeriodTitle;

  /// No description provided for @conditionDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String conditionDaysCount(int days);

  /// No description provided for @menopauseMilestoneHint.
  ///
  /// In en, this message translates to:
  /// **'12 period-free months marks menopause.'**
  String get menopauseMilestoneHint;

  /// No description provided for @menopauseMilestoneReached.
  ///
  /// In en, this message translates to:
  /// **'12 months period-free — you\'ve reached menopause. 🌿'**
  String get menopauseMilestoneReached;

  /// No description provided for @menopauseNeedPeriodData.
  ///
  /// In en, this message translates to:
  /// **'Log a period to start counting the gap.'**
  String get menopauseNeedPeriodData;

  /// No description provided for @pcosCycleGapTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle gap'**
  String get pcosCycleGapTitle;

  /// No description provided for @pcosTypicalCycle.
  ///
  /// In en, this message translates to:
  /// **'Your typical cycle is about {days} days.'**
  String pcosTypicalCycle(int days);

  /// No description provided for @pcosGapNormal.
  ///
  /// In en, this message translates to:
  /// **'You\'re within your usual range.'**
  String get pcosGapNormal;

  /// No description provided for @pcosGapLong.
  ///
  /// In en, this message translates to:
  /// **'Longer than usual — common with PCOS. Keep logging every period.'**
  String get pcosGapLong;

  /// No description provided for @pcosGapUnknown.
  ///
  /// In en, this message translates to:
  /// **'Log a couple of cycles so we can compare your gaps.'**
  String get pcosGapUnknown;

  /// No description provided for @postpartumMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get postpartumMoodTitle;

  /// No description provided for @postpartumMoodSaved.
  ///
  /// In en, this message translates to:
  /// **'Thanks for checking in 🤍'**
  String get postpartumMoodSaved;

  /// No description provided for @postpartumMoodLowSupport.
  ///
  /// In en, this message translates to:
  /// **'It\'s okay to not be okay. If this feeling lingers, please reach out to someone you trust or your doctor.'**
  String get postpartumMoodLowSupport;

  /// No description provided for @postpartumJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery journey'**
  String get postpartumJourneyTitle;

  /// No description provided for @postpartumJourneyCaption.
  ///
  /// In en, this message translates to:
  /// **'About {percent}% through your first year.'**
  String postpartumJourneyCaption(int percent);

  /// No description provided for @moodVeryLow.
  ///
  /// In en, this message translates to:
  /// **'Very low'**
  String get moodVeryLow;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get moodLow;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @activatePremiumTest.
  ///
  /// In en, this message translates to:
  /// **'Activate Premium (test)'**
  String get activatePremiumTest;

  /// No description provided for @planYearlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearlyTitle;

  /// No description provided for @planMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthlyTitle;

  /// No description provided for @planPerYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get planPerYear;

  /// No description provided for @planPerMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get planPerMonth;

  /// No description provided for @planBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get planBestValue;

  /// No description provided for @planUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable right now'**
  String get planUnavailable;

  /// No description provided for @planMonthlyEquivalent.
  ///
  /// In en, this message translates to:
  /// **'Equivalent to {price} / month'**
  String planMonthlyEquivalent(String price);

  /// No description provided for @planSaveBadge.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String planSaveBadge(int percent);

  /// No description provided for @communityMediaDisabled.
  ///
  /// In en, this message translates to:
  /// **'Photo and video uploads are temporarily disabled for community safety.'**
  String get communityMediaDisabled;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'Cycle data is encrypted on your device. Cloud sync and AI only run when you sign in and opt in.'**
  String get privacyBody;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premiumActive;

  /// No description provided for @notPremium.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get notPremium;

  /// No description provided for @phaseToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s phase'**
  String get phaseToday;

  /// No description provided for @nextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get nextPeriod;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @loginRequiredAi.
  ///
  /// In en, this message translates to:
  /// **'Sign in to chat with Lune AI'**
  String get loginRequiredAi;

  /// No description provided for @authOrEmail.
  ///
  /// In en, this message translates to:
  /// **'or continue with email'**
  String get authOrEmail;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @adminPromoTitle.
  ///
  /// In en, this message translates to:
  /// **'Promo codes'**
  String get adminPromoTitle;

  /// No description provided for @adminPromoManageBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage promo codes'**
  String get adminPromoManageBtn;

  /// No description provided for @adminPromoCreateHeader.
  ///
  /// In en, this message translates to:
  /// **'Create a code'**
  String get adminPromoCreateHeader;

  /// No description provided for @adminPromoCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. LUNE30)'**
  String get adminPromoCodeHint;

  /// No description provided for @adminPromoDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Premium days'**
  String get adminPromoDaysLabel;

  /// No description provided for @adminPromoMaxUsesLabel.
  ///
  /// In en, this message translates to:
  /// **'Max uses'**
  String get adminPromoMaxUsesLabel;

  /// No description provided for @adminPromoNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get adminPromoNoteHint;

  /// No description provided for @adminPromoCreateBtn.
  ///
  /// In en, this message translates to:
  /// **'Create code'**
  String get adminPromoCreateBtn;

  /// No description provided for @adminPromoCreatedMsg.
  ///
  /// In en, this message translates to:
  /// **'Code created'**
  String get adminPromoCreatedMsg;

  /// No description provided for @adminPromoExistingHeader.
  ///
  /// In en, this message translates to:
  /// **'Existing codes'**
  String get adminPromoExistingHeader;

  /// No description provided for @adminPromoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No codes yet'**
  String get adminPromoEmpty;

  /// No description provided for @adminPromoRevokeBtn.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get adminPromoRevokeBtn;

  /// No description provided for @adminPromoRevokedMsg.
  ///
  /// In en, this message translates to:
  /// **'Code revoked'**
  String get adminPromoRevokedMsg;

  /// No description provided for @adminPromoActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminPromoActiveLabel;

  /// No description provided for @adminPromoRevokedLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminPromoRevokedLabel;

  /// No description provided for @adminPromoUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get adminPromoUsedLabel;

  /// No description provided for @adminPromoCodeTooShort.
  ///
  /// In en, this message translates to:
  /// **'Code must be at least 3 characters'**
  String get adminPromoCodeTooShort;

  /// No description provided for @premiumDaysShort.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get premiumDaysShort;

  /// No description provided for @adminRolesTitle.
  ///
  /// In en, this message translates to:
  /// **'Admins and moderators'**
  String get adminRolesTitle;

  /// No description provided for @adminRolesManageBtn.
  ///
  /// In en, this message translates to:
  /// **'Manage admins'**
  String get adminRolesManageBtn;

  /// No description provided for @adminRolesAddHeader.
  ///
  /// In en, this message translates to:
  /// **'Add an admin'**
  String get adminRolesAddHeader;

  /// No description provided for @adminRolesEmailHint.
  ///
  /// In en, this message translates to:
  /// **'User email'**
  String get adminRolesEmailHint;

  /// No description provided for @adminRolesRoleModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get adminRolesRoleModerator;

  /// No description provided for @adminRolesRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminRolesRoleAdmin;

  /// No description provided for @adminRolesRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get adminRolesRoleOwner;

  /// No description provided for @adminRolesGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant role'**
  String get adminRolesGrant;

  /// No description provided for @adminRolesGranted.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get adminRolesGranted;

  /// No description provided for @adminRolesCurrentHeader.
  ///
  /// In en, this message translates to:
  /// **'Current admins'**
  String get adminRolesCurrentHeader;

  /// No description provided for @adminRolesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No admins yet'**
  String get adminRolesEmpty;

  /// No description provided for @adminRolesRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get adminRolesRemove;

  /// No description provided for @adminRolesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Admin removed'**
  String get adminRolesRemoved;

  /// No description provided for @adminRolesOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can add or remove admins.'**
  String get adminRolesOwnerOnly;

  /// No description provided for @adminRolesUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with that email'**
  String get adminRolesUserNotFound;

  /// No description provided for @loginRequiredPremium.
  ///
  /// In en, this message translates to:
  /// **'Sign in to subscribe'**
  String get loginRequiredPremium;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable reminders'**
  String get notificationsEnable;

  /// No description provided for @periodReminder.
  ///
  /// In en, this message translates to:
  /// **'Period reminder'**
  String get periodReminder;

  /// No description provided for @dailyLogReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily log reminder'**
  String get dailyLogReminder;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup'**
  String get cloudSync;

  /// No description provided for @cloudSyncEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable encrypted cloud backup'**
  String get cloudSyncEnable;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup synced successfully.'**
  String get syncSuccess;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Try again.'**
  String get syncFailed;

  /// No description provided for @syncNeedsPremium.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is a Premium feature.'**
  String get syncNeedsPremium;

  /// No description provided for @syncNeedsConsent.
  ///
  /// In en, this message translates to:
  /// **'Please enable cloud backup consent first.'**
  String get syncNeedsConsent;

  /// No description provided for @syncNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to use cloud backup.'**
  String get syncNotSignedIn;

  /// No description provided for @syncCycleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cycle data is not ready yet. Open the home screen, then try again.'**
  String get syncCycleUnavailable;

  /// No description provided for @syncNoBackupFound.
  ///
  /// In en, this message translates to:
  /// **'No cloud backup was found yet.'**
  String get syncNoBackupFound;

  /// No description provided for @localBackupExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Local backup is ready to share.'**
  String get localBackupExportSuccess;

  /// No description provided for @localBackupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export the local backup.'**
  String get localBackupExportFailed;

  /// No description provided for @localBackupImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not import this backup file.'**
  String get localBackupImportFailed;

  /// No description provided for @logSaved.
  ///
  /// In en, this message translates to:
  /// **'Log saved!'**
  String get logSaved;

  /// No description provided for @logSavedHint.
  ///
  /// In en, this message translates to:
  /// **'Stored on your device. See it on Home, in Reports, and in Insights.'**
  String get logSavedHint;

  /// No description provided for @logChangesDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Changes discarded'**
  String get logChangesDiscarded;

  /// No description provided for @logChangesDiscardedHint.
  ///
  /// In en, this message translates to:
  /// **'Reloaded the last saved data for this day — nothing new was saved.'**
  String get logChangesDiscardedHint;

  /// No description provided for @logSaveFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get logSaveFailedHint;

  /// No description provided for @homeTodayLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s log'**
  String get homeTodayLogTitle;

  /// No description provided for @homeTodayLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet today. Tap + to log mood and symptoms.'**
  String get homeTodayLogEmpty;

  /// No description provided for @homeTodayLogSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Mood & symptoms'**
  String get homeTodayLogSymptoms;

  /// No description provided for @homeTodayLogWater.
  ///
  /// In en, this message translates to:
  /// **'{count} cups of water'**
  String homeTodayLogWater(int count);

  /// No description provided for @homeTodayLogStoredHint.
  ///
  /// In en, this message translates to:
  /// **'Saved on your device — full charts in Reports → Insights'**
  String get homeTodayLogStoredHint;

  /// No description provided for @homeAiChipLabel.
  ///
  /// In en, this message translates to:
  /// **'Lune AI'**
  String get homeAiChipLabel;

  /// No description provided for @homeAiCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune AI'**
  String get homeAiCardTitle;

  /// No description provided for @homeAiCardTap.
  ///
  /// In en, this message translates to:
  /// **'Tap to start chatting'**
  String get homeAiCardTap;

  /// No description provided for @homeAiCardSubtitlePremium.
  ///
  /// In en, this message translates to:
  /// **'Your smart assistant — up to 30 messages daily'**
  String get homeAiCardSubtitlePremium;

  /// No description provided for @homeAiCardSubtitlePremiumOnly.
  ///
  /// In en, this message translates to:
  /// **'Premium only — tap to view plans'**
  String get homeAiCardSubtitlePremiumOnly;

  /// No description provided for @onboardingBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onboardingBirthDateLabel;

  /// No description provided for @onboardingBirthDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get onboardingBirthDateHint;

  /// No description provided for @onboardingBirthDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get onboardingBirthDateRequired;

  /// No description provided for @subscriptionPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune Premium'**
  String get subscriptionPlansTitle;

  /// No description provided for @subscriptionPlansHeadline.
  ///
  /// In en, this message translates to:
  /// **'More insight. More privacy. More support.'**
  String get subscriptionPlansHeadline;

  /// No description provided for @subscriptionPlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited chat, cycle analysis, encrypted cloud backup, and priority support.'**
  String get subscriptionPlansSubtitle;

  /// No description provided for @subscriptionPlansCta.
  ///
  /// In en, this message translates to:
  /// **'Subscribe with Google Play'**
  String get subscriptionPlansCta;

  /// No description provided for @subscriptionPlansAccountHint.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription in Account'**
  String get subscriptionPlansAccountHint;

  /// No description provided for @subscriptionChoosePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the plan that suits you'**
  String get subscriptionChoosePlanTitle;

  /// No description provided for @subscriptionChoosePlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All plans unlock the same Premium features. Cancel anytime through Google Play.'**
  String get subscriptionChoosePlanSubtitle;

  /// No description provided for @subscriptionSelectedCta.
  ///
  /// In en, this message translates to:
  /// **'Continue with {plan}'**
  String subscriptionSelectedCta(String plan);

  /// No description provided for @subscriptionLoadingPrice.
  ///
  /// In en, this message translates to:
  /// **'Loading price…'**
  String get subscriptionLoadingPrice;

  /// No description provided for @subscriptionSecurePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure payment through Google Play • Cancel anytime'**
  String get subscriptionSecurePayment;

  /// No description provided for @logTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily log'**
  String get logTabTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @weeklyCalendar.
  ///
  /// In en, this message translates to:
  /// **'Weekly view'**
  String get weeklyCalendar;

  /// No description provided for @graphsWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get graphsWeight;

  /// No description provided for @graphsSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get graphsSleep;

  /// No description provided for @graphsWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get graphsWater;

  /// No description provided for @graphsTemperature.
  ///
  /// In en, this message translates to:
  /// **'Body temperature'**
  String get graphsTemperature;

  /// No description provided for @graphsMeditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get graphsMeditation;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccount;

  /// No description provided for @geminiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key (optional local fallback)'**
  String get geminiKeyLabel;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Small Communities'**
  String get communityTitle;

  /// No description provided for @communityLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage blocking and reports'**
  String get communityLoginRequired;

  /// No description provided for @communityPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your cycle logs never leave your device. Communities use a nickname only.'**
  String get communityPrivacyNote;

  /// No description provided for @communityYourAlias.
  ///
  /// In en, this message translates to:
  /// **'Your community nickname'**
  String get communityYourAlias;

  /// No description provided for @communityBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse groups'**
  String get communityBrowse;

  /// No description provided for @communityRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get communityRecommendedTitle;

  /// No description provided for @communityJoinedBadge.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get communityJoinedBadge;

  /// No description provided for @communityDiscoverNew.
  ///
  /// In en, this message translates to:
  /// **'Discover groups'**
  String get communityDiscoverNew;

  /// No description provided for @communityDiscoverJoined.
  ///
  /// In en, this message translates to:
  /// **'Your groups'**
  String get communityDiscoverJoined;

  /// No description provided for @communityDiscoverNoResults.
  ///
  /// In en, this message translates to:
  /// **'No groups match your search. Try another category or clear filters.'**
  String get communityDiscoverNoResults;

  /// No description provided for @communityClosedBadge.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get communityClosedBadge;

  /// No description provided for @communityFeedBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse all groups'**
  String get communityFeedBrowseTitle;

  /// No description provided for @communityFeedBrowseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The feed shows your joined groups only — explore more communities here.'**
  String get communityFeedBrowseSubtitle;

  /// No description provided for @communitySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a nickname'**
  String get communitySetupTitle;

  /// No description provided for @communitySetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a nickname — not your real name. Cycle data is never shared.'**
  String get communitySetupSubtitle;

  /// No description provided for @communityAliasLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get communityAliasLabel;

  /// No description provided for @communityAliasHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Luna_92'**
  String get communityAliasHint;

  /// No description provided for @communityJoin.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get communityJoin;

  /// No description provided for @communityLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get communityLeave;

  /// No description provided for @communityJoined.
  ///
  /// In en, this message translates to:
  /// **'You joined the group'**
  String get communityJoined;

  /// No description provided for @communityLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the group'**
  String get communityLeft;

  /// No description provided for @communityNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get communityNewPost;

  /// No description provided for @communityPostHint.
  ///
  /// In en, this message translates to:
  /// **'Share support, ask a question...'**
  String get communityPostHint;

  /// No description provided for @communityPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get communityPublish;

  /// No description provided for @communityPostPublished.
  ///
  /// In en, this message translates to:
  /// **'Post published'**
  String get communityPostPublished;

  /// No description provided for @communityModerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Post not approved'**
  String get communityModerationFailed;

  /// No description provided for @communityDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Peer support only — not medical advice. Posts are reviewed by AI.'**
  String get communityDisclaimer;

  /// No description provided for @communityNoPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet. Be the first to share!'**
  String get communityNoPosts;

  /// No description provided for @communityPostDetail.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get communityPostDetail;

  /// No description provided for @communityComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get communityComments;

  /// No description provided for @communityNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get communityNoComments;

  /// No description provided for @communityCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a supportive comment...'**
  String get communityCommentHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @navAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get navAnalysis;

  /// No description provided for @accountMenuAi.
  ///
  /// In en, this message translates to:
  /// **'Lune chat'**
  String get accountMenuAi;

  /// No description provided for @accountMenuCalendar.
  ///
  /// In en, this message translates to:
  /// **'Period & calendar'**
  String get accountMenuCalendar;

  /// No description provided for @accountMenuInsights.
  ///
  /// In en, this message translates to:
  /// **'Cycle insights'**
  String get accountMenuInsights;

  /// No description provided for @accountMenuEducation.
  ///
  /// In en, this message translates to:
  /// **'Learn & guides'**
  String get accountMenuEducation;

  /// No description provided for @accountMenuCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get accountMenuCommunity;

  /// No description provided for @accountMenuReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get accountMenuReminders;

  /// No description provided for @accountMenuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get accountMenuSettings;

  /// No description provided for @accountStatCycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get accountStatCycles;

  /// No description provided for @accountStatAvgCycle.
  ///
  /// In en, this message translates to:
  /// **'Avg cycle'**
  String get accountStatAvgCycle;

  /// No description provided for @accountStatAvgPeriod.
  ///
  /// In en, this message translates to:
  /// **'Avg period'**
  String get accountStatAvgPeriod;

  /// No description provided for @accountQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get accountQuickActions;

  /// No description provided for @accountMenuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & instructions'**
  String get accountMenuHelp;

  /// No description provided for @homeExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get homeExplore;

  /// No description provided for @homeUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Updates & news'**
  String get homeUpdatesTitle;

  /// No description provided for @homeUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Announcements and offers'**
  String get homeUpdatesSubtitle;

  /// No description provided for @homeMoreThisWeek.
  ///
  /// In en, this message translates to:
  /// **'More this week'**
  String get homeMoreThisWeek;

  /// No description provided for @homeGoalMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More for your goal'**
  String get homeGoalMoreTitle;

  /// No description provided for @homeGoalMoreGeneral.
  ///
  /// In en, this message translates to:
  /// **'Stats, dates, tips & education'**
  String get homeGoalMoreGeneral;

  /// No description provided for @homeGoalMoreConceive.
  ///
  /// In en, this message translates to:
  /// **'Fertility stats, tips & guides'**
  String get homeGoalMoreConceive;

  /// No description provided for @homeGoalMoreAvoid.
  ///
  /// In en, this message translates to:
  /// **'Protection stats, tips & guides'**
  String get homeGoalMoreAvoid;

  /// No description provided for @homeQuickLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get homeQuickLog;

  /// No description provided for @homeQuickAi.
  ///
  /// In en, this message translates to:
  /// **'AI chat'**
  String get homeQuickAi;

  /// No description provided for @homeQuickCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get homeQuickCalendar;

  /// No description provided for @reportsChecklistHint.
  ///
  /// In en, this message translates to:
  /// **'Your personalized action list'**
  String get reportsChecklistHint;

  /// No description provided for @insightsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights & reports'**
  String get insightsHubTitle;

  /// No description provided for @insightsHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your cycle at a glance, the charts behind it, and a doctor-ready record.'**
  String get insightsHubSubtitle;

  /// No description provided for @insightsHubTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get insightsHubTabOverview;

  /// No description provided for @insightsHubTabCharts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get insightsHubTabCharts;

  /// No description provided for @insightsHubTabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get insightsHubTabHistory;

  /// No description provided for @insightsHubChartsTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed charts'**
  String get insightsHubChartsTitle;

  /// No description provided for @insightsHubChartsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trends from everything you log.'**
  String get insightsHubChartsSubtitle;

  /// No description provided for @insightsHubSymptomPatternsCta.
  ///
  /// In en, this message translates to:
  /// **'See when your symptoms tend to appear in your cycle'**
  String get insightsHubSymptomPatternsCta;

  /// No description provided for @reportsPregnancyOverview.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy overview'**
  String get reportsPregnancyOverview;

  /// No description provided for @reportsMenopauseOverview.
  ///
  /// In en, this message translates to:
  /// **'Menopause overview'**
  String get reportsMenopauseOverview;

  /// No description provided for @reportsPcosOverview.
  ///
  /// In en, this message translates to:
  /// **'PCOS overview'**
  String get reportsPcosOverview;

  /// No description provided for @reportsRecoveryOverview.
  ///
  /// In en, this message translates to:
  /// **'Recovery overview'**
  String get reportsRecoveryOverview;

  /// No description provided for @goalModeGeneralReportStats.
  ///
  /// In en, this message translates to:
  /// **'Cycle overview'**
  String get goalModeGeneralReportStats;

  /// No description provided for @goalModeConceiveReportStats.
  ///
  /// In en, this message translates to:
  /// **'Fertility overview'**
  String get goalModeConceiveReportStats;

  /// No description provided for @goalModeAvoidReportStats.
  ///
  /// In en, this message translates to:
  /// **'Protection overview'**
  String get goalModeAvoidReportStats;

  /// No description provided for @selfCareMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'More self-care'**
  String get selfCareMoreTitle;

  /// No description provided for @selfCareMoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI tips, challenges, rituals & wellness hub'**
  String get selfCareMoreSubtitle;

  /// No description provided for @accountSectionTools.
  ///
  /// In en, this message translates to:
  /// **'Tools & features'**
  String get accountSectionTools;

  /// No description provided for @accountSectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get accountSectionPersonal;

  /// No description provided for @accountSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support & settings'**
  String get accountSectionSupport;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @wellnessHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Wellness Hub'**
  String get wellnessHubTitle;

  /// No description provided for @wellnessHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Birth control, symptoms, and daily care — all in one place.'**
  String get wellnessHubSubtitle;

  /// No description provided for @wellnessCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize goals'**
  String get wellnessCustomize;

  /// No description provided for @wellnessSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load wellness features. Please try again.'**
  String get wellnessSetupFailed;

  /// No description provided for @wellnessDailyLog.
  ///
  /// In en, this message translates to:
  /// **'Symptom journal'**
  String get wellnessDailyLog;

  /// No description provided for @wellnessDailyLogDesc.
  ///
  /// In en, this message translates to:
  /// **'Log mood, pain, and daily symptoms'**
  String get wellnessDailyLogDesc;

  /// No description provided for @wellnessPills.
  ///
  /// In en, this message translates to:
  /// **'Birth control pills'**
  String get wellnessPills;

  /// No description provided for @wellnessPillsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track your pill pack and reminders'**
  String get wellnessPillsDesc;

  /// No description provided for @wellnessSanitary.
  ///
  /// In en, this message translates to:
  /// **'Sanitary products'**
  String get wellnessSanitary;

  /// No description provided for @wellnessSanitaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Products, timers, and period care'**
  String get wellnessSanitaryDesc;

  /// No description provided for @wellnessSex.
  ///
  /// In en, this message translates to:
  /// **'Sex activity'**
  String get wellnessSex;

  /// No description provided for @wellnessSexDesc.
  ///
  /// In en, this message translates to:
  /// **'Private activity log and insights'**
  String get wellnessSexDesc;

  /// No description provided for @wellnessLarc.
  ///
  /// In en, this message translates to:
  /// **'LARC / IUD'**
  String get wellnessLarc;

  /// No description provided for @wellnessLarcDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-acting reversible contraceptives'**
  String get wellnessLarcDesc;

  /// No description provided for @navSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Self-care'**
  String get navSelfCare;

  /// No description provided for @selfCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-care space'**
  String get selfCareTitle;

  /// No description provided for @selfCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Breathe, reflect, and care for yourself through every phase.'**
  String get selfCareSubtitle;

  /// No description provided for @selfCareTodayTip.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tip'**
  String get selfCareTodayTip;

  /// No description provided for @selfCareActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get selfCareActivities;

  /// No description provided for @selfCareBreathe.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get selfCareBreathe;

  /// No description provided for @selfCareBreatheDesc.
  ///
  /// In en, this message translates to:
  /// **'Box breathing — 4 seconds each phase'**
  String get selfCareBreatheDesc;

  /// No description provided for @selfCareStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get selfCareStart;

  /// No description provided for @selfCarePause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get selfCarePause;

  /// No description provided for @selfCareAffirmations.
  ///
  /// In en, this message translates to:
  /// **'Affirmations'**
  String get selfCareAffirmations;

  /// No description provided for @selfCareJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get selfCareJournal;

  /// No description provided for @selfCareJournalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Prompt'**
  String get selfCareJournalPrompt;

  /// No description provided for @selfCareJournalHint.
  ///
  /// In en, this message translates to:
  /// **'Write freely — stored only on your device'**
  String get selfCareJournalHint;

  /// No description provided for @selfCareJournalSave.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get selfCareJournalSave;

  /// No description provided for @selfCareJournalSaved.
  ///
  /// In en, this message translates to:
  /// **'Journal saved'**
  String get selfCareJournalSaved;

  /// No description provided for @selfCareStretch.
  ///
  /// In en, this message translates to:
  /// **'Gentle stretch'**
  String get selfCareStretch;

  /// No description provided for @selfCareStretchTip.
  ///
  /// In en, this message translates to:
  /// **'Try 5 minutes of neck and hip stretches today.'**
  String get selfCareStretchTip;

  /// No description provided for @selfCareRituals.
  ///
  /// In en, this message translates to:
  /// **'Daily rituals'**
  String get selfCareRituals;

  /// No description provided for @selfCareRitualWater.
  ///
  /// In en, this message translates to:
  /// **'Drank enough water'**
  String get selfCareRitualWater;

  /// No description provided for @selfCareRitualRest.
  ///
  /// In en, this message translates to:
  /// **'Took time to rest'**
  String get selfCareRitualRest;

  /// No description provided for @selfCareRitualStretch.
  ///
  /// In en, this message translates to:
  /// **'Gentle movement'**
  String get selfCareRitualStretch;

  /// No description provided for @selfCareRitualMindful.
  ///
  /// In en, this message translates to:
  /// **'5 min mindfulness'**
  String get selfCareRitualMindful;

  /// No description provided for @selfCareHealthTools.
  ///
  /// In en, this message translates to:
  /// **'Health tracking'**
  String get selfCareHealthTools;

  /// No description provided for @selfCareHealthToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Pills, sanitary, sex & more'**
  String get selfCareHealthToolsDesc;

  /// No description provided for @selfCareWhisperTitle.
  ///
  /// In en, this message translates to:
  /// **'Whisper of the day'**
  String get selfCareWhisperTitle;

  /// No description provided for @selfCareWhisperLocked.
  ///
  /// In en, this message translates to:
  /// **'Unlock Lune\'s personal whisper with Premium.'**
  String get selfCareWhisperLocked;

  /// No description provided for @selfCareWhisperPrompt.
  ///
  /// In en, this message translates to:
  /// **'Give me a gentle self-care whisper for today based on my cycle phase and mood.'**
  String get selfCareWhisperPrompt;

  /// No description provided for @moodCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get moodCheckInTitle;

  /// No description provided for @moodCheckInDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s mood is logged 🌸'**
  String get moodCheckInDone;

  /// No description provided for @moodTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get moodTrendTitle;

  /// No description provided for @selfCareAffirmationGenerate.
  ///
  /// In en, this message translates to:
  /// **'Personal affirmation from Lune'**
  String get selfCareAffirmationGenerate;

  /// No description provided for @selfCareAffirmationPrompt.
  ///
  /// In en, this message translates to:
  /// **'Write one short, uplifting first-person affirmation for me based on my cycle phase and mood.'**
  String get selfCareAffirmationPrompt;

  /// No description provided for @selfCareMovement.
  ///
  /// In en, this message translates to:
  /// **'Gentle movement'**
  String get selfCareMovement;

  /// No description provided for @selfCareMovementStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String selfCareMovementStep(int current, int total);

  /// No description provided for @selfCareMovementDone.
  ///
  /// In en, this message translates to:
  /// **'Beautifully done 🌸'**
  String get selfCareMovementDone;

  /// No description provided for @selfCareMovementDoneCue.
  ///
  /// In en, this message translates to:
  /// **'Take a moment to notice how your body feels.'**
  String get selfCareMovementDoneCue;

  /// No description provided for @selfCareRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get selfCareRestart;

  /// No description provided for @selfCareSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get selfCareSkip;

  /// No description provided for @selfCareBreatheCycles.
  ///
  /// In en, this message translates to:
  /// **'{count} cycles completed'**
  String selfCareBreatheCycles(int count);

  /// No description provided for @selfCareCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get selfCareCopied;

  /// No description provided for @selfCareLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle self-care guide'**
  String get selfCareLibraryTitle;

  /// No description provided for @selfCareLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition, movement, rest & mind for every phase.'**
  String get selfCareLibrarySubtitle;

  /// No description provided for @selfCareLibraryCurrent.
  ///
  /// In en, this message translates to:
  /// **'You\'re here'**
  String get selfCareLibraryCurrent;

  /// No description provided for @selfCareJournalHistory.
  ///
  /// In en, this message translates to:
  /// **'Past entries'**
  String get selfCareJournalHistory;

  /// No description provided for @selfCareJournalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Write your first reflection above.'**
  String get selfCareJournalEmpty;

  /// No description provided for @selfCareJournalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get selfCareJournalDelete;

  /// No description provided for @selfCareJournalReflect.
  ///
  /// In en, this message translates to:
  /// **'Reflect with Lune'**
  String get selfCareJournalReflect;

  /// No description provided for @selfCareJournalReflecting.
  ///
  /// In en, this message translates to:
  /// **'Lune is reflecting on your words…'**
  String get selfCareJournalReflecting;

  /// No description provided for @selfCareRitualStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String selfCareRitualStreak(int days);

  /// No description provided for @selfCareRitualsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String selfCareRitualsProgress(int done, int total);

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @aiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lune is unavailable right now. Please try again later.'**
  String get aiUnavailable;

  /// No description provided for @communityTabFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get communityTabFeed;

  /// No description provided for @communityTabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get communityTabDiscover;

  /// No description provided for @communityTabMine.
  ///
  /// In en, this message translates to:
  /// **'My groups'**
  String get communityTabMine;

  /// No description provided for @communityFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Join a group to see posts from your communities here.'**
  String get communityFeedEmpty;

  /// No description provided for @communityMineEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any groups yet.'**
  String get communityMineEmpty;

  /// No description provided for @communitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search communities...'**
  String get communitySearchHint;

  /// No description provided for @communityCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityCatAll;

  /// No description provided for @communityCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get communityCatGeneral;

  /// No description provided for @communityCatConception.
  ///
  /// In en, this message translates to:
  /// **'Fertility'**
  String get communityCatConception;

  /// No description provided for @communityCatContraception.
  ///
  /// In en, this message translates to:
  /// **'Birth control'**
  String get communityCatContraception;

  /// No description provided for @communityCatCondition.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get communityCatCondition;

  /// No description provided for @communityCatSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get communityCatSupport;

  /// No description provided for @communityPostsTab.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get communityPostsTab;

  /// No description provided for @communityAboutTab.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get communityAboutTab;

  /// No description provided for @communityRules.
  ///
  /// In en, this message translates to:
  /// **'Community rules'**
  String get communityRules;

  /// No description provided for @communityPostType.
  ///
  /// In en, this message translates to:
  /// **'Post type'**
  String get communityPostType;

  /// No description provided for @communityReported.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you.'**
  String get communityReported;

  /// No description provided for @communityAliasTooShort.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be at least 2 characters'**
  String get communityAliasTooShort;

  /// No description provided for @communityAliasInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a nickname without spaces or email'**
  String get communityAliasInvalid;

  /// No description provided for @communityBirthYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth year'**
  String get communityBirthYearLabel;

  /// No description provided for @communityBirthYearRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your birth year'**
  String get communityBirthYearRequired;

  /// No description provided for @communityBirthYearWhy.
  ///
  /// In en, this message translates to:
  /// **'Used only to keep the community safe for younger members. It is never shown to anyone.'**
  String get communityBirthYearWhy;

  /// No description provided for @communityMinorBanner.
  ///
  /// In en, this message translates to:
  /// **'You can read posts, but joining, posting, and commenting unlock at 18 — this keeps you safe.'**
  String get communityMinorBanner;

  /// No description provided for @communityMinorRestricted.
  ///
  /// In en, this message translates to:
  /// **'Joining and posting are available from age 18.'**
  String get communityMinorRestricted;

  /// No description provided for @communityBannedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is banned from the community. Contact support if this is a mistake.'**
  String get communityBannedMessage;

  /// No description provided for @communityFull.
  ///
  /// In en, this message translates to:
  /// **'This community is full. Try another group.'**
  String get communityFull;

  /// No description provided for @communityPostNotFound.
  ///
  /// In en, this message translates to:
  /// **'This post is no longer available.'**
  String get communityPostNotFound;

  /// No description provided for @communityBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block author'**
  String get communityBlockUser;

  /// No description provided for @communityBlocked.
  ///
  /// In en, this message translates to:
  /// **'Author blocked. You won\'t see their posts anymore.'**
  String get communityBlocked;

  /// No description provided for @communityReportPost.
  ///
  /// In en, this message translates to:
  /// **'Report post'**
  String get communityReportPost;

  /// No description provided for @communityReportComment.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get communityReportComment;

  /// No description provided for @communityReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting?'**
  String get communityReportTitle;

  /// No description provided for @communityReportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment or bullying'**
  String get communityReportReasonHarassment;

  /// No description provided for @communityReportReasonHate.
  ///
  /// In en, this message translates to:
  /// **'Hate speech'**
  String get communityReportReasonHate;

  /// No description provided for @communityReportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or ads'**
  String get communityReportReasonSpam;

  /// No description provided for @communityReportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get communityReportReasonInappropriate;

  /// No description provided for @communityReportReasonMisinformation.
  ///
  /// In en, this message translates to:
  /// **'Misinformation'**
  String get communityReportReasonMisinformation;

  /// No description provided for @communityReportReasonSelfHarm.
  ///
  /// In en, this message translates to:
  /// **'Self-harm or danger'**
  String get communityReportReasonSelfHarm;

  /// No description provided for @communityReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get communityReportReasonOther;

  /// No description provided for @communityBlockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this author?'**
  String get communityBlockConfirmTitle;

  /// No description provided for @communityBlockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see posts or comments from {alias} anymore.'**
  String communityBlockConfirmMessage(String alias);

  /// No description provided for @communityBlockConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get communityBlockConfirmAction;

  /// No description provided for @communityBlockCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get communityBlockCancel;

  /// No description provided for @communityBlockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get communityBlockedUsersTitle;

  /// No description provided for @communityBlockedUsersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage who you blocked in communities'**
  String get communityBlockedUsersSubtitle;

  /// No description provided for @communityBlockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No blocked users.'**
  String get communityBlockedUsersEmpty;

  /// No description provided for @communityBlockedUserUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get communityBlockedUserUnknown;

  /// No description provided for @communityUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get communityUnblockUser;

  /// No description provided for @communityUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked.'**
  String get communityUnblocked;

  /// No description provided for @accountBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Community blocked users'**
  String get accountBlockedUsers;

  /// No description provided for @aiInsightDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tip for you'**
  String get aiInsightDailyTitle;

  /// No description provided for @aiInsightMoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Your emotional weather'**
  String get aiInsightMoodTitle;

  /// No description provided for @aiInsightCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cycle health'**
  String get aiInsightCycleTitle;

  /// No description provided for @aiInsightWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week in review'**
  String get aiInsightWeeklyTitle;

  /// No description provided for @aiInsightBadge.
  ///
  /// In en, this message translates to:
  /// **'Aura AI'**
  String get aiInsightBadge;

  /// No description provided for @aiInsightRefresh.
  ///
  /// In en, this message translates to:
  /// **'New insight'**
  String get aiInsightRefresh;

  /// No description provided for @aiInsightDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI-generated wellness suggestion — not medical advice.'**
  String get aiInsightDisclaimer;

  /// No description provided for @doctorReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cycle Report'**
  String get doctorReportTitle;

  /// No description provided for @doctorReportButton.
  ///
  /// In en, this message translates to:
  /// **'View full report'**
  String get doctorReportButton;

  /// No description provided for @doctorReportGenerating.
  ///
  /// In en, this message translates to:
  /// **'Preparing your report...'**
  String get doctorReportGenerating;

  /// No description provided for @doctorReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Cycle data isn\'t ready yet. Open the home screen, then try again.'**
  String get doctorReportFailed;

  /// No description provided for @doctorReportRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get doctorReportRetry;

  /// No description provided for @doctorReportLimitedData.
  ///
  /// In en, this message translates to:
  /// **'This report is based on limited data. Logging several completed cycle starts enables personal accuracy measurement and a better prediction window.'**
  String get doctorReportLimitedData;

  /// No description provided for @doctorReportAiTitle.
  ///
  /// In en, this message translates to:
  /// **'AI assistant notes'**
  String get doctorReportAiTitle;

  /// No description provided for @doctorReportAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helpful context for your doctor visit — not a diagnosis.'**
  String get doctorReportAiSubtitle;

  /// No description provided for @doctorReportAiLoading.
  ///
  /// In en, this message translates to:
  /// **'AI is reviewing your data…'**
  String get doctorReportAiLoading;

  /// No description provided for @doctorReportAiFailed.
  ///
  /// In en, this message translates to:
  /// **'AI notes could not be generated right now. Your cycle data above is still complete.'**
  String get doctorReportAiFailed;

  /// No description provided for @doctorReportAiNeedsConsent.
  ///
  /// In en, this message translates to:
  /// **'Enable AI in Privacy settings to get assistant notes for your report.'**
  String get doctorReportAiNeedsConsent;

  /// No description provided for @doctorReportAiEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable AI assistant'**
  String get doctorReportAiEnable;

  /// No description provided for @doctorReportCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get doctorReportCopy;

  /// No description provided for @doctorReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied'**
  String get doctorReportCopied;

  /// No description provided for @doctorReportShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get doctorReportShare;

  /// No description provided for @doctorReportDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get doctorReportDownload;

  /// No description provided for @doctorReportExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export report'**
  String get doctorReportExportTitle;

  /// No description provided for @doctorReportExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a file format to save or share'**
  String get doctorReportExportSubtitle;

  /// No description provided for @doctorReportExportPdf.
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get doctorReportExportPdf;

  /// No description provided for @doctorReportExportPdfHint.
  ///
  /// In en, this message translates to:
  /// **'Best for printing or sending to your doctor'**
  String get doctorReportExportPdfHint;

  /// No description provided for @doctorReportExportTxt.
  ///
  /// In en, this message translates to:
  /// **'Text file (.txt)'**
  String get doctorReportExportTxt;

  /// No description provided for @doctorReportExportTxtHint.
  ///
  /// In en, this message translates to:
  /// **'Plain text — works everywhere'**
  String get doctorReportExportTxtHint;

  /// No description provided for @doctorReportExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet (.csv)'**
  String get doctorReportExportCsv;

  /// No description provided for @doctorReportExportCsvHint.
  ///
  /// In en, this message translates to:
  /// **'Open in Excel or Google Sheets'**
  String get doctorReportExportCsvHint;

  /// No description provided for @doctorReportExportJson.
  ///
  /// In en, this message translates to:
  /// **'JSON data (.json)'**
  String get doctorReportExportJson;

  /// No description provided for @doctorReportExportJsonHint.
  ///
  /// In en, this message translates to:
  /// **'Structured data for apps and backups'**
  String get doctorReportExportJsonHint;

  /// No description provided for @doctorReportExporting.
  ///
  /// In en, this message translates to:
  /// **'Preparing file...'**
  String get doctorReportExporting;

  /// No description provided for @doctorReportExportShared.
  ///
  /// In en, this message translates to:
  /// **'File ready — pick where to save it'**
  String get doctorReportExportShared;

  /// No description provided for @doctorReportExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get doctorReportExportFailed;

  /// No description provided for @doctorReportDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Personal tracking summary from the app — not a medical diagnosis. Always consult your healthcare provider.'**
  String get doctorReportDisclaimer;

  /// No description provided for @healthReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Report'**
  String get healthReportTitle;

  /// No description provided for @healthReportClinicalSummary.
  ///
  /// In en, this message translates to:
  /// **'Clinical summary'**
  String get healthReportClinicalSummary;

  /// No description provided for @healthReportObservedPatterns.
  ///
  /// In en, this message translates to:
  /// **'Observed patterns'**
  String get healthReportObservedPatterns;

  /// No description provided for @healthReportDiscussionPoints.
  ///
  /// In en, this message translates to:
  /// **'Points for discussion'**
  String get healthReportDiscussionPoints;

  /// No description provided for @doctorReportRefining.
  ///
  /// In en, this message translates to:
  /// **'Finalizing clinical summary…'**
  String get doctorReportRefining;

  /// No description provided for @healthReportCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Created by Lune'**
  String get healthReportCreatedBy;

  /// No description provided for @healthReportExportedOn.
  ///
  /// In en, this message translates to:
  /// **'Exported on: {date}'**
  String healthReportExportedOn(String date);

  /// No description provided for @healthReportCyclePeriodLength.
  ///
  /// In en, this message translates to:
  /// **'Cycle and Period Length'**
  String get healthReportCyclePeriodLength;

  /// No description provided for @healthReportPredictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get healthReportPredictions;

  /// No description provided for @healthReportCycleHistorySummary.
  ///
  /// In en, this message translates to:
  /// **'Cycle History Summary'**
  String get healthReportCycleHistorySummary;

  /// No description provided for @healthReportSymptomPatternsSummary.
  ///
  /// In en, this message translates to:
  /// **'Symptom Patterns Summary'**
  String get healthReportSymptomPatternsSummary;

  /// No description provided for @healthReportPrevCycleLength.
  ///
  /// In en, this message translates to:
  /// **'Previous cycle length'**
  String get healthReportPrevCycleLength;

  /// No description provided for @healthReportPrevPeriodDuration.
  ///
  /// In en, this message translates to:
  /// **'Previous period duration'**
  String get healthReportPrevPeriodDuration;

  /// No description provided for @healthReportCycleRegularityScore.
  ///
  /// In en, this message translates to:
  /// **'Cycle regularity score'**
  String get healthReportCycleRegularityScore;

  /// No description provided for @healthReportPeriodRegularityScore.
  ///
  /// In en, this message translates to:
  /// **'Period regularity score'**
  String get healthReportPeriodRegularityScore;

  /// No description provided for @healthReportNextPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Next period day'**
  String get healthReportNextPeriodDay;

  /// No description provided for @healthReportNextOvulationDay.
  ///
  /// In en, this message translates to:
  /// **'Next ovulation day'**
  String get healthReportNextOvulationDay;

  /// No description provided for @healthReportDaysCycle.
  ///
  /// In en, this message translates to:
  /// **'{count} days cycle'**
  String healthReportDaysCycle(int count);

  /// No description provided for @healthReportUntilNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get healthReportUntilNow;

  /// No description provided for @healthReportFooter.
  ///
  /// In en, this message translates to:
  /// **'© Lune'**
  String get healthReportFooter;

  /// No description provided for @healthReportPatientSection.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get healthReportPatientSection;

  /// No description provided for @healthReportMode.
  ///
  /// In en, this message translates to:
  /// **'Tracking mode'**
  String get healthReportMode;

  /// No description provided for @healthReportModeCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle tracking'**
  String get healthReportModeCycle;

  /// No description provided for @healthReportModePregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy tracking'**
  String get healthReportModePregnancy;

  /// No description provided for @healthReportReportId.
  ///
  /// In en, this message translates to:
  /// **'Report ID'**
  String get healthReportReportId;

  /// No description provided for @healthReportMenstrualHistory.
  ///
  /// In en, this message translates to:
  /// **'Menstrual history'**
  String get healthReportMenstrualHistory;

  /// No description provided for @healthReportLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'Last period (LMP)'**
  String get healthReportLastPeriod;

  /// No description provided for @healthReportDataPeriod.
  ///
  /// In en, this message translates to:
  /// **'Data period'**
  String get healthReportDataPeriod;

  /// No description provided for @healthReportCyclesAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Cycles analyzed'**
  String get healthReportCyclesAnalyzed;

  /// No description provided for @healthReportCycleLengthRange.
  ///
  /// In en, this message translates to:
  /// **'Cycle length range'**
  String get healthReportCycleLengthRange;

  /// No description provided for @healthReportCycleVariability.
  ///
  /// In en, this message translates to:
  /// **'Cycle variability'**
  String get healthReportCycleVariability;

  /// No description provided for @healthReportPeriodLengthRange.
  ///
  /// In en, this message translates to:
  /// **'Period length range'**
  String get healthReportPeriodLengthRange;

  /// No description provided for @healthReportPatternsToDiscuss.
  ///
  /// In en, this message translates to:
  /// **'Patterns worth discussing'**
  String get healthReportPatternsToDiscuss;

  /// No description provided for @healthReportSymptomBurden.
  ///
  /// In en, this message translates to:
  /// **'Symptom & pain summary'**
  String get healthReportSymptomBurden;

  /// No description provided for @healthReportAveragePain.
  ///
  /// In en, this message translates to:
  /// **'Average pain (last 30 days)'**
  String get healthReportAveragePain;

  /// No description provided for @healthReportWellnessEntries.
  ///
  /// In en, this message translates to:
  /// **'Wellness log entries'**
  String get healthReportWellnessEntries;

  /// No description provided for @healthReportRedFlags.
  ///
  /// In en, this message translates to:
  /// **'Worth mentioning to your doctor'**
  String get healthReportRedFlags;

  /// No description provided for @healthReportVitalsAdherence.
  ///
  /// In en, this message translates to:
  /// **'Vitals & adherence'**
  String get healthReportVitalsAdherence;

  /// No description provided for @healthReportLatestWeight.
  ///
  /// In en, this message translates to:
  /// **'Latest weight'**
  String get healthReportLatestWeight;

  /// No description provided for @healthReportLatestTemperature.
  ///
  /// In en, this message translates to:
  /// **'Latest temperature'**
  String get healthReportLatestTemperature;

  /// No description provided for @healthReportAvgWater.
  ///
  /// In en, this message translates to:
  /// **'Average water (30 days)'**
  String get healthReportAvgWater;

  /// No description provided for @healthReportPillAdherence.
  ///
  /// In en, this message translates to:
  /// **'Pill adherence (last 7 days)'**
  String get healthReportPillAdherence;

  /// No description provided for @clinicalFlagShortCycle.
  ///
  /// In en, this message translates to:
  /// **'Average cycle {days} days — shorter than the 24–38 day reference range; worth discussing with your doctor.'**
  String clinicalFlagShortCycle(int days);

  /// No description provided for @clinicalFlagLongCycle.
  ///
  /// In en, this message translates to:
  /// **'Average cycle {days} days — longer than the 24–38 day reference range; worth discussing with your doctor.'**
  String clinicalFlagLongCycle(int days);

  /// No description provided for @clinicalFlagIrregularCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle length varies by about {days} days between cycles — worth discussing regularity with your doctor.'**
  String clinicalFlagIrregularCycle(int days);

  /// No description provided for @clinicalFlagProlongedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Average period {days} days — longer than the 8-day reference duration; worth discussing with your doctor.'**
  String clinicalFlagProlongedPeriod(int days);

  /// No description provided for @clinicalFlagHighPain.
  ///
  /// In en, this message translates to:
  /// **'Average logged pain is in the severe range — worth discussing pain management with your doctor.'**
  String get clinicalFlagHighPain;

  /// No description provided for @doctorReportPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient details'**
  String get doctorReportPatientTitle;

  /// No description provided for @doctorReportPatientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — shown at the top of the report for your doctor. Stored on your device only.'**
  String get doctorReportPatientSubtitle;

  /// No description provided for @doctorReportPatientName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get doctorReportPatientName;

  /// No description provided for @doctorReportPatientAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get doctorReportPatientAge;

  /// No description provided for @doctorReportPatientNote.
  ///
  /// In en, this message translates to:
  /// **'Note for the doctor'**
  String get doctorReportPatientNote;

  /// No description provided for @doctorReportPatientNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. reason for visit, medications, concerns'**
  String get doctorReportPatientNoteHint;

  /// No description provided for @doctorReportPatientSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get doctorReportPatientSave;

  /// No description provided for @doctorReportEditPatient.
  ///
  /// In en, this message translates to:
  /// **'Edit patient details'**
  String get doctorReportEditPatient;

  /// No description provided for @communityAdultsOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Communities are for adults'**
  String get communityAdultsOnlyTitle;

  /// No description provided for @communityAdultsOnly.
  ///
  /// In en, this message translates to:
  /// **'Community features are available from age 18. You can still use all other app features.'**
  String get communityAdultsOnly;

  /// No description provided for @communityGuidelinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Community guidelines'**
  String get communityGuidelinesTitle;

  /// No description provided for @communityGuidelinesIntro.
  ///
  /// In en, this message translates to:
  /// **'Before joining, please read and accept our community rules:'**
  String get communityGuidelinesIntro;

  /// No description provided for @communityGuidelinesAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to follow the community guidelines'**
  String get communityGuidelinesAgree;

  /// No description provided for @communityGuidelinesAccept.
  ///
  /// In en, this message translates to:
  /// **'Join community'**
  String get communityGuidelinesAccept;

  /// No description provided for @challengesTitle.
  ///
  /// In en, this message translates to:
  /// **'My challenges'**
  String get challengesTitle;

  /// No description provided for @challengesToday.
  ///
  /// In en, this message translates to:
  /// **'Today\'s challenges'**
  String get challengesToday;

  /// No description provided for @challengesAllDone.
  ///
  /// In en, this message translates to:
  /// **'Amazing! You completed everything today.'**
  String get challengesAllDone;

  /// No description provided for @challengeDone.
  ///
  /// In en, this message translates to:
  /// **'Challenge completed'**
  String get challengeDone;

  /// No description provided for @challengeStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get challengeStreakLabel;

  /// No description provided for @challengePointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get challengePointsLabel;

  /// No description provided for @challengeStreakValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String challengeStreakValue(int count);

  /// No description provided for @challengeHydrate.
  ///
  /// In en, this message translates to:
  /// **'Drink 6-8 glasses of water'**
  String get challengeHydrate;

  /// No description provided for @challengeStretch.
  ///
  /// In en, this message translates to:
  /// **'Gentle stretch for 5 minutes'**
  String get challengeStretch;

  /// No description provided for @challengeWalk.
  ///
  /// In en, this message translates to:
  /// **'Take a 10-minute walk'**
  String get challengeWalk;

  /// No description provided for @challengeMindful.
  ///
  /// In en, this message translates to:
  /// **'One mindful breathing break'**
  String get challengeMindful;

  /// No description provided for @challengeLogToday.
  ///
  /// In en, this message translates to:
  /// **'Log your symptoms and mood'**
  String get challengeLogToday;

  /// No description provided for @challengeSleepEarly.
  ///
  /// In en, this message translates to:
  /// **'Wind down before 11 PM'**
  String get challengeSleepEarly;

  /// No description provided for @badgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get badgesTitle;

  /// No description provided for @badgeEarned.
  ///
  /// In en, this message translates to:
  /// **'New achievement'**
  String get badgeEarned;

  /// No description provided for @badgeFirstStep.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get badgeFirstStep;

  /// No description provided for @badgeStreak3.
  ///
  /// In en, this message translates to:
  /// **'3-day streak'**
  String get badgeStreak3;

  /// No description provided for @badgeStreak7.
  ///
  /// In en, this message translates to:
  /// **'Week of care'**
  String get badgeStreak7;

  /// No description provided for @badgeStreak30.
  ///
  /// In en, this message translates to:
  /// **'30-day champion'**
  String get badgeStreak30;

  /// No description provided for @badgePoints100.
  ///
  /// In en, this message translates to:
  /// **'100 points'**
  String get badgePoints100;

  /// No description provided for @badgePoints500.
  ///
  /// In en, this message translates to:
  /// **'500 points'**
  String get badgePoints500;

  /// No description provided for @badgeAllInADay.
  ///
  /// In en, this message translates to:
  /// **'Perfect day'**
  String get badgeAllInADay;

  /// No description provided for @educationTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get educationTitle;

  /// No description provided for @magazineTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune Magazine'**
  String get magazineTitle;

  /// No description provided for @magazineFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get magazineFeatured;

  /// No description provided for @magazineFromLune.
  ///
  /// In en, this message translates to:
  /// **'From the magazine'**
  String get magazineFromLune;

  /// No description provided for @magazineReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get magazineReadMore;

  /// No description provided for @educationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trusted, age-appropriate articles about your cycle, body, and wellbeing.'**
  String get educationSubtitle;

  /// No description provided for @educationCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get educationCatAll;

  /// No description provided for @educationCatBasics.
  ///
  /// In en, this message translates to:
  /// **'Cycle basics'**
  String get educationCatBasics;

  /// No description provided for @educationCatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health & symptoms'**
  String get educationCatHealth;

  /// No description provided for @educationCatNutrition.
  ///
  /// In en, this message translates to:
  /// **'Food & movement'**
  String get educationCatNutrition;

  /// No description provided for @educationCatMind.
  ///
  /// In en, this message translates to:
  /// **'Mind & mood'**
  String get educationCatMind;

  /// No description provided for @educationCatFertility.
  ///
  /// In en, this message translates to:
  /// **'Fertility'**
  String get educationCatFertility;

  /// No description provided for @educationCatFitness.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get educationCatFitness;

  /// No description provided for @educationCatAdult.
  ///
  /// In en, this message translates to:
  /// **'18+ topics'**
  String get educationCatAdult;

  /// No description provided for @educationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min read'**
  String educationMinutes(int count);

  /// No description provided for @educationDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Educational content only — not a substitute for medical advice.'**
  String get educationDisclaimer;

  /// No description provided for @educationArticles.
  ///
  /// In en, this message translates to:
  /// **'articles'**
  String get educationArticles;

  /// No description provided for @educationNoArticles.
  ///
  /// In en, this message translates to:
  /// **'No articles available'**
  String get educationNoArticles;

  /// No description provided for @educationPoweredByAi.
  ///
  /// In en, this message translates to:
  /// **'Powered by AI'**
  String get educationPoweredByAi;

  /// No description provided for @educationAskAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get educationAskAi;

  /// No description provided for @educationAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask any health question'**
  String get educationAskAnything;

  /// No description provided for @educationAskHint.
  ///
  /// In en, this message translates to:
  /// **'Ask about any health topic...'**
  String get educationAskHint;

  /// No description provided for @educationThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get educationThinking;

  /// No description provided for @educationTopicPhase.
  ///
  /// In en, this message translates to:
  /// **'My current phase'**
  String get educationTopicPhase;

  /// No description provided for @educationTopicPhasePrompt.
  ///
  /// In en, this message translates to:
  /// **'Tell me about my current cycle phase and what I should know'**
  String get educationTopicPhasePrompt;

  /// No description provided for @educationTopicNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition tips'**
  String get educationTopicNutrition;

  /// No description provided for @educationTopicNutritionPrompt.
  ///
  /// In en, this message translates to:
  /// **'What foods are best for my current cycle phase?'**
  String get educationTopicNutritionPrompt;

  /// No description provided for @educationTopicExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get educationTopicExercise;

  /// No description provided for @educationTopicExercisePrompt.
  ///
  /// In en, this message translates to:
  /// **'What exercises are best for my current cycle phase?'**
  String get educationTopicExercisePrompt;

  /// No description provided for @educationTopicPain.
  ///
  /// In en, this message translates to:
  /// **'Pain management'**
  String get educationTopicPain;

  /// No description provided for @educationTopicPainPrompt.
  ///
  /// In en, this message translates to:
  /// **'How can I manage period pain naturally?'**
  String get educationTopicPainPrompt;

  /// No description provided for @educationTopicSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep better'**
  String get educationTopicSleep;

  /// No description provided for @educationTopicSleepPrompt.
  ///
  /// In en, this message translates to:
  /// **'How can I improve my sleep during my cycle?'**
  String get educationTopicSleepPrompt;

  /// No description provided for @educationTopicMood.
  ///
  /// In en, this message translates to:
  /// **'Mood & stress'**
  String get educationTopicMood;

  /// No description provided for @educationTopicMoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'How do I manage mood changes during my cycle?'**
  String get educationTopicMoodPrompt;

  /// No description provided for @reportCycleHealth.
  ///
  /// In en, this message translates to:
  /// **'Cycle Health'**
  String get reportCycleHealth;

  /// No description provided for @hormoneIndicatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hormone indicators'**
  String get hormoneIndicatorsTitle;

  /// No description provided for @hormoneIndicatorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estrogen & progesterone through your cycle'**
  String get hormoneIndicatorsSubtitle;

  /// No description provided for @hormoneIndicatorsCaption.
  ///
  /// In en, this message translates to:
  /// **'Estimated hormone levels based on your cycle day and length.'**
  String get hormoneIndicatorsCaption;

  /// No description provided for @reportFertility.
  ///
  /// In en, this message translates to:
  /// **'Fertility & Pregnancy'**
  String get reportFertility;

  /// No description provided for @reportFullHistory.
  ///
  /// In en, this message translates to:
  /// **'Full Cycle History'**
  String get reportFullHistory;

  /// No description provided for @reportSymptomPatterns.
  ///
  /// In en, this message translates to:
  /// **'Symptom Patterns'**
  String get reportSymptomPatterns;

  /// No description provided for @reportsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reports yet. Log your cycle and symptoms with + for a few days, then check back here.'**
  String get reportsEmpty;

  /// No description provided for @reportsLoadPartial.
  ///
  /// In en, this message translates to:
  /// **'Some report data could not load. Pull down to refresh.'**
  String get reportsLoadPartial;

  /// No description provided for @reportsSetupRequired.
  ///
  /// In en, this message translates to:
  /// **'Complete cycle setup during onboarding first, then open Reports again.'**
  String get reportsSetupRequired;

  /// No description provided for @doctorReportQrHint.
  ///
  /// In en, this message translates to:
  /// **'Scan to share a report summary'**
  String get doctorReportQrHint;

  /// No description provided for @doctorReportUpgradeUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited reports with Pro'**
  String get doctorReportUpgradeUnlimited;

  /// No description provided for @reportCycleSummary.
  ///
  /// In en, this message translates to:
  /// **'Cycle Summary'**
  String get reportCycleSummary;

  /// No description provided for @reportCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle day'**
  String get reportCycleDay;

  /// No description provided for @reportPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Period day'**
  String get reportPeriodDay;

  /// No description provided for @reportAvgCycle.
  ///
  /// In en, this message translates to:
  /// **'Avg cycle'**
  String get reportAvgCycle;

  /// No description provided for @reportAvgPeriod.
  ///
  /// In en, this message translates to:
  /// **'Avg period'**
  String get reportAvgPeriod;

  /// No description provided for @reportTotalCycles.
  ///
  /// In en, this message translates to:
  /// **'Total cycles'**
  String get reportTotalCycles;

  /// No description provided for @reportRegularity.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get reportRegularity;

  /// No description provided for @reportOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get reportOvulation;

  /// No description provided for @reportPregnancyChance.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy chance'**
  String get reportPregnancyChance;

  /// No description provided for @reportDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get reportDueDate;

  /// No description provided for @reportPregnancyWeek.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy week'**
  String get reportPregnancyWeek;

  /// No description provided for @reportTrimester.
  ///
  /// In en, this message translates to:
  /// **'Trimester'**
  String get reportTrimester;

  /// No description provided for @accountExportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export local backup'**
  String get accountExportBackup;

  /// No description provided for @accountImportBackup.
  ///
  /// In en, this message translates to:
  /// **'Import local backup'**
  String get accountImportBackup;

  /// No description provided for @accountRestoreCloud.
  ///
  /// In en, this message translates to:
  /// **'Restore from cloud'**
  String get accountRestoreCloud;

  /// No description provided for @accountAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get accountAdvanced;

  /// No description provided for @accountGeminiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'Gemini key saved'**
  String get accountGeminiKeySaved;

  /// No description provided for @accountGeminiKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional Gemini API key fallback if Cloud Functions are not deployed.'**
  String get accountGeminiKeyHelp;

  /// No description provided for @accountGeminiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key'**
  String get accountGeminiKeyLabel;

  /// No description provided for @accountGeminiKeySave.
  ///
  /// In en, this message translates to:
  /// **'Save Gemini key'**
  String get accountGeminiKeySave;

  /// No description provided for @reportPatternFallback.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get reportPatternFallback;

  /// No description provided for @reportPercentOfCycles.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of cycles'**
  String reportPercentOfCycles(Object percent);

  /// No description provided for @postTypeSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get postTypeSupport;

  /// No description provided for @postTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get postTypeQuestion;

  /// No description provided for @postTypeTip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get postTypeTip;

  /// No description provided for @postTypeVent.
  ///
  /// In en, this message translates to:
  /// **'Vent'**
  String get postTypeVent;

  /// No description provided for @postTypeMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get postTypeMilestone;

  /// No description provided for @postTypePoll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get postTypePoll;

  /// No description provided for @weeklyRecapTitle.
  ///
  /// In en, this message translates to:
  /// **'Your week with Lune'**
  String get weeklyRecapTitle;

  /// No description provided for @weeklyRecapPrompt.
  ///
  /// In en, this message translates to:
  /// **'Summarize my last 7 days based on the data — what went well, what to focus on next week.'**
  String get weeklyRecapPrompt;

  /// No description provided for @weeklyRecapLoading.
  ///
  /// In en, this message translates to:
  /// **'Reflecting on your week…'**
  String get weeklyRecapLoading;

  /// No description provided for @weeklyRecapRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get weeklyRecapRefresh;

  /// No description provided for @dayLabelToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dayLabelToday;

  /// No description provided for @dayLabelYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dayLabelYesterday;

  /// No description provided for @aiActionLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged: {label}'**
  String aiActionLogged(String label);

  /// No description provided for @aiActionLogMood.
  ///
  /// In en, this message translates to:
  /// **'Log mood: {mood}'**
  String aiActionLogMood(String mood);

  /// No description provided for @aiActionLogSymptom.
  ///
  /// In en, this message translates to:
  /// **'Log: {symptom}'**
  String aiActionLogSymptom(String symptom);

  /// No description provided for @aiActionLogWater.
  ///
  /// In en, this message translates to:
  /// **'Log {count} water'**
  String aiActionLogWater(String count);

  /// No description provided for @aiActionLogPain.
  ///
  /// In en, this message translates to:
  /// **'Log pain {level}/10'**
  String aiActionLogPain(String level);

  /// No description provided for @aiActionOpenLog.
  ///
  /// In en, this message translates to:
  /// **'Open log'**
  String get aiActionOpenLog;

  /// No description provided for @aiActionOpenInsights.
  ///
  /// In en, this message translates to:
  /// **'See insights'**
  String get aiActionOpenInsights;

  /// No description provided for @aiActionLogFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that — open the log to add it'**
  String get aiActionLogFailed;

  /// No description provided for @aiSuggestHowsMyDay.
  ///
  /// In en, this message translates to:
  /// **'How\'s my day looking?'**
  String get aiSuggestHowsMyDay;

  /// No description provided for @aiSuggestMoodCheck.
  ///
  /// In en, this message translates to:
  /// **'Help me check in on my mood'**
  String get aiSuggestMoodCheck;

  /// No description provided for @aiSuggestFoodIdeas.
  ///
  /// In en, this message translates to:
  /// **'Food ideas for today'**
  String get aiSuggestFoodIdeas;

  /// No description provided for @aiSuggestExplainPhase.
  ///
  /// In en, this message translates to:
  /// **'Explain my current phase'**
  String get aiSuggestExplainPhase;

  /// No description provided for @aiSuggestSymptomCheck.
  ///
  /// In en, this message translates to:
  /// **'Should I worry about this symptom?'**
  String get aiSuggestSymptomCheck;

  /// No description provided for @aiSuggestPrep.
  ///
  /// In en, this message translates to:
  /// **'Prep for my doctor visit'**
  String get aiSuggestPrep;

  /// No description provided for @aiSuggestEnergyBoost.
  ///
  /// In en, this message translates to:
  /// **'Quick energy boost'**
  String get aiSuggestEnergyBoost;

  /// No description provided for @aiSuggestMoveToday.
  ///
  /// In en, this message translates to:
  /// **'Movement plan for today'**
  String get aiSuggestMoveToday;

  /// No description provided for @aiSuggestSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set me a tiny goal'**
  String get aiSuggestSetGoal;

  /// No description provided for @adminTabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminTabUsers;

  /// No description provided for @adminTabQA.
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get adminTabQA;

  /// No description provided for @adminTabBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get adminTabBroadcast;

  /// No description provided for @adminFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminFilterPending;

  /// No description provided for @adminFilterAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get adminFilterAnswered;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminQuestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No {filter} questions yet.'**
  String adminQuestionsEmpty(String filter);

  /// No description provided for @adminQAExpertAnswer.
  ///
  /// In en, this message translates to:
  /// **'Expert answer'**
  String get adminQAExpertAnswer;

  /// No description provided for @adminPostsToday.
  ///
  /// In en, this message translates to:
  /// **'Posts today'**
  String get adminPostsToday;

  /// No description provided for @adminAiToday.
  ///
  /// In en, this message translates to:
  /// **'AI today'**
  String get adminAiToday;

  /// No description provided for @adminQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get adminQuickActions;

  /// No description provided for @adminQuickViewReports.
  ///
  /// In en, this message translates to:
  /// **'Review reports'**
  String get adminQuickViewReports;

  /// No description provided for @adminQuickSendBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Send broadcast'**
  String get adminQuickSendBroadcast;

  /// No description provided for @adminQuickEditSettings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get adminQuickEditSettings;

  /// No description provided for @adminConfirmBan.
  ///
  /// In en, this message translates to:
  /// **'Ban this user?'**
  String get adminConfirmBan;

  /// No description provided for @adminConfirmBanMsg.
  ///
  /// In en, this message translates to:
  /// **'They will lose access to community features immediately. You can unban later.'**
  String get adminConfirmBanMsg;

  /// No description provided for @adminConfirmBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Send to all users?'**
  String get adminConfirmBroadcast;

  /// No description provided for @adminConfirmBroadcastMsg.
  ///
  /// In en, this message translates to:
  /// **'This notification will be delivered to every signed-in user. Make sure the title and message are correct.'**
  String get adminConfirmBroadcastMsg;

  /// No description provided for @adminBroadcastSent.
  ///
  /// In en, this message translates to:
  /// **'Broadcast sent · {sent} delivered, {failed} failed'**
  String adminBroadcastSent(String sent, String failed);

  /// No description provided for @adminConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get adminConfirm;

  /// No description provided for @adminCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminCancel;

  /// No description provided for @adminGroupFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get adminGroupFeatures;

  /// No description provided for @adminGroupAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get adminGroupAnnouncement;

  /// No description provided for @adminGroupLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get adminGroupLinks;

  /// No description provided for @adminSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get adminSending;

  /// No description provided for @adminSendBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Send broadcast'**
  String get adminSendBroadcast;

  /// No description provided for @adminNotifPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get adminNotifPreview;

  /// No description provided for @adminNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get adminNoEmail;

  /// No description provided for @adminBannedBadge.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get adminBannedBadge;

  /// No description provided for @adminGrantPremium.
  ///
  /// In en, this message translates to:
  /// **'Grant Premium'**
  String get adminGrantPremium;

  /// No description provided for @adminRevokePremium.
  ///
  /// In en, this message translates to:
  /// **'Revoke Premium'**
  String get adminRevokePremium;

  /// No description provided for @adminPremiumUpdated.
  ///
  /// In en, this message translates to:
  /// **'Subscription status updated'**
  String get adminPremiumUpdated;

  /// No description provided for @adminAiCost30d.
  ///
  /// In en, this message translates to:
  /// **'AI cost (last 30 days)'**
  String get adminAiCost30d;

  /// No description provided for @adminAiTokensCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tokens'**
  String adminAiTokensCount(String count);

  /// No description provided for @adminAiRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} requests'**
  String adminAiRequestsCount(String count);

  /// No description provided for @adminTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get adminTimeNow;

  /// No description provided for @adminTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String adminTimeMinutes(int n);

  /// No description provided for @adminTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String adminTimeHours(int n);

  /// No description provided for @adminTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String adminTimeDays(int n);

  /// No description provided for @onboardingPrivacyAgree.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Privacy Policy. Cycle data stays on my device by default. Cloud backup, AI chat, and community are optional and require separate consent in Privacy Center.'**
  String get onboardingPrivacyAgree;

  /// No description provided for @privacyCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get privacyCenterTitle;

  /// No description provided for @privacyCenterIntro.
  ///
  /// In en, this message translates to:
  /// **'Lune is privacy-first. Health data is stored locally and encrypted. Cloud, AI, and community features are optional and require your consent.'**
  String get privacyCenterIntro;

  /// No description provided for @privacyDataLocal.
  ///
  /// In en, this message translates to:
  /// **'Stored on your device'**
  String get privacyDataLocal;

  /// No description provided for @privacyDataOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional (with your consent)'**
  String get privacyDataOptional;

  /// No description provided for @privacyDataNotCollected.
  ///
  /// In en, this message translates to:
  /// **'We never'**
  String get privacyDataNotCollected;

  /// No description provided for @privacyBulletLocal.
  ///
  /// In en, this message translates to:
  /// **'Cycle logs, journal, and wellness data stay on your phone by default.'**
  String get privacyBulletLocal;

  /// No description provided for @privacyBulletEncrypt.
  ///
  /// In en, this message translates to:
  /// **'Encryption keys are stored in Android Keystore / iOS Keychain.'**
  String get privacyBulletEncrypt;

  /// No description provided for @privacyBulletCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup only when you sign in and turn on sync.'**
  String get privacyBulletCloud;

  /// No description provided for @privacyBulletAi.
  ///
  /// In en, this message translates to:
  /// **'AI chat sends messages to Google Gemini only when you opt in.'**
  String get privacyBulletAi;

  /// No description provided for @privacyBulletCommunity.
  ///
  /// In en, this message translates to:
  /// **'Communities use an anonymous alias — never your real name or cycle data.'**
  String get privacyBulletCommunity;

  /// No description provided for @privacyBulletNoSell.
  ///
  /// In en, this message translates to:
  /// **'Sell or share your health data with advertisers.'**
  String get privacyBulletNoSell;

  /// No description provided for @privacyBulletNoTrack.
  ///
  /// In en, this message translates to:
  /// **'Track you across other apps for ads.'**
  String get privacyBulletNoTrack;

  /// No description provided for @privacyPolicyLink.
  ///
  /// In en, this message translates to:
  /// **'Read full Privacy Policy'**
  String get privacyPolicyLink;

  /// No description provided for @privacyMedicalDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Lune is not a medical device. Always consult a healthcare professional.'**
  String get privacyMedicalDisclaimer;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes cloud data and your sign-in permanently.'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, cloud backups, AI chats, community posts and comments, partner data, and profile photos from our servers. Local data on this device stays until you uninstall the app.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountReauth.
  ///
  /// In en, this message translates to:
  /// **'Sign in again, then retry deletion.'**
  String get deleteAccountReauth;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again or contact support.'**
  String get deleteAccountFailed;

  /// No description provided for @termsOfServiceLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceLink;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @contactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions, abuse reports, or account help'**
  String get contactSupportSubtitle;

  /// No description provided for @accountMenuFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback & promo codes'**
  String get accountMenuFeedback;

  /// No description provided for @accountMenuFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a note or apply a promo code'**
  String get accountMenuFeedbackSubtitle;

  /// No description provided for @accountMenuAiDiagnostic.
  ///
  /// In en, this message translates to:
  /// **'AI diagnostic'**
  String get accountMenuAiDiagnostic;

  /// No description provided for @accountMenuAiDiagnosticSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Test connection or update Gemini key'**
  String get accountMenuAiDiagnosticSubtitle;

  /// No description provided for @consentManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Your consents'**
  String get consentManageTitle;

  /// No description provided for @consentManageBody.
  ///
  /// In en, this message translates to:
  /// **'Turn optional features off anytime. Core tracking on your device is unaffected.'**
  String get consentManageBody;

  /// No description provided for @premiumRequiredCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is a Premium feature. Subscribe in Account.'**
  String get premiumRequiredCloud;

  /// No description provided for @premiumRequiredAi.
  ///
  /// In en, this message translates to:
  /// **'This AI feature requires Premium. Subscribe in Account.'**
  String get premiumRequiredAi;

  /// No description provided for @premiumAiLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used today\'s free AI messages. Upgrade to Premium for unlimited chat.'**
  String get premiumAiLimitReached;

  /// No description provided for @aiDailyLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your 30 daily Lune AI messages. Your limit resets automatically tomorrow.'**
  String get aiDailyLimitReached;

  /// No description provided for @premiumAiFreeRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} free AI messages left today'**
  String premiumAiFreeRemaining(int count);

  /// No description provided for @openPrivacyCenter.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data settings'**
  String get openPrivacyCenter;

  /// No description provided for @consentCloudTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable cloud backup?'**
  String get consentCloudTitle;

  /// No description provided for @consentCloudBody.
  ///
  /// In en, this message translates to:
  /// **'Encrypted cycle backups will be stored in your Firebase account. You can turn this off anytime.'**
  String get consentCloudBody;

  /// No description provided for @consentAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable AI features?'**
  String get consentAiTitle;

  /// No description provided for @consentAiBody.
  ///
  /// In en, this message translates to:
  /// **'When you enable AI, the message or content you submit and relevant cycle context (such as symptoms, mood, phase, and saved preferences) are sent to DeepSeek and/or Google through our secure server to provide a personalized response. Do not include identifying information you do not want processed. This is not medical advice. You can disable AI anytime.'**
  String get consentAiBody;

  /// No description provided for @aiAdultsOnly.
  ///
  /// In en, this message translates to:
  /// **'Lune AI is for adults 18+ only.'**
  String get aiAdultsOnly;

  /// No description provided for @consentCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Join communities?'**
  String get consentCommunityTitle;

  /// No description provided for @consentCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'You will use an anonymous alias. Posts are moderated by AI. Your cycle data is never shared.'**
  String get consentCommunityBody;

  /// No description provided for @consentAccept.
  ///
  /// In en, this message translates to:
  /// **'I agree'**
  String get consentAccept;

  /// No description provided for @consentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept to continue'**
  String get consentRequired;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get homeGreeting;

  /// No description provided for @homeGreetingName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String homeGreetingName(String name);

  /// No description provided for @homeSubtitleDay.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {phase}'**
  String homeSubtitleDay(int day, String phase);

  /// No description provided for @homeOvulation.
  ///
  /// In en, this message translates to:
  /// **'Next ovulation'**
  String get homeOvulation;

  /// No description provided for @homeRegularity.
  ///
  /// In en, this message translates to:
  /// **'Cycle regularity'**
  String get homeRegularity;

  /// No description provided for @homeCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle day {day}'**
  String homeCycleDay(int day);

  /// No description provided for @homePeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Period day {day}'**
  String homePeriodDay(int day);

  /// No description provided for @homeOvulationToday.
  ///
  /// In en, this message translates to:
  /// **'Ovulation today'**
  String get homeOvulationToday;

  /// No description provided for @homeKeyDates.
  ///
  /// In en, this message translates to:
  /// **'Important dates'**
  String get homeKeyDates;

  /// No description provided for @homeDueDate.
  ///
  /// In en, this message translates to:
  /// **'Expected due date'**
  String get homeDueDate;

  /// No description provided for @homeCycleProgress.
  ///
  /// In en, this message translates to:
  /// **'Cycle progress'**
  String get homeCycleProgress;

  /// No description provided for @homeWeeklyCalendar.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get homeWeeklyCalendar;

  /// No description provided for @homeTipsSection.
  ///
  /// In en, this message translates to:
  /// **'Tips & insights'**
  String get homeTipsSection;

  /// No description provided for @homeLearnSection.
  ///
  /// In en, this message translates to:
  /// **'Learn & watch'**
  String get homeLearnSection;

  /// No description provided for @homeVideoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get homeVideoLabel;

  /// No description provided for @homeArticleLabel.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get homeArticleLabel;

  /// No description provided for @homeCycleView.
  ///
  /// In en, this message translates to:
  /// **'Cycle overview'**
  String get homeCycleView;

  /// No description provided for @homeOpenCalendar.
  ///
  /// In en, this message translates to:
  /// **'View full calendar'**
  String get homeOpenCalendar;

  /// No description provided for @homeStatsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load cycle stats. Pull to refresh.'**
  String get homeStatsError;

  /// No description provided for @homeLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Loading your cycle data…'**
  String get homeLoadingStats;

  /// No description provided for @homeDayShort.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get homeDayShort;

  /// No description provided for @onboardingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStepLabel(int current, int total);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Lune'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lune means moon — a private companion for every phase of your cycle'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingWelcomeHelps.
  ///
  /// In en, this message translates to:
  /// **'We\'ll help you:'**
  String get onboardingWelcomeHelps;

  /// No description provided for @onboardingWelcomeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track your cycle, symptoms & mood'**
  String get onboardingWelcomeTrack;

  /// No description provided for @onboardingWelcomeAi.
  ///
  /// In en, this message translates to:
  /// **'Smart AI chat to answer your questions'**
  String get onboardingWelcomeAi;

  /// No description provided for @onboardingWelcomeCommunity.
  ///
  /// In en, this message translates to:
  /// **'Supportive community of women'**
  String get onboardingWelcomeCommunity;

  /// No description provided for @onboardingWelcomePregnancy.
  ///
  /// In en, this message translates to:
  /// **'Week-by-week pregnancy tracking'**
  String get onboardingWelcomePregnancy;

  /// No description provided for @onboardingWelcomeSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Personalized self-care tips'**
  String get onboardingWelcomeSelfCare;

  /// No description provided for @onboardingFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your app at a glance'**
  String get onboardingFeaturesTitle;

  /// No description provided for @onboardingFeaturesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here are the main screens:'**
  String get onboardingFeaturesSubtitle;

  /// No description provided for @onboardingReadyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Get Started below to enter the app'**
  String get onboardingReadyHint;

  /// No description provided for @onboardingFeatureHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get onboardingFeatureHome;

  /// No description provided for @onboardingFeatureHomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Quick cycle overview, fast logging, and predictions'**
  String get onboardingFeatureHomeDesc;

  /// No description provided for @onboardingFeatureSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Self-care'**
  String get onboardingFeatureSelfCare;

  /// No description provided for @onboardingFeatureSelfCareDesc.
  ///
  /// In en, this message translates to:
  /// **'Breathing exercises, affirmations, journal, and challenges'**
  String get onboardingFeatureSelfCareDesc;

  /// No description provided for @onboardingFeatureCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get onboardingFeatureCommunity;

  /// No description provided for @onboardingFeatureCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Support groups, questions & discussions with women like you'**
  String get onboardingFeatureCommunityDesc;

  /// No description provided for @onboardingFeatureReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get onboardingFeatureReports;

  /// No description provided for @onboardingFeatureReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Cycle analysis, charts, and a doctor-ready report'**
  String get onboardingFeatureReportsDesc;

  /// No description provided for @onboardingFeatureAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get onboardingFeatureAccount;

  /// No description provided for @onboardingFeatureAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Profile, settings, Premium'**
  String get onboardingFeatureAccountDesc;

  /// No description provided for @educationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Education section is not available yet'**
  String get educationNotAvailable;

  /// No description provided for @selfCareWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to your self-care space'**
  String get selfCareWelcomeTitle;

  /// No description provided for @selfCareWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your cycle to get personalized tips, or explore activities now.'**
  String get selfCareWelcomeSubtitle;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get to know you'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your name helps personalize AI tips, self-care, and your home screen.'**
  String get onboardingProfileSubtitle;

  /// No description provided for @onboardingNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get onboardingNameLabel;

  /// No description provided for @onboardingNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we greet you?'**
  String get onboardingNameHint;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your focus?'**
  String get onboardingGoalTitle;

  /// No description provided for @onboardingGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what matters now — cycle, pregnancy, fertility, PCOS, menopause, or recovery — and the app adapts with you.'**
  String get onboardingGoalSubtitle;

  /// No description provided for @onboardingCycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cycle basics'**
  String get onboardingCycleTitle;

  /// No description provided for @onboardingCycleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These power predictions, reminders, reports, and AI — everywhere in the app.'**
  String get onboardingCycleSubtitle;

  /// No description provided for @onboardingPregnancyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your pregnancy'**
  String get onboardingPregnancyDataTitle;

  /// No description provided for @onboardingPregnancyDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use the first day of your last period to estimate your week, due date, and how your baby is growing.'**
  String get onboardingPregnancyDataSubtitle;

  /// No description provided for @onboardingPregnancyLmp.
  ///
  /// In en, this message translates to:
  /// **'First day of last period (LMP)'**
  String get onboardingPregnancyLmp;

  /// No description provided for @pregnancyModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy tracking'**
  String get pregnancyModeTitle;

  /// No description provided for @pregnancyWeekDay.
  ///
  /// In en, this message translates to:
  /// **'Week {week} · day {day}'**
  String pregnancyWeekDay(int week, int day);

  /// No description provided for @pregnancyTrimester.
  ///
  /// In en, this message translates to:
  /// **'Trimester {n}'**
  String pregnancyTrimester(int n);

  /// No description provided for @pregnancyDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String pregnancyDueDate(String date);

  /// No description provided for @pregnancyBabyThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Baby this week'**
  String get pregnancyBabyThisWeek;

  /// No description provided for @pregnancyBabyVisualTitle.
  ///
  /// In en, this message translates to:
  /// **'Your baby now'**
  String get pregnancyBabyVisualTitle;

  /// No description provided for @pregnancyBabyNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week preview'**
  String get pregnancyBabyNextWeek;

  /// No description provided for @pregnancyWeekShort.
  ///
  /// In en, this message translates to:
  /// **'wk'**
  String get pregnancyWeekShort;

  /// No description provided for @pregnancyExploreWeeks.
  ///
  /// In en, this message translates to:
  /// **'Explore by week'**
  String get pregnancyExploreWeeks;

  /// No description provided for @pregnancyWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String pregnancyWeekLabel(int week);

  /// No description provided for @pregnancySizeLike.
  ///
  /// In en, this message translates to:
  /// **'Your baby is the size of a {item}'**
  String pregnancySizeLike(String item);

  /// No description provided for @pregnancySizeComparison.
  ///
  /// In en, this message translates to:
  /// **'Size comparison'**
  String get pregnancySizeComparison;

  /// No description provided for @pregnancyGrowthTitle.
  ///
  /// In en, this message translates to:
  /// **'Approximate growth'**
  String get pregnancyGrowthTitle;

  /// No description provided for @pregnancyLengthLabel.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get pregnancyLengthLabel;

  /// No description provided for @pregnancyWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get pregnancyWeightLabel;

  /// No description provided for @pregnancyYourBody.
  ///
  /// In en, this message translates to:
  /// **'Your body this week'**
  String get pregnancyYourBody;

  /// No description provided for @pregnancySelfCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Prenatal self-care'**
  String get pregnancySelfCareTitle;

  /// No description provided for @pregnancySelfCareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gentle rituals and tips for your trimester.'**
  String get pregnancySelfCareSubtitle;

  /// No description provided for @pregnancyReportOverview.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy overview'**
  String get pregnancyReportOverview;

  /// No description provided for @pregnancyReportChecklist.
  ///
  /// In en, this message translates to:
  /// **'Trimester checklist'**
  String get pregnancyReportChecklist;

  /// No description provided for @pregnancyDaysToDue.
  ///
  /// In en, this message translates to:
  /// **'{days} days to due date'**
  String pregnancyDaysToDue(int days);

  /// No description provided for @pregnancyCheckFirstVisit.
  ///
  /// In en, this message translates to:
  /// **'Schedule your first prenatal visit'**
  String get pregnancyCheckFirstVisit;

  /// No description provided for @pregnancyCheckPrenatalVitamins.
  ///
  /// In en, this message translates to:
  /// **'Take prenatal vitamins as advised'**
  String get pregnancyCheckPrenatalVitamins;

  /// No description provided for @pregnancyCheckRest.
  ///
  /// In en, this message translates to:
  /// **'Rest when you feel tired'**
  String get pregnancyCheckRest;

  /// No description provided for @pregnancyCheckAnatomyScan.
  ///
  /// In en, this message translates to:
  /// **'Anatomy scan around week 20'**
  String get pregnancyCheckAnatomyScan;

  /// No description provided for @pregnancyCheckMovement.
  ///
  /// In en, this message translates to:
  /// **'Note baby movements daily'**
  String get pregnancyCheckMovement;

  /// No description provided for @pregnancyCheckHydration.
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated throughout the day'**
  String get pregnancyCheckHydration;

  /// No description provided for @pregnancyCheckBirthPlan.
  ///
  /// In en, this message translates to:
  /// **'Discuss your birth plan with your provider'**
  String get pregnancyCheckBirthPlan;

  /// No description provided for @pregnancyCheckHospitalBag.
  ///
  /// In en, this message translates to:
  /// **'Start packing your hospital bag'**
  String get pregnancyCheckHospitalBag;

  /// No description provided for @pregnancyCheckKickCounts.
  ///
  /// In en, this message translates to:
  /// **'Count kicks once daily in the third trimester'**
  String get pregnancyCheckKickCounts;

  /// No description provided for @aiInsightPrenatalTitle.
  ///
  /// In en, this message translates to:
  /// **'Prenatal tip'**
  String get aiInsightPrenatalTitle;

  /// No description provided for @aiInsightConceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertility tip'**
  String get aiInsightConceiveTitle;

  /// No description provided for @aiInsightAvoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Protection tip'**
  String get aiInsightAvoidTitle;

  /// No description provided for @aiInsightWellnessTitle.
  ///
  /// In en, this message translates to:
  /// **'Wellness tip'**
  String get aiInsightWellnessTitle;

  /// No description provided for @cycleCauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Was this cycle different?'**
  String get cycleCauseTitle;

  /// No description provided for @cycleCauseIntro.
  ///
  /// In en, this message translates to:
  /// **'If something threw this cycle off, tell me. I\'ll leave it out of your averages instead of learning the wrong pattern from it.'**
  String get cycleCauseIntro;

  /// No description provided for @cycleCauseIllness.
  ///
  /// In en, this message translates to:
  /// **'Illness'**
  String get cycleCauseIllness;

  /// No description provided for @cycleCauseTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get cycleCauseTravel;

  /// No description provided for @cycleCauseStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get cycleCauseStress;

  /// No description provided for @cycleCauseWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight change'**
  String get cycleCauseWeight;

  /// No description provided for @cycleCauseMedication.
  ///
  /// In en, this message translates to:
  /// **'New medication'**
  String get cycleCauseMedication;

  /// No description provided for @cycleCauseSleep.
  ///
  /// In en, this message translates to:
  /// **'Poor sleep'**
  String get cycleCauseSleep;

  /// No description provided for @cycleCauseExercise.
  ///
  /// In en, this message translates to:
  /// **'Intense exercise'**
  String get cycleCauseExercise;

  /// No description provided for @cycleCauseNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing unusual'**
  String get cycleCauseNothing;

  /// No description provided for @cycleCauseSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved — this cycle is set aside from your averages.'**
  String get cycleCauseSaved;

  /// No description provided for @cycleCauseCleared.
  ///
  /// In en, this message translates to:
  /// **'Saved — this cycle counts toward your averages.'**
  String get cycleCauseCleared;

  /// No description provided for @cycleCauseLearned.
  ///
  /// In en, this message translates to:
  /// **'{count} cycles set aside from your averages'**
  String cycleCauseLearned(int count);

  /// No description provided for @cycleCauseStillCounted.
  ///
  /// In en, this message translates to:
  /// **'Set-aside cycles are still reviewed for health patterns.'**
  String get cycleCauseStillCounted;

  /// No description provided for @cycleSignalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worth mentioning to a doctor'**
  String get cycleSignalsTitle;

  /// No description provided for @cycleSignalsIntro.
  ///
  /// In en, this message translates to:
  /// **'These come from your own logged cycles. They are observations, not a diagnosis — stress, travel, illness and weight changes all cause them too.'**
  String get cycleSignalsIntro;

  /// No description provided for @cycleSignalsProlonged.
  ///
  /// In en, this message translates to:
  /// **'Several recent cycles ran longer than 35 days.'**
  String get cycleSignalsProlonged;

  /// No description provided for @cycleSignalsShort.
  ///
  /// In en, this message translates to:
  /// **'Several recent cycles were shorter than 21 days.'**
  String get cycleSignalsShort;

  /// No description provided for @cycleSignalsVariable.
  ///
  /// In en, this message translates to:
  /// **'Your cycle length swung by 9 days or more between cycles.'**
  String get cycleSignalsVariable;

  /// No description provided for @cycleSignalsAbsent.
  ///
  /// In en, this message translates to:
  /// **'There was a gap of 90 days or more with no period logged.'**
  String get cycleSignalsAbsent;

  /// No description provided for @cycleSignalsFooter.
  ///
  /// In en, this message translates to:
  /// **'Bring this up at your next visit. Your doctor report already includes it.'**
  String get cycleSignalsFooter;

  /// No description provided for @cycleSignalsOpenReport.
  ///
  /// In en, this message translates to:
  /// **'Open doctor report'**
  String get cycleSignalsOpenReport;

  /// No description provided for @ovulationConfirmedHint.
  ///
  /// In en, this message translates to:
  /// **'Confirmed by your temperature — up {rise}°C'**
  String ovulationConfirmedHint(String rise);

  /// No description provided for @ovulationConfirmedBadge.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get ovulationConfirmedBadge;

  /// No description provided for @bbtCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your ovulation'**
  String get bbtCardTitle;

  /// No description provided for @bbtCardWhy.
  ///
  /// In en, this message translates to:
  /// **'Your temperature rises 0.2–0.5°C after ovulation and stays up. It is the only at-home sign that ovulation actually happened — everything else is an estimate from your dates.'**
  String get bbtCardWhy;

  /// No description provided for @bbtCardHow.
  ///
  /// In en, this message translates to:
  /// **'Take it each morning before getting out of bed, at roughly the same time.'**
  String get bbtCardHow;

  /// No description provided for @bbtCardProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} readings this cycle'**
  String bbtCardProgress(int done, int total);

  /// No description provided for @bbtCardReady.
  ///
  /// In en, this message translates to:
  /// **'Enough readings — watching for the rise that confirms ovulation.'**
  String get bbtCardReady;

  /// No description provided for @bbtCardConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Ovulation confirmed on {date}, temperature up {rise}°C.'**
  String bbtCardConfirmed(String date, String rise);

  /// No description provided for @bbtCardConfirmedNote.
  ///
  /// In en, this message translates to:
  /// **'Your next period is now predicted from this, not from your average cycle length.'**
  String get bbtCardConfirmedNote;

  /// No description provided for @bbtCardCalibrated.
  ///
  /// In en, this message translates to:
  /// **'Your luteal phase is measured from {count} real signals instead of assumed.'**
  String bbtCardCalibrated(int count);

  /// No description provided for @bbtCardReminderOn.
  ///
  /// In en, this message translates to:
  /// **'Remind me each morning'**
  String get bbtCardReminderOn;

  /// No description provided for @bbtCardReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder at {time}'**
  String bbtCardReminderTime(String time);

  /// No description provided for @bbtCardLogNow.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s temperature'**
  String get bbtCardLogNow;

  /// No description provided for @bbtReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Morning temperature reminder'**
  String get bbtReminderEnabled;

  /// No description provided for @bbtReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fires at your wake time — basal temperature only counts before you get up.'**
  String get bbtReminderSubtitle;

  /// No description provided for @aiInsightPcosTitle.
  ///
  /// In en, this message translates to:
  /// **'Your PCOS pattern'**
  String get aiInsightPcosTitle;

  /// No description provided for @aiInsightMenopauseTitle.
  ///
  /// In en, this message translates to:
  /// **'Your menopause pattern'**
  String get aiInsightMenopauseTitle;

  /// No description provided for @aiInsightPostpartumTitle.
  ///
  /// In en, this message translates to:
  /// **'Your recovery'**
  String get aiInsightPostpartumTitle;

  /// No description provided for @aiInsightLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s reflection'**
  String get aiInsightLogTitle;

  /// No description provided for @goalModeConceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Trying to conceive'**
  String get goalModeConceiveTitle;

  /// No description provided for @goalModeAvoidTitle.
  ///
  /// In en, this message translates to:
  /// **'Avoiding pregnancy'**
  String get goalModeAvoidTitle;

  /// No description provided for @goalModeGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General wellness'**
  String get goalModeGeneralTitle;

  /// No description provided for @goalModeTodayFocus.
  ///
  /// In en, this message translates to:
  /// **'Today\'s focus'**
  String get goalModeTodayFocus;

  /// No description provided for @goalModeChecklist.
  ///
  /// In en, this message translates to:
  /// **'Your checklist'**
  String get goalModeChecklist;

  /// No description provided for @goalModeReportInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights for your goal'**
  String get goalModeReportInsights;

  /// No description provided for @goalModeFertilityToday.
  ///
  /// In en, this message translates to:
  /// **'Fertility estimate today'**
  String get goalModeFertilityToday;

  /// No description provided for @goalModeFertilityHigh.
  ///
  /// In en, this message translates to:
  /// **'Estimated high'**
  String get goalModeFertilityHigh;

  /// No description provided for @goalModeFertilityModerate.
  ///
  /// In en, this message translates to:
  /// **'Estimated moderate'**
  String get goalModeFertilityModerate;

  /// No description provided for @goalModeFertilityLow.
  ///
  /// In en, this message translates to:
  /// **'Estimated lower'**
  String get goalModeFertilityLow;

  /// No description provided for @goalModeFertilityUnknown.
  ///
  /// In en, this message translates to:
  /// **'Track more'**
  String get goalModeFertilityUnknown;

  /// No description provided for @goalModeTestDate.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy test'**
  String get goalModeTestDate;

  /// No description provided for @goalModeOvulationToday.
  ///
  /// In en, this message translates to:
  /// **'Estimated ovulation window today'**
  String get goalModeOvulationToday;

  /// No description provided for @goalModeConceiveSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Fertility self-care'**
  String get goalModeConceiveSelfCare;

  /// No description provided for @goalModeConceiveSelfCareSub.
  ///
  /// In en, this message translates to:
  /// **'Small daily habits that support conception.'**
  String get goalModeConceiveSelfCareSub;

  /// No description provided for @goalModeAvoidSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Protection self-care'**
  String get goalModeAvoidSelfCare;

  /// No description provided for @goalModeAvoidSelfCareSub.
  ///
  /// In en, this message translates to:
  /// **'Stay aware of fertile days and your contraception routine.'**
  String get goalModeAvoidSelfCareSub;

  /// No description provided for @goalModeGeneralSelfCare.
  ///
  /// In en, this message translates to:
  /// **'Cycle wellness'**
  String get goalModeGeneralSelfCare;

  /// No description provided for @goalModeGeneralSelfCareSub.
  ///
  /// In en, this message translates to:
  /// **'Holistic care for your body across every phase.'**
  String get goalModeGeneralSelfCareSub;

  /// No description provided for @pregnancyTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Track your pregnancy'**
  String get pregnancyTrackingTitle;

  /// No description provided for @pregnancyTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log weight, count kicks, and time contractions — week by week with Lune.'**
  String get pregnancyTrackingSubtitle;

  /// No description provided for @pregnancyWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get pregnancyWeightTitle;

  /// No description provided for @pregnancyWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weight'**
  String get pregnancyWeightHint;

  /// No description provided for @pregnancyWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get pregnancyWeightUnit;

  /// No description provided for @pregnancyWeightSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get pregnancyWeightSave;

  /// No description provided for @pregnancyWeightSaved.
  ///
  /// In en, this message translates to:
  /// **'Weight saved'**
  String get pregnancyWeightSaved;

  /// No description provided for @pregnancyWeightInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid weight between 30 and 200 kg'**
  String get pregnancyWeightInvalid;

  /// No description provided for @pregnancyWeightLatest.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg (latest)'**
  String pregnancyWeightLatest(double kg);

  /// No description provided for @pregnancyKicksTitle.
  ///
  /// In en, this message translates to:
  /// **'Kick counter'**
  String get pregnancyKicksTitle;

  /// No description provided for @pregnancyKicksHint.
  ///
  /// In en, this message translates to:
  /// **'Count 10 kicks — tap each time baby moves. Contact your provider if movement drops.'**
  String get pregnancyKicksHint;

  /// No description provided for @pregnancyKicksStart.
  ///
  /// In en, this message translates to:
  /// **'Start counting'**
  String get pregnancyKicksStart;

  /// No description provided for @pregnancyKicksTap.
  ///
  /// In en, this message translates to:
  /// **'Kick!'**
  String get pregnancyKicksTap;

  /// No description provided for @pregnancyKicksEnd.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get pregnancyKicksEnd;

  /// No description provided for @pregnancyKicksToday.
  ///
  /// In en, this message translates to:
  /// **'{count} kicks today'**
  String pregnancyKicksToday(int count);

  /// No description provided for @pregnancyContractionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contraction timer'**
  String get pregnancyContractionsTitle;

  /// No description provided for @pregnancyContractionsHint.
  ///
  /// In en, this message translates to:
  /// **'Start when a contraction begins, stop when it ends. Call your provider if contractions are regular before 37 weeks.'**
  String get pregnancyContractionsHint;

  /// No description provided for @pregnancyContractionStart.
  ///
  /// In en, this message translates to:
  /// **'Contraction started'**
  String get pregnancyContractionStart;

  /// No description provided for @pregnancyContractionEnd.
  ///
  /// In en, this message translates to:
  /// **'Contraction ended'**
  String get pregnancyContractionEnd;

  /// No description provided for @pregnancyContractionsToday.
  ///
  /// In en, this message translates to:
  /// **'{count} today'**
  String pregnancyContractionsToday(int count);

  /// No description provided for @pregnancyContractionAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg {seconds}s'**
  String pregnancyContractionAvg(int seconds);

  /// No description provided for @pregnancyContractionInterval.
  ///
  /// In en, this message translates to:
  /// **'Every {minutes} min'**
  String pregnancyContractionInterval(int minutes);

  /// No description provided for @pregnancyContractionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent today'**
  String get pregnancyContractionRecent;

  /// No description provided for @pregnancyContractionDuration.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String pregnancyContractionDuration(int seconds);

  /// No description provided for @onboardingDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date format'**
  String get onboardingDateFormat;

  /// No description provided for @cycleSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cycle settings'**
  String get cycleSettingsTitle;

  /// No description provided for @cycleSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates Home, AI, reminders, and predictions across the app.'**
  String get cycleSettingsSubtitle;

  /// No description provided for @cycleSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save & sync'**
  String get cycleSettingsSave;

  /// No description provided for @onboardingNoEmailNote.
  ///
  /// In en, this message translates to:
  /// **'No email required — your data stays on this device.'**
  String get onboardingNoEmailNote;

  /// No description provided for @onboardingPartialSave.
  ///
  /// In en, this message translates to:
  /// **'Setup saved locally. You can adjust cycle settings anytime from Account.'**
  String get onboardingPartialSave;

  /// No description provided for @accountRerunSetup.
  ///
  /// In en, this message translates to:
  /// **'Run setup again'**
  String get accountRerunSetup;

  /// No description provided for @accountRerunSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your name, goal, and cycle basics'**
  String get accountRerunSetupSubtitle;

  /// No description provided for @rerunSetupConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get rerunSetupConfirmTitle;

  /// No description provided for @rerunSetupConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will restart the initial setup. Your existing data won\'t be lost, but you\'ll need to re-enter your preferences.'**
  String get rerunSetupConfirmBody;

  /// No description provided for @rerunSetupConfirmYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, restart'**
  String get rerunSetupConfirmYes;

  /// No description provided for @rerunSetupConfirmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get rerunSetupConfirmCancel;

  /// No description provided for @accountChangeGoal.
  ///
  /// In en, this message translates to:
  /// **'Your goal'**
  String get accountChangeGoal;

  /// No description provided for @accountChangeGoalHint.
  ///
  /// In en, this message translates to:
  /// **'The app adapts instantly — home, reports, self-care, and AI.'**
  String get accountChangeGoalHint;

  /// No description provided for @goalChangedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Goal updated — the app is now tailored to you'**
  String get goalChangedSnackbar;

  /// No description provided for @accountUserId.
  ///
  /// In en, this message translates to:
  /// **'Account ID: {id}'**
  String accountUserId(String id);

  /// No description provided for @premiumRefreshStatus.
  ///
  /// In en, this message translates to:
  /// **'Check subscription status'**
  String get premiumRefreshStatus;

  /// No description provided for @signOutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutConfirmTitle;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your local data stays on this device. You can sign back in anytime.'**
  String get signOutConfirmBody;

  /// No description provided for @guestModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Private guest mode'**
  String get guestModeTitle;

  /// No description provided for @guestModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Local profile · no email'**
  String get guestModeLabel;

  /// No description provided for @guestModeBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re using Lune privately. Sign in only for Communities, Premium, or cloud backup.'**
  String get guestModeBody;

  /// No description provided for @signInOptionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in (optional)'**
  String get signInOptionalTitle;

  /// No description provided for @signInOptionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For communities, Premium subscription, and cloud backup'**
  String get signInOptionalSubtitle;

  /// No description provided for @communityRequiresAccount.
  ///
  /// In en, this message translates to:
  /// **'Communities need a sign-in to protect everyone\'s privacy. Your cycle data is never shared.'**
  String get communityRequiresAccount;

  /// No description provided for @aiGuestHint.
  ///
  /// In en, this message translates to:
  /// **'Works on your device. Sign in for full cloud AI features.'**
  String get aiGuestHint;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile'**
  String get editProfileTitle;

  /// No description provided for @avatarPickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your character'**
  String get avatarPickTitle;

  /// No description provided for @avatarUsePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use my photo'**
  String get avatarUsePhoto;

  /// No description provided for @communityAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get communityAttachPhoto;

  /// No description provided for @communityAttachVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get communityAttachVideo;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a fun character or your own photo.'**
  String get editProfileSubtitle;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get editProfileSave;

  /// No description provided for @partnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner mode'**
  String get partnerTitle;

  /// No description provided for @partnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share only what you choose with one trusted partner'**
  String get partnerSubtitle;

  /// No description provided for @partnerIntro.
  ///
  /// In en, this message translates to:
  /// **'Your partner sees a limited card: cycle phase, days until the next period — nothing else. You control every item and can unlink anytime.'**
  String get partnerIntro;

  /// No description provided for @partnerSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Partner mode needs a sign-in so the link stays private and secure.'**
  String get partnerSignInPrompt;

  /// No description provided for @partnerOwnerSection.
  ///
  /// In en, this message translates to:
  /// **'Share my cycle'**
  String get partnerOwnerSection;

  /// No description provided for @partnerYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your invite code'**
  String get partnerYourCode;

  /// No description provided for @partnerCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get partnerCodeCopied;

  /// No description provided for @partnerRegenerate.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get partnerRegenerate;

  /// No description provided for @partnerShareWhat.
  ///
  /// In en, this message translates to:
  /// **'What your partner can see'**
  String get partnerShareWhat;

  /// No description provided for @partnerSharePhase.
  ///
  /// In en, this message translates to:
  /// **'Cycle phase & day'**
  String get partnerSharePhase;

  /// No description provided for @partnerShareNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'Days until next period'**
  String get partnerShareNextPeriod;

  /// No description provided for @partnerSharePain.
  ///
  /// In en, this message translates to:
  /// **'Recent pain level'**
  String get partnerSharePain;

  /// No description provided for @partnerLinked.
  ///
  /// In en, this message translates to:
  /// **'Partner linked'**
  String get partnerLinked;

  /// No description provided for @partnerNotLinked.
  ///
  /// In en, this message translates to:
  /// **'No partner linked yet — share your code'**
  String get partnerNotLinked;

  /// No description provided for @partnerUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink partner'**
  String get partnerUnlink;

  /// No description provided for @partnerUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Partner unlinked'**
  String get partnerUnlinked;

  /// No description provided for @partnerPublishNow.
  ///
  /// In en, this message translates to:
  /// **'Update shared card now'**
  String get partnerPublishNow;

  /// No description provided for @partnerPublished.
  ///
  /// In en, this message translates to:
  /// **'Shared card updated'**
  String get partnerPublished;

  /// No description provided for @partnerNothingToPublish.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared — link a partner first'**
  String get partnerNothingToPublish;

  /// No description provided for @partnerPartnerSection.
  ///
  /// In en, this message translates to:
  /// **'I\'m the partner'**
  String get partnerPartnerSection;

  /// No description provided for @partnerEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter her invite code'**
  String get partnerEnterCode;

  /// No description provided for @partnerCodeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. K7XF2M'**
  String get partnerCodeHint;

  /// No description provided for @partnerJoin.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get partnerJoin;

  /// No description provided for @partnerJoinedOk.
  ///
  /// In en, this message translates to:
  /// **'Linked successfully'**
  String get partnerJoinedOk;

  /// No description provided for @partnerInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get partnerInvalidCode;

  /// No description provided for @partnerLeave.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get partnerLeave;

  /// No description provided for @partnerStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Her cycle today'**
  String get partnerStatusTitle;

  /// No description provided for @partnerStatusPhase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get partnerStatusPhase;

  /// No description provided for @partnerStatusCycleDay.
  ///
  /// In en, this message translates to:
  /// **'Cycle day'**
  String get partnerStatusCycleDay;

  /// No description provided for @partnerStatusNextPeriod.
  ///
  /// In en, this message translates to:
  /// **'{days} days until next period'**
  String partnerStatusNextPeriod(int days);

  /// No description provided for @partnerStatusPain.
  ///
  /// In en, this message translates to:
  /// **'Recent pain level'**
  String get partnerStatusPain;

  /// No description provided for @partnerStatusPeriodActive.
  ///
  /// In en, this message translates to:
  /// **'Period is active now'**
  String get partnerStatusPeriodActive;

  /// No description provided for @partnerStatusEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing shared yet — ask her to update the shared card.'**
  String get partnerStatusEmpty;

  /// No description provided for @partnerStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String partnerStatusUpdated(String time);

  /// No description provided for @partnerTipTitle.
  ///
  /// In en, this message translates to:
  /// **'How to support her today'**
  String get partnerTipTitle;

  /// No description provided for @partnerTipMenstruation.
  ///
  /// In en, this message translates to:
  /// **'Energy may be low. A warm drink, patience, and taking something off her plate go a long way.'**
  String get partnerTipMenstruation;

  /// No description provided for @partnerTipFollicular.
  ///
  /// In en, this message translates to:
  /// **'Energy is rising — a great time to plan something fun together.'**
  String get partnerTipFollicular;

  /// No description provided for @partnerTipOvulation.
  ///
  /// In en, this message translates to:
  /// **'She is likely feeling at her best. Enjoy quality time together.'**
  String get partnerTipOvulation;

  /// No description provided for @partnerTipLuteal.
  ///
  /// In en, this message translates to:
  /// **'PMS may show up: be patient and extra kind, small gestures matter most now.'**
  String get partnerTipLuteal;

  /// No description provided for @partnerTipDefault.
  ///
  /// In en, this message translates to:
  /// **'Check in with her and ask how she is feeling today.'**
  String get partnerTipDefault;

  /// No description provided for @communityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityFilterAll;

  /// No description provided for @communityAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get communityAnswered;

  /// No description provided for @communityTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get communityTabSaved;

  /// No description provided for @communitySavedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved posts yet. Tap the bookmark on a post to save it.'**
  String get communitySavedEmpty;

  /// No description provided for @communityShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get communityShare;

  /// No description provided for @communityShareVia.
  ///
  /// In en, this message translates to:
  /// **'Shared from Lune'**
  String get communityShareVia;

  /// No description provided for @communityPostSaved.
  ///
  /// In en, this message translates to:
  /// **'Post saved'**
  String get communityPostSaved;

  /// No description provided for @communityPostUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get communityPostUnsaved;

  /// No description provided for @communityDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete post'**
  String get communityDeletePost;

  /// No description provided for @communityDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get communityDeleteComment;

  /// No description provided for @communityDeletePostConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this post permanently?'**
  String get communityDeletePostConfirm;

  /// No description provided for @communityDeleteCommentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this comment?'**
  String get communityDeleteCommentConfirm;

  /// No description provided for @communityPostDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get communityPostDeleted;

  /// No description provided for @communityCommentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted'**
  String get communityCommentDeleted;

  /// No description provided for @communityReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get communityReply;

  /// No description provided for @communityReplyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {alias}'**
  String communityReplyingTo(String alias);

  /// No description provided for @communityMarkBestAnswer.
  ///
  /// In en, this message translates to:
  /// **'Mark as best answer'**
  String get communityMarkBestAnswer;

  /// No description provided for @communityBestAnswer.
  ///
  /// In en, this message translates to:
  /// **'Best answer'**
  String get communityBestAnswer;

  /// No description provided for @communityCatCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get communityCatCulture;

  /// No description provided for @communityCatAge.
  ///
  /// In en, this message translates to:
  /// **'Young adults'**
  String get communityCatAge;

  /// No description provided for @communityHomeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityHomeCardTitle;

  /// No description provided for @communityHomeCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Support, questions, and sisterhood — nickname only'**
  String get communityHomeCardSubtitle;

  /// No description provided for @communityNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Community activity'**
  String get communityNotifTitle;

  /// No description provided for @communityNotifSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Likes and comments on your posts'**
  String get communityNotifSubtitle;

  /// No description provided for @communityTextOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Photos & videos are Premium. Community reports auto-hide unsafe posts.'**
  String get communityTextOnlyNote;

  /// No description provided for @communityEditPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get communityEditPost;

  /// No description provided for @communityPostUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post updated'**
  String get communityPostUpdated;

  /// No description provided for @communityEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get communityEdited;

  /// No description provided for @communityActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get communityActivityTitle;

  /// No description provided for @communityActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity yet. When someone likes or comments on your posts, it appears here.'**
  String get communityActivityEmpty;

  /// No description provided for @communityActivityComment.
  ///
  /// In en, this message translates to:
  /// **'{alias} commented on your post'**
  String communityActivityComment(String alias);

  /// No description provided for @communityActivityLike.
  ///
  /// In en, this message translates to:
  /// **'{alias} liked your post'**
  String communityActivityLike(String alias);

  /// No description provided for @communityActivityReply.
  ///
  /// In en, this message translates to:
  /// **'{alias} replied to your comment'**
  String communityActivityReply(String alias);

  /// No description provided for @communityActivityFollow.
  ///
  /// In en, this message translates to:
  /// **'{alias} started following you'**
  String communityActivityFollow(String alias);

  /// No description provided for @communityActivityMention.
  ///
  /// In en, this message translates to:
  /// **'{alias} mentioned you in a comment'**
  String communityActivityMention(String alias);

  /// No description provided for @communityFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get communityFollow;

  /// No description provided for @communityFollowingBtn.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get communityFollowingBtn;

  /// No description provided for @communityUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get communityUnfollow;

  /// No description provided for @communityUnfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed'**
  String get communityUnfollowed;

  /// No description provided for @communityFollowedToast.
  ///
  /// In en, this message translates to:
  /// **'You\'re now following {alias}'**
  String communityFollowedToast(String alias);

  /// No description provided for @communityFollowingTitle.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get communityFollowingTitle;

  /// No description provided for @communityFollowingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Members you follow'**
  String get communityFollowingSubtitle;

  /// No description provided for @communityFollowingEmpty.
  ///
  /// In en, this message translates to:
  /// **'You aren\'t following anyone yet. Tap a member\'s name on a post to follow them.'**
  String get communityFollowingEmpty;

  /// No description provided for @communityCommentSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get communityCommentSortOldest;

  /// No description provided for @communityCommentSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get communityCommentSortNewest;

  /// No description provided for @communityCommentSortTop.
  ///
  /// In en, this message translates to:
  /// **'Most liked'**
  String get communityCommentSortTop;

  /// No description provided for @communityMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get communityMarkAllRead;

  /// No description provided for @communitySortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get communitySortNewest;

  /// No description provided for @communityFeedPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get communityFeedPopular;

  /// No description provided for @communityFeedMyComments.
  ///
  /// In en, this message translates to:
  /// **'My comments'**
  String get communityFeedMyComments;

  /// No description provided for @communityCoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Post cover'**
  String get communityCoverTitle;

  /// No description provided for @communityCoverNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get communityCoverNone;

  /// No description provided for @communitySortDiscussed.
  ///
  /// In en, this message translates to:
  /// **'Most discussed'**
  String get communitySortDiscussed;

  /// No description provided for @communityFilterMyPosts.
  ///
  /// In en, this message translates to:
  /// **'My posts'**
  String get communityFilterMyPosts;

  /// No description provided for @communitySearchPosts.
  ///
  /// In en, this message translates to:
  /// **'Search posts...'**
  String get communitySearchPosts;

  /// No description provided for @communityCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get communityCopied;

  /// No description provided for @communityCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get communityCopy;

  /// No description provided for @communityGuidelinesShort.
  ///
  /// In en, this message translates to:
  /// **'Guidelines'**
  String get communityGuidelinesShort;

  /// No description provided for @communityPollAddOption.
  ///
  /// In en, this message translates to:
  /// **'Add option'**
  String get communityPollAddOption;

  /// No description provided for @communityPollOptionHint.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String communityPollOptionHint(int number);

  /// No description provided for @communityPollNeedsOptions.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 poll options'**
  String get communityPollNeedsOptions;

  /// No description provided for @communityPollVotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No votes yet} =1{1 vote} other{{count} votes}}'**
  String communityPollVotesCount(int count);

  /// No description provided for @communityPollTapToVote.
  ///
  /// In en, this message translates to:
  /// **'Tap an option to vote'**
  String get communityPollTapToVote;

  /// No description provided for @communityFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get communityFilters;

  /// No description provided for @communityFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get communityFilterCategory;

  /// No description provided for @communityFilterPostType.
  ///
  /// In en, this message translates to:
  /// **'Post type'**
  String get communityFilterPostType;

  /// No description provided for @communityFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get communityFilterReset;

  /// No description provided for @communityFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get communityFilterApply;

  /// No description provided for @storyChooseCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share story to...'**
  String get storyChooseCommunity;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1m ago} other{{count}m ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1h ago} other{{count}h ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Yesterday} other{{count}d ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @reactionHeart.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get reactionHeart;

  /// No description provided for @reactionHug.
  ///
  /// In en, this message translates to:
  /// **'Hug'**
  String get reactionHug;

  /// No description provided for @reactionCelebrate.
  ///
  /// In en, this message translates to:
  /// **'Celebrate'**
  String get reactionCelebrate;

  /// No description provided for @reactionStrong.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get reactionStrong;

  /// No description provided for @communityMemberProfile.
  ///
  /// In en, this message translates to:
  /// **'Member profile'**
  String get communityMemberProfile;

  /// No description provided for @communityRecentPosts.
  ///
  /// In en, this message translates to:
  /// **'Recent posts'**
  String get communityRecentPosts;

  /// No description provided for @communityNoRecentPosts.
  ///
  /// In en, this message translates to:
  /// **'No public posts yet'**
  String get communityNoRecentPosts;

  /// No description provided for @communityWeeklyQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question of the week'**
  String get communityWeeklyQuestion;

  /// No description provided for @communityWeeklyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Share your answer'**
  String get communityWeeklyAnswer;

  /// No description provided for @premiumUpsellTitle.
  ///
  /// In en, this message translates to:
  /// **'Lune Premium'**
  String get premiumUpsellTitle;

  /// No description provided for @premiumUpsellSubscribe.
  ///
  /// In en, this message translates to:
  /// **'View subscription'**
  String get premiumUpsellSubscribe;

  /// No description provided for @premiumUpsellNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get premiumUpsellNotNow;

  /// No description provided for @moderationRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Content not approved'**
  String get moderationRejectedTitle;

  /// No description provided for @moderationRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your post or comment did not pass our community guidelines review.'**
  String get moderationRejectedBody;

  /// No description provided for @moderationRejectedTips.
  ///
  /// In en, this message translates to:
  /// **'Tips: no phone numbers, links, or email addresses. Keep it supportive and respectful. Medical topics need a healthcare provider.'**
  String get moderationRejectedTips;

  /// No description provided for @moderationContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get moderationContactSupport;

  /// No description provided for @moderationTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Edit and try again'**
  String get moderationTryAgain;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Lune means moon — your private phase-by-phase wellness companion. Data stays on device; cloud, AI, and communities are optional.'**
  String get aboutTagline;

  /// No description provided for @insightsCycleRegularityScore.
  ///
  /// In en, this message translates to:
  /// **'Cycle regularity (CRS)'**
  String get insightsCycleRegularityScore;

  /// No description provided for @insightsPeriodRegularityScore.
  ///
  /// In en, this message translates to:
  /// **'Period regularity (PRS)'**
  String get insightsPeriodRegularityScore;

  /// No description provided for @insightsGraphEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log more data to see this chart — track symptoms, weight, sleep, and more in Daily Log.'**
  String get insightsGraphEmpty;

  /// No description provided for @predictedSymptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Likely symptoms'**
  String get predictedSymptomsTitle;

  /// No description provided for @predictedSymptomsDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Based on your past cycles on this cycle day — not a medical prediction.'**
  String get predictedSymptomsDisclaimer;

  /// No description provided for @predictedSymptomsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get predictedSymptomsToday;

  /// No description provided for @predictedSymptomsTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get predictedSymptomsTomorrow;

  /// No description provided for @predictedSymptomsLikelihood.
  ///
  /// In en, this message translates to:
  /// **'{percent}% likely'**
  String predictedSymptomsLikelihood(int percent);

  /// No description provided for @reportCycleHistoryTable.
  ///
  /// In en, this message translates to:
  /// **'Recent cycles'**
  String get reportCycleHistoryTable;

  /// No description provided for @reportCycleHistoryStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get reportCycleHistoryStart;

  /// No description provided for @reportCycleHistoryCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get reportCycleHistoryCycle;

  /// No description provided for @reportCycleHistoryPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get reportCycleHistoryPeriod;

  /// No description provided for @reportPregnancyTestDate.
  ///
  /// In en, this message translates to:
  /// **'Expected pregnancy test'**
  String get reportPregnancyTestDate;

  /// No description provided for @ovulationReminder.
  ///
  /// In en, this message translates to:
  /// **'Ovulation reminder'**
  String get ovulationReminder;

  /// No description provided for @notificationsWellnessNote.
  ///
  /// In en, this message translates to:
  /// **'Pill, sanitary, and LARC reminders in Wellness follow the main toggle above.'**
  String get notificationsWellnessNote;

  /// No description provided for @smartPhaseReminder.
  ///
  /// In en, this message translates to:
  /// **'Smart phase-based reminders'**
  String get smartPhaseReminder;

  /// No description provided for @smartPhaseReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a supportive daily tip that adapts to your cycle phase or pregnancy week.'**
  String get smartPhaseReminderSubtitle;

  /// No description provided for @latePeriodReminder.
  ///
  /// In en, this message translates to:
  /// **'Late period warning'**
  String get latePeriodReminder;

  /// No description provided for @latePeriodReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a gentle heads-up if your period runs a couple of days past its predicted date.'**
  String get latePeriodReminderSubtitle;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send a test notification'**
  String get sendTestNotification;

  /// No description provided for @testNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Sent! Check your notification shade.'**
  String get testNotificationSent;

  /// No description provided for @testNotificationBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off for Lune. Turn them on in system settings.'**
  String get testNotificationBlocked;

  /// No description provided for @graphExportShared.
  ///
  /// In en, this message translates to:
  /// **'Chart ready to share.'**
  String get graphExportShared;

  /// No description provided for @adminTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminTitle;

  /// No description provided for @adminAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have admin access.'**
  String get adminAccessDenied;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashboard;

  /// No description provided for @adminReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get adminReports;

  /// No description provided for @adminSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminSettings;

  /// No description provided for @adminTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total users'**
  String get adminTotalUsers;

  /// No description provided for @adminPendingReports.
  ///
  /// In en, this message translates to:
  /// **'Pending reports'**
  String get adminPendingReports;

  /// No description provided for @adminRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get adminRecentActivity;

  /// No description provided for @adminNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get adminNoActivity;

  /// No description provided for @adminReportAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get adminReportAuthor;

  /// No description provided for @adminReportReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminReportReason;

  /// No description provided for @adminReportStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminReportStatus;

  /// No description provided for @adminReportPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminReportPending;

  /// No description provided for @adminReportResolved.
  ///
  /// In en, this message translates to:
  /// **'Report resolved'**
  String get adminReportResolved;

  /// No description provided for @adminReportDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss report'**
  String get adminReportDismiss;

  /// No description provided for @adminHidePost.
  ///
  /// In en, this message translates to:
  /// **'Hide post'**
  String get adminHidePost;

  /// No description provided for @adminBanUser.
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get adminBanUser;

  /// No description provided for @adminUnbanUser.
  ///
  /// In en, this message translates to:
  /// **'Unban user'**
  String get adminUnbanUser;

  /// No description provided for @adminUserBanned.
  ///
  /// In en, this message translates to:
  /// **'User banned'**
  String get adminUserBanned;

  /// No description provided for @adminUserUnbanned.
  ///
  /// In en, this message translates to:
  /// **'User unbaned'**
  String get adminUserUnbanned;

  /// No description provided for @adminPostHidden.
  ///
  /// In en, this message translates to:
  /// **'Post hidden'**
  String get adminPostHidden;

  /// No description provided for @adminSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get adminSettingsSaved;

  /// No description provided for @adminCommunityEnabled.
  ///
  /// In en, this message translates to:
  /// **'Community enabled'**
  String get adminCommunityEnabled;

  /// No description provided for @adminAiEducation.
  ///
  /// In en, this message translates to:
  /// **'AI Education enabled'**
  String get adminAiEducation;

  /// No description provided for @adminAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get adminAnnouncement;

  /// No description provided for @adminAnnouncementTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get adminAnnouncementTitleEn;

  /// No description provided for @adminAnnouncementTitleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get adminAnnouncementTitleAr;

  /// No description provided for @adminAnnouncementBodyEn.
  ///
  /// In en, this message translates to:
  /// **'Body (English)'**
  String get adminAnnouncementBodyEn;

  /// No description provided for @adminAnnouncementBodyAr.
  ///
  /// In en, this message translates to:
  /// **'Body (Arabic)'**
  String get adminAnnouncementBodyAr;

  /// No description provided for @adminSupportUrl.
  ///
  /// In en, this message translates to:
  /// **'Support URL'**
  String get adminSupportUrl;

  /// No description provided for @adminPrivacyUrl.
  ///
  /// In en, this message translates to:
  /// **'Privacy URL'**
  String get adminPrivacyUrl;

  /// No description provided for @adminSave.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get adminSave;

  /// No description provided for @communityEditComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get communityEditComment;

  /// No description provided for @communityCommentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Comment updated'**
  String get communityCommentUpdated;

  /// No description provided for @communityPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get communityPickImage;

  /// No description provided for @communityPickVideo.
  ///
  /// In en, this message translates to:
  /// **'Choose video'**
  String get communityPickVideo;

  /// No description provided for @communityAddMedia.
  ///
  /// In en, this message translates to:
  /// **'Add photo or video'**
  String get communityAddMedia;

  /// No description provided for @communityPostAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Post anonymously'**
  String get communityPostAnonymously;

  /// No description provided for @communityMediaPremiumGate.
  ///
  /// In en, this message translates to:
  /// **'Attaching photos and videos is a Premium feature. Upgrade to unlock media posts.'**
  String get communityMediaPremiumGate;

  /// No description provided for @premiumFeatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium feature'**
  String get premiumFeatureTitle;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeToPremium;

  /// No description provided for @communityPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get communityPendingReview;

  /// No description provided for @communityThreadTitle.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get communityThreadTitle;

  /// No description provided for @communityNoReplies.
  ///
  /// In en, this message translates to:
  /// **'No replies yet'**
  String get communityNoReplies;

  /// No description provided for @communityViewReplies.
  ///
  /// In en, this message translates to:
  /// **'View {count} replies'**
  String communityViewReplies(int count);

  /// No description provided for @adminPendingModeration.
  ///
  /// In en, this message translates to:
  /// **'Pending moderation'**
  String get adminPendingModeration;

  /// No description provided for @adminApprovePost.
  ///
  /// In en, this message translates to:
  /// **'Approve post'**
  String get adminApprovePost;

  /// No description provided for @adminRejectPost.
  ///
  /// In en, this message translates to:
  /// **'Reject post'**
  String get adminRejectPost;

  /// No description provided for @adminNoReports.
  ///
  /// In en, this message translates to:
  /// **'No pending reports or moderation'**
  String get adminNoReports;

  /// No description provided for @adminPendingComments.
  ///
  /// In en, this message translates to:
  /// **'Pending comments'**
  String get adminPendingComments;

  /// No description provided for @adminApproveComment.
  ///
  /// In en, this message translates to:
  /// **'Approve comment'**
  String get adminApproveComment;

  /// No description provided for @adminRejectComment.
  ///
  /// In en, this message translates to:
  /// **'Reject comment'**
  String get adminRejectComment;

  /// No description provided for @storyCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Story'**
  String get storyCreate;

  /// No description provided for @storyPickImage.
  ///
  /// In en, this message translates to:
  /// **'Photo from gallery'**
  String get storyPickImage;

  /// No description provided for @storyPickMultiple.
  ///
  /// In en, this message translates to:
  /// **'Multiple photos'**
  String get storyPickMultiple;

  /// No description provided for @storyTextOnly.
  ///
  /// In en, this message translates to:
  /// **'Text story'**
  String get storyTextOnly;

  /// No description provided for @storyTextOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Colored background with text'**
  String get storyTextOnlyHint;

  /// No description provided for @storyTextHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get storyTextHint;

  /// No description provided for @storyPublish.
  ///
  /// In en, this message translates to:
  /// **'Share Story'**
  String get storyPublish;

  /// No description provided for @storyPublished.
  ///
  /// In en, this message translates to:
  /// **'Story shared!'**
  String get storyPublished;

  /// No description provided for @storyPremiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Stories with media require Premium'**
  String get storyPremiumRequired;

  /// No description provided for @storyYourStory.
  ///
  /// In en, this message translates to:
  /// **'Your story'**
  String get storyYourStory;

  /// No description provided for @storyViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all stories'**
  String get storyViewAll;

  /// No description provided for @aiQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like?'**
  String get aiQuickActionsTitle;

  /// No description provided for @aiFeatureBriefing.
  ///
  /// In en, this message translates to:
  /// **'Daily Briefing'**
  String get aiFeatureBriefing;

  /// No description provided for @aiFeatureBriefingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Give me my daily briefing'**
  String get aiFeatureBriefingPrompt;

  /// No description provided for @aiFeaturePatterns.
  ///
  /// In en, this message translates to:
  /// **'My Patterns'**
  String get aiFeaturePatterns;

  /// No description provided for @aiFeaturePatternsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Analyze my cycle patterns from recent months'**
  String get aiFeaturePatternsPrompt;

  /// No description provided for @aiFeatureNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Tips'**
  String get aiFeatureNutrition;

  /// No description provided for @aiFeatureNutritionPrompt.
  ///
  /// In en, this message translates to:
  /// **'What should I eat today based on my cycle phase?'**
  String get aiFeatureNutritionPrompt;

  /// No description provided for @aiFeaturePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner Message'**
  String get aiFeaturePartner;

  /// No description provided for @aiFeaturePartnerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Help me tell my partner how I\'m feeling today'**
  String get aiFeaturePartnerPrompt;

  /// No description provided for @aiFeatureMood.
  ///
  /// In en, this message translates to:
  /// **'Mood Journal'**
  String get aiFeatureMood;

  /// No description provided for @aiFeatureMoodPrompt.
  ///
  /// In en, this message translates to:
  /// **'I want to write about how I\'m feeling'**
  String get aiFeatureMoodPrompt;

  /// No description provided for @aiFeatureEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency Help'**
  String get aiFeatureEmergency;

  /// No description provided for @aiEmergencyPrompt.
  ///
  /// In en, this message translates to:
  /// **'I\'m in pain and need help right now'**
  String get aiEmergencyPrompt;

  /// No description provided for @aiEmergencyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick pain relief guidance'**
  String get aiEmergencyTooltip;

  /// No description provided for @aiFeatureFertility.
  ///
  /// In en, this message translates to:
  /// **'Fertility Insights'**
  String get aiFeatureFertility;

  /// No description provided for @aiFeatureFertilityPrompt.
  ///
  /// In en, this message translates to:
  /// **'Help me understand my fertility window'**
  String get aiFeatureFertilityPrompt;

  /// No description provided for @aiFeatureWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight & Nutrition'**
  String get aiFeatureWeight;

  /// No description provided for @aiFeatureWeightPrompt.
  ///
  /// In en, this message translates to:
  /// **'What should I eat for my phase?'**
  String get aiFeatureWeightPrompt;

  /// No description provided for @aiFeatureIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy Guidance'**
  String get aiFeatureIntimacy;

  /// No description provided for @aiFeatureIntimacyPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tips for intimacy during my cycle'**
  String get aiFeatureIntimacyPrompt;

  /// No description provided for @dailyBriefingTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Briefing'**
  String get dailyBriefingTitle;

  /// No description provided for @dailyBriefingLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing your daily briefing...'**
  String get dailyBriefingLoading;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyEffectiveDate.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get privacyEffectiveDate;

  /// No description provided for @privacyOpenExternal.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get privacyOpenExternal;

  /// No description provided for @privacyContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get privacyContactTitle;

  /// No description provided for @privacyContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about this Privacy Policy or wish to exercise your data rights, contact us at: {email}'**
  String privacyContactBody(Object email);

  /// No description provided for @privacyP1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Introduction'**
  String get privacyP1Title;

  /// No description provided for @privacyP1Body.
  ///
  /// In en, this message translates to:
  /// **'Lune (\"we\", \"us\", or \"our\") is a menstrual cycle tracking application designed to help users monitor their health and wellness. This Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use our mobile application and related services. By using Lune, you agree to the practices described in this policy. If you do not agree, please discontinue use of the application.'**
  String get privacyP1Body;

  /// No description provided for @privacyP2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Information We Collect'**
  String get privacyP2Title;

  /// No description provided for @privacyP2Body.
  ///
  /// In en, this message translates to:
  /// **'We collect the following types of information:\n\n• Health & Cycle Data: Menstrual cycle dates, symptoms, moods, flow levels, and other health-related entries you voluntarily log.\n• Google Health Connect (optional): If you enable a Health Connect group, Lune reads and writes only selected cycle, fertility, sleep, activity, vital, weight, and hydration categories during a manual foreground sync. Imported snapshots stay encrypted on your device and are not sent to Firebase, AI providers, advertising, communities, or partner features.\n• Account Information: Email, display name, and sign-in method when you register (email/password, Google, or Apple). If you use the app as a guest, we create an anonymous Firebase account linked to your device without collecting your email.\n• Community Content: Posts, comments, reactions, and profile information you share in community features (if you opt in).\n• Device Information: Basic device identifiers required for push notifications, app security (Firebase App Check), and app functionality.\n• AI Data: If you explicitly enable AI, the message or content you submit and relevant cycle context—such as symptoms, mood, phase, and saved preferences—are processed by DeepSeek and/or Google to generate personalized responses. Text you type may contain information you choose to disclose. Guest users: chat history stays on your device only. Registered users: chat history may be stored in your cloud account (Firebase) to restore conversations.\n• Usage & Diagnostics: Approximate last-active timestamp and crash/error reports via Firebase Crashlytics in release builds to help us fix bugs. We do not use third-party advertising trackers.'**
  String get privacyP2Body;

  /// No description provided for @privacyP3Title.
  ///
  /// In en, this message translates to:
  /// **'3. How We Use Your Information'**
  String get privacyP3Title;

  /// No description provided for @privacyP3Body.
  ///
  /// In en, this message translates to:
  /// **'Your information is used to:\n\n• Provide core cycle tracking, predictions, and personalized insights.\n• Deliver AI-powered wellness information and daily briefings (not medical advice).\n• Enable community features (posts, comments, stories) if you opt in.\n• Process cloud backups if you enable encrypted backup.\n• Send optional notifications (period reminders, pill reminders).\n• Improve app performance, diagnose crashes, and fix bugs.\n• Ensure safety and prevent misuse of community features.'**
  String get privacyP3Body;

  /// No description provided for @privacyP4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Storage & Security'**
  String get privacyP4Title;

  /// No description provided for @privacyP4Body.
  ///
  /// In en, this message translates to:
  /// **'Your cycle and health data is stored locally on your device by default. Optional Health Connect records are managed by Android\'s on-device store; Lune accesses them only during manual foreground sync, and imported snapshots remain in encrypted local storage. If you enable Premium cloud backup, the encrypted backup payload is stored in Firebase, with Health Connect snapshots excluded. Encryption keys stay in your device\'s secure storage (Android Keystore / iOS Keychain).'**
  String get privacyP4Body;

  /// No description provided for @privacyP5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Third-Party Services'**
  String get privacyP5Title;

  /// No description provided for @privacyP5Body.
  ///
  /// In en, this message translates to:
  /// **'We use the following third-party services:\n\n• Google Firebase (Authentication, Firestore, Cloud Functions, Cloud Messaging, Hosting, App Check, Crashlytics): Accounts, data storage, push notifications, security, and crash reporting.\n• Google Health Connect: Optional Android on-device health data exchange. Access is off by default, split into permission groups, and Lune does not request background health-data access.\n• Google Gemini AI: AI chat and content processing. Messages are sent to Google for processing per Google\'s API terms.\n• DeepSeek AI: Alternative AI provider for chat and analysis when used by our backend. Messages are sent to DeepSeek for processing per their API terms.\n• Google Play Billing: Premium subscription payments on Android (processed by Google).\n\nEach provider has its own privacy policy. We encourage you to review them. We do not sell your personal data.'**
  String get privacyP5Body;

  /// No description provided for @privacyP6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Your Data Rights'**
  String get privacyP6Title;

  /// No description provided for @privacyP6Body.
  ///
  /// In en, this message translates to:
  /// **'You have the right to:\n\n• Access your data: View all data stored about you within the app.\n• Export your data: Download your cycle data as a local backup file.\n• Delete your data: Delete your account and all associated data permanently from the Privacy Center.\n• Revoke consent: Withdraw consent for cloud sync, AI features, or community participation at any time.\n• Opt out of notifications: Disable any notification type from settings.\n\nIf you are in the EU/UK, you may also have rights under GDPR/UK GDPR. To exercise these rights, use the in-app Privacy Center or contact us at the email below.'**
  String get privacyP6Body;

  /// No description provided for @privacyP7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Children\'s Privacy'**
  String get privacyP7Title;

  /// No description provided for @privacyP7Body.
  ///
  /// In en, this message translates to:
  /// **'Lune is not intended for children under 13 years of age (or the applicable age of consent in your jurisdiction). We do not knowingly collect personal information from children. If we discover that a child has provided us with personal data, we will delete it promptly. Parents or guardians who believe a child has used Lune should contact us immediately.'**
  String get privacyP7Body;

  /// No description provided for @privacyP8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Data Retention'**
  String get privacyP8Title;

  /// No description provided for @privacyP8Body.
  ///
  /// In en, this message translates to:
  /// **'We retain your data for as long as you maintain an active account or as needed to provide services. If you delete your account, we immediately remove your Firestore profile, cloud backups, chat history, and community content from our servers and delete your Firebase Authentication account. Local data on your device remains until you uninstall the app or manually delete it. Technical backups at Firebase or Google Cloud may be retained briefly per their infrastructure policies. Crash reports in Crashlytics are retained according to Firebase\'s retention settings.'**
  String get privacyP8Body;

  /// No description provided for @privacyP9Title.
  ///
  /// In en, this message translates to:
  /// **'9. International Data Transfers'**
  String get privacyP9Title;

  /// No description provided for @privacyP9Body.
  ///
  /// In en, this message translates to:
  /// **'Your data may be processed in countries other than your own, including the United States where Google Firebase and AI provider servers may be located. By using Lune, you consent to the transfer of your data to these locations. We ensure appropriate safeguards are in place for international transfers. If you are in the EU/UK, you may have additional rights under GDPR/UK GDPR as described in section 6.'**
  String get privacyP9Body;

  /// No description provided for @privacyP10Title.
  ///
  /// In en, this message translates to:
  /// **'10. Medical Disclaimer'**
  String get privacyP10Title;

  /// No description provided for @privacyP10Body.
  ///
  /// In en, this message translates to:
  /// **'Lune is designed for informational and wellness tracking purposes only. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional for medical concerns. Do not rely solely on Lune\'s predictions or AI-generated content for health decisions.'**
  String get privacyP10Body;

  /// No description provided for @privacyP11Title.
  ///
  /// In en, this message translates to:
  /// **'11. Changes to This Policy'**
  String get privacyP11Title;

  /// No description provided for @privacyP11Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this Privacy Policy from time to time. We will notify you of significant changes through in-app notifications or email. Your continued use of Lune after changes constitutes acceptance of the updated policy. We encourage you to review this policy periodically.'**
  String get privacyP11Body;

  /// No description provided for @privacyP12Title.
  ///
  /// In en, this message translates to:
  /// **'12. Contact Us'**
  String get privacyP12Title;

  /// No description provided for @privacyP12Body.
  ///
  /// In en, this message translates to:
  /// **'For questions, concerns, or data requests related to this Privacy Policy, please contact us at:'**
  String get privacyP12Body;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsTitle;

  /// No description provided for @termsP1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get termsP1Title;

  /// No description provided for @termsP1Body.
  ///
  /// In en, this message translates to:
  /// **'By downloading, installing, or using Lune (the \"App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, do not use the App. These Terms constitute a legally binding agreement between you and Lune.'**
  String get termsP1Body;

  /// No description provided for @termsP2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Description of Service'**
  String get termsP2Title;

  /// No description provided for @termsP2Body.
  ///
  /// In en, this message translates to:
  /// **'Lune is a menstrual cycle tracking application that provides:\n\n• Cycle logging and prediction tools.\n• AI-powered wellness insights and chat assistance (educational only, not medical advice).\n• Self-care content and wellness recommendations.\n• Community features for sharing experiences.\n• Data backup and synchronization services.\n• Educational wellness content and magazine articles.\n\nThe App is intended for personal, non-commercial use only.'**
  String get termsP2Body;

  /// No description provided for @termsP3Title.
  ///
  /// In en, this message translates to:
  /// **'3. User Accounts'**
  String get termsP3Title;

  /// No description provided for @termsP3Body.
  ///
  /// In en, this message translates to:
  /// **'You may use Lune as a guest with an anonymous device-based account, or create a registered account using email/password, Google Sign-In, or Sign in with Apple (where available). You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. You must be at least 13 years old to use the App. We reserve the right to suspend or terminate accounts that violate these Terms.'**
  String get termsP3Body;

  /// No description provided for @termsP4Title.
  ///
  /// In en, this message translates to:
  /// **'4. User Conduct'**
  String get termsP4Title;

  /// No description provided for @termsP4Body.
  ///
  /// In en, this message translates to:
  /// **'You agree NOT to:\n\n• Use the App for any unlawful purpose.\n• Post harmful, abusive, or misleading content in community features.\n• Impersonate another person or entity.\n• Attempt to access other users\' accounts or data.\n• Upload viruses or malicious code.\n• Scrape, reverse-engineer, or decompile the App.\n• Use automated tools to interact with the App.\n• Spam or harass other community members.\n\nViolation of these rules may result in immediate account termination.'**
  String get termsP4Body;

  /// No description provided for @termsP5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Community Features'**
  String get termsP5Title;

  /// No description provided for @termsP5Body.
  ///
  /// In en, this message translates to:
  /// **'Lune offers optional community features where users can share posts, comments, and stories. By posting content, you grant Lune a non-exclusive, royalty-free license to display, distribute, and store your content within the App. You retain ownership of your content. We reserve the right to remove content that violates these Terms or is reported by other users. You may block other users and manage your community privacy settings at any time.'**
  String get termsP5Body;

  /// No description provided for @termsP6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Subscriptions & Payments'**
  String get termsP6Title;

  /// No description provided for @termsP6Body.
  ///
  /// In en, this message translates to:
  /// **'Lune offers premium features through in-app subscriptions processed via Google Play Billing. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage subscriptions through your Google Play account settings. Refunds are handled according to Google Play\'s refund policy. Free features remain available without a subscription.'**
  String get termsP6Body;

  /// No description provided for @termsP7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Intellectual Property'**
  String get termsP7Title;

  /// No description provided for @termsP7Body.
  ///
  /// In en, this message translates to:
  /// **'The App, including its design, code, graphics, logos, and content, is the intellectual property of Lune and is protected by copyright, trademark, and other laws. You may not copy, modify, distribute, or create derivative works based on the App without our express written permission. The Lune name, logo, and related marks are trademarks of Lune.'**
  String get termsP7Body;

  /// No description provided for @termsP8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Disclaimer of Warranties'**
  String get termsP8Title;

  /// No description provided for @termsP8Body.
  ///
  /// In en, this message translates to:
  /// **'THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE. THE APP IS NOT A MEDICAL DEVICE AND SHOULD NOT BE USED AS A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE, DIAGNOSIS, OR TREATMENT. CYCLE PREDICTIONS ARE ESTIMATES AND MAY NOT BE ACCURATE.'**
  String get termsP8Body;

  /// No description provided for @termsP9Title.
  ///
  /// In en, this message translates to:
  /// **'9. Limitation of Liability'**
  String get termsP9Title;

  /// No description provided for @termsP9Body.
  ///
  /// In en, this message translates to:
  /// **'TO THE MAXIMUM EXTENT PERMITTED BY LAW, LUNE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APP. OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE 12 MONTHS PRECEDING THE CLAIM. THIS LIMITATION APPLIES REGARDLESS OF THE LEGAL THEORY.'**
  String get termsP9Body;

  /// No description provided for @termsP10Title.
  ///
  /// In en, this message translates to:
  /// **'10. Termination'**
  String get termsP10Title;

  /// No description provided for @termsP10Body.
  ///
  /// In en, this message translates to:
  /// **'You may stop using the App at any time and delete your account through the Privacy Center. We may suspend or terminate your access if you violate these Terms or engage in harmful behavior. Upon termination, your right to use the App ceases immediately. Sections regarding intellectual property, disclaimers, and liability limitations survive termination.'**
  String get termsP10Body;

  /// No description provided for @termsP11Title.
  ///
  /// In en, this message translates to:
  /// **'11. Governing Law & Contact'**
  String get termsP11Title;

  /// No description provided for @termsP11Body.
  ///
  /// In en, this message translates to:
  /// **'These Terms are governed by the laws applicable in the jurisdiction of the Lune operator, except where mandatory consumer protection laws in your country of residence provide otherwise. Disputes shall first be resolved through good-faith negotiation. If you have questions about these Terms, contact us at:'**
  String get termsP11Body;

  /// No description provided for @notifRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on Track'**
  String get notifRationaleTitle;

  /// No description provided for @notifRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'Lune can send you gentle reminders about your upcoming period, ovulation, and daily check-ins. You can customize or turn off notifications anytime in Settings.'**
  String get notifRationaleBody;

  /// No description provided for @notifRationaleAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get notifRationaleAllow;

  /// No description provided for @notifRationaleSkip.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get notifRationaleSkip;

  /// No description provided for @notifOsDisabledBanner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Lune in system settings. Reminders will not appear until you enable them.'**
  String get notifOsDisabledBanner;

  /// No description provided for @notifRequestPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notifRequestPermission;

  /// No description provided for @notifExactAlarmsHint.
  ///
  /// In en, this message translates to:
  /// **'For on-time reminders, allow Alarms & reminders for Lune in Android settings.'**
  String get notifExactAlarmsHint;

  /// No description provided for @notifEnableExactAlarms.
  ///
  /// In en, this message translates to:
  /// **'Enable precise alarms'**
  String get notifEnableExactAlarms;

  /// No description provided for @notifScheduledCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reminders scheduled'**
  String notifScheduledCount(int count);

  /// No description provided for @notifNoScheduled.
  ///
  /// In en, this message translates to:
  /// **'No reminders scheduled yet. Allow notifications and log your cycle.'**
  String get notifNoScheduled;

  /// No description provided for @notifTestExactAlarmsHint.
  ///
  /// In en, this message translates to:
  /// **'Test sent, but precise alarms are off — reminders may be delayed.'**
  String get notifTestExactAlarmsHint;

  /// No description provided for @notifNextReminder.
  ///
  /// In en, this message translates to:
  /// **'Next reminder: {when}'**
  String notifNextReminder(String when);

  /// No description provided for @ovulationLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Fertility signals'**
  String get ovulationLogTitle;

  /// No description provided for @ovulationLogToday.
  ///
  /// In en, this message translates to:
  /// **'Ovulated today'**
  String get ovulationLogToday;

  /// No description provided for @ovulationLogLhPositive.
  ///
  /// In en, this message translates to:
  /// **'LH test positive'**
  String get ovulationLogLhPositive;

  /// No description provided for @ovulationLogPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick another date'**
  String get ovulationLogPickDate;

  /// No description provided for @ovulationLogSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved — predictions will adjust'**
  String get ovulationLogSaved;

  /// No description provided for @ovulationCalibratedHint.
  ///
  /// In en, this message translates to:
  /// **'Calibrated from your log'**
  String get ovulationCalibratedHint;

  /// No description provided for @predictionWindowHint.
  ///
  /// In en, this message translates to:
  /// **'Estimate — the more you log, the narrower the window gets'**
  String get predictionWindowHint;

  /// No description provided for @predictionCenterDate.
  ///
  /// In en, this message translates to:
  /// **'Best guess: {date}'**
  String predictionCenterDate(String date);

  /// No description provided for @predictionConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Prediction confidence'**
  String get predictionConfidenceLabel;

  /// No description provided for @predictionConfidenceLearning.
  ///
  /// In en, this message translates to:
  /// **'Still learning'**
  String get predictionConfidenceLearning;

  /// No description provided for @predictionConfidenceModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get predictionConfidenceModerate;

  /// No description provided for @predictionConfidenceStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get predictionConfidenceStrong;

  /// No description provided for @predictionAccuracyPersonal.
  ///
  /// In en, this message translates to:
  /// **'Within 2 days for {within} of your last {total} testable cycles'**
  String predictionAccuracyPersonal(int within, int total);

  /// No description provided for @predictionAccuracyLearning.
  ///
  /// In en, this message translates to:
  /// **'Complete 4 cycles to see your personal accuracy'**
  String get predictionAccuracyLearning;

  /// No description provided for @predictionWindowActive.
  ///
  /// In en, this message translates to:
  /// **'You are currently inside the expected period window'**
  String get predictionWindowActive;

  /// No description provided for @periodPredictionLate.
  ///
  /// In en, this message translates to:
  /// **'{days} days past the end of your expected window'**
  String periodPredictionLate(int days);

  /// No description provided for @predictionPossibleMissingLog.
  ///
  /// In en, this message translates to:
  /// **'This may be a longer cycle, or a period log may be missing. Review your calendar before relying on the next estimate.'**
  String get predictionPossibleMissingLog;

  /// No description provided for @predictionEvidenceNote.
  ///
  /// In en, this message translates to:
  /// **'Personal range based on your history — an estimate, not a medical guarantee'**
  String get predictionEvidenceNote;

  /// No description provided for @ovulationEstimateHint.
  ///
  /// In en, this message translates to:
  /// **'Current-cycle estimate — do not use it alone for contraception'**
  String get ovulationEstimateHint;

  /// No description provided for @ageGateTitle.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get ageGateTitle;

  /// No description provided for @ageGateBody.
  ///
  /// In en, this message translates to:
  /// **'Lune is designed for users aged 13 and older. Some features like community discussions are restricted to users 18+.'**
  String get ageGateBody;

  /// No description provided for @ageGateUnder13.
  ///
  /// In en, this message translates to:
  /// **'Under 13'**
  String get ageGateUnder13;

  /// No description provided for @ageGate13to17.
  ///
  /// In en, this message translates to:
  /// **'13 – 17'**
  String get ageGate13to17;

  /// No description provided for @ageGate18plus.
  ///
  /// In en, this message translates to:
  /// **'18 or older'**
  String get ageGate18plus;

  /// No description provided for @ageGateUnder13Message.
  ///
  /// In en, this message translates to:
  /// **'We\'re sorry, but Lune is not available for users under 13. Please ask a parent or guardian for help.'**
  String get ageGateUnder13Message;

  /// No description provided for @ageGateMinorNote.
  ///
  /// In en, this message translates to:
  /// **'Some features like community discussions are restricted to users 18+.'**
  String get ageGateMinorNote;

  /// No description provided for @adminActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminActive;

  /// No description provided for @adminSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get adminSearch;

  /// No description provided for @adminSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by email or UID...'**
  String get adminSearchHint;

  /// No description provided for @adminSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users by email or UID'**
  String get adminSearchUsers;

  /// No description provided for @adminNoUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsers;

  /// No description provided for @adminBanReporter.
  ///
  /// In en, this message translates to:
  /// **'Ban reporter'**
  String get adminBanReporter;

  /// No description provided for @adminFailedSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save settings'**
  String get adminFailedSave;

  /// No description provided for @adminError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get adminError;

  /// No description provided for @adminQuestionRejected.
  ///
  /// In en, this message translates to:
  /// **'Question rejected'**
  String get adminQuestionRejected;

  /// No description provided for @adminPublishAnswer.
  ///
  /// In en, this message translates to:
  /// **'Publish Answer'**
  String get adminPublishAnswer;

  /// No description provided for @adminReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReject;

  /// No description provided for @adminExpertAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type expert answer...'**
  String get adminExpertAnswerHint;

  /// No description provided for @adminNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Title'**
  String get adminNotifTitle;

  /// No description provided for @adminNotifBody.
  ///
  /// In en, this message translates to:
  /// **'Notification Body'**
  String get adminNotifBody;

  /// No description provided for @adminTitleEnglish.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get adminTitleEnglish;

  /// No description provided for @adminTitleArabic.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get adminTitleArabic;

  /// No description provided for @adminBodyEnglish.
  ///
  /// In en, this message translates to:
  /// **'Body (English)'**
  String get adminBodyEnglish;

  /// No description provided for @adminBodyArabic.
  ///
  /// In en, this message translates to:
  /// **'Body (Arabic)'**
  String get adminBodyArabic;

  /// No description provided for @stealthSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set Stealth PIN'**
  String get stealthSetPin;

  /// No description provided for @stealthPinHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a 4-6 digit PIN to unlock the real app from the calculator.'**
  String get stealthPinHint;

  /// No description provided for @stealthPin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get stealthPin;

  /// No description provided for @stealthConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get stealthConfirmPin;

  /// No description provided for @stealthCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get stealthCancel;

  /// No description provided for @stealthSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get stealthSave;

  /// No description provided for @stealthPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs must match and be at least 4 digits'**
  String get stealthPinMismatch;

  /// No description provided for @stealthEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Stealth Mode'**
  String get stealthEnable;

  /// No description provided for @stealthActivated.
  ///
  /// In en, this message translates to:
  /// **'Stealth mode enabled! Restart the app to activate.'**
  String get stealthActivated;

  /// No description provided for @premiumActivated.
  ///
  /// In en, this message translates to:
  /// **'Premium activated!'**
  String get premiumActivated;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @accountWatchAppleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apple Watch support'**
  String get accountWatchAppleSubtitle;

  /// No description provided for @accountWatchWearSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wear OS support'**
  String get accountWatchWearSubtitle;

  /// No description provided for @insightHeadlineFirstTrimester.
  ///
  /// In en, this message translates to:
  /// **'First trimester'**
  String get insightHeadlineFirstTrimester;

  /// No description provided for @insightBodyFirstTrimester.
  ///
  /// In en, this message translates to:
  /// **'Gentle movement, hydration, and rest are your best friends this week.'**
  String get insightBodyFirstTrimester;

  /// No description provided for @insightHeadlineSecondTrimester.
  ///
  /// In en, this message translates to:
  /// **'Second trimester'**
  String get insightHeadlineSecondTrimester;

  /// No description provided for @insightBodySecondTrimester.
  ///
  /// In en, this message translates to:
  /// **'Energy usually picks up here — great time for light walks and stretching.'**
  String get insightBodySecondTrimester;

  /// No description provided for @insightHeadlineThirdTrimester.
  ///
  /// In en, this message translates to:
  /// **'Third trimester'**
  String get insightHeadlineThirdTrimester;

  /// No description provided for @insightBodyThirdTrimester.
  ///
  /// In en, this message translates to:
  /// **'Rest often, hydrate, and reach out to your provider with any concerns.'**
  String get insightBodyThirdTrimester;

  /// No description provided for @insightHeadlinePeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Period day'**
  String get insightHeadlinePeriodDay;

  /// No description provided for @insightBodyPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Warm drinks + magnesium-rich foods can ease cramps. Be gentle with yourself today.'**
  String get insightBodyPeriodDay;

  /// No description provided for @insightHeadlineFollicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular phase'**
  String get insightHeadlineFollicular;

  /// No description provided for @insightBodyFollicular.
  ///
  /// In en, this message translates to:
  /// **'Energy tends to climb — try a new workout or tackle a tough task today.'**
  String get insightBodyFollicular;

  /// No description provided for @insightHeadlineOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get insightHeadlineOvulation;

  /// No description provided for @insightBodyOvulation.
  ///
  /// In en, this message translates to:
  /// **'Peak energy + confidence. Good day for a hard workout or a social plan.'**
  String get insightBodyOvulation;

  /// No description provided for @insightHeadlineLuteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal phase'**
  String get insightHeadlineLuteal;

  /// No description provided for @insightBodyLutealEarly.
  ///
  /// In en, this message translates to:
  /// **'Luteal phase — crave calm: less caffeine, more rest, gentle movement.'**
  String get insightBodyLutealEarly;

  /// No description provided for @insightBodyLutealLate.
  ///
  /// In en, this message translates to:
  /// **'Luteal week — complex carbs + earlier bedtime can really help mood right now.'**
  String get insightBodyLutealLate;

  /// No description provided for @insightHeadlineLatePeriod.
  ///
  /// In en, this message translates to:
  /// **'Cycle is running late'**
  String get insightHeadlineLatePeriod;

  /// No description provided for @insightBodyLatePeriod.
  ///
  /// In en, this message translates to:
  /// **'Stress or sleep changes can shift things. Give it 2-3 days — log any symptoms.'**
  String get insightBodyLatePeriod;

  /// No description provided for @insightHeadlineWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome 🌸'**
  String get insightHeadlineWelcome;

  /// No description provided for @insightBodyWelcome.
  ///
  /// In en, this message translates to:
  /// **'Set your last period date to unlock personalised daily insights.'**
  String get insightBodyWelcome;

  /// No description provided for @smartWatch.
  ///
  /// In en, this message translates to:
  /// **'Smart Watch'**
  String get smartWatch;

  /// No description provided for @anonymousQa.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Q&A'**
  String get anonymousQa;

  /// No description provided for @anonymousQaDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask health questions privately'**
  String get anonymousQaDesc;

  /// No description provided for @accountWatchSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Watch Sync'**
  String get accountWatchSheetTitle;

  /// No description provided for @accountWatchSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Your cycle data is automatically synced to your paired smart watch. You can view your cycle progress and log your period directly from your watch.'**
  String get accountWatchSheetBody;

  /// No description provided for @accountWatchFeatureSync.
  ///
  /// In en, this message translates to:
  /// **'Auto-syncs cycle data to watch'**
  String get accountWatchFeatureSync;

  /// No description provided for @accountWatchFeatureRing.
  ///
  /// In en, this message translates to:
  /// **'Cycle ring on watch face'**
  String get accountWatchFeatureRing;

  /// No description provided for @accountWatchFeatureLog.
  ///
  /// In en, this message translates to:
  /// **'Log period from watch'**
  String get accountWatchFeatureLog;

  /// No description provided for @accountWatchFeaturePhase.
  ///
  /// In en, this message translates to:
  /// **'Current phase display'**
  String get accountWatchFeaturePhase;

  /// No description provided for @watchSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get watchSyncNow;

  /// No description provided for @watchSyncSuccess.
  ///
  /// In en, this message translates to:
  /// **'Watch data synced successfully!'**
  String get watchSyncSuccess;

  /// No description provided for @watchSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: make sure your watch is paired.'**
  String get watchSyncFailed;

  /// No description provided for @dateFormatDDMMYYYY.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get dateFormatDDMMYYYY;

  /// No description provided for @dateFormatMMDDYYYY.
  ///
  /// In en, this message translates to:
  /// **'MM/DD/YYYY'**
  String get dateFormatMMDDYYYY;

  /// No description provided for @dateFormatYYYYMMDD.
  ///
  /// In en, this message translates to:
  /// **'YYYY/MM/DD'**
  String get dateFormatYYYYMMDD;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 15 MB)'**
  String get fileTooLarge;

  /// No description provided for @healthQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Type your health question here...'**
  String get healthQuestionHint;

  /// No description provided for @geminiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste your API key here'**
  String get geminiKeyHint;

  /// No description provided for @appLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App Lock'**
  String get appLockTitle;

  /// No description provided for @appLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Require your fingerprint or device passcode every time Lune opens.'**
  String get appLockDescription;

  /// No description provided for @appLockEnable.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint'**
  String get appLockEnable;

  /// No description provided for @appLockConfirmReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to change App Lock'**
  String get appLockConfirmReason;

  /// No description provided for @appLockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint or screen lock is set up on this device.'**
  String get appLockUnavailable;

  /// No description provided for @appLockActivated.
  ///
  /// In en, this message translates to:
  /// **'App Lock is on — Lune will ask for your fingerprint when it opens.'**
  String get appLockActivated;

  /// No description provided for @stealthTitle.
  ///
  /// In en, this message translates to:
  /// **'Stealth Mode'**
  String get stealthTitle;

  /// No description provided for @stealthDescription.
  ///
  /// In en, this message translates to:
  /// **'Disguise the app as a calculator. Enter your secret PIN then press = to unlock.'**
  String get stealthDescription;

  /// No description provided for @stealthUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'To unlock: open the calculator, type your PIN, then press ='**
  String get stealthUnlockHint;

  /// No description provided for @stealthHideNow.
  ///
  /// In en, this message translates to:
  /// **'Hide app now'**
  String get stealthHideNow;

  /// No description provided for @stealthHideNowHint.
  ///
  /// In en, this message translates to:
  /// **'Instantly switch to the calculator disguise.'**
  String get stealthHideNowHint;

  /// No description provided for @anonymousQaTooltip.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Q&A'**
  String get anonymousQaTooltip;

  /// No description provided for @anonymousQaTitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymous Health Q&A'**
  String get anonymousQaTitle;

  /// No description provided for @anonymousQaIntro.
  ///
  /// In en, this message translates to:
  /// **'Ask your health question anonymously. A certified expert will answer it and the answer will be published in the Education section.'**
  String get anonymousQaIntro;

  /// No description provided for @anonymousQaPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'What is this page?'**
  String get anonymousQaPurposeTitle;

  /// No description provided for @anonymousQaStep1.
  ///
  /// In en, this message translates to:
  /// **'Write your health question — your name is never shown'**
  String get anonymousQaStep1;

  /// No description provided for @anonymousQaStep2.
  ///
  /// In en, this message translates to:
  /// **'The Lune team reviews it and prepares an answer'**
  String get anonymousQaStep2;

  /// No description provided for @anonymousQaStep3.
  ///
  /// In en, this message translates to:
  /// **'The answer is published in Education to help everyone'**
  String get anonymousQaStep3;

  /// No description provided for @anonymousQaDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'For general education only — not medical diagnosis or treatment. For urgent concerns, contact your doctor or emergency services.'**
  String get anonymousQaDisclaimer;

  /// No description provided for @anonymousQaCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get anonymousQaCategoryLabel;

  /// No description provided for @anonymousQaQuestionLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Question'**
  String get anonymousQaQuestionLabel;

  /// No description provided for @anonymousQaPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your identity is 100% anonymous. No name, email, or ID is stored.'**
  String get anonymousQaPrivacyNote;

  /// No description provided for @anonymousQaSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Question'**
  String get anonymousQaSubmit;

  /// No description provided for @anonymousQaSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get anonymousQaSubmitting;

  /// No description provided for @anonymousQaSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your question was submitted. Thank you!'**
  String get anonymousQaSubmitted;

  /// No description provided for @anonymousQaTooShort.
  ///
  /// In en, this message translates to:
  /// **'Please write at least 10 characters.'**
  String get anonymousQaTooShort;

  /// No description provided for @anonymousQaError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit your question. Please try again.'**
  String get anonymousQaError;

  /// No description provided for @qaCatGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get qaCatGeneral;

  /// No description provided for @qaCatCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle & Period'**
  String get qaCatCycle;

  /// No description provided for @qaCatPregnancy.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy'**
  String get qaCatPregnancy;

  /// No description provided for @qaCatPcos.
  ///
  /// In en, this message translates to:
  /// **'PCOS'**
  String get qaCatPcos;

  /// No description provided for @qaCatContraception.
  ///
  /// In en, this message translates to:
  /// **'Contraception'**
  String get qaCatContraception;

  /// No description provided for @qaCatMental.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get qaCatMental;

  /// No description provided for @qaCatNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get qaCatNutrition;

  /// No description provided for @dailyBriefingPrompt.
  ///
  /// In en, this message translates to:
  /// **'Give me my daily briefing for today.'**
  String get dailyBriefingPrompt;

  /// No description provided for @accountSectionPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get accountSectionPremium;

  /// No description provided for @accountViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View plans and prices'**
  String get accountViewPlans;

  /// No description provided for @accountPremiumThanks.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Premium member — thank you for supporting Lune!'**
  String get accountPremiumThanks;

  /// No description provided for @accountManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get accountManageSubscription;

  /// No description provided for @accountManageSubscriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Opens Google Play subscriptions'**
  String get accountManageSubscriptionHint;

  /// No description provided for @accountSectionInfo.
  ///
  /// In en, this message translates to:
  /// **'Account info'**
  String get accountSectionInfo;

  /// No description provided for @accountUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accountUsernameTitle;

  /// No description provided for @accountUsernameNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — edit your profile to add one'**
  String get accountUsernameNotSet;

  /// No description provided for @accountEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmailTitle;

  /// No description provided for @accountEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get accountEmailVerified;

  /// No description provided for @accountEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get accountEmailNotVerified;

  /// No description provided for @accountVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent. Check your inbox.'**
  String get accountVerificationSent;

  /// No description provided for @accountIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get accountIdTitle;

  /// No description provided for @accountMemberSinceTitle.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get accountMemberSinceTitle;

  /// No description provided for @accountTypeGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest account'**
  String get accountTypeGuest;

  /// No description provided for @accountTypeEmail.
  ///
  /// In en, this message translates to:
  /// **'Email account'**
  String get accountTypeEmail;

  /// No description provided for @accountCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get accountCopied;

  /// No description provided for @accountUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accountUsernameLabel;

  /// No description provided for @accountUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. luna_star'**
  String get accountUsernameHint;

  /// No description provided for @accountUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters: letters, numbers, dot or underscore'**
  String get accountUsernameInvalid;

  /// No description provided for @trustHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust & Privacy'**
  String get trustHubTitle;

  /// No description provided for @trustHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear answers about how Lune protects your health data — security, cookies, accessibility, and more.'**
  String get trustHubSubtitle;

  /// No description provided for @trustHubLink.
  ///
  /// In en, this message translates to:
  /// **'Trust & Privacy Center'**
  String get trustHubLink;

  /// No description provided for @trustLinkSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security at Lune'**
  String get trustLinkSecurity;

  /// No description provided for @trustLinkSecuritySub.
  ///
  /// In en, this message translates to:
  /// **'Encryption, authentication, and how we protect your data'**
  String get trustLinkSecuritySub;

  /// No description provided for @trustLinkBodyData.
  ///
  /// In en, this message translates to:
  /// **'Your Body, Your Data'**
  String get trustLinkBodyData;

  /// No description provided for @trustLinkBodyDataSub.
  ///
  /// In en, this message translates to:
  /// **'You own your cycle data — we never sell it'**
  String get trustLinkBodyDataSub;

  /// No description provided for @trustLinkDataEnds.
  ///
  /// In en, this message translates to:
  /// **'Your Data Ends With You'**
  String get trustLinkDataEnds;

  /// No description provided for @trustLinkDataEndsSub.
  ///
  /// In en, this message translates to:
  /// **'Delete your account and cloud data anytime'**
  String get trustLinkDataEndsSub;

  /// No description provided for @trustLinkFaq.
  ///
  /// In en, this message translates to:
  /// **'Privacy FAQ'**
  String get trustLinkFaq;

  /// No description provided for @trustLinkFaqSub.
  ///
  /// In en, this message translates to:
  /// **'Common questions about privacy at Lune'**
  String get trustLinkFaqSub;

  /// No description provided for @trustLinkCookies.
  ///
  /// In en, this message translates to:
  /// **'Cookie Policy'**
  String get trustLinkCookies;

  /// No description provided for @trustLinkCookiesSub.
  ///
  /// In en, this message translates to:
  /// **'How we use local storage and website cookies'**
  String get trustLinkCookiesSub;

  /// No description provided for @trustLinkIp.
  ///
  /// In en, this message translates to:
  /// **'IP Address Use'**
  String get trustLinkIp;

  /// No description provided for @trustLinkIpSub.
  ///
  /// In en, this message translates to:
  /// **'Why we process IP addresses and what we don\'t do'**
  String get trustLinkIpSub;

  /// No description provided for @trustLinkAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get trustLinkAccessibility;

  /// No description provided for @trustLinkAccessibilitySub.
  ///
  /// In en, this message translates to:
  /// **'Our commitment to an inclusive experience'**
  String get trustLinkAccessibilitySub;

  /// No description provided for @trustSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security at Lune'**
  String get trustSecurityTitle;

  /// No description provided for @trustSecurityIntro.
  ///
  /// In en, this message translates to:
  /// **'Your health data deserves bank-grade care. Security is built into every layer of Lune — not added as an afterthought. This page explains how we protect your cycle logs, account, and optional cloud features in plain language.'**
  String get trustSecurityIntro;

  /// No description provided for @trustSecurityS1Title.
  ///
  /// In en, this message translates to:
  /// **'Encryption on your device'**
  String get trustSecurityS1Title;

  /// No description provided for @trustSecurityS1Body.
  ///
  /// In en, this message translates to:
  /// **'Your cycle database is encrypted locally using AES-256 before it is stored on your phone. Symptom, mood, flow, and wellness entries live inside this protected store. Encryption keys are generated on your device and stored in Android Keystore or iOS Keychain — they never leave your device unprotected.'**
  String get trustSecurityS1Body;

  /// No description provided for @trustSecurityS2Title.
  ///
  /// In en, this message translates to:
  /// **'Encrypted cloud sync (optional, Premium)'**
  String get trustSecurityS2Title;

  /// No description provided for @trustSecurityS2Body.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup is optional and requires Premium plus your explicit consent. When enabled, your cycle backup payload is encrypted on the device before upload and stored in your private Firebase account. We do not claim every Firestore profile field uses the same AES-256 scheme — the sensitive cycle payload itself is encrypted before it leaves your phone.'**
  String get trustSecurityS2Body;

  /// No description provided for @trustSecurityS3Title.
  ///
  /// In en, this message translates to:
  /// **'Secure connections & app integrity'**
  String get trustSecurityS3Title;

  /// No description provided for @trustSecurityS3Body.
  ///
  /// In en, this message translates to:
  /// **'All network traffic uses TLS encryption. Firebase App Check helps verify genuine app requests. You can sign in with email, Google, Apple, or continue as an anonymous guest — each method is handled through Firebase Authentication with industry-standard protections.'**
  String get trustSecurityS3Body;

  /// No description provided for @trustSecurityS4Title.
  ///
  /// In en, this message translates to:
  /// **'No ads, no data brokers'**
  String get trustSecurityS4Title;

  /// No description provided for @trustSecurityS4Body.
  ///
  /// In en, this message translates to:
  /// **'Lune does not show third-party ads and does not sell your personal or health data. We do not share your cycle data with advertisers, data brokers, employers, or insurers. Our revenue comes from optional Premium subscriptions, not from monetizing your health information.'**
  String get trustSecurityS4Body;

  /// No description provided for @trustSecurityS5Title.
  ///
  /// In en, this message translates to:
  /// **'You control optional features'**
  String get trustSecurityS5Title;

  /// No description provided for @trustSecurityS5Body.
  ///
  /// In en, this message translates to:
  /// **'AI chat (Google Gemini and DeepSeek), community, push notifications, and cloud sync are optional and require your consent. You can review and change these choices anytime in Privacy Center without affecting core local tracking.'**
  String get trustSecurityS5Body;

  /// No description provided for @trustSecurityS6Title.
  ///
  /// In en, this message translates to:
  /// **'Crash reporting (Firebase Crashlytics)'**
  String get trustSecurityS6Title;

  /// No description provided for @trustSecurityS6Body.
  ///
  /// In en, this message translates to:
  /// **'Lune uses Firebase Crashlytics to collect anonymized crash reports and basic diagnostic data when the app fails unexpectedly. This helps us fix bugs quickly. Crash reports do not include your cycle logs, wellness entries, or AI chat content.'**
  String get trustSecurityS6Body;

  /// No description provided for @trustSecurityS7Title.
  ///
  /// In en, this message translates to:
  /// **'Cloud infrastructure'**
  String get trustSecurityS7Title;

  /// No description provided for @trustSecurityS7Body.
  ///
  /// In en, this message translates to:
  /// **'Registered accounts, optional cloud backups, community content, and AI chat (for Premium users) run on Google Firebase — including Authentication, Firestore, Cloud Functions, Cloud Messaging, Hosting, App Check, and Crashlytics. Access to your data is restricted by Firebase security rules and your sign-in credentials.'**
  String get trustSecurityS7Body;

  /// No description provided for @trustSecurityS8Title.
  ///
  /// In en, this message translates to:
  /// **'Stealth mode on your device'**
  String get trustSecurityS8Title;

  /// No description provided for @trustSecurityS8Body.
  ///
  /// In en, this message translates to:
  /// **'Stealth mode disguises Lune as a calculator until you enter your PIN. This protects privacy on your phone if someone picks it up — it is a local lock only and does not encrypt data differently. You can enable or disable it in Privacy Center.'**
  String get trustSecurityS8Body;

  /// No description provided for @trustSecurityS9Title.
  ///
  /// In en, this message translates to:
  /// **'Payment security'**
  String get trustSecurityS9Title;

  /// No description provided for @trustSecurityS9Body.
  ///
  /// In en, this message translates to:
  /// **'Premium subscriptions on Android are processed by Google Play Billing. Lune never sees or stores your card number. Manage or cancel your subscription through your Google Play account settings.'**
  String get trustSecurityS9Body;

  /// No description provided for @trustSecurityS10Title.
  ///
  /// In en, this message translates to:
  /// **'Android app permissions'**
  String get trustSecurityS10Title;

  /// No description provided for @trustSecurityS10Body.
  ///
  /// In en, this message translates to:
  /// **'Lune requests only permissions needed for features you use: Internet (sign-in, optional cloud sync, AI, community), Notifications (optional cycle reminders), Google Play Billing (Premium), exact alarms and boot restart (reliable local reminders), and photos/media only when you choose to attach an image or set a profile photo. Android backup for app data is disabled (allowBackup=false) so cycle data is not copied to Google device backup by default.'**
  String get trustSecurityS10Body;

  /// No description provided for @trustCookiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cookie & Storage Policy'**
  String get trustCookiesTitle;

  /// No description provided for @trustCookiesIntro.
  ///
  /// In en, this message translates to:
  /// **'Lune is a mobile app first. This page explains what is stored on your device, what our website keeps, and what we deliberately do not track. We believe clarity about storage is part of respecting your privacy.'**
  String get trustCookiesIntro;

  /// No description provided for @trustCookiesS1Title.
  ///
  /// In en, this message translates to:
  /// **'App local storage'**
  String get trustCookiesS1Title;

  /// No description provided for @trustCookiesS1Body.
  ///
  /// In en, this message translates to:
  /// **'The Lune app stores your cycle logs, wellness entries, preferences, consent choices, and (if you are a guest) AI chat history on your device using encrypted local databases and secure storage. This is essential for offline tracking and fast daily logging.'**
  String get trustCookiesS1Body;

  /// No description provided for @trustCookiesS2Title.
  ///
  /// In en, this message translates to:
  /// **'Website cookies'**
  String get trustCookiesS2Title;

  /// No description provided for @trustCookiesS2Body.
  ///
  /// In en, this message translates to:
  /// **'Our website (lune-7d956.web.app) does not use advertising or tracking cookies. We may use essential technical storage — such as remembering your language choice on legal pages — so you do not have to re-select it every visit.'**
  String get trustCookiesS2Body;

  /// No description provided for @trustCookiesS3Title.
  ///
  /// In en, this message translates to:
  /// **'No ad tracking'**
  String get trustCookiesS3Title;

  /// No description provided for @trustCookiesS3Body.
  ///
  /// In en, this message translates to:
  /// **'We do not use third-party ad networks, cross-app trackers, or marketing pixels in the Lune app. Your health data is never used for targeted advertising, audience profiling, or retargeting campaigns.'**
  String get trustCookiesS3Body;

  /// No description provided for @trustCookiesS4Title.
  ///
  /// In en, this message translates to:
  /// **'Managing storage'**
  String get trustCookiesS4Title;

  /// No description provided for @trustCookiesS4Body.
  ///
  /// In en, this message translates to:
  /// **'You can clear local app data by uninstalling the app or deleting your account from Privacy Center. Exported backup files you save to your clipboard or elsewhere remain under your control — delete them when you no longer need them.'**
  String get trustCookiesS4Body;

  /// No description provided for @trustCookiesS5Title.
  ///
  /// In en, this message translates to:
  /// **'Push notification tokens'**
  String get trustCookiesS5Title;

  /// No description provided for @trustCookiesS5Body.
  ///
  /// In en, this message translates to:
  /// **'If you enable notifications, Firebase Cloud Messaging stores a device token so we can deliver cycle reminders and app updates you asked for. This token is used for delivery only — not for advertising or selling your identity to third parties.'**
  String get trustCookiesS5Body;

  /// No description provided for @trustCookiesS6Title.
  ///
  /// In en, this message translates to:
  /// **'Community cache'**
  String get trustCookiesS6Title;

  /// No description provided for @trustCookiesS6Body.
  ///
  /// In en, this message translates to:
  /// **'When you browse communities, posts and images may be cached temporarily on your device for smoother scrolling. This cache is part of normal app performance and is cleared when you uninstall the app or clear app data.'**
  String get trustCookiesS6Body;

  /// No description provided for @trustCookiesS7Title.
  ///
  /// In en, this message translates to:
  /// **'Language & consent preferences'**
  String get trustCookiesS7Title;

  /// No description provided for @trustCookiesS7Body.
  ///
  /// In en, this message translates to:
  /// **'Your language choice, Privacy Center consent toggles, and stealth-mode settings are saved locally so the app remembers your preferences between sessions. These settings stay on your device unless you sign in and sync account-level preferences.'**
  String get trustCookiesS7Body;

  /// No description provided for @trustCookiesS8Title.
  ///
  /// In en, this message translates to:
  /// **'What we never store for ads'**
  String get trustCookiesS8Title;

  /// No description provided for @trustCookiesS8Body.
  ///
  /// In en, this message translates to:
  /// **'We do not place ad cookies, social pixels, or behavioral tracking SDKs in Lune. We do not build marketing profiles from your cycle data, symptoms, moods, or AI conversations.'**
  String get trustCookiesS8Body;

  /// No description provided for @trustIpTitle.
  ///
  /// In en, this message translates to:
  /// **'How We Use IP Addresses'**
  String get trustIpTitle;

  /// No description provided for @trustIpIntro.
  ///
  /// In en, this message translates to:
  /// **'When you use Lune or our website, your IP address may be processed by our infrastructure providers. This page explains why that happens, what we do not do with it, and the choices available to you.'**
  String get trustIpIntro;

  /// No description provided for @trustIpS1Title.
  ///
  /// In en, this message translates to:
  /// **'Why IP addresses are processed'**
  String get trustIpS1Title;

  /// No description provided for @trustIpS1Body.
  ///
  /// In en, this message translates to:
  /// **'IP addresses help Firebase and our Cloud Functions deliver requests securely, route traffic to the correct server, and keep the service available. Without basic network metadata, cloud apps cannot function reliably.'**
  String get trustIpS1Body;

  /// No description provided for @trustIpS2Title.
  ///
  /// In en, this message translates to:
  /// **'What we do not do'**
  String get trustIpS2Title;

  /// No description provided for @trustIpS2Body.
  ///
  /// In en, this message translates to:
  /// **'We do not sell IP addresses, use them for advertising profiles, or attempt to determine your precise physical location from your IP alone. Your IP is not shared with data brokers or ad networks.'**
  String get trustIpS2Body;

  /// No description provided for @trustIpS3Title.
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get trustIpS3Title;

  /// No description provided for @trustIpS3Body.
  ///
  /// In en, this message translates to:
  /// **'IP addresses in server and hosting logs are kept only as long as needed for security, abuse prevention, and troubleshooting. They are then rotated or deleted according to Firebase and Google Cloud retention policies.'**
  String get trustIpS3Body;

  /// No description provided for @trustIpS4Title.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get trustIpS4Title;

  /// No description provided for @trustIpS4Body.
  ///
  /// In en, this message translates to:
  /// **'Using a VPN is your choice — we do not penalize VPN users. Deleting your account removes your profile and associated cloud content from our servers. For full details, see our Privacy Policy.'**
  String get trustIpS4Body;

  /// No description provided for @trustIpS5Title.
  ///
  /// In en, this message translates to:
  /// **'Rate limits & abuse prevention'**
  String get trustIpS5Title;

  /// No description provided for @trustIpS5Body.
  ///
  /// In en, this message translates to:
  /// **'We apply server-side rate limits on AI chat and community actions to prevent spam and protect all users. IP addresses and authenticated account IDs may be used together to detect abusive patterns — never to profile you for marketing.'**
  String get trustIpS5Body;

  /// No description provided for @trustIpS6Title.
  ///
  /// In en, this message translates to:
  /// **'Where data may be processed'**
  String get trustIpS6Title;

  /// No description provided for @trustIpS6Body.
  ///
  /// In en, this message translates to:
  /// **'Firebase and our AI providers may process requests in the United States and other regions where Google and DeepSeek operate data centers. This is standard for cloud-hosted health apps with optional sync.'**
  String get trustIpS6Body;

  /// No description provided for @trustIpS7Title.
  ///
  /// In en, this message translates to:
  /// **'Legal requests'**
  String get trustIpS7Title;

  /// No description provided for @trustIpS7Body.
  ///
  /// In en, this message translates to:
  /// **'We may disclose information — which could include IP-related server logs — only when required by valid legal process and to the minimum extent the law demands. We do not voluntarily share cycle health data with authorities.'**
  String get trustIpS7Body;

  /// No description provided for @trustIpS8Title.
  ///
  /// In en, this message translates to:
  /// **'VPNs and privacy tools'**
  String get trustIpS8Title;

  /// No description provided for @trustIpS8Body.
  ///
  /// In en, this message translates to:
  /// **'If you use a VPN, your visible IP may differ from your physical region. Lune does not block VPN connections. Some Firebase security checks may still apply to protect accounts from takeover attempts.'**
  String get trustIpS8Body;

  /// No description provided for @trustFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy FAQ'**
  String get trustFaqTitle;

  /// No description provided for @trustFaqIntro.
  ///
  /// In en, this message translates to:
  /// **'Answers to the questions we hear most about privacy, security, and how Lune handles your cycle data. If you do not find your answer here, contact us anytime.'**
  String get trustFaqIntro;

  /// No description provided for @trustFaqQ1.
  ///
  /// In en, this message translates to:
  /// **'Who can see my cycle data?'**
  String get trustFaqQ1;

  /// No description provided for @trustFaqA1.
  ///
  /// In en, this message translates to:
  /// **'Only you. By default, your cycle data stays on your device in an encrypted local database. If you enable Premium cloud backup, encrypted copies are stored in your private Firebase account. We do not share cycle data with other users unless you explicitly post in community features.'**
  String get trustFaqA1;

  /// No description provided for @trustFaqQ2.
  ///
  /// In en, this message translates to:
  /// **'Does Lune sell my data?'**
  String get trustFaqQ2;

  /// No description provided for @trustFaqA2.
  ///
  /// In en, this message translates to:
  /// **'No. We never sell your personal or health data. Lune is funded through optional Premium subscriptions processed by Google Play — not through advertising or data brokerage.'**
  String get trustFaqA2;

  /// No description provided for @trustFaqQ3.
  ///
  /// In en, this message translates to:
  /// **'What happens when I delete my account?'**
  String get trustFaqQ3;

  /// No description provided for @trustFaqA3.
  ///
  /// In en, this message translates to:
  /// **'When you confirm deletion in Privacy Center, we immediately remove your Firestore profile, cloud backups, chat history, and community content from our servers, then delete your Firebase Authentication account. Local data on your device remains until you uninstall the app. Technical backups at Firebase may be retained briefly per their infrastructure policies.'**
  String get trustFaqA3;

  /// No description provided for @trustFaqQ4.
  ///
  /// In en, this message translates to:
  /// **'Is AI chat private?'**
  String get trustFaqQ4;

  /// No description provided for @trustFaqA4.
  ///
  /// In en, this message translates to:
  /// **'AI chat requires Premium. Guest users keep chat on the device only. Registered Premium users may have messages stored in the cloud to restore conversations. Every AI message is sent to Google Gemini and/or DeepSeek for processing — see our Privacy Policy. We recommend not sharing information you would not want a third-party AI provider to process.'**
  String get trustFaqA4;

  /// No description provided for @trustFaqQ5.
  ///
  /// In en, this message translates to:
  /// **'Can I use Lune without an account?'**
  String get trustFaqQ5;

  /// No description provided for @trustFaqA5.
  ///
  /// In en, this message translates to:
  /// **'Yes. You can use Lune as a guest with an anonymous Firebase account linked to your device — no email required. Core cycle tracking works fully offline. Cloud backup, Premium AI, cross-device chat history, and some community features require a registered account.'**
  String get trustFaqA5;

  /// No description provided for @trustFaqQ6.
  ///
  /// In en, this message translates to:
  /// **'Where is my data stored?'**
  String get trustFaqQ6;

  /// No description provided for @trustFaqA6.
  ///
  /// In en, this message translates to:
  /// **'Locally on your phone by default in an AES-256 encrypted database. If you enable Premium cloud backup, encrypted backup payloads are stored in Google Firebase, which may process data in the United States and other regions.'**
  String get trustFaqA6;

  /// No description provided for @trustFaqQ7.
  ///
  /// In en, this message translates to:
  /// **'How do I export my data?'**
  String get trustFaqQ7;

  /// No description provided for @trustFaqA7.
  ///
  /// In en, this message translates to:
  /// **'Open Privacy Center → Export Data to copy an encrypted local backup to your clipboard. You can save it in a password manager or secure notes app. For help with portability requests, email merrsoheb@gmail.com.'**
  String get trustFaqA7;

  /// No description provided for @trustFaqQ8.
  ///
  /// In en, this message translates to:
  /// **'How do I contact you about privacy?'**
  String get trustFaqQ8;

  /// No description provided for @trustFaqA8.
  ///
  /// In en, this message translates to:
  /// **'Email merrsoheb@gmail.com or use Contact Support in Privacy Center. We aim to respond to privacy requests within 30 days.'**
  String get trustFaqA8;

  /// No description provided for @trustFaqQ9.
  ///
  /// In en, this message translates to:
  /// **'Is AI chat free?'**
  String get trustFaqQ9;

  /// No description provided for @trustFaqA9.
  ///
  /// In en, this message translates to:
  /// **'No. Lune AI is a Premium feature. Premium subscribers can send up to 30 AI messages per calendar day — enforced on our servers. If a provider fails, we do not count that message against your limit.'**
  String get trustFaqA9;

  /// No description provided for @trustFaqQ10.
  ///
  /// In en, this message translates to:
  /// **'What does Premium unlock?'**
  String get trustFaqQ10;

  /// No description provided for @trustFaqA10.
  ///
  /// In en, this message translates to:
  /// **'Premium includes cloud cycle backup, Lune AI chat (30 messages/day), and attaching photos or videos in community posts and stories. Core local tracking remains free for all users.'**
  String get trustFaqA10;

  /// No description provided for @trustFaqQ11.
  ///
  /// In en, this message translates to:
  /// **'How does Stealth mode work?'**
  String get trustFaqQ11;

  /// No description provided for @trustFaqA11.
  ///
  /// In en, this message translates to:
  /// **'Stealth mode shows a calculator screen instead of Lune until you enter your secret PIN and press equals. It protects your privacy if someone opens your phone. It is a local disguise only — enable it in Privacy Center.'**
  String get trustFaqA11;

  /// No description provided for @trustFaqQ12.
  ///
  /// In en, this message translates to:
  /// **'Who sees my community posts?'**
  String get trustFaqQ12;

  /// No description provided for @trustFaqA12.
  ///
  /// In en, this message translates to:
  /// **'Posts are visible to members of the Lune communities you join. You can report unsafe content; reported posts may be auto-hidden while we review them. Community participation is optional and requires consent.'**
  String get trustFaqA12;

  /// No description provided for @trustFaqQ13.
  ///
  /// In en, this message translates to:
  /// **'Can I share a health report with my doctor?'**
  String get trustFaqQ13;

  /// No description provided for @trustFaqA13.
  ///
  /// In en, this message translates to:
  /// **'Yes. Lune can generate a health summary report from your logged data that you can review and share yourself. We do not send reports to doctors automatically — you choose what to share and with whom.'**
  String get trustFaqA13;

  /// No description provided for @trustFaqQ14.
  ///
  /// In en, this message translates to:
  /// **'Does the magazine use my personal data?'**
  String get trustFaqQ14;

  /// No description provided for @trustFaqA14.
  ///
  /// In en, this message translates to:
  /// **'No. Educational articles in the Lune magazine are editorial content managed separately from your private cycle logs. Reading articles does not upload your personal health data for personalization.'**
  String get trustFaqA14;

  /// No description provided for @trustFaqQ15.
  ///
  /// In en, this message translates to:
  /// **'What notifications does Lune send?'**
  String get trustFaqQ15;

  /// No description provided for @trustFaqA15.
  ///
  /// In en, this message translates to:
  /// **'If you opt in, we may send cycle reminders, wellness prompts, and important app updates via Firebase Cloud Messaging. We do not send promotional ads or sell notification audiences to third parties. You can disable notifications in device settings.'**
  String get trustFaqA15;

  /// No description provided for @trustFaqQ16.
  ///
  /// In en, this message translates to:
  /// **'What are my GDPR rights?'**
  String get trustFaqQ16;

  /// No description provided for @trustFaqA16.
  ///
  /// In en, this message translates to:
  /// **'If you are in the EEA or UK, you may request access, correction, deletion, or export of your personal data. Delete your account in Privacy Center for immediate server removal, or email merrsoheb@gmail.com for assistance. We respond within 30 days.'**
  String get trustFaqA16;

  /// No description provided for @trustFaqQ17.
  ///
  /// In en, this message translates to:
  /// **'What Android permissions does Lune use?'**
  String get trustFaqQ17;

  /// No description provided for @trustFaqA17.
  ///
  /// In en, this message translates to:
  /// **'Internet for sign-in and optional online features; Notifications for reminders you enable; Google Play Billing for Premium; exact alarms and boot restart for reliable local reminders. Photos or videos are requested only when you attach media in community (Premium) or choose a profile photo. We do not access your contacts, SMS, or call logs.'**
  String get trustFaqA17;

  /// No description provided for @trustFaqQ18.
  ///
  /// In en, this message translates to:
  /// **'How do Google Play subscriptions work?'**
  String get trustFaqQ18;

  /// No description provided for @trustFaqA18.
  ///
  /// In en, this message translates to:
  /// **'Premium is billed through Google Play. Subscriptions auto-renew unless you cancel at least 24 hours before the period ends. Manage or cancel in Google Play → Subscriptions. Refunds follow Google Play\'s refund policy. Deleting your Lune account does not automatically stop billing — cancel the subscription separately.'**
  String get trustFaqA18;

  /// No description provided for @trustFaqQ19.
  ///
  /// In en, this message translates to:
  /// **'What is the minimum age to use Lune?'**
  String get trustFaqQ19;

  /// No description provided for @trustFaqA19.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 13 years old. Users under 13 cannot continue after the age gate. Some community features are restricted to users 18 and older. Parents who believe a child under 13 used Lune should contact us to request deletion.'**
  String get trustFaqA19;

  /// No description provided for @trustFaqQ20.
  ///
  /// In en, this message translates to:
  /// **'Is Lune a medical device or medical advice?'**
  String get trustFaqQ20;

  /// No description provided for @trustFaqA20.
  ///
  /// In en, this message translates to:
  /// **'No. Lune is for informational wellness tracking only — not a medical device, diagnosis, or treatment. Cycle predictions, AI chat, community posts, and magazine articles are not medical advice. Always consult a qualified healthcare professional for medical decisions.'**
  String get trustFaqA20;

  /// No description provided for @trustFaqQ21.
  ///
  /// In en, this message translates to:
  /// **'What data does Lune collect (Google Play Data Safety)?'**
  String get trustFaqQ21;

  /// No description provided for @trustFaqA21.
  ///
  /// In en, this message translates to:
  /// **'Data you provide: cycle dates, symptoms, moods, wellness notes, and optional community posts. Account data if registered (email, name, sign-in method). Technical data: device tokens for notifications, anonymized crash reports, and approximate activity timestamps. Premium AI messages are sent to Google Gemini/DeepSeek for processing. Data is not sold. Core tracking stays on your device unless you enable Premium cloud backup.'**
  String get trustFaqA21;

  /// No description provided for @trustBodyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Body, Your Data'**
  String get trustBodyDataTitle;

  /// No description provided for @trustBodyDataIntro.
  ///
  /// In en, this message translates to:
  /// **'Your menstrual and wellness data is deeply personal. At Lune, you are in control — always. This page explains what you log, who owns it, and how optional features use it.'**
  String get trustBodyDataIntro;

  /// No description provided for @trustBodyDataS1Title.
  ///
  /// In en, this message translates to:
  /// **'Ownership'**
  String get trustBodyDataS1Title;

  /// No description provided for @trustBodyDataS1Body.
  ///
  /// In en, this message translates to:
  /// **'You own the cycle, symptom, mood, flow, water intake, and wellness data you log. Lune is a tool to help you understand your body — not a platform that monetizes your health information or sells insights about you.'**
  String get trustBodyDataS1Body;

  /// No description provided for @trustBodyDataS2Title.
  ///
  /// In en, this message translates to:
  /// **'Local-first design'**
  String get trustBodyDataS2Title;

  /// No description provided for @trustBodyDataS2Body.
  ///
  /// In en, this message translates to:
  /// **'The app works fully offline. Your daily logs are written to an encrypted database on your device first. Nothing leaves your phone unless you choose cloud backup, AI chat, community, or other features that require a network connection.'**
  String get trustBodyDataS2Body;

  /// No description provided for @trustBodyDataS3Title.
  ///
  /// In en, this message translates to:
  /// **'Explicit consent'**
  String get trustBodyDataS3Title;

  /// No description provided for @trustBodyDataS3Body.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup, AI features, community participation, and push notifications each require separate consent in Privacy Center. You can enable or disable them individually without losing your local cycle history.'**
  String get trustBodyDataS3Body;

  /// No description provided for @trustBodyDataS4Title.
  ///
  /// In en, this message translates to:
  /// **'No hidden sharing'**
  String get trustBodyDataS4Title;

  /// No description provided for @trustBodyDataS4Body.
  ///
  /// In en, this message translates to:
  /// **'We do not share your cycle data with employers, insurers, advertisers, or external social networks. Community posts and stories are visible only within Lune communities you choose to join.'**
  String get trustBodyDataS4Body;

  /// No description provided for @trustBodyDataS5Title.
  ///
  /// In en, this message translates to:
  /// **'What you can log'**
  String get trustBodyDataS5Title;

  /// No description provided for @trustBodyDataS5Body.
  ///
  /// In en, this message translates to:
  /// **'Lune lets you track periods, symptoms, moods, pain levels, water intake, and other wellness notes you choose to record. You decide how much detail to add each day. None of this is required beyond what you need for your own understanding.'**
  String get trustBodyDataS5Body;

  /// No description provided for @trustBodyDataS6Title.
  ///
  /// In en, this message translates to:
  /// **'How AI uses your cycle context'**
  String get trustBodyDataS6Title;

  /// No description provided for @trustBodyDataS6Body.
  ///
  /// In en, this message translates to:
  /// **'When you use Lune AI (Premium), relevant cycle context you approve may be sent to our servers and then to Google Gemini or DeepSeek to personalize responses. AI is optional — you can track your cycle without ever opening chat.'**
  String get trustBodyDataS6Body;

  /// No description provided for @trustBodyDataS7Title.
  ///
  /// In en, this message translates to:
  /// **'Magazine & education'**
  String get trustBodyDataS7Title;

  /// No description provided for @trustBodyDataS7Body.
  ///
  /// In en, this message translates to:
  /// **'Articles in the Lune magazine are general health education content. They are separate from your private logs and are not generated from your personal cycle data. Editors publish articles through our admin tools — not by reading your diary.'**
  String get trustBodyDataS7Body;

  /// No description provided for @trustBodyDataS8Title.
  ///
  /// In en, this message translates to:
  /// **'Portability'**
  String get trustBodyDataS8Title;

  /// No description provided for @trustBodyDataS8Body.
  ///
  /// In en, this message translates to:
  /// **'You can export an encrypted backup from Privacy Center at any time. Your data belongs to you — if you leave Lune, you can take a copy with you before deleting your account.'**
  String get trustBodyDataS8Body;

  /// No description provided for @trustDataEndsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Data Ends With You'**
  String get trustDataEndsTitle;

  /// No description provided for @trustDataEndsIntro.
  ///
  /// In en, this message translates to:
  /// **'When you decide to leave Lune, your data should leave too. This page walks through every step — server deletion, local files, subscriptions, and what cannot be undone.'**
  String get trustDataEndsIntro;

  /// No description provided for @trustDataEndsS1Title.
  ///
  /// In en, this message translates to:
  /// **'Delete anytime'**
  String get trustDataEndsS1Title;

  /// No description provided for @trustDataEndsS1Body.
  ///
  /// In en, this message translates to:
  /// **'You can delete your account from Privacy Center at any time. No phone calls, no dark patterns — just a clear confirmation step. Guest users can clear local data by uninstalling the app.'**
  String get trustDataEndsS1Body;

  /// No description provided for @trustDataEndsS2Title.
  ///
  /// In en, this message translates to:
  /// **'Immediate server deletion'**
  String get trustDataEndsS2Title;

  /// No description provided for @trustDataEndsS2Body.
  ///
  /// In en, this message translates to:
  /// **'When you confirm account deletion, our servers immediately remove your Firestore profile, cloud cycle backups, chat history, and community posts, then delete your Firebase Authentication account. This is not a 30-day waiting period — deletion starts right away.'**
  String get trustDataEndsS2Body;

  /// No description provided for @trustDataEndsS3Title.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get trustDataEndsS3Title;

  /// No description provided for @trustDataEndsS3Body.
  ///
  /// In en, this message translates to:
  /// **'Data on your device is not automatically erased when you delete your cloud account. Uninstall the app or use your phone\'s app settings to remove remaining local encrypted databases and preferences.'**
  String get trustDataEndsS3Body;

  /// No description provided for @trustDataEndsS4Title.
  ///
  /// In en, this message translates to:
  /// **'Backups you exported'**
  String get trustDataEndsS4Title;

  /// No description provided for @trustDataEndsS4Body.
  ///
  /// In en, this message translates to:
  /// **'If you exported a backup file to your clipboard or saved it elsewhere, that copy is outside our control. Delete those files if you no longer need them — we cannot reach into your notes app or cloud drive.'**
  String get trustDataEndsS4Body;

  /// No description provided for @trustDataEndsS5Title.
  ///
  /// In en, this message translates to:
  /// **'Permanent action'**
  String get trustDataEndsS5Title;

  /// No description provided for @trustDataEndsS5Body.
  ///
  /// In en, this message translates to:
  /// **'Account deletion cannot be undone. If you return to Lune later, you start fresh unless you restore from a local backup you saved before deleting.'**
  String get trustDataEndsS5Body;

  /// No description provided for @trustDataEndsS6Title.
  ///
  /// In en, this message translates to:
  /// **'Guest vs registered accounts'**
  String get trustDataEndsS6Title;

  /// No description provided for @trustDataEndsS6Body.
  ///
  /// In en, this message translates to:
  /// **'Guest accounts exist mainly on your device with a lightweight anonymous Firebase identity. Deleting a registered account triggers full server cleanup. Guests should uninstall the app to remove all local traces.'**
  String get trustDataEndsS6Body;

  /// No description provided for @trustDataEndsS7Title.
  ///
  /// In en, this message translates to:
  /// **'Premium subscriptions'**
  String get trustDataEndsS7Title;

  /// No description provided for @trustDataEndsS7Body.
  ///
  /// In en, this message translates to:
  /// **'Deleting your Lune account does not automatically cancel a Google Play subscription. Open Google Play → Subscriptions to cancel Premium billing separately so you are not charged after leaving.'**
  String get trustDataEndsS7Body;

  /// No description provided for @trustDataEndsS8Title.
  ///
  /// In en, this message translates to:
  /// **'Community content removal'**
  String get trustDataEndsS8Title;

  /// No description provided for @trustDataEndsS8Body.
  ///
  /// In en, this message translates to:
  /// **'When you delete your account, we remove your posts, comments, and stories from Lune communities through automated server cleanup. Remaining copies in other users\' caches disappear as they refresh or reinstall.'**
  String get trustDataEndsS8Body;

  /// No description provided for @trustA11yTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility at Lune'**
  String get trustA11yTitle;

  /// No description provided for @trustA11yIntro.
  ///
  /// In en, this message translates to:
  /// **'We believe everyone deserves access to cycle health tools — regardless of language, vision, or motor ability. Accessibility is an ongoing commitment, not a one-time feature.'**
  String get trustA11yIntro;

  /// No description provided for @trustA11yS1Title.
  ///
  /// In en, this message translates to:
  /// **'Our commitment'**
  String get trustA11yS1Title;

  /// No description provided for @trustA11yS1Body.
  ///
  /// In en, this message translates to:
  /// **'We design Lune to be usable with screen readers, system font scaling, and both left-to-right and right-to-left layouts. Arabic and English receive equal attention in navigation, labels, and reading direction.'**
  String get trustA11yS1Body;

  /// No description provided for @trustA11yS2Title.
  ///
  /// In en, this message translates to:
  /// **'In-app features'**
  String get trustA11yS2Title;

  /// No description provided for @trustA11yS2Body.
  ///
  /// In en, this message translates to:
  /// **'Lune respects your device\'s text size, bold text, and contrast settings where supported by Flutter and your operating system. Navigation uses standard Material patterns for predictable screen-reader behavior across tabs and forms.'**
  String get trustA11yS2Body;

  /// No description provided for @trustA11yS3Title.
  ///
  /// In en, this message translates to:
  /// **'Request accommodations'**
  String get trustA11yS3Title;

  /// No description provided for @trustA11yS3Body.
  ///
  /// In en, this message translates to:
  /// **'If you encounter a barrier while using Lune, email merrsoheb@gmail.com with a description of the issue, your device model, and your preferred language. We take accessibility feedback seriously and prioritize fixes that block core tracking.'**
  String get trustA11yS3Body;

  /// No description provided for @trustA11yS4Title.
  ///
  /// In en, this message translates to:
  /// **'Ongoing improvements'**
  String get trustA11yS4Title;

  /// No description provided for @trustA11yS4Body.
  ///
  /// In en, this message translates to:
  /// **'We review new features for color contrast, touch target size, and screen reader labels before release. Past releases have improved RTL layouts, larger tap areas, and clearer error messages — and more improvements are planned.'**
  String get trustA11yS4Body;

  /// No description provided for @trustA11yS5Title.
  ///
  /// In en, this message translates to:
  /// **'Arabic & English parity'**
  String get trustA11yS5Title;

  /// No description provided for @trustA11yS5Body.
  ///
  /// In en, this message translates to:
  /// **'Switching between Arabic and English flips the entire interface direction — menus, cards, and legal pages included. You should not need to fight the layout to read content in your language.'**
  String get trustA11yS5Body;

  /// No description provided for @trustA11yS6Title.
  ///
  /// In en, this message translates to:
  /// **'Themes & system settings'**
  String get trustA11yS6Title;

  /// No description provided for @trustA11yS6Body.
  ///
  /// In en, this message translates to:
  /// **'Lune follows your device theme where possible and uses readable typography across light backgrounds. If system high-contrast mode is enabled, OS-level settings may further improve readability.'**
  String get trustA11yS6Body;

  /// No description provided for @trustA11yS7Title.
  ///
  /// In en, this message translates to:
  /// **'Roadmap'**
  String get trustA11yS7Title;

  /// No description provided for @trustA11yS7Body.
  ///
  /// In en, this message translates to:
  /// **'We are working toward broader WCAG-aligned improvements — including richer screen reader descriptions for charts, keyboard navigation enhancements, and user-tested contrast audits. Tell us what matters most to you.'**
  String get trustA11yS7Body;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
