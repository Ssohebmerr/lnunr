// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lune';

  @override
  String get navHome => 'Home';

  @override
  String get navLog => 'Log';

  @override
  String get navInsights => 'Insights';

  @override
  String get navWellness => 'Wellness';

  @override
  String get navCommunity => 'Community';

  @override
  String get navAi => 'Lune AI';

  @override
  String get navAccount => 'Account';

  @override
  String get welcomeTitle => 'Your cycle has phases — like the moon';

  @override
  String get welcomeSubtitle =>
      'Track your cycle locally. Cloud & AI are optional and encrypted.';

  @override
  String get welcomeHubTitle => 'Welcome to Lune';

  @override
  String get welcomeHubSubtitle =>
      'Start privately with your name, or sign in with your email if you already have an account.';

  @override
  String get welcomeNewUser => 'New user — set up privately';

  @override
  String get welcomeHaveAccount => 'I already have an account';

  @override
  String get welcomeCreateEmailAccount => 'Create account with email';

  @override
  String get accountLinkEmail => 'Link email to account';

  @override
  String get accountEmailNotLinked => 'No email linked yet';

  @override
  String get getStarted => 'Get Started';

  @override
  String get cycleLength => 'Cycle length (days)';

  @override
  String get periodDuration => 'Period duration (days)';

  @override
  String get lastPeriodDate => 'Last period start date';

  @override
  String get continueBtn => 'Continue';

  @override
  String get loginTitle => 'Sign in for cloud features';

  @override
  String get loginSubtitle => 'Optional — your data stays on device by default';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle =>
      'Create your account with email or Google — your data stays on your device by default';

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordHint =>
      'Enter your email and we will send a reset link.';

  @override
  String get resetPassword => 'Send reset link';

  @override
  String get resetSent => 'Password reset email sent.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordMismatch => 'Passwords do not match.';

  @override
  String get registerFieldsRequired => 'Enter your email and password.';

  @override
  String get authPrivacyRequired =>
      'Please accept the Privacy Policy and Terms to continue.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorUserNotFound => 'No account found with this email.';

  @override
  String get authErrorEmailInUse => 'This email is already registered.';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters.';

  @override
  String get authErrorTooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get authErrorNetwork => 'Network error. Check your connection.';

  @override
  String get authErrorCancelled => 'Sign-in was cancelled.';

  @override
  String get authErrorGoogleConfig =>
      'Google Sign-In is not configured on this build. Reinstall the latest app version.';

  @override
  String get consentDataPurged => 'Cloud data for this feature was removed.';

  @override
  String get consentRevokeTitle => 'Turn off this feature?';

  @override
  String get consentRevokeBody =>
      'Your consent will be withdrawn and cloud data for this feature will be deleted from our servers. Local data on your device stays.';

  @override
  String get consentRevokeConfirm => 'Turn off & delete cloud data';

  @override
  String get communityBirthYearTooYoung =>
      'Community access is for adults 18+. Choose an earlier birth year.';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Create Account';

  @override
  String get signInGoogle => 'Continue with Google';

  @override
  String get signInApple => 'Continue with Apple';

  @override
  String get skipLogin => 'Continue without account';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get aiTitle => 'Lune AI';

  @override
  String get aiSubtitle =>
      'Lune means moon — ask about your phases, symptoms, or self-care. Not medical advice.';

  @override
  String get aiWelcome => 'Hi! I\'m Lune — your moon-phase wellness companion.';

  @override
  String get aiWelcomeHint =>
      'Short, helpful answers about your cycle, mood, and self-care.';

  @override
  String get aiSuggestion1 => 'What helps with period cramps?';

  @override
  String get aiSuggestion2 => 'What should I eat in my current phase?';

  @override
  String get aiSuggestion3 => 'How is my cycle looking?';

  @override
  String get aiAnalyze => 'Analyze my cycle';

  @override
  String get aiPlaceholder => 'Message Lune...';

  @override
  String get aiThinking => 'Lune is thinking...';

  @override
  String get premiumTitle => 'Lune Premium';

  @override
  String get premiumSubtitle => 'Unlock advanced AI analysis & cloud backup';

  @override
  String get premiumFeature1 => 'Unlimited Lune chat & cycle analysis';

  @override
  String get premiumFeature2 => 'Encrypted cloud backup';

  @override
  String get premiumFeature3 => 'Priority support';

  @override
  String get premiumPlayHint =>
      'Payment is handled securely by Google Play. Manage or cancel your subscription anytime in Play Store settings.';

  @override
  String get premiumPlayOnly =>
      'Subscriptions are available on Android via Google Play.';

  @override
  String get premiumProductUnavailable =>
      'Product unavailable. Set up the subscription in Play Console first.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get restorePurchasesDone => 'Your purchases were checked.';

  @override
  String get restorePurchasesChecking => 'Checking your purchases…';

  @override
  String postpartumRecoveryWeek(int week) {
    return 'Recovery · week $week';
  }

  @override
  String get postpartumTodayFocus => 'Today\'s focus';

  @override
  String get postpartumYourBody => 'Your body this stage';

  @override
  String get postpartumYourBaby => 'Your baby this stage';

  @override
  String get postpartumDailyRituals => 'Daily rituals';

  @override
  String get postpartumWellbeingTitle => 'How are you, really?';

  @override
  String get postpartumWellbeingBody =>
      'Mood swings in the early weeks are common. But if sadness, anxiety, or emptiness lasts more than two weeks, please reach out to your doctor — postpartum depression is real and treatable.';

  @override
  String get postpartumSetDateTitle => 'When was your baby born?';

  @override
  String get postpartumSetDatePrompt =>
      'Set your baby\'s birth date so we can guide your recovery week by week.';

  @override
  String get postpartumSetDateCta => 'Set birth date';

  @override
  String get postpartumBirthDateLabel => 'Baby\'s birth date';

  @override
  String get conditionWhatToTrack => 'What to track';

  @override
  String get conditionUnderstanding => 'Understanding your body';

  @override
  String get conditionDailyRituals => 'Daily rituals';

  @override
  String get conditionWhenToSeeDoctor => 'When to see a doctor';

  @override
  String get goalMenopauseTitle => 'Menopause journey';

  @override
  String get goalPcosTitle => 'PCOS management';

  @override
  String get conditionHowAreYouToday => 'How are you today?';

  @override
  String get conditionTapToLog => 'Tap what you feel — it\'s saved for today.';

  @override
  String conditionLoggedNamed(String name) {
    return 'Logged: $name';
  }

  @override
  String conditionRemovedNamed(String name) {
    return 'Removed: $name';
  }

  @override
  String conditionRitualsDoneToday(int done, int total) {
    return '$done of $total done today';
  }

  @override
  String get conditionTrendsTitle => 'Your trends';

  @override
  String get conditionTrendsEmpty =>
      'Nothing logged yet — track your symptoms and rituals from the Home screen and your trends will appear here.';

  @override
  String get conditionTrendLast14Days => 'Last 14 days';

  @override
  String get conditionTrendLast30Days => 'Last 30 days';

  @override
  String get conditionTrendLast7Days => 'Last 7 days';

  @override
  String get conditionTrendToday => 'Today';

  @override
  String get conditionTrendHotFlashes => 'Hot flashes';

  @override
  String get conditionTrendMood => 'Mood check-ins';

  @override
  String get conditionTrendSymptomsPerDay => 'Symptoms per day';

  @override
  String get conditionTopSymptoms => 'Most frequent symptoms';

  @override
  String get conditionDaysLogged => 'Days logged';

  @override
  String get conditionRitualCompletion => 'Rituals done';

  @override
  String get conditionDoctorReportCta => 'Doctor report (PDF)';

  @override
  String get conditionReportTitle => 'Doctor summary report';

  @override
  String get conditionReportOverview => 'Overview';

  @override
  String get conditionReportGoalLabel => 'Health focus';

  @override
  String get conditionReportConsistency => 'Tracking consistency';

  @override
  String get conditionReportNoLogs =>
      'No daily logs in the last 30 days — track symptoms from the Home screen to enrich this report.';

  @override
  String conditionReportTimes(int count) {
    return '$count×';
  }

  @override
  String conditionStreakDays(int days) {
    return '$days-day logging streak';
  }

  @override
  String get menopauseHotFlashesToday => 'Hot flashes today';

  @override
  String get menopauseHotFlashHint => 'Tap − / + each time one hits';

  @override
  String get menopauseDaysSincePeriodTitle => 'Since your last period';

  @override
  String conditionDaysCount(int days) {
    return '$days days';
  }

  @override
  String get menopauseMilestoneHint => '12 period-free months marks menopause.';

  @override
  String get menopauseMilestoneReached =>
      '12 months period-free — you\'ve reached menopause. 🌿';

  @override
  String get menopauseNeedPeriodData =>
      'Log a period to start counting the gap.';

  @override
  String get pcosCycleGapTitle => 'Cycle gap';

  @override
  String pcosTypicalCycle(int days) {
    return 'Your typical cycle is about $days days.';
  }

  @override
  String get pcosGapNormal => 'You\'re within your usual range.';

  @override
  String get pcosGapLong =>
      'Longer than usual — common with PCOS. Keep logging every period.';

  @override
  String get pcosGapUnknown =>
      'Log a couple of cycles so we can compare your gaps.';

  @override
  String get postpartumMoodTitle => 'How are you feeling today?';

  @override
  String get postpartumMoodSaved => 'Thanks for checking in 🤍';

  @override
  String get postpartumMoodLowSupport =>
      'It\'s okay to not be okay. If this feeling lingers, please reach out to someone you trust or your doctor.';

  @override
  String get postpartumJourneyTitle => 'Recovery journey';

  @override
  String postpartumJourneyCaption(int percent) {
    return 'About $percent% through your first year.';
  }

  @override
  String get moodVeryLow => 'Very low';

  @override
  String get moodLow => 'Low';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodGood => 'Good';

  @override
  String get moodGreat => 'Great';

  @override
  String get activatePremiumTest => 'Activate Premium (test)';

  @override
  String get planYearlyTitle => 'Yearly';

  @override
  String get planMonthlyTitle => 'Monthly';

  @override
  String get planPerYear => 'per year';

  @override
  String get planPerMonth => 'per month';

  @override
  String get planBestValue => 'Best value';

  @override
  String get planUnavailable => 'Unavailable right now';

  @override
  String planMonthlyEquivalent(String price) {
    return 'Equivalent to $price / month';
  }

  @override
  String planSaveBadge(int percent) {
    return 'Save $percent%';
  }

  @override
  String get communityMediaDisabled =>
      'Photo and video uploads are temporarily disabled for community safety.';

  @override
  String get privacyTitle => 'Your privacy matters';

  @override
  String get privacyBody =>
      'Cycle data is encrypted on your device. Cloud sync and AI only run when you sign in and opt in.';

  @override
  String get signOut => 'Sign Out';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get notPremium => 'Free plan';

  @override
  String get phaseToday => 'Today\'s phase';

  @override
  String get nextPeriod => 'Next period';

  @override
  String get send => 'Send';

  @override
  String get loading => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get loginRequiredAi => 'Sign in to chat with Lune AI';

  @override
  String get authOrEmail => 'or continue with email';

  @override
  String get authOr => 'or';

  @override
  String get adminPromoTitle => 'Promo codes';

  @override
  String get adminPromoManageBtn => 'Manage promo codes';

  @override
  String get adminPromoCreateHeader => 'Create a code';

  @override
  String get adminPromoCodeHint => 'Code (e.g. LUNE30)';

  @override
  String get adminPromoDaysLabel => 'Premium days';

  @override
  String get adminPromoMaxUsesLabel => 'Max uses';

  @override
  String get adminPromoNoteHint => 'Note (optional)';

  @override
  String get adminPromoCreateBtn => 'Create code';

  @override
  String get adminPromoCreatedMsg => 'Code created';

  @override
  String get adminPromoExistingHeader => 'Existing codes';

  @override
  String get adminPromoEmpty => 'No codes yet';

  @override
  String get adminPromoRevokeBtn => 'Revoke';

  @override
  String get adminPromoRevokedMsg => 'Code revoked';

  @override
  String get adminPromoActiveLabel => 'Active';

  @override
  String get adminPromoRevokedLabel => 'Inactive';

  @override
  String get adminPromoUsedLabel => 'used';

  @override
  String get adminPromoCodeTooShort => 'Code must be at least 3 characters';

  @override
  String get premiumDaysShort => 'days';

  @override
  String get adminRolesTitle => 'Admins and moderators';

  @override
  String get adminRolesManageBtn => 'Manage admins';

  @override
  String get adminRolesAddHeader => 'Add an admin';

  @override
  String get adminRolesEmailHint => 'User email';

  @override
  String get adminRolesRoleModerator => 'Moderator';

  @override
  String get adminRolesRoleAdmin => 'Admin';

  @override
  String get adminRolesRoleOwner => 'Owner';

  @override
  String get adminRolesGrant => 'Grant role';

  @override
  String get adminRolesGranted => 'Role updated';

  @override
  String get adminRolesCurrentHeader => 'Current admins';

  @override
  String get adminRolesEmpty => 'No admins yet';

  @override
  String get adminRolesRemove => 'Remove';

  @override
  String get adminRolesRemoved => 'Admin removed';

  @override
  String get adminRolesOwnerOnly => 'Only the owner can add or remove admins.';

  @override
  String get adminRolesUserNotFound => 'No user found with that email';

  @override
  String get loginRequiredPremium => 'Sign in to subscribe';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsEnable => 'Enable reminders';

  @override
  String get periodReminder => 'Period reminder';

  @override
  String get dailyLogReminder => 'Daily log reminder';

  @override
  String get cloudSync => 'Cloud backup';

  @override
  String get cloudSyncEnable => 'Enable encrypted cloud backup';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncSuccess => 'Backup synced successfully.';

  @override
  String get syncFailed => 'Sync failed. Try again.';

  @override
  String get syncNeedsPremium => 'Cloud backup is a Premium feature.';

  @override
  String get syncNeedsConsent => 'Please enable cloud backup consent first.';

  @override
  String get syncNotSignedIn => 'Sign in to use cloud backup.';

  @override
  String get syncCycleUnavailable =>
      'Cycle data is not ready yet. Open the home screen, then try again.';

  @override
  String get syncNoBackupFound => 'No cloud backup was found yet.';

  @override
  String get localBackupExportSuccess => 'Local backup is ready to share.';

  @override
  String get localBackupExportFailed => 'Could not export the local backup.';

  @override
  String get localBackupImportFailed => 'Could not import this backup file.';

  @override
  String get logSaved => 'Log saved!';

  @override
  String get logSavedHint =>
      'Stored on your device. See it on Home, in Reports, and in Insights.';

  @override
  String get logChangesDiscarded => 'Changes discarded';

  @override
  String get logChangesDiscardedHint =>
      'Reloaded the last saved data for this day — nothing new was saved.';

  @override
  String get logSaveFailedHint => 'Please try again.';

  @override
  String get homeTodayLogTitle => 'Today\'s log';

  @override
  String get homeTodayLogEmpty =>
      'Nothing logged yet today. Tap + to log mood and symptoms.';

  @override
  String get homeTodayLogSymptoms => 'Mood & symptoms';

  @override
  String homeTodayLogWater(int count) {
    return '$count cups of water';
  }

  @override
  String get homeTodayLogStoredHint =>
      'Saved on your device — full charts in Reports → Insights';

  @override
  String get homeAiChipLabel => 'Lune AI';

  @override
  String get homeAiCardTitle => 'Lune AI';

  @override
  String get homeAiCardTap => 'Tap to start chatting';

  @override
  String get homeAiCardSubtitlePremium =>
      'Your smart assistant — up to 30 messages daily';

  @override
  String get homeAiCardSubtitlePremiumOnly =>
      'Premium only — tap to view plans';

  @override
  String get onboardingBirthDateLabel => 'Date of birth';

  @override
  String get onboardingBirthDateHint => 'Select your date of birth';

  @override
  String get onboardingBirthDateRequired => 'Please select your date of birth';

  @override
  String get subscriptionPlansTitle => 'Lune Premium';

  @override
  String get subscriptionPlansHeadline =>
      'More insight. More privacy. More support.';

  @override
  String get subscriptionPlansSubtitle =>
      'Unlock unlimited chat, cycle analysis, encrypted cloud backup, and priority support.';

  @override
  String get subscriptionPlansCta => 'Subscribe with Google Play';

  @override
  String get subscriptionPlansAccountHint => 'Manage subscription in Account';

  @override
  String get subscriptionChoosePlanTitle => 'Choose the plan that suits you';

  @override
  String get subscriptionChoosePlanSubtitle =>
      'All plans unlock the same Premium features. Cancel anytime through Google Play.';

  @override
  String subscriptionSelectedCta(String plan) {
    return 'Continue with $plan';
  }

  @override
  String get subscriptionLoadingPrice => 'Loading price…';

  @override
  String get subscriptionSecurePayment =>
      'Secure payment through Google Play • Cancel anytime';

  @override
  String get logTabTitle => 'Daily log';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get weeklyCalendar => 'Weekly view';

  @override
  String get graphsWeight => 'Weight';

  @override
  String get graphsSleep => 'Sleep';

  @override
  String get graphsWater => 'Water';

  @override
  String get graphsTemperature => 'Body temperature';

  @override
  String get graphsMeditation => 'Meditation';

  @override
  String get haveAccount => 'Already have an account? Sign in';

  @override
  String get noAccount => 'Don\'t have an account? Sign up';

  @override
  String get geminiKeyLabel => 'Gemini API Key (optional local fallback)';

  @override
  String get communityTitle => 'Small Communities';

  @override
  String get communityLoginRequired => 'Sign in to manage blocking and reports';

  @override
  String get communityPrivacyNote =>
      'Your cycle logs never leave your device. Communities use a nickname only.';

  @override
  String get communityYourAlias => 'Your community nickname';

  @override
  String get communityBrowse => 'Browse groups';

  @override
  String get communityRecommendedTitle => 'Recommended for you';

  @override
  String get communityJoinedBadge => 'Joined';

  @override
  String get communityDiscoverNew => 'Discover groups';

  @override
  String get communityDiscoverJoined => 'Your groups';

  @override
  String get communityDiscoverNoResults =>
      'No groups match your search. Try another category or clear filters.';

  @override
  String get communityClosedBadge => 'Closed';

  @override
  String get communityFeedBrowseTitle => 'Browse all groups';

  @override
  String get communityFeedBrowseSubtitle =>
      'The feed shows your joined groups only — explore more communities here.';

  @override
  String get communitySetupTitle => 'Choose a nickname';

  @override
  String get communitySetupSubtitle =>
      'Use a nickname — not your real name. Cycle data is never shared.';

  @override
  String get communityAliasLabel => 'Nickname';

  @override
  String get communityAliasHint => 'e.g. Luna_92';

  @override
  String get communityJoin => 'Join group';

  @override
  String get communityLeave => 'Leave group';

  @override
  String get communityJoined => 'You joined the group';

  @override
  String get communityLeft => 'You left the group';

  @override
  String get communityNewPost => 'New post';

  @override
  String get communityPostHint => 'Share support, ask a question...';

  @override
  String get communityPublish => 'Publish';

  @override
  String get communityPostPublished => 'Post published';

  @override
  String get communityModerationFailed => 'Post not approved';

  @override
  String get communityDisclaimer =>
      'Peer support only — not medical advice. Posts are reviewed by AI.';

  @override
  String get communityNoPosts => 'No posts yet. Be the first to share!';

  @override
  String get communityPostDetail => 'Post';

  @override
  String get communityComments => 'Comments';

  @override
  String get communityNoComments => 'No comments yet';

  @override
  String get communityCommentHint => 'Write a supportive comment...';

  @override
  String get cancel => 'Cancel';

  @override
  String get navAnalysis => 'Analysis';

  @override
  String get accountMenuAi => 'Lune chat';

  @override
  String get accountMenuCalendar => 'Period & calendar';

  @override
  String get accountMenuInsights => 'Cycle insights';

  @override
  String get accountMenuEducation => 'Learn & guides';

  @override
  String get accountMenuCommunity => 'Community';

  @override
  String get accountMenuReminders => 'Reminders';

  @override
  String get accountMenuSettings => 'Settings';

  @override
  String get accountStatCycles => 'Cycles';

  @override
  String get accountStatAvgCycle => 'Avg cycle';

  @override
  String get accountStatAvgPeriod => 'Avg period';

  @override
  String get accountQuickActions => 'Quick access';

  @override
  String get accountMenuHelp => 'Help & instructions';

  @override
  String get homeExplore => 'Explore';

  @override
  String get homeUpdatesTitle => 'Updates & news';

  @override
  String get homeUpdatesSubtitle => 'Announcements and offers';

  @override
  String get homeMoreThisWeek => 'More this week';

  @override
  String get homeGoalMoreTitle => 'More for your goal';

  @override
  String get homeGoalMoreGeneral => 'Stats, dates, tips & education';

  @override
  String get homeGoalMoreConceive => 'Fertility stats, tips & guides';

  @override
  String get homeGoalMoreAvoid => 'Protection stats, tips & guides';

  @override
  String get homeQuickLog => 'Log';

  @override
  String get homeQuickAi => 'AI chat';

  @override
  String get homeQuickCalendar => 'Calendar';

  @override
  String get reportsChecklistHint => 'Your personalized action list';

  @override
  String get insightsHubTitle => 'Insights & reports';

  @override
  String get insightsHubSubtitle =>
      'Your cycle at a glance, the charts behind it, and a doctor-ready record.';

  @override
  String get insightsHubTabOverview => 'Overview';

  @override
  String get insightsHubTabCharts => 'Charts';

  @override
  String get insightsHubTabHistory => 'History';

  @override
  String get insightsHubChartsTitle => 'Detailed charts';

  @override
  String get insightsHubChartsSubtitle => 'Trends from everything you log.';

  @override
  String get insightsHubSymptomPatternsCta =>
      'See when your symptoms tend to appear in your cycle';

  @override
  String get reportsPregnancyOverview => 'Pregnancy overview';

  @override
  String get reportsMenopauseOverview => 'Menopause overview';

  @override
  String get reportsPcosOverview => 'PCOS overview';

  @override
  String get reportsRecoveryOverview => 'Recovery overview';

  @override
  String get goalModeGeneralReportStats => 'Cycle overview';

  @override
  String get goalModeConceiveReportStats => 'Fertility overview';

  @override
  String get goalModeAvoidReportStats => 'Protection overview';

  @override
  String get selfCareMoreTitle => 'More self-care';

  @override
  String get selfCareMoreSubtitle =>
      'AI tips, challenges, rituals & wellness hub';

  @override
  String get accountSectionTools => 'Tools & features';

  @override
  String get accountSectionPersonal => 'Personal';

  @override
  String get accountSectionSupport => 'Support & settings';

  @override
  String get retry => 'Retry';

  @override
  String get wellnessHubTitle => 'Wellness Hub';

  @override
  String get wellnessHubSubtitle =>
      'Birth control, symptoms, and daily care — all in one place.';

  @override
  String get wellnessCustomize => 'Customize goals';

  @override
  String get wellnessSetupFailed =>
      'Could not load wellness features. Please try again.';

  @override
  String get wellnessDailyLog => 'Symptom journal';

  @override
  String get wellnessDailyLogDesc => 'Log mood, pain, and daily symptoms';

  @override
  String get wellnessPills => 'Birth control pills';

  @override
  String get wellnessPillsDesc => 'Track your pill pack and reminders';

  @override
  String get wellnessSanitary => 'Sanitary products';

  @override
  String get wellnessSanitaryDesc => 'Products, timers, and period care';

  @override
  String get wellnessSex => 'Sex activity';

  @override
  String get wellnessSexDesc => 'Private activity log and insights';

  @override
  String get wellnessLarc => 'LARC / IUD';

  @override
  String get wellnessLarcDesc => 'Long-acting reversible contraceptives';

  @override
  String get navSelfCare => 'Self-care';

  @override
  String get selfCareTitle => 'Self-care space';

  @override
  String get selfCareSubtitle =>
      'Breathe, reflect, and care for yourself through every phase.';

  @override
  String get selfCareTodayTip => 'Today\'s tip';

  @override
  String get selfCareActivities => 'Activities';

  @override
  String get selfCareBreathe => 'Breathing';

  @override
  String get selfCareBreatheDesc => 'Box breathing — 4 seconds each phase';

  @override
  String get selfCareStart => 'Start';

  @override
  String get selfCarePause => 'Pause';

  @override
  String get selfCareAffirmations => 'Affirmations';

  @override
  String get selfCareJournal => 'Journal';

  @override
  String get selfCareJournalPrompt => 'Prompt';

  @override
  String get selfCareJournalHint => 'Write freely — stored only on your device';

  @override
  String get selfCareJournalSave => 'Save entry';

  @override
  String get selfCareJournalSaved => 'Journal saved';

  @override
  String get selfCareStretch => 'Gentle stretch';

  @override
  String get selfCareStretchTip =>
      'Try 5 minutes of neck and hip stretches today.';

  @override
  String get selfCareRituals => 'Daily rituals';

  @override
  String get selfCareRitualWater => 'Drank enough water';

  @override
  String get selfCareRitualRest => 'Took time to rest';

  @override
  String get selfCareRitualStretch => 'Gentle movement';

  @override
  String get selfCareRitualMindful => '5 min mindfulness';

  @override
  String get selfCareHealthTools => 'Health tracking';

  @override
  String get selfCareHealthToolsDesc => 'Pills, sanitary, sex & more';

  @override
  String get selfCareWhisperTitle => 'Whisper of the day';

  @override
  String get selfCareWhisperLocked =>
      'Unlock Lune\'s personal whisper with Premium.';

  @override
  String get selfCareWhisperPrompt =>
      'Give me a gentle self-care whisper for today based on my cycle phase and mood.';

  @override
  String get moodCheckInTitle => 'How are you feeling today?';

  @override
  String get moodCheckInDone => 'Today\'s mood is logged 🌸';

  @override
  String get moodTrendTitle => 'This week';

  @override
  String get selfCareAffirmationGenerate => 'Personal affirmation from Lune';

  @override
  String get selfCareAffirmationPrompt =>
      'Write one short, uplifting first-person affirmation for me based on my cycle phase and mood.';

  @override
  String get selfCareMovement => 'Gentle movement';

  @override
  String selfCareMovementStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get selfCareMovementDone => 'Beautifully done 🌸';

  @override
  String get selfCareMovementDoneCue =>
      'Take a moment to notice how your body feels.';

  @override
  String get selfCareRestart => 'Restart';

  @override
  String get selfCareSkip => 'Skip';

  @override
  String selfCareBreatheCycles(int count) {
    return '$count cycles completed';
  }

  @override
  String get selfCareCopied => 'Copied to clipboard';

  @override
  String get selfCareLibraryTitle => 'Cycle self-care guide';

  @override
  String get selfCareLibrarySubtitle =>
      'Nutrition, movement, rest & mind for every phase.';

  @override
  String get selfCareLibraryCurrent => 'You\'re here';

  @override
  String get selfCareJournalHistory => 'Past entries';

  @override
  String get selfCareJournalEmpty =>
      'No entries yet. Write your first reflection above.';

  @override
  String get selfCareJournalDelete => 'Delete';

  @override
  String get selfCareJournalReflect => 'Reflect with Lune';

  @override
  String get selfCareJournalReflecting => 'Lune is reflecting on your words…';

  @override
  String selfCareRitualStreak(int days) {
    return '${days}d';
  }

  @override
  String selfCareRitualsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get aiUnavailable =>
      'Lune is unavailable right now. Please try again later.';

  @override
  String get communityTabFeed => 'Feed';

  @override
  String get communityTabDiscover => 'Discover';

  @override
  String get communityTabMine => 'My groups';

  @override
  String get communityFeedEmpty =>
      'Join a group to see posts from your communities here.';

  @override
  String get communityMineEmpty => 'You haven\'t joined any groups yet.';

  @override
  String get communitySearchHint => 'Search communities...';

  @override
  String get communityCatAll => 'All';

  @override
  String get communityCatGeneral => 'General';

  @override
  String get communityCatConception => 'Fertility';

  @override
  String get communityCatContraception => 'Birth control';

  @override
  String get communityCatCondition => 'Conditions';

  @override
  String get communityCatSupport => 'Support';

  @override
  String get communityPostsTab => 'Posts';

  @override
  String get communityAboutTab => 'About';

  @override
  String get communityRules => 'Community rules';

  @override
  String get communityPostType => 'Post type';

  @override
  String get communityReported => 'Report submitted. Thank you.';

  @override
  String get communityAliasTooShort => 'Nickname must be at least 2 characters';

  @override
  String get communityAliasInvalid => 'Use a nickname without spaces or email';

  @override
  String get communityBirthYearLabel => 'Birth year';

  @override
  String get communityBirthYearRequired => 'Please select your birth year';

  @override
  String get communityBirthYearWhy =>
      'Used only to keep the community safe for younger members. It is never shown to anyone.';

  @override
  String get communityMinorBanner =>
      'You can read posts, but joining, posting, and commenting unlock at 18 — this keeps you safe.';

  @override
  String get communityMinorRestricted =>
      'Joining and posting are available from age 18.';

  @override
  String get communityBannedMessage =>
      'Your account is banned from the community. Contact support if this is a mistake.';

  @override
  String get communityFull => 'This community is full. Try another group.';

  @override
  String get communityPostNotFound => 'This post is no longer available.';

  @override
  String get communityBlockUser => 'Block author';

  @override
  String get communityBlocked =>
      'Author blocked. You won\'t see their posts anymore.';

  @override
  String get communityReportPost => 'Report post';

  @override
  String get communityReportComment => 'Report comment';

  @override
  String get communityReportTitle => 'Why are you reporting?';

  @override
  String get communityReportReasonHarassment => 'Harassment or bullying';

  @override
  String get communityReportReasonHate => 'Hate speech';

  @override
  String get communityReportReasonSpam => 'Spam or ads';

  @override
  String get communityReportReasonInappropriate => 'Inappropriate content';

  @override
  String get communityReportReasonMisinformation => 'Misinformation';

  @override
  String get communityReportReasonSelfHarm => 'Self-harm or danger';

  @override
  String get communityReportReasonOther => 'Other';

  @override
  String get communityBlockConfirmTitle => 'Block this author?';

  @override
  String communityBlockConfirmMessage(String alias) {
    return 'You won\'t see posts or comments from $alias anymore.';
  }

  @override
  String get communityBlockConfirmAction => 'Block';

  @override
  String get communityBlockCancel => 'Cancel';

  @override
  String get communityBlockedUsersTitle => 'Blocked users';

  @override
  String get communityBlockedUsersSubtitle =>
      'Manage who you blocked in communities';

  @override
  String get communityBlockedUsersEmpty => 'No blocked users.';

  @override
  String get communityBlockedUserUnknown => 'Unknown user';

  @override
  String get communityUnblockUser => 'Unblock';

  @override
  String get communityUnblocked => 'User unblocked.';

  @override
  String get accountBlockedUsers => 'Community blocked users';

  @override
  String get aiInsightDailyTitle => 'Today\'s tip for you';

  @override
  String get aiInsightMoodTitle => 'Your emotional weather';

  @override
  String get aiInsightCycleTitle => 'Your cycle health';

  @override
  String get aiInsightWeeklyTitle => 'Your week in review';

  @override
  String get aiInsightBadge => 'Aura AI';

  @override
  String get aiInsightRefresh => 'New insight';

  @override
  String get aiInsightDisclaimer =>
      'AI-generated wellness suggestion — not medical advice.';

  @override
  String get doctorReportTitle => 'Monthly Cycle Report';

  @override
  String get doctorReportButton => 'View full report';

  @override
  String get doctorReportGenerating => 'Preparing your report...';

  @override
  String get doctorReportFailed =>
      'Cycle data isn\'t ready yet. Open the home screen, then try again.';

  @override
  String get doctorReportRetry => 'Try again';

  @override
  String get doctorReportLimitedData =>
      'This report is based on limited data. Logging several completed cycle starts enables personal accuracy measurement and a better prediction window.';

  @override
  String get doctorReportAiTitle => 'AI assistant notes';

  @override
  String get doctorReportAiSubtitle =>
      'Helpful context for your doctor visit — not a diagnosis.';

  @override
  String get doctorReportAiLoading => 'AI is reviewing your data…';

  @override
  String get doctorReportAiFailed =>
      'AI notes could not be generated right now. Your cycle data above is still complete.';

  @override
  String get doctorReportAiNeedsConsent =>
      'Enable AI in Privacy settings to get assistant notes for your report.';

  @override
  String get doctorReportAiEnable => 'Enable AI assistant';

  @override
  String get doctorReportCopy => 'Copy';

  @override
  String get doctorReportCopied => 'Report copied';

  @override
  String get doctorReportShare => 'Share';

  @override
  String get doctorReportDownload => 'Download';

  @override
  String get doctorReportExportTitle => 'Export report';

  @override
  String get doctorReportExportSubtitle =>
      'Choose a file format to save or share';

  @override
  String get doctorReportExportPdf => 'PDF document';

  @override
  String get doctorReportExportPdfHint =>
      'Best for printing or sending to your doctor';

  @override
  String get doctorReportExportTxt => 'Text file (.txt)';

  @override
  String get doctorReportExportTxtHint => 'Plain text — works everywhere';

  @override
  String get doctorReportExportCsv => 'Spreadsheet (.csv)';

  @override
  String get doctorReportExportCsvHint => 'Open in Excel or Google Sheets';

  @override
  String get doctorReportExportJson => 'JSON data (.json)';

  @override
  String get doctorReportExportJsonHint =>
      'Structured data for apps and backups';

  @override
  String get doctorReportExporting => 'Preparing file...';

  @override
  String get doctorReportExportShared => 'File ready — pick where to save it';

  @override
  String get doctorReportExportFailed => 'Export failed. Please try again.';

  @override
  String get doctorReportDisclaimer =>
      'Personal tracking summary from the app — not a medical diagnosis. Always consult your healthcare provider.';

  @override
  String get healthReportTitle => 'Health Report';

  @override
  String get healthReportClinicalSummary => 'Clinical summary';

  @override
  String get healthReportObservedPatterns => 'Observed patterns';

  @override
  String get healthReportDiscussionPoints => 'Points for discussion';

  @override
  String get doctorReportRefining => 'Finalizing clinical summary…';

  @override
  String get healthReportCreatedBy => 'Created by Lune';

  @override
  String healthReportExportedOn(String date) {
    return 'Exported on: $date';
  }

  @override
  String get healthReportCyclePeriodLength => 'Cycle and Period Length';

  @override
  String get healthReportPredictions => 'Predictions';

  @override
  String get healthReportCycleHistorySummary => 'Cycle History Summary';

  @override
  String get healthReportSymptomPatternsSummary => 'Symptom Patterns Summary';

  @override
  String get healthReportPrevCycleLength => 'Previous cycle length';

  @override
  String get healthReportPrevPeriodDuration => 'Previous period duration';

  @override
  String get healthReportCycleRegularityScore => 'Cycle regularity score';

  @override
  String get healthReportPeriodRegularityScore => 'Period regularity score';

  @override
  String get healthReportNextPeriodDay => 'Next period day';

  @override
  String get healthReportNextOvulationDay => 'Next ovulation day';

  @override
  String healthReportDaysCycle(int count) {
    return '$count days cycle';
  }

  @override
  String get healthReportUntilNow => 'Now';

  @override
  String get healthReportFooter => '© Lune';

  @override
  String get healthReportPatientSection => 'Patient';

  @override
  String get healthReportMode => 'Tracking mode';

  @override
  String get healthReportModeCycle => 'Cycle tracking';

  @override
  String get healthReportModePregnancy => 'Pregnancy tracking';

  @override
  String get healthReportReportId => 'Report ID';

  @override
  String get healthReportMenstrualHistory => 'Menstrual history';

  @override
  String get healthReportLastPeriod => 'Last period (LMP)';

  @override
  String get healthReportDataPeriod => 'Data period';

  @override
  String get healthReportCyclesAnalyzed => 'Cycles analyzed';

  @override
  String get healthReportCycleLengthRange => 'Cycle length range';

  @override
  String get healthReportCycleVariability => 'Cycle variability';

  @override
  String get healthReportPeriodLengthRange => 'Period length range';

  @override
  String get healthReportPatternsToDiscuss => 'Patterns worth discussing';

  @override
  String get healthReportSymptomBurden => 'Symptom & pain summary';

  @override
  String get healthReportAveragePain => 'Average pain (last 30 days)';

  @override
  String get healthReportWellnessEntries => 'Wellness log entries';

  @override
  String get healthReportRedFlags => 'Worth mentioning to your doctor';

  @override
  String get healthReportVitalsAdherence => 'Vitals & adherence';

  @override
  String get healthReportLatestWeight => 'Latest weight';

  @override
  String get healthReportLatestTemperature => 'Latest temperature';

  @override
  String get healthReportAvgWater => 'Average water (30 days)';

  @override
  String get healthReportPillAdherence => 'Pill adherence (last 7 days)';

  @override
  String clinicalFlagShortCycle(int days) {
    return 'Average cycle $days days — shorter than the 24–38 day reference range; worth discussing with your doctor.';
  }

  @override
  String clinicalFlagLongCycle(int days) {
    return 'Average cycle $days days — longer than the 24–38 day reference range; worth discussing with your doctor.';
  }

  @override
  String clinicalFlagIrregularCycle(int days) {
    return 'Cycle length varies by about $days days between cycles — worth discussing regularity with your doctor.';
  }

  @override
  String clinicalFlagProlongedPeriod(int days) {
    return 'Average period $days days — longer than the 8-day reference duration; worth discussing with your doctor.';
  }

  @override
  String get clinicalFlagHighPain =>
      'Average logged pain is in the severe range — worth discussing pain management with your doctor.';

  @override
  String get doctorReportPatientTitle => 'Patient details';

  @override
  String get doctorReportPatientSubtitle =>
      'Optional — shown at the top of the report for your doctor. Stored on your device only.';

  @override
  String get doctorReportPatientName => 'Name';

  @override
  String get doctorReportPatientAge => 'Age';

  @override
  String get doctorReportPatientNote => 'Note for the doctor';

  @override
  String get doctorReportPatientNoteHint =>
      'e.g. reason for visit, medications, concerns';

  @override
  String get doctorReportPatientSave => 'Save';

  @override
  String get doctorReportEditPatient => 'Edit patient details';

  @override
  String get communityAdultsOnlyTitle => 'Communities are for adults';

  @override
  String get communityAdultsOnly =>
      'Community features are available from age 18. You can still use all other app features.';

  @override
  String get communityGuidelinesTitle => 'Community guidelines';

  @override
  String get communityGuidelinesIntro =>
      'Before joining, please read and accept our community rules:';

  @override
  String get communityGuidelinesAgree =>
      'I agree to follow the community guidelines';

  @override
  String get communityGuidelinesAccept => 'Join community';

  @override
  String get challengesTitle => 'My challenges';

  @override
  String get challengesToday => 'Today\'s challenges';

  @override
  String get challengesAllDone => 'Amazing! You completed everything today.';

  @override
  String get challengeDone => 'Challenge completed';

  @override
  String get challengeStreakLabel => 'Day streak';

  @override
  String get challengePointsLabel => 'Points';

  @override
  String challengeStreakValue(int count) {
    return '$count days';
  }

  @override
  String get challengeHydrate => 'Drink 6-8 glasses of water';

  @override
  String get challengeStretch => 'Gentle stretch for 5 minutes';

  @override
  String get challengeWalk => 'Take a 10-minute walk';

  @override
  String get challengeMindful => 'One mindful breathing break';

  @override
  String get challengeLogToday => 'Log your symptoms and mood';

  @override
  String get challengeSleepEarly => 'Wind down before 11 PM';

  @override
  String get badgesTitle => 'Achievements';

  @override
  String get badgeEarned => 'New achievement';

  @override
  String get badgeFirstStep => 'First step';

  @override
  String get badgeStreak3 => '3-day streak';

  @override
  String get badgeStreak7 => 'Week of care';

  @override
  String get badgeStreak30 => '30-day champion';

  @override
  String get badgePoints100 => '100 points';

  @override
  String get badgePoints500 => '500 points';

  @override
  String get badgeAllInADay => 'Perfect day';

  @override
  String get educationTitle => 'Learn';

  @override
  String get magazineTitle => 'Lune Magazine';

  @override
  String get magazineFeatured => 'Featured';

  @override
  String get magazineFromLune => 'From the magazine';

  @override
  String get magazineReadMore => 'Read more';

  @override
  String get educationSubtitle =>
      'Trusted, age-appropriate articles about your cycle, body, and wellbeing.';

  @override
  String get educationCatAll => 'All';

  @override
  String get educationCatBasics => 'Cycle basics';

  @override
  String get educationCatHealth => 'Health & symptoms';

  @override
  String get educationCatNutrition => 'Food & movement';

  @override
  String get educationCatMind => 'Mind & mood';

  @override
  String get educationCatFertility => 'Fertility';

  @override
  String get educationCatFitness => 'Movement';

  @override
  String get educationCatAdult => '18+ topics';

  @override
  String educationMinutes(int count) {
    return '$count min read';
  }

  @override
  String get educationDisclaimer =>
      'Educational content only — not a substitute for medical advice.';

  @override
  String get educationArticles => 'articles';

  @override
  String get educationNoArticles => 'No articles available';

  @override
  String get educationPoweredByAi => 'Powered by AI';

  @override
  String get educationAskAi => 'Ask AI';

  @override
  String get educationAskAnything => 'Ask any health question';

  @override
  String get educationAskHint => 'Ask about any health topic...';

  @override
  String get educationThinking => 'Thinking...';

  @override
  String get educationTopicPhase => 'My current phase';

  @override
  String get educationTopicPhasePrompt =>
      'Tell me about my current cycle phase and what I should know';

  @override
  String get educationTopicNutrition => 'Nutrition tips';

  @override
  String get educationTopicNutritionPrompt =>
      'What foods are best for my current cycle phase?';

  @override
  String get educationTopicExercise => 'Exercise';

  @override
  String get educationTopicExercisePrompt =>
      'What exercises are best for my current cycle phase?';

  @override
  String get educationTopicPain => 'Pain management';

  @override
  String get educationTopicPainPrompt =>
      'How can I manage period pain naturally?';

  @override
  String get educationTopicSleep => 'Sleep better';

  @override
  String get educationTopicSleepPrompt =>
      'How can I improve my sleep during my cycle?';

  @override
  String get educationTopicMood => 'Mood & stress';

  @override
  String get educationTopicMoodPrompt =>
      'How do I manage mood changes during my cycle?';

  @override
  String get reportCycleHealth => 'Cycle Health';

  @override
  String get hormoneIndicatorsTitle => 'Hormone indicators';

  @override
  String get hormoneIndicatorsSubtitle =>
      'Estrogen & progesterone through your cycle';

  @override
  String get hormoneIndicatorsCaption =>
      'Estimated hormone levels based on your cycle day and length.';

  @override
  String get reportFertility => 'Fertility & Pregnancy';

  @override
  String get reportFullHistory => 'Full Cycle History';

  @override
  String get reportSymptomPatterns => 'Symptom Patterns';

  @override
  String get reportsEmpty =>
      'No reports yet. Log your cycle and symptoms with + for a few days, then check back here.';

  @override
  String get reportsLoadPartial =>
      'Some report data could not load. Pull down to refresh.';

  @override
  String get reportsSetupRequired =>
      'Complete cycle setup during onboarding first, then open Reports again.';

  @override
  String get doctorReportQrHint => 'Scan to share a report summary';

  @override
  String get doctorReportUpgradeUnlimited => 'Unlimited reports with Pro';

  @override
  String get reportCycleSummary => 'Cycle Summary';

  @override
  String get reportCycleDay => 'Cycle day';

  @override
  String get reportPeriodDay => 'Period day';

  @override
  String get reportAvgCycle => 'Avg cycle';

  @override
  String get reportAvgPeriod => 'Avg period';

  @override
  String get reportTotalCycles => 'Total cycles';

  @override
  String get reportRegularity => 'Regularity';

  @override
  String get reportOvulation => 'Ovulation';

  @override
  String get reportPregnancyChance => 'Pregnancy chance';

  @override
  String get reportDueDate => 'Due date';

  @override
  String get reportPregnancyWeek => 'Pregnancy week';

  @override
  String get reportTrimester => 'Trimester';

  @override
  String get accountExportBackup => 'Export local backup';

  @override
  String get accountImportBackup => 'Import local backup';

  @override
  String get accountRestoreCloud => 'Restore from cloud';

  @override
  String get accountAdvanced => 'Advanced';

  @override
  String get accountGeminiKeySaved => 'Gemini key saved';

  @override
  String get accountGeminiKeyHelp =>
      'Optional Gemini API key fallback if Cloud Functions are not deployed.';

  @override
  String get accountGeminiKeyLabel => 'Gemini API Key';

  @override
  String get accountGeminiKeySave => 'Save Gemini key';

  @override
  String get reportPatternFallback => 'Pattern';

  @override
  String reportPercentOfCycles(Object percent) {
    return '$percent% of cycles';
  }

  @override
  String get postTypeSupport => 'Support';

  @override
  String get postTypeQuestion => 'Question';

  @override
  String get postTypeTip => 'Tip';

  @override
  String get postTypeVent => 'Vent';

  @override
  String get postTypeMilestone => 'Milestone';

  @override
  String get postTypePoll => 'Poll';

  @override
  String get weeklyRecapTitle => 'Your week with Lune';

  @override
  String get weeklyRecapPrompt =>
      'Summarize my last 7 days based on the data — what went well, what to focus on next week.';

  @override
  String get weeklyRecapLoading => 'Reflecting on your week…';

  @override
  String get weeklyRecapRefresh => 'Refresh';

  @override
  String get dayLabelToday => 'Today';

  @override
  String get dayLabelYesterday => 'Yesterday';

  @override
  String aiActionLogged(String label) {
    return 'Logged: $label';
  }

  @override
  String aiActionLogMood(String mood) {
    return 'Log mood: $mood';
  }

  @override
  String aiActionLogSymptom(String symptom) {
    return 'Log: $symptom';
  }

  @override
  String aiActionLogWater(String count) {
    return 'Log $count water';
  }

  @override
  String aiActionLogPain(String level) {
    return 'Log pain $level/10';
  }

  @override
  String get aiActionOpenLog => 'Open log';

  @override
  String get aiActionOpenInsights => 'See insights';

  @override
  String get aiActionLogFailed =>
      'Couldn\'t save that — open the log to add it';

  @override
  String get aiSuggestHowsMyDay => 'How\'s my day looking?';

  @override
  String get aiSuggestMoodCheck => 'Help me check in on my mood';

  @override
  String get aiSuggestFoodIdeas => 'Food ideas for today';

  @override
  String get aiSuggestExplainPhase => 'Explain my current phase';

  @override
  String get aiSuggestSymptomCheck => 'Should I worry about this symptom?';

  @override
  String get aiSuggestPrep => 'Prep for my doctor visit';

  @override
  String get aiSuggestEnergyBoost => 'Quick energy boost';

  @override
  String get aiSuggestMoveToday => 'Movement plan for today';

  @override
  String get aiSuggestSetGoal => 'Set me a tiny goal';

  @override
  String get adminTabUsers => 'Users';

  @override
  String get adminTabQA => 'Q&A';

  @override
  String get adminTabBroadcast => 'Broadcast';

  @override
  String get adminFilterPending => 'Pending';

  @override
  String get adminFilterAnswered => 'Answered';

  @override
  String get adminFilterAll => 'All';

  @override
  String adminQuestionsEmpty(String filter) {
    return 'No $filter questions yet.';
  }

  @override
  String get adminQAExpertAnswer => 'Expert answer';

  @override
  String get adminPostsToday => 'Posts today';

  @override
  String get adminAiToday => 'AI today';

  @override
  String get adminQuickActions => 'Quick actions';

  @override
  String get adminQuickViewReports => 'Review reports';

  @override
  String get adminQuickSendBroadcast => 'Send broadcast';

  @override
  String get adminQuickEditSettings => 'App settings';

  @override
  String get adminConfirmBan => 'Ban this user?';

  @override
  String get adminConfirmBanMsg =>
      'They will lose access to community features immediately. You can unban later.';

  @override
  String get adminConfirmBroadcast => 'Send to all users?';

  @override
  String get adminConfirmBroadcastMsg =>
      'This notification will be delivered to every signed-in user. Make sure the title and message are correct.';

  @override
  String adminBroadcastSent(String sent, String failed) {
    return 'Broadcast sent · $sent delivered, $failed failed';
  }

  @override
  String get adminConfirm => 'Confirm';

  @override
  String get adminCancel => 'Cancel';

  @override
  String get adminGroupFeatures => 'Features';

  @override
  String get adminGroupAnnouncement => 'Announcement';

  @override
  String get adminGroupLinks => 'Links';

  @override
  String get adminSending => 'Sending…';

  @override
  String get adminSendBroadcast => 'Send broadcast';

  @override
  String get adminNotifPreview => 'Preview';

  @override
  String get adminNoEmail => 'No email';

  @override
  String get adminBannedBadge => 'Banned';

  @override
  String get adminGrantPremium => 'Grant Premium';

  @override
  String get adminRevokePremium => 'Revoke Premium';

  @override
  String get adminPremiumUpdated => 'Subscription status updated';

  @override
  String get adminAiCost30d => 'AI cost (last 30 days)';

  @override
  String adminAiTokensCount(String count) {
    return '$count tokens';
  }

  @override
  String adminAiRequestsCount(String count) {
    return '$count requests';
  }

  @override
  String get adminTimeNow => 'now';

  @override
  String adminTimeMinutes(int n) {
    return '${n}m';
  }

  @override
  String adminTimeHours(int n) {
    return '${n}h';
  }

  @override
  String adminTimeDays(int n) {
    return '${n}d';
  }

  @override
  String get onboardingPrivacyAgree =>
      'I agree to the Privacy Policy. Cycle data stays on my device by default. Cloud backup, AI chat, and community are optional and require separate consent in Privacy Center.';

  @override
  String get privacyCenterTitle => 'Privacy & data';

  @override
  String get privacyCenterIntro =>
      'Lune is privacy-first. Health data is stored locally and encrypted. Cloud, AI, and community features are optional and require your consent.';

  @override
  String get privacyDataLocal => 'Stored on your device';

  @override
  String get privacyDataOptional => 'Optional (with your consent)';

  @override
  String get privacyDataNotCollected => 'We never';

  @override
  String get privacyBulletLocal =>
      'Cycle logs, journal, and wellness data stay on your phone by default.';

  @override
  String get privacyBulletEncrypt =>
      'Encryption keys are stored in Android Keystore / iOS Keychain.';

  @override
  String get privacyBulletCloud =>
      'Cloud backup only when you sign in and turn on sync.';

  @override
  String get privacyBulletAi =>
      'AI chat sends messages to Google Gemini only when you opt in.';

  @override
  String get privacyBulletCommunity =>
      'Communities use an anonymous alias — never your real name or cycle data.';

  @override
  String get privacyBulletNoSell =>
      'Sell or share your health data with advertisers.';

  @override
  String get privacyBulletNoTrack => 'Track you across other apps for ads.';

  @override
  String get privacyPolicyLink => 'Read full Privacy Policy';

  @override
  String get privacyMedicalDisclaimer =>
      'Lune is not a medical device. Always consult a healthcare professional.';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountSubtitle =>
      'Removes cloud data and your sign-in permanently.';

  @override
  String get deleteAccountWarning =>
      'This permanently deletes your account, cloud backups, AI chats, community posts and comments, partner data, and profile photos from our servers. Local data on this device stays until you uninstall the app.';

  @override
  String get deleteAccountConfirm => 'Delete permanently';

  @override
  String get deleteAccountDone => 'Account deleted';

  @override
  String get deleteAccountReauth => 'Sign in again, then retry deletion.';

  @override
  String get deleteAccountFailed =>
      'Could not delete your account. Please try again or contact support.';

  @override
  String get termsOfServiceLink => 'Terms of Service';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get contactSupportSubtitle =>
      'Questions, abuse reports, or account help';

  @override
  String get accountMenuFeedback => 'Feedback & promo codes';

  @override
  String get accountMenuFeedbackSubtitle => 'Send a note or apply a promo code';

  @override
  String get accountMenuAiDiagnostic => 'AI diagnostic';

  @override
  String get accountMenuAiDiagnosticSubtitle =>
      'Test connection or update Gemini key';

  @override
  String get consentManageTitle => 'Your consents';

  @override
  String get consentManageBody =>
      'Turn optional features off anytime. Core tracking on your device is unaffected.';

  @override
  String get premiumRequiredCloud =>
      'Cloud backup is a Premium feature. Subscribe in Account.';

  @override
  String get premiumRequiredAi =>
      'This AI feature requires Premium. Subscribe in Account.';

  @override
  String get premiumAiLimitReached =>
      'You\'ve used today\'s free AI messages. Upgrade to Premium for unlimited chat.';

  @override
  String get aiDailyLimitReached =>
      'You\'ve used your 30 daily Lune AI messages. Your limit resets automatically tomorrow.';

  @override
  String premiumAiFreeRemaining(int count) {
    return '$count free AI messages left today';
  }

  @override
  String get openPrivacyCenter => 'Privacy & data settings';

  @override
  String get consentCloudTitle => 'Enable cloud backup?';

  @override
  String get consentCloudBody =>
      'Encrypted cycle backups will be stored in your Firebase account. You can turn this off anytime.';

  @override
  String get consentAiTitle => 'Enable AI features?';

  @override
  String get consentAiBody =>
      'When you enable AI, the message or content you submit and relevant cycle context (such as symptoms, mood, phase, and saved preferences) are sent to DeepSeek and/or Google through our secure server to provide a personalized response. Do not include identifying information you do not want processed. This is not medical advice. You can disable AI anytime.';

  @override
  String get aiAdultsOnly => 'Lune AI is for adults 18+ only.';

  @override
  String get consentCommunityTitle => 'Join communities?';

  @override
  String get consentCommunityBody =>
      'You will use an anonymous alias. Posts are moderated by AI. Your cycle data is never shared.';

  @override
  String get consentAccept => 'I agree';

  @override
  String get consentRequired => 'Please accept to continue';

  @override
  String get homeGreeting => 'Welcome back';

  @override
  String homeGreetingName(String name) {
    return 'Hello, $name';
  }

  @override
  String homeSubtitleDay(int day, String phase) {
    return 'Day $day · $phase';
  }

  @override
  String get homeOvulation => 'Next ovulation';

  @override
  String get homeRegularity => 'Cycle regularity';

  @override
  String homeCycleDay(int day) {
    return 'Cycle day $day';
  }

  @override
  String homePeriodDay(int day) {
    return 'Period day $day';
  }

  @override
  String get homeOvulationToday => 'Ovulation today';

  @override
  String get homeKeyDates => 'Important dates';

  @override
  String get homeDueDate => 'Expected due date';

  @override
  String get homeCycleProgress => 'Cycle progress';

  @override
  String get homeWeeklyCalendar => 'This week';

  @override
  String get homeTipsSection => 'Tips & insights';

  @override
  String get homeLearnSection => 'Learn & watch';

  @override
  String get homeVideoLabel => 'Video';

  @override
  String get homeArticleLabel => 'Article';

  @override
  String get homeCycleView => 'Cycle overview';

  @override
  String get homeOpenCalendar => 'View full calendar';

  @override
  String get homeStatsError => 'Could not load cycle stats. Pull to refresh.';

  @override
  String get homeLoadingStats => 'Loading your cycle data…';

  @override
  String get homeDayShort => 'day';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to Lune';

  @override
  String get onboardingWelcomeSubtitle =>
      'Lune means moon — a private companion for every phase of your cycle';

  @override
  String get onboardingWelcomeHelps => 'We\'ll help you:';

  @override
  String get onboardingWelcomeTrack => 'Track your cycle, symptoms & mood';

  @override
  String get onboardingWelcomeAi => 'Smart AI chat to answer your questions';

  @override
  String get onboardingWelcomeCommunity => 'Supportive community of women';

  @override
  String get onboardingWelcomePregnancy => 'Week-by-week pregnancy tracking';

  @override
  String get onboardingWelcomeSelfCare => 'Personalized self-care tips';

  @override
  String get onboardingFeaturesTitle => 'Your app at a glance';

  @override
  String get onboardingFeaturesSubtitle => 'Here are the main screens:';

  @override
  String get onboardingReadyHint => 'Tap Get Started below to enter the app';

  @override
  String get onboardingFeatureHome => 'Home';

  @override
  String get onboardingFeatureHomeDesc =>
      'Quick cycle overview, fast logging, and predictions';

  @override
  String get onboardingFeatureSelfCare => 'Self-care';

  @override
  String get onboardingFeatureSelfCareDesc =>
      'Breathing exercises, affirmations, journal, and challenges';

  @override
  String get onboardingFeatureCommunity => 'Community';

  @override
  String get onboardingFeatureCommunityDesc =>
      'Support groups, questions & discussions with women like you';

  @override
  String get onboardingFeatureReports => 'Reports';

  @override
  String get onboardingFeatureReportsDesc =>
      'Cycle analysis, charts, and a doctor-ready report';

  @override
  String get onboardingFeatureAccount => 'Account';

  @override
  String get onboardingFeatureAccountDesc => 'Profile, settings, Premium';

  @override
  String get educationNotAvailable => 'Education section is not available yet';

  @override
  String get selfCareWelcomeTitle => 'Welcome to your self-care space';

  @override
  String get selfCareWelcomeSubtitle =>
      'Start tracking your cycle to get personalized tips, or explore activities now.';

  @override
  String get onboardingProfileTitle => 'Let\'s get to know you';

  @override
  String get onboardingProfileSubtitle =>
      'Your name helps personalize AI tips, self-care, and your home screen.';

  @override
  String get onboardingNameLabel => 'Your name';

  @override
  String get onboardingNameHint => 'How should we greet you?';

  @override
  String get onboardingGoalTitle => 'What\'s your focus?';

  @override
  String get onboardingGoalSubtitle =>
      'Choose what matters now — cycle, pregnancy, fertility, PCOS, menopause, or recovery — and the app adapts with you.';

  @override
  String get onboardingCycleTitle => 'Your cycle basics';

  @override
  String get onboardingCycleSubtitle =>
      'These power predictions, reminders, reports, and AI — everywhere in the app.';

  @override
  String get onboardingPregnancyDataTitle => 'Your pregnancy';

  @override
  String get onboardingPregnancyDataSubtitle =>
      'We use the first day of your last period to estimate your week, due date, and how your baby is growing.';

  @override
  String get onboardingPregnancyLmp => 'First day of last period (LMP)';

  @override
  String get pregnancyModeTitle => 'Pregnancy tracking';

  @override
  String pregnancyWeekDay(int week, int day) {
    return 'Week $week · day $day';
  }

  @override
  String pregnancyTrimester(int n) {
    return 'Trimester $n';
  }

  @override
  String pregnancyDueDate(String date) {
    return 'Due $date';
  }

  @override
  String get pregnancyBabyThisWeek => 'Baby this week';

  @override
  String get pregnancyBabyVisualTitle => 'Your baby now';

  @override
  String get pregnancyBabyNextWeek => 'Next week preview';

  @override
  String get pregnancyWeekShort => 'wk';

  @override
  String get pregnancyExploreWeeks => 'Explore by week';

  @override
  String pregnancyWeekLabel(int week) {
    return 'Week $week';
  }

  @override
  String pregnancySizeLike(String item) {
    return 'Your baby is the size of a $item';
  }

  @override
  String get pregnancySizeComparison => 'Size comparison';

  @override
  String get pregnancyGrowthTitle => 'Approximate growth';

  @override
  String get pregnancyLengthLabel => 'Length';

  @override
  String get pregnancyWeightLabel => 'Weight';

  @override
  String get pregnancyYourBody => 'Your body this week';

  @override
  String get pregnancySelfCareTitle => 'Prenatal self-care';

  @override
  String get pregnancySelfCareSubtitle =>
      'Gentle rituals and tips for your trimester.';

  @override
  String get pregnancyReportOverview => 'Pregnancy overview';

  @override
  String get pregnancyReportChecklist => 'Trimester checklist';

  @override
  String pregnancyDaysToDue(int days) {
    return '$days days to due date';
  }

  @override
  String get pregnancyCheckFirstVisit => 'Schedule your first prenatal visit';

  @override
  String get pregnancyCheckPrenatalVitamins =>
      'Take prenatal vitamins as advised';

  @override
  String get pregnancyCheckRest => 'Rest when you feel tired';

  @override
  String get pregnancyCheckAnatomyScan => 'Anatomy scan around week 20';

  @override
  String get pregnancyCheckMovement => 'Note baby movements daily';

  @override
  String get pregnancyCheckHydration => 'Stay hydrated throughout the day';

  @override
  String get pregnancyCheckBirthPlan =>
      'Discuss your birth plan with your provider';

  @override
  String get pregnancyCheckHospitalBag => 'Start packing your hospital bag';

  @override
  String get pregnancyCheckKickCounts =>
      'Count kicks once daily in the third trimester';

  @override
  String get aiInsightPrenatalTitle => 'Prenatal tip';

  @override
  String get aiInsightConceiveTitle => 'Fertility tip';

  @override
  String get aiInsightAvoidTitle => 'Protection tip';

  @override
  String get aiInsightWellnessTitle => 'Wellness tip';

  @override
  String get cycleCauseTitle => 'Was this cycle different?';

  @override
  String get cycleCauseIntro =>
      'If something threw this cycle off, tell me. I\'ll leave it out of your averages instead of learning the wrong pattern from it.';

  @override
  String get cycleCauseIllness => 'Illness';

  @override
  String get cycleCauseTravel => 'Travel';

  @override
  String get cycleCauseStress => 'Stress';

  @override
  String get cycleCauseWeight => 'Weight change';

  @override
  String get cycleCauseMedication => 'New medication';

  @override
  String get cycleCauseSleep => 'Poor sleep';

  @override
  String get cycleCauseExercise => 'Intense exercise';

  @override
  String get cycleCauseNothing => 'Nothing unusual';

  @override
  String get cycleCauseSaved =>
      'Saved — this cycle is set aside from your averages.';

  @override
  String get cycleCauseCleared =>
      'Saved — this cycle counts toward your averages.';

  @override
  String cycleCauseLearned(int count) {
    return '$count cycles set aside from your averages';
  }

  @override
  String get cycleCauseStillCounted =>
      'Set-aside cycles are still reviewed for health patterns.';

  @override
  String get cycleSignalsTitle => 'Worth mentioning to a doctor';

  @override
  String get cycleSignalsIntro =>
      'These come from your own logged cycles. They are observations, not a diagnosis — stress, travel, illness and weight changes all cause them too.';

  @override
  String get cycleSignalsProlonged =>
      'Several recent cycles ran longer than 35 days.';

  @override
  String get cycleSignalsShort =>
      'Several recent cycles were shorter than 21 days.';

  @override
  String get cycleSignalsVariable =>
      'Your cycle length swung by 9 days or more between cycles.';

  @override
  String get cycleSignalsAbsent =>
      'There was a gap of 90 days or more with no period logged.';

  @override
  String get cycleSignalsFooter =>
      'Bring this up at your next visit. Your doctor report already includes it.';

  @override
  String get cycleSignalsOpenReport => 'Open doctor report';

  @override
  String ovulationConfirmedHint(String rise) {
    return 'Confirmed by your temperature — up $rise°C';
  }

  @override
  String get ovulationConfirmedBadge => 'Confirmed';

  @override
  String get bbtCardTitle => 'Confirm your ovulation';

  @override
  String get bbtCardWhy =>
      'Your temperature rises 0.2–0.5°C after ovulation and stays up. It is the only at-home sign that ovulation actually happened — everything else is an estimate from your dates.';

  @override
  String get bbtCardHow =>
      'Take it each morning before getting out of bed, at roughly the same time.';

  @override
  String bbtCardProgress(int done, int total) {
    return '$done of $total readings this cycle';
  }

  @override
  String get bbtCardReady =>
      'Enough readings — watching for the rise that confirms ovulation.';

  @override
  String bbtCardConfirmed(String date, String rise) {
    return 'Ovulation confirmed on $date, temperature up $rise°C.';
  }

  @override
  String get bbtCardConfirmedNote =>
      'Your next period is now predicted from this, not from your average cycle length.';

  @override
  String bbtCardCalibrated(int count) {
    return 'Your luteal phase is measured from $count real signals instead of assumed.';
  }

  @override
  String get bbtCardReminderOn => 'Remind me each morning';

  @override
  String bbtCardReminderTime(String time) {
    return 'Reminder at $time';
  }

  @override
  String get bbtCardLogNow => 'Log today\'s temperature';

  @override
  String get bbtReminderEnabled => 'Morning temperature reminder';

  @override
  String get bbtReminderSubtitle =>
      'Fires at your wake time — basal temperature only counts before you get up.';

  @override
  String get aiInsightPcosTitle => 'Your PCOS pattern';

  @override
  String get aiInsightMenopauseTitle => 'Your menopause pattern';

  @override
  String get aiInsightPostpartumTitle => 'Your recovery';

  @override
  String get aiInsightLogTitle => 'Today\'s reflection';

  @override
  String get goalModeConceiveTitle => 'Trying to conceive';

  @override
  String get goalModeAvoidTitle => 'Avoiding pregnancy';

  @override
  String get goalModeGeneralTitle => 'General wellness';

  @override
  String get goalModeTodayFocus => 'Today\'s focus';

  @override
  String get goalModeChecklist => 'Your checklist';

  @override
  String get goalModeReportInsights => 'Insights for your goal';

  @override
  String get goalModeFertilityToday => 'Fertility estimate today';

  @override
  String get goalModeFertilityHigh => 'Estimated high';

  @override
  String get goalModeFertilityModerate => 'Estimated moderate';

  @override
  String get goalModeFertilityLow => 'Estimated lower';

  @override
  String get goalModeFertilityUnknown => 'Track more';

  @override
  String get goalModeTestDate => 'Pregnancy test';

  @override
  String get goalModeOvulationToday => 'Estimated ovulation window today';

  @override
  String get goalModeConceiveSelfCare => 'Fertility self-care';

  @override
  String get goalModeConceiveSelfCareSub =>
      'Small daily habits that support conception.';

  @override
  String get goalModeAvoidSelfCare => 'Protection self-care';

  @override
  String get goalModeAvoidSelfCareSub =>
      'Stay aware of fertile days and your contraception routine.';

  @override
  String get goalModeGeneralSelfCare => 'Cycle wellness';

  @override
  String get goalModeGeneralSelfCareSub =>
      'Holistic care for your body across every phase.';

  @override
  String get pregnancyTrackingTitle => 'Track your pregnancy';

  @override
  String get pregnancyTrackingSubtitle =>
      'Log weight, count kicks, and time contractions — week by week with Lune.';

  @override
  String get pregnancyWeightTitle => 'Weight';

  @override
  String get pregnancyWeightHint => 'Today\'s weight';

  @override
  String get pregnancyWeightUnit => 'kg';

  @override
  String get pregnancyWeightSave => 'Save';

  @override
  String get pregnancyWeightSaved => 'Weight saved';

  @override
  String get pregnancyWeightInvalid =>
      'Enter a valid weight between 30 and 200 kg';

  @override
  String pregnancyWeightLatest(double kg) {
    return '$kg kg (latest)';
  }

  @override
  String get pregnancyKicksTitle => 'Kick counter';

  @override
  String get pregnancyKicksHint =>
      'Count 10 kicks — tap each time baby moves. Contact your provider if movement drops.';

  @override
  String get pregnancyKicksStart => 'Start counting';

  @override
  String get pregnancyKicksTap => 'Kick!';

  @override
  String get pregnancyKicksEnd => 'Stop';

  @override
  String pregnancyKicksToday(int count) {
    return '$count kicks today';
  }

  @override
  String get pregnancyContractionsTitle => 'Contraction timer';

  @override
  String get pregnancyContractionsHint =>
      'Start when a contraction begins, stop when it ends. Call your provider if contractions are regular before 37 weeks.';

  @override
  String get pregnancyContractionStart => 'Contraction started';

  @override
  String get pregnancyContractionEnd => 'Contraction ended';

  @override
  String pregnancyContractionsToday(int count) {
    return '$count today';
  }

  @override
  String pregnancyContractionAvg(int seconds) {
    return 'Avg ${seconds}s';
  }

  @override
  String pregnancyContractionInterval(int minutes) {
    return 'Every $minutes min';
  }

  @override
  String get pregnancyContractionRecent => 'Recent today';

  @override
  String pregnancyContractionDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String get onboardingDateFormat => 'Date format';

  @override
  String get cycleSettingsTitle => 'Cycle settings';

  @override
  String get cycleSettingsSubtitle =>
      'Updates Home, AI, reminders, and predictions across the app.';

  @override
  String get cycleSettingsSave => 'Save & sync';

  @override
  String get onboardingNoEmailNote =>
      'No email required — your data stays on this device.';

  @override
  String get onboardingPartialSave =>
      'Setup saved locally. You can adjust cycle settings anytime from Account.';

  @override
  String get accountRerunSetup => 'Run setup again';

  @override
  String get accountRerunSetupSubtitle =>
      'Re-enter your name, goal, and cycle basics';

  @override
  String get rerunSetupConfirmTitle => 'Are you sure?';

  @override
  String get rerunSetupConfirmBody =>
      'This will restart the initial setup. Your existing data won\'t be lost, but you\'ll need to re-enter your preferences.';

  @override
  String get rerunSetupConfirmYes => 'Yes, restart';

  @override
  String get rerunSetupConfirmCancel => 'Cancel';

  @override
  String get accountChangeGoal => 'Your goal';

  @override
  String get accountChangeGoalHint =>
      'The app adapts instantly — home, reports, self-care, and AI.';

  @override
  String get goalChangedSnackbar =>
      'Goal updated — the app is now tailored to you';

  @override
  String accountUserId(String id) {
    return 'Account ID: $id';
  }

  @override
  String get premiumRefreshStatus => 'Check subscription status';

  @override
  String get signOutConfirmTitle => 'Sign out?';

  @override
  String get signOutConfirmBody =>
      'Your local data stays on this device. You can sign back in anytime.';

  @override
  String get guestModeTitle => 'Private guest mode';

  @override
  String get guestModeLabel => 'Local profile · no email';

  @override
  String get guestModeBody =>
      'You\'re using Lune privately. Sign in only for Communities, Premium, or cloud backup.';

  @override
  String get signInOptionalTitle => 'Sign in (optional)';

  @override
  String get signInOptionalSubtitle =>
      'For communities, Premium subscription, and cloud backup';

  @override
  String get communityRequiresAccount =>
      'Communities need a sign-in to protect everyone\'s privacy. Your cycle data is never shared.';

  @override
  String get aiGuestHint =>
      'Works on your device. Sign in for full cloud AI features.';

  @override
  String get editProfileTitle => 'Your profile';

  @override
  String get avatarPickTitle => 'Choose your character';

  @override
  String get avatarUsePhoto => 'Use my photo';

  @override
  String get communityAttachPhoto => 'Add photo';

  @override
  String get communityAttachVideo => 'Add video';

  @override
  String get editProfileSubtitle => 'Pick a fun character or your own photo.';

  @override
  String get editProfileSave => 'Save profile';

  @override
  String get partnerTitle => 'Partner mode';

  @override
  String get partnerSubtitle =>
      'Share only what you choose with one trusted partner';

  @override
  String get partnerIntro =>
      'Your partner sees a limited card: cycle phase, days until the next period — nothing else. You control every item and can unlink anytime.';

  @override
  String get partnerSignInPrompt =>
      'Partner mode needs a sign-in so the link stays private and secure.';

  @override
  String get partnerOwnerSection => 'Share my cycle';

  @override
  String get partnerYourCode => 'Your invite code';

  @override
  String get partnerCodeCopied => 'Code copied';

  @override
  String get partnerRegenerate => 'New code';

  @override
  String get partnerShareWhat => 'What your partner can see';

  @override
  String get partnerSharePhase => 'Cycle phase & day';

  @override
  String get partnerShareNextPeriod => 'Days until next period';

  @override
  String get partnerSharePain => 'Recent pain level';

  @override
  String get partnerLinked => 'Partner linked';

  @override
  String get partnerNotLinked => 'No partner linked yet — share your code';

  @override
  String get partnerUnlink => 'Unlink partner';

  @override
  String get partnerUnlinked => 'Partner unlinked';

  @override
  String get partnerPublishNow => 'Update shared card now';

  @override
  String get partnerPublished => 'Shared card updated';

  @override
  String get partnerNothingToPublish => 'Nothing shared — link a partner first';

  @override
  String get partnerPartnerSection => 'I\'m the partner';

  @override
  String get partnerEnterCode => 'Enter her invite code';

  @override
  String get partnerCodeHint => 'e.g. K7XF2M';

  @override
  String get partnerJoin => 'Link';

  @override
  String get partnerJoinedOk => 'Linked successfully';

  @override
  String get partnerInvalidCode => 'Invalid or expired code';

  @override
  String get partnerLeave => 'Remove link';

  @override
  String get partnerStatusTitle => 'Her cycle today';

  @override
  String get partnerStatusPhase => 'Phase';

  @override
  String get partnerStatusCycleDay => 'Cycle day';

  @override
  String partnerStatusNextPeriod(int days) {
    return '$days days until next period';
  }

  @override
  String get partnerStatusPain => 'Recent pain level';

  @override
  String get partnerStatusPeriodActive => 'Period is active now';

  @override
  String get partnerStatusEmpty =>
      'Nothing shared yet — ask her to update the shared card.';

  @override
  String partnerStatusUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get partnerTipTitle => 'How to support her today';

  @override
  String get partnerTipMenstruation =>
      'Energy may be low. A warm drink, patience, and taking something off her plate go a long way.';

  @override
  String get partnerTipFollicular =>
      'Energy is rising — a great time to plan something fun together.';

  @override
  String get partnerTipOvulation =>
      'She is likely feeling at her best. Enjoy quality time together.';

  @override
  String get partnerTipLuteal =>
      'PMS may show up: be patient and extra kind, small gestures matter most now.';

  @override
  String get partnerTipDefault =>
      'Check in with her and ask how she is feeling today.';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityAnswered => 'Answered';

  @override
  String get communityTabSaved => 'Saved';

  @override
  String get communitySavedEmpty =>
      'No saved posts yet. Tap the bookmark on a post to save it.';

  @override
  String get communityShare => 'Share';

  @override
  String get communityShareVia => 'Shared from Lune';

  @override
  String get communityPostSaved => 'Post saved';

  @override
  String get communityPostUnsaved => 'Removed from saved';

  @override
  String get communityDeletePost => 'Delete post';

  @override
  String get communityDeleteComment => 'Delete comment';

  @override
  String get communityDeletePostConfirm => 'Delete this post permanently?';

  @override
  String get communityDeleteCommentConfirm =>
      'Are you sure you want to delete this comment?';

  @override
  String get communityPostDeleted => 'Post deleted';

  @override
  String get communityCommentDeleted => 'Comment deleted';

  @override
  String get communityReply => 'Reply';

  @override
  String communityReplyingTo(String alias) {
    return 'Replying to $alias';
  }

  @override
  String get communityMarkBestAnswer => 'Mark as best answer';

  @override
  String get communityBestAnswer => 'Best answer';

  @override
  String get communityCatCulture => 'Culture';

  @override
  String get communityCatAge => 'Young adults';

  @override
  String get communityHomeCardTitle => 'Community';

  @override
  String get communityHomeCardSubtitle =>
      'Support, questions, and sisterhood — nickname only';

  @override
  String get communityNotifTitle => 'Community activity';

  @override
  String get communityNotifSubtitle => 'Likes and comments on your posts';

  @override
  String get communityTextOnlyNote =>
      'Photos & videos are Premium. Community reports auto-hide unsafe posts.';

  @override
  String get communityEditPost => 'Edit post';

  @override
  String get communityPostUpdated => 'Post updated';

  @override
  String get communityEdited => 'Edited';

  @override
  String get communityActivityTitle => 'Activity';

  @override
  String get communityActivityEmpty =>
      'No activity yet. When someone likes or comments on your posts, it appears here.';

  @override
  String communityActivityComment(String alias) {
    return '$alias commented on your post';
  }

  @override
  String communityActivityLike(String alias) {
    return '$alias liked your post';
  }

  @override
  String communityActivityReply(String alias) {
    return '$alias replied to your comment';
  }

  @override
  String communityActivityFollow(String alias) {
    return '$alias started following you';
  }

  @override
  String communityActivityMention(String alias) {
    return '$alias mentioned you in a comment';
  }

  @override
  String get communityFollow => 'Follow';

  @override
  String get communityFollowingBtn => 'Following';

  @override
  String get communityUnfollow => 'Unfollow';

  @override
  String get communityUnfollowed => 'Unfollowed';

  @override
  String communityFollowedToast(String alias) {
    return 'You\'re now following $alias';
  }

  @override
  String get communityFollowingTitle => 'Following';

  @override
  String get communityFollowingSubtitle => 'Members you follow';

  @override
  String get communityFollowingEmpty =>
      'You aren\'t following anyone yet. Tap a member\'s name on a post to follow them.';

  @override
  String get communityCommentSortOldest => 'Oldest first';

  @override
  String get communityCommentSortNewest => 'Newest first';

  @override
  String get communityCommentSortTop => 'Most liked';

  @override
  String get communityMarkAllRead => 'Mark all read';

  @override
  String get communitySortNewest => 'Newest';

  @override
  String get communityFeedPopular => 'Popular';

  @override
  String get communityFeedMyComments => 'My comments';

  @override
  String get communityCoverTitle => 'Post cover';

  @override
  String get communityCoverNone => 'None';

  @override
  String get communitySortDiscussed => 'Most discussed';

  @override
  String get communityFilterMyPosts => 'My posts';

  @override
  String get communitySearchPosts => 'Search posts...';

  @override
  String get communityCopied => 'Copied to clipboard';

  @override
  String get communityCopy => 'Copy text';

  @override
  String get communityGuidelinesShort => 'Guidelines';

  @override
  String get communityPollAddOption => 'Add option';

  @override
  String communityPollOptionHint(int number) {
    return 'Option $number';
  }

  @override
  String get communityPollNeedsOptions => 'Add at least 2 poll options';

  @override
  String communityPollVotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count votes',
      one: '1 vote',
      zero: 'No votes yet',
    );
    return '$_temp0';
  }

  @override
  String get communityPollTapToVote => 'Tap an option to vote';

  @override
  String get communityFilters => 'Filters';

  @override
  String get communityFilterCategory => 'Category';

  @override
  String get communityFilterPostType => 'Post type';

  @override
  String get communityFilterReset => 'Reset';

  @override
  String get communityFilterApply => 'Apply';

  @override
  String get storyChooseCommunity => 'Share story to...';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}m ago',
      one: '1m ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}h ago',
      one: '1h ago',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '${count}d ago',
      one: 'Yesterday',
    );
    return '$_temp0';
  }

  @override
  String get reactionHeart => 'Love';

  @override
  String get reactionHug => 'Hug';

  @override
  String get reactionCelebrate => 'Celebrate';

  @override
  String get reactionStrong => 'Strength';

  @override
  String get communityMemberProfile => 'Member profile';

  @override
  String get communityRecentPosts => 'Recent posts';

  @override
  String get communityNoRecentPosts => 'No public posts yet';

  @override
  String get communityWeeklyQuestion => 'Question of the week';

  @override
  String get communityWeeklyAnswer => 'Share your answer';

  @override
  String get premiumUpsellTitle => 'Lune Premium';

  @override
  String get premiumUpsellSubscribe => 'View subscription';

  @override
  String get premiumUpsellNotNow => 'Not now';

  @override
  String get moderationRejectedTitle => 'Content not approved';

  @override
  String get moderationRejectedBody =>
      'Your post or comment did not pass our community guidelines review.';

  @override
  String get moderationRejectedTips =>
      'Tips: no phone numbers, links, or email addresses. Keep it supportive and respectful. Medical topics need a healthcare provider.';

  @override
  String get moderationContactSupport => 'Contact support';

  @override
  String get moderationTryAgain => 'Edit and try again';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutTagline =>
      'Lune means moon — your private phase-by-phase wellness companion. Data stays on device; cloud, AI, and communities are optional.';

  @override
  String get insightsCycleRegularityScore => 'Cycle regularity (CRS)';

  @override
  String get insightsPeriodRegularityScore => 'Period regularity (PRS)';

  @override
  String get insightsGraphEmpty =>
      'Log more data to see this chart — track symptoms, weight, sleep, and more in Daily Log.';

  @override
  String get predictedSymptomsTitle => 'Likely symptoms';

  @override
  String get predictedSymptomsDisclaimer =>
      'Based on your past cycles on this cycle day — not a medical prediction.';

  @override
  String get predictedSymptomsToday => 'Today';

  @override
  String get predictedSymptomsTomorrow => 'Tomorrow';

  @override
  String predictedSymptomsLikelihood(int percent) {
    return '$percent% likely';
  }

  @override
  String get reportCycleHistoryTable => 'Recent cycles';

  @override
  String get reportCycleHistoryStart => 'Start';

  @override
  String get reportCycleHistoryCycle => 'Cycle';

  @override
  String get reportCycleHistoryPeriod => 'Period';

  @override
  String get reportPregnancyTestDate => 'Expected pregnancy test';

  @override
  String get ovulationReminder => 'Ovulation reminder';

  @override
  String get notificationsWellnessNote =>
      'Pill, sanitary, and LARC reminders in Wellness follow the main toggle above.';

  @override
  String get smartPhaseReminder => 'Smart phase-based reminders';

  @override
  String get smartPhaseReminderSubtitle =>
      'Get a supportive daily tip that adapts to your cycle phase or pregnancy week.';

  @override
  String get latePeriodReminder => 'Late period warning';

  @override
  String get latePeriodReminderSubtitle =>
      'Get a gentle heads-up if your period runs a couple of days past its predicted date.';

  @override
  String get sendTestNotification => 'Send a test notification';

  @override
  String get testNotificationSent => 'Sent! Check your notification shade.';

  @override
  String get testNotificationBlocked =>
      'Notifications are off for Lune. Turn them on in system settings.';

  @override
  String get graphExportShared => 'Chart ready to share.';

  @override
  String get adminTitle => 'Admin Panel';

  @override
  String get adminAccessDenied => 'You don\'t have admin access.';

  @override
  String get adminDashboard => 'Dashboard';

  @override
  String get adminReports => 'Reports';

  @override
  String get adminSettings => 'Settings';

  @override
  String get adminTotalUsers => 'Total users';

  @override
  String get adminPendingReports => 'Pending reports';

  @override
  String get adminRecentActivity => 'Recent activity';

  @override
  String get adminNoActivity => 'No activity yet.';

  @override
  String get adminReportAuthor => 'Author';

  @override
  String get adminReportReason => 'Reason';

  @override
  String get adminReportStatus => 'Status';

  @override
  String get adminReportPending => 'Pending';

  @override
  String get adminReportResolved => 'Report resolved';

  @override
  String get adminReportDismiss => 'Dismiss report';

  @override
  String get adminHidePost => 'Hide post';

  @override
  String get adminBanUser => 'Ban user';

  @override
  String get adminUnbanUser => 'Unban user';

  @override
  String get adminUserBanned => 'User banned';

  @override
  String get adminUserUnbanned => 'User unbaned';

  @override
  String get adminPostHidden => 'Post hidden';

  @override
  String get adminSettingsSaved => 'Settings saved';

  @override
  String get adminCommunityEnabled => 'Community enabled';

  @override
  String get adminAiEducation => 'AI Education enabled';

  @override
  String get adminAnnouncement => 'Announcement';

  @override
  String get adminAnnouncementTitleEn => 'Title (English)';

  @override
  String get adminAnnouncementTitleAr => 'Title (Arabic)';

  @override
  String get adminAnnouncementBodyEn => 'Body (English)';

  @override
  String get adminAnnouncementBodyAr => 'Body (Arabic)';

  @override
  String get adminSupportUrl => 'Support URL';

  @override
  String get adminPrivacyUrl => 'Privacy URL';

  @override
  String get adminSave => 'Save settings';

  @override
  String get communityEditComment => 'Edit comment';

  @override
  String get communityCommentUpdated => 'Comment updated';

  @override
  String get communityPickImage => 'Choose photo';

  @override
  String get communityPickVideo => 'Choose video';

  @override
  String get communityAddMedia => 'Add photo or video';

  @override
  String get communityPostAnonymously => 'Post anonymously';

  @override
  String get communityMediaPremiumGate =>
      'Attaching photos and videos is a Premium feature. Upgrade to unlock media posts.';

  @override
  String get premiumFeatureTitle => 'Premium feature';

  @override
  String get upgradeToPremium => 'Upgrade';

  @override
  String get communityPendingReview => 'Pending review';

  @override
  String get communityThreadTitle => 'Replies';

  @override
  String get communityNoReplies => 'No replies yet';

  @override
  String communityViewReplies(int count) {
    return 'View $count replies';
  }

  @override
  String get adminPendingModeration => 'Pending moderation';

  @override
  String get adminApprovePost => 'Approve post';

  @override
  String get adminRejectPost => 'Reject post';

  @override
  String get adminNoReports => 'No pending reports or moderation';

  @override
  String get adminPendingComments => 'Pending comments';

  @override
  String get adminApproveComment => 'Approve comment';

  @override
  String get adminRejectComment => 'Reject comment';

  @override
  String get storyCreate => 'Create Story';

  @override
  String get storyPickImage => 'Photo from gallery';

  @override
  String get storyPickMultiple => 'Multiple photos';

  @override
  String get storyTextOnly => 'Text story';

  @override
  String get storyTextOnlyHint => 'Colored background with text';

  @override
  String get storyTextHint => 'What\'s on your mind?';

  @override
  String get storyPublish => 'Share Story';

  @override
  String get storyPublished => 'Story shared!';

  @override
  String get storyPremiumRequired => 'Stories with media require Premium';

  @override
  String get storyYourStory => 'Your story';

  @override
  String get storyViewAll => 'View all stories';

  @override
  String get aiQuickActionsTitle => 'What would you like?';

  @override
  String get aiFeatureBriefing => 'Daily Briefing';

  @override
  String get aiFeatureBriefingPrompt => 'Give me my daily briefing';

  @override
  String get aiFeaturePatterns => 'My Patterns';

  @override
  String get aiFeaturePatternsPrompt =>
      'Analyze my cycle patterns from recent months';

  @override
  String get aiFeatureNutrition => 'Nutrition Tips';

  @override
  String get aiFeatureNutritionPrompt =>
      'What should I eat today based on my cycle phase?';

  @override
  String get aiFeaturePartner => 'Partner Message';

  @override
  String get aiFeaturePartnerPrompt =>
      'Help me tell my partner how I\'m feeling today';

  @override
  String get aiFeatureMood => 'Mood Journal';

  @override
  String get aiFeatureMoodPrompt => 'I want to write about how I\'m feeling';

  @override
  String get aiFeatureEmergency => 'Emergency Help';

  @override
  String get aiEmergencyPrompt => 'I\'m in pain and need help right now';

  @override
  String get aiEmergencyTooltip => 'Quick pain relief guidance';

  @override
  String get aiFeatureFertility => 'Fertility Insights';

  @override
  String get aiFeatureFertilityPrompt =>
      'Help me understand my fertility window';

  @override
  String get aiFeatureWeight => 'Weight & Nutrition';

  @override
  String get aiFeatureWeightPrompt => 'What should I eat for my phase?';

  @override
  String get aiFeatureIntimacy => 'Intimacy Guidance';

  @override
  String get aiFeatureIntimacyPrompt => 'Tips for intimacy during my cycle';

  @override
  String get dailyBriefingTitle => 'Daily Briefing';

  @override
  String get dailyBriefingLoading => 'Preparing your daily briefing...';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyEffectiveDate => 'Effective Date';

  @override
  String get privacyOpenExternal => 'Open in browser';

  @override
  String get privacyContactTitle => 'Contact Us';

  @override
  String privacyContactBody(Object email) {
    return 'If you have questions about this Privacy Policy or wish to exercise your data rights, contact us at: $email';
  }

  @override
  String get privacyP1Title => '1. Introduction';

  @override
  String get privacyP1Body =>
      'Lune (\"we\", \"us\", or \"our\") is a menstrual cycle tracking application designed to help users monitor their health and wellness. This Privacy Policy explains how we collect, use, disclose, and protect your personal information when you use our mobile application and related services. By using Lune, you agree to the practices described in this policy. If you do not agree, please discontinue use of the application.';

  @override
  String get privacyP2Title => '2. Information We Collect';

  @override
  String get privacyP2Body =>
      'We collect the following types of information:\n\n• Health & Cycle Data: Menstrual cycle dates, symptoms, moods, flow levels, and other health-related entries you voluntarily log.\n• Google Health Connect (optional): If you enable a Health Connect group, Lune reads and writes only selected cycle, fertility, sleep, activity, vital, weight, and hydration categories during a manual foreground sync. Imported snapshots stay encrypted on your device and are not sent to Firebase, AI providers, advertising, communities, or partner features.\n• Account Information: Email, display name, and sign-in method when you register (email/password, Google, or Apple). If you use the app as a guest, we create an anonymous Firebase account linked to your device without collecting your email.\n• Community Content: Posts, comments, reactions, and profile information you share in community features (if you opt in).\n• Device Information: Basic device identifiers required for push notifications, app security (Firebase App Check), and app functionality.\n• AI Data: If you explicitly enable AI, the message or content you submit and relevant cycle context—such as symptoms, mood, phase, and saved preferences—are processed by DeepSeek and/or Google to generate personalized responses. Text you type may contain information you choose to disclose. Guest users: chat history stays on your device only. Registered users: chat history may be stored in your cloud account (Firebase) to restore conversations.\n• Usage & Diagnostics: Approximate last-active timestamp and crash/error reports via Firebase Crashlytics in release builds to help us fix bugs. We do not use third-party advertising trackers.';

  @override
  String get privacyP3Title => '3. How We Use Your Information';

  @override
  String get privacyP3Body =>
      'Your information is used to:\n\n• Provide core cycle tracking, predictions, and personalized insights.\n• Deliver AI-powered wellness information and daily briefings (not medical advice).\n• Enable community features (posts, comments, stories) if you opt in.\n• Process cloud backups if you enable encrypted backup.\n• Send optional notifications (period reminders, pill reminders).\n• Improve app performance, diagnose crashes, and fix bugs.\n• Ensure safety and prevent misuse of community features.';

  @override
  String get privacyP4Title => '4. Data Storage & Security';

  @override
  String get privacyP4Body =>
      'Your cycle and health data is stored locally on your device by default. Optional Health Connect records are managed by Android\'s on-device store; Lune accesses them only during manual foreground sync, and imported snapshots remain in encrypted local storage. If you enable Premium cloud backup, the encrypted backup payload is stored in Firebase, with Health Connect snapshots excluded. Encryption keys stay in your device\'s secure storage (Android Keystore / iOS Keychain).';

  @override
  String get privacyP5Title => '5. Third-Party Services';

  @override
  String get privacyP5Body =>
      'We use the following third-party services:\n\n• Google Firebase (Authentication, Firestore, Cloud Functions, Cloud Messaging, Hosting, App Check, Crashlytics): Accounts, data storage, push notifications, security, and crash reporting.\n• Google Health Connect: Optional Android on-device health data exchange. Access is off by default, split into permission groups, and Lune does not request background health-data access.\n• Google Gemini AI: AI chat and content processing. Messages are sent to Google for processing per Google\'s API terms.\n• DeepSeek AI: Alternative AI provider for chat and analysis when used by our backend. Messages are sent to DeepSeek for processing per their API terms.\n• Google Play Billing: Premium subscription payments on Android (processed by Google).\n\nEach provider has its own privacy policy. We encourage you to review them. We do not sell your personal data.';

  @override
  String get privacyP6Title => '6. Your Data Rights';

  @override
  String get privacyP6Body =>
      'You have the right to:\n\n• Access your data: View all data stored about you within the app.\n• Export your data: Download your cycle data as a local backup file.\n• Delete your data: Delete your account and all associated data permanently from the Privacy Center.\n• Revoke consent: Withdraw consent for cloud sync, AI features, or community participation at any time.\n• Opt out of notifications: Disable any notification type from settings.\n\nIf you are in the EU/UK, you may also have rights under GDPR/UK GDPR. To exercise these rights, use the in-app Privacy Center or contact us at the email below.';

  @override
  String get privacyP7Title => '7. Children\'s Privacy';

  @override
  String get privacyP7Body =>
      'Lune is not intended for children under 13 years of age (or the applicable age of consent in your jurisdiction). We do not knowingly collect personal information from children. If we discover that a child has provided us with personal data, we will delete it promptly. Parents or guardians who believe a child has used Lune should contact us immediately.';

  @override
  String get privacyP8Title => '8. Data Retention';

  @override
  String get privacyP8Body =>
      'We retain your data for as long as you maintain an active account or as needed to provide services. If you delete your account, we immediately remove your Firestore profile, cloud backups, chat history, and community content from our servers and delete your Firebase Authentication account. Local data on your device remains until you uninstall the app or manually delete it. Technical backups at Firebase or Google Cloud may be retained briefly per their infrastructure policies. Crash reports in Crashlytics are retained according to Firebase\'s retention settings.';

  @override
  String get privacyP9Title => '9. International Data Transfers';

  @override
  String get privacyP9Body =>
      'Your data may be processed in countries other than your own, including the United States where Google Firebase and AI provider servers may be located. By using Lune, you consent to the transfer of your data to these locations. We ensure appropriate safeguards are in place for international transfers. If you are in the EU/UK, you may have additional rights under GDPR/UK GDPR as described in section 6.';

  @override
  String get privacyP10Title => '10. Medical Disclaimer';

  @override
  String get privacyP10Body =>
      'Lune is designed for informational and wellness tracking purposes only. It is not a medical device and does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional for medical concerns. Do not rely solely on Lune\'s predictions or AI-generated content for health decisions.';

  @override
  String get privacyP11Title => '11. Changes to This Policy';

  @override
  String get privacyP11Body =>
      'We may update this Privacy Policy from time to time. We will notify you of significant changes through in-app notifications or email. Your continued use of Lune after changes constitutes acceptance of the updated policy. We encourage you to review this policy periodically.';

  @override
  String get privacyP12Title => '12. Contact Us';

  @override
  String get privacyP12Body =>
      'For questions, concerns, or data requests related to this Privacy Policy, please contact us at:';

  @override
  String get termsTitle => 'Terms of Service';

  @override
  String get termsP1Title => '1. Acceptance of Terms';

  @override
  String get termsP1Body =>
      'By downloading, installing, or using Lune (the \"App\"), you agree to be bound by these Terms of Service (\"Terms\"). If you do not agree to these Terms, do not use the App. These Terms constitute a legally binding agreement between you and Lune.';

  @override
  String get termsP2Title => '2. Description of Service';

  @override
  String get termsP2Body =>
      'Lune is a menstrual cycle tracking application that provides:\n\n• Cycle logging and prediction tools.\n• AI-powered wellness insights and chat assistance (educational only, not medical advice).\n• Self-care content and wellness recommendations.\n• Community features for sharing experiences.\n• Data backup and synchronization services.\n• Educational wellness content and magazine articles.\n\nThe App is intended for personal, non-commercial use only.';

  @override
  String get termsP3Title => '3. User Accounts';

  @override
  String get termsP3Body =>
      'You may use Lune as a guest with an anonymous device-based account, or create a registered account using email/password, Google Sign-In, or Sign in with Apple (where available). You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account. You must be at least 13 years old to use the App. We reserve the right to suspend or terminate accounts that violate these Terms.';

  @override
  String get termsP4Title => '4. User Conduct';

  @override
  String get termsP4Body =>
      'You agree NOT to:\n\n• Use the App for any unlawful purpose.\n• Post harmful, abusive, or misleading content in community features.\n• Impersonate another person or entity.\n• Attempt to access other users\' accounts or data.\n• Upload viruses or malicious code.\n• Scrape, reverse-engineer, or decompile the App.\n• Use automated tools to interact with the App.\n• Spam or harass other community members.\n\nViolation of these rules may result in immediate account termination.';

  @override
  String get termsP5Title => '5. Community Features';

  @override
  String get termsP5Body =>
      'Lune offers optional community features where users can share posts, comments, and stories. By posting content, you grant Lune a non-exclusive, royalty-free license to display, distribute, and store your content within the App. You retain ownership of your content. We reserve the right to remove content that violates these Terms or is reported by other users. You may block other users and manage your community privacy settings at any time.';

  @override
  String get termsP6Title => '6. Subscriptions & Payments';

  @override
  String get termsP6Body =>
      'Lune offers premium features through in-app subscriptions processed via Google Play Billing. Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage subscriptions through your Google Play account settings. Refunds are handled according to Google Play\'s refund policy. Free features remain available without a subscription.';

  @override
  String get termsP7Title => '7. Intellectual Property';

  @override
  String get termsP7Body =>
      'The App, including its design, code, graphics, logos, and content, is the intellectual property of Lune and is protected by copyright, trademark, and other laws. You may not copy, modify, distribute, or create derivative works based on the App without our express written permission. The Lune name, logo, and related marks are trademarks of Lune.';

  @override
  String get termsP8Title => '8. Disclaimer of Warranties';

  @override
  String get termsP8Body =>
      'THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE. THE APP IS NOT A MEDICAL DEVICE AND SHOULD NOT BE USED AS A SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE, DIAGNOSIS, OR TREATMENT. CYCLE PREDICTIONS ARE ESTIMATES AND MAY NOT BE ACCURATE.';

  @override
  String get termsP9Title => '9. Limitation of Liability';

  @override
  String get termsP9Body =>
      'TO THE MAXIMUM EXTENT PERMITTED BY LAW, LUNE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APP. OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE 12 MONTHS PRECEDING THE CLAIM. THIS LIMITATION APPLIES REGARDLESS OF THE LEGAL THEORY.';

  @override
  String get termsP10Title => '10. Termination';

  @override
  String get termsP10Body =>
      'You may stop using the App at any time and delete your account through the Privacy Center. We may suspend or terminate your access if you violate these Terms or engage in harmful behavior. Upon termination, your right to use the App ceases immediately. Sections regarding intellectual property, disclaimers, and liability limitations survive termination.';

  @override
  String get termsP11Title => '11. Governing Law & Contact';

  @override
  String get termsP11Body =>
      'These Terms are governed by the laws applicable in the jurisdiction of the Lune operator, except where mandatory consumer protection laws in your country of residence provide otherwise. Disputes shall first be resolved through good-faith negotiation. If you have questions about these Terms, contact us at:';

  @override
  String get notifRationaleTitle => 'Stay on Track';

  @override
  String get notifRationaleBody =>
      'Lune can send you gentle reminders about your upcoming period, ovulation, and daily check-ins. You can customize or turn off notifications anytime in Settings.';

  @override
  String get notifRationaleAllow => 'Allow Notifications';

  @override
  String get notifRationaleSkip => 'Not Now';

  @override
  String get notifOsDisabledBanner =>
      'Notifications are turned off for Lune in system settings. Reminders will not appear until you enable them.';

  @override
  String get notifRequestPermission => 'Allow notifications';

  @override
  String get notifExactAlarmsHint =>
      'For on-time reminders, allow Alarms & reminders for Lune in Android settings.';

  @override
  String get notifEnableExactAlarms => 'Enable precise alarms';

  @override
  String notifScheduledCount(int count) {
    return '$count reminders scheduled';
  }

  @override
  String get notifNoScheduled =>
      'No reminders scheduled yet. Allow notifications and log your cycle.';

  @override
  String get notifTestExactAlarmsHint =>
      'Test sent, but precise alarms are off — reminders may be delayed.';

  @override
  String notifNextReminder(String when) {
    return 'Next reminder: $when';
  }

  @override
  String get ovulationLogTitle => 'Fertility signals';

  @override
  String get ovulationLogToday => 'Ovulated today';

  @override
  String get ovulationLogLhPositive => 'LH test positive';

  @override
  String get ovulationLogPickDate => 'Pick another date';

  @override
  String get ovulationLogSaved => 'Saved — predictions will adjust';

  @override
  String get ovulationCalibratedHint => 'Calibrated from your log';

  @override
  String get predictionWindowHint =>
      'Estimate — the more you log, the narrower the window gets';

  @override
  String predictionCenterDate(String date) {
    return 'Best guess: $date';
  }

  @override
  String get predictionConfidenceLabel => 'Prediction confidence';

  @override
  String get predictionConfidenceLearning => 'Still learning';

  @override
  String get predictionConfidenceModerate => 'Moderate';

  @override
  String get predictionConfidenceStrong => 'Strong';

  @override
  String predictionAccuracyPersonal(int within, int total) {
    return 'Within 2 days for $within of your last $total testable cycles';
  }

  @override
  String get predictionAccuracyLearning =>
      'Complete 4 cycles to see your personal accuracy';

  @override
  String get predictionWindowActive =>
      'You are currently inside the expected period window';

  @override
  String periodPredictionLate(int days) {
    return '$days days past the end of your expected window';
  }

  @override
  String get predictionPossibleMissingLog =>
      'This may be a longer cycle, or a period log may be missing. Review your calendar before relying on the next estimate.';

  @override
  String get predictionEvidenceNote =>
      'Personal range based on your history — an estimate, not a medical guarantee';

  @override
  String get ovulationEstimateHint =>
      'Current-cycle estimate — do not use it alone for contraception';

  @override
  String get ageGateTitle => 'How old are you?';

  @override
  String get ageGateBody =>
      'Lune is designed for users aged 13 and older. Some features like community discussions are restricted to users 18+.';

  @override
  String get ageGateUnder13 => 'Under 13';

  @override
  String get ageGate13to17 => '13 – 17';

  @override
  String get ageGate18plus => '18 or older';

  @override
  String get ageGateUnder13Message =>
      'We\'re sorry, but Lune is not available for users under 13. Please ask a parent or guardian for help.';

  @override
  String get ageGateMinorNote =>
      'Some features like community discussions are restricted to users 18+.';

  @override
  String get adminActive => 'Active';

  @override
  String get adminSearch => 'Search';

  @override
  String get adminSearchHint => 'Search by email or UID...';

  @override
  String get adminSearchUsers => 'Search users by email or UID';

  @override
  String get adminNoUsers => 'No users found';

  @override
  String get adminBanReporter => 'Ban reporter';

  @override
  String get adminFailedSave => 'Failed to save settings';

  @override
  String get adminError => 'Error';

  @override
  String get adminQuestionRejected => 'Question rejected';

  @override
  String get adminPublishAnswer => 'Publish Answer';

  @override
  String get adminReject => 'Reject';

  @override
  String get adminExpertAnswerHint => 'Type expert answer...';

  @override
  String get adminNotifTitle => 'Notification Title';

  @override
  String get adminNotifBody => 'Notification Body';

  @override
  String get adminTitleEnglish => 'Title (English)';

  @override
  String get adminTitleArabic => 'Title (Arabic)';

  @override
  String get adminBodyEnglish => 'Body (English)';

  @override
  String get adminBodyArabic => 'Body (Arabic)';

  @override
  String get stealthSetPin => 'Set Stealth PIN';

  @override
  String get stealthPinHint =>
      'Enter a 4-6 digit PIN to unlock the real app from the calculator.';

  @override
  String get stealthPin => 'PIN';

  @override
  String get stealthConfirmPin => 'Confirm PIN';

  @override
  String get stealthCancel => 'Cancel';

  @override
  String get stealthSave => 'Save';

  @override
  String get stealthPinMismatch => 'PINs must match and be at least 4 digits';

  @override
  String get stealthEnable => 'Enable Stealth Mode';

  @override
  String get stealthActivated =>
      'Stealth mode enabled! Restart the app to activate.';

  @override
  String get premiumActivated => 'Premium activated!';

  @override
  String get gotIt => 'Got it';

  @override
  String get accountWatchAppleSubtitle => 'Apple Watch support';

  @override
  String get accountWatchWearSubtitle => 'Wear OS support';

  @override
  String get insightHeadlineFirstTrimester => 'First trimester';

  @override
  String get insightBodyFirstTrimester =>
      'Gentle movement, hydration, and rest are your best friends this week.';

  @override
  String get insightHeadlineSecondTrimester => 'Second trimester';

  @override
  String get insightBodySecondTrimester =>
      'Energy usually picks up here — great time for light walks and stretching.';

  @override
  String get insightHeadlineThirdTrimester => 'Third trimester';

  @override
  String get insightBodyThirdTrimester =>
      'Rest often, hydrate, and reach out to your provider with any concerns.';

  @override
  String get insightHeadlinePeriodDay => 'Period day';

  @override
  String get insightBodyPeriodDay =>
      'Warm drinks + magnesium-rich foods can ease cramps. Be gentle with yourself today.';

  @override
  String get insightHeadlineFollicular => 'Follicular phase';

  @override
  String get insightBodyFollicular =>
      'Energy tends to climb — try a new workout or tackle a tough task today.';

  @override
  String get insightHeadlineOvulation => 'Ovulation';

  @override
  String get insightBodyOvulation =>
      'Peak energy + confidence. Good day for a hard workout or a social plan.';

  @override
  String get insightHeadlineLuteal => 'Luteal phase';

  @override
  String get insightBodyLutealEarly =>
      'Luteal phase — crave calm: less caffeine, more rest, gentle movement.';

  @override
  String get insightBodyLutealLate =>
      'Luteal week — complex carbs + earlier bedtime can really help mood right now.';

  @override
  String get insightHeadlineLatePeriod => 'Cycle is running late';

  @override
  String get insightBodyLatePeriod =>
      'Stress or sleep changes can shift things. Give it 2-3 days — log any symptoms.';

  @override
  String get insightHeadlineWelcome => 'Welcome 🌸';

  @override
  String get insightBodyWelcome =>
      'Set your last period date to unlock personalised daily insights.';

  @override
  String get smartWatch => 'Smart Watch';

  @override
  String get anonymousQa => 'Anonymous Q&A';

  @override
  String get anonymousQaDesc => 'Ask health questions privately';

  @override
  String get accountWatchSheetTitle => 'Smart Watch Sync';

  @override
  String get accountWatchSheetBody =>
      'Your cycle data is automatically synced to your paired smart watch. You can view your cycle progress and log your period directly from your watch.';

  @override
  String get accountWatchFeatureSync => 'Auto-syncs cycle data to watch';

  @override
  String get accountWatchFeatureRing => 'Cycle ring on watch face';

  @override
  String get accountWatchFeatureLog => 'Log period from watch';

  @override
  String get accountWatchFeaturePhase => 'Current phase display';

  @override
  String get watchSyncNow => 'Sync now';

  @override
  String get watchSyncSuccess => 'Watch data synced successfully!';

  @override
  String get watchSyncFailed => 'Sync failed: make sure your watch is paired.';

  @override
  String get dateFormatDDMMYYYY => 'DD/MM/YYYY';

  @override
  String get dateFormatMMDDYYYY => 'MM/DD/YYYY';

  @override
  String get dateFormatYYYYMMDD => 'YYYY/MM/DD';

  @override
  String get fileTooLarge => 'File too large (max 15 MB)';

  @override
  String get healthQuestionHint => 'Type your health question here...';

  @override
  String get geminiKeyHint => 'Paste your API key here';

  @override
  String get appLockTitle => 'App Lock';

  @override
  String get appLockDescription =>
      'Require your fingerprint or device passcode every time Lune opens.';

  @override
  String get appLockEnable => 'Unlock with fingerprint';

  @override
  String get appLockConfirmReason => 'Confirm it\'s you to change App Lock';

  @override
  String get appLockUnavailable =>
      'No fingerprint or screen lock is set up on this device.';

  @override
  String get appLockActivated =>
      'App Lock is on — Lune will ask for your fingerprint when it opens.';

  @override
  String get stealthTitle => 'Stealth Mode';

  @override
  String get stealthDescription =>
      'Disguise the app as a calculator. Enter your secret PIN then press = to unlock.';

  @override
  String get stealthUnlockHint =>
      'To unlock: open the calculator, type your PIN, then press =';

  @override
  String get stealthHideNow => 'Hide app now';

  @override
  String get stealthHideNowHint =>
      'Instantly switch to the calculator disguise.';

  @override
  String get anonymousQaTooltip => 'Anonymous Q&A';

  @override
  String get anonymousQaTitle => 'Anonymous Health Q&A';

  @override
  String get anonymousQaIntro =>
      'Ask your health question anonymously. A certified expert will answer it and the answer will be published in the Education section.';

  @override
  String get anonymousQaPurposeTitle => 'What is this page?';

  @override
  String get anonymousQaStep1 =>
      'Write your health question — your name is never shown';

  @override
  String get anonymousQaStep2 =>
      'The Lune team reviews it and prepares an answer';

  @override
  String get anonymousQaStep3 =>
      'The answer is published in Education to help everyone';

  @override
  String get anonymousQaDisclaimer =>
      'For general education only — not medical diagnosis or treatment. For urgent concerns, contact your doctor or emergency services.';

  @override
  String get anonymousQaCategoryLabel => 'Category';

  @override
  String get anonymousQaQuestionLabel => 'Your Question';

  @override
  String get anonymousQaPrivacyNote =>
      'Your identity is 100% anonymous. No name, email, or ID is stored.';

  @override
  String get anonymousQaSubmit => 'Submit Question';

  @override
  String get anonymousQaSubmitting => 'Submitting...';

  @override
  String get anonymousQaSubmitted => 'Your question was submitted. Thank you!';

  @override
  String get anonymousQaTooShort => 'Please write at least 10 characters.';

  @override
  String get anonymousQaError =>
      'Could not submit your question. Please try again.';

  @override
  String get qaCatGeneral => 'General';

  @override
  String get qaCatCycle => 'Cycle & Period';

  @override
  String get qaCatPregnancy => 'Pregnancy';

  @override
  String get qaCatPcos => 'PCOS';

  @override
  String get qaCatContraception => 'Contraception';

  @override
  String get qaCatMental => 'Mental Health';

  @override
  String get qaCatNutrition => 'Nutrition';

  @override
  String get dailyBriefingPrompt => 'Give me my daily briefing for today.';

  @override
  String get accountSectionPremium => 'Premium';

  @override
  String get accountViewPlans => 'View plans and prices';

  @override
  String get accountPremiumThanks =>
      'You\'re a Premium member — thank you for supporting Lune!';

  @override
  String get accountManageSubscription => 'Manage subscription';

  @override
  String get accountManageSubscriptionHint => 'Opens Google Play subscriptions';

  @override
  String get accountSectionInfo => 'Account info';

  @override
  String get accountUsernameTitle => 'Username';

  @override
  String get accountUsernameNotSet => 'Not set — edit your profile to add one';

  @override
  String get accountEmailTitle => 'Email';

  @override
  String get accountEmailVerified => 'Verified';

  @override
  String get accountEmailNotVerified => 'Not verified';

  @override
  String get accountVerificationSent =>
      'Verification email sent. Check your inbox.';

  @override
  String get accountIdTitle => 'Account ID';

  @override
  String get accountMemberSinceTitle => 'Member since';

  @override
  String get accountTypeGuest => 'Guest account';

  @override
  String get accountTypeEmail => 'Email account';

  @override
  String get accountCopied => 'Copied to clipboard';

  @override
  String get accountUsernameLabel => 'Username';

  @override
  String get accountUsernameHint => 'e.g. luna_star';

  @override
  String get accountUsernameInvalid =>
      '3–20 characters: letters, numbers, dot or underscore';

  @override
  String get trustHubTitle => 'Trust & Privacy';

  @override
  String get trustHubSubtitle =>
      'Clear answers about how Lune protects your health data — security, cookies, accessibility, and more.';

  @override
  String get trustHubLink => 'Trust & Privacy Center';

  @override
  String get trustLinkSecurity => 'Security at Lune';

  @override
  String get trustLinkSecuritySub =>
      'Encryption, authentication, and how we protect your data';

  @override
  String get trustLinkBodyData => 'Your Body, Your Data';

  @override
  String get trustLinkBodyDataSub =>
      'You own your cycle data — we never sell it';

  @override
  String get trustLinkDataEnds => 'Your Data Ends With You';

  @override
  String get trustLinkDataEndsSub =>
      'Delete your account and cloud data anytime';

  @override
  String get trustLinkFaq => 'Privacy FAQ';

  @override
  String get trustLinkFaqSub => 'Common questions about privacy at Lune';

  @override
  String get trustLinkCookies => 'Cookie Policy';

  @override
  String get trustLinkCookiesSub =>
      'How we use local storage and website cookies';

  @override
  String get trustLinkIp => 'IP Address Use';

  @override
  String get trustLinkIpSub =>
      'Why we process IP addresses and what we don\'t do';

  @override
  String get trustLinkAccessibility => 'Accessibility';

  @override
  String get trustLinkAccessibilitySub =>
      'Our commitment to an inclusive experience';

  @override
  String get trustSecurityTitle => 'Security at Lune';

  @override
  String get trustSecurityIntro =>
      'Your health data deserves bank-grade care. Security is built into every layer of Lune — not added as an afterthought. This page explains how we protect your cycle logs, account, and optional cloud features in plain language.';

  @override
  String get trustSecurityS1Title => 'Encryption on your device';

  @override
  String get trustSecurityS1Body =>
      'Your cycle database is encrypted locally using AES-256 before it is stored on your phone. Symptom, mood, flow, and wellness entries live inside this protected store. Encryption keys are generated on your device and stored in Android Keystore or iOS Keychain — they never leave your device unprotected.';

  @override
  String get trustSecurityS2Title => 'Encrypted cloud sync (optional, Premium)';

  @override
  String get trustSecurityS2Body =>
      'Cloud backup is optional and requires Premium plus your explicit consent. When enabled, your cycle backup payload is encrypted on the device before upload and stored in your private Firebase account. We do not claim every Firestore profile field uses the same AES-256 scheme — the sensitive cycle payload itself is encrypted before it leaves your phone.';

  @override
  String get trustSecurityS3Title => 'Secure connections & app integrity';

  @override
  String get trustSecurityS3Body =>
      'All network traffic uses TLS encryption. Firebase App Check helps verify genuine app requests. You can sign in with email, Google, Apple, or continue as an anonymous guest — each method is handled through Firebase Authentication with industry-standard protections.';

  @override
  String get trustSecurityS4Title => 'No ads, no data brokers';

  @override
  String get trustSecurityS4Body =>
      'Lune does not show third-party ads and does not sell your personal or health data. We do not share your cycle data with advertisers, data brokers, employers, or insurers. Our revenue comes from optional Premium subscriptions, not from monetizing your health information.';

  @override
  String get trustSecurityS5Title => 'You control optional features';

  @override
  String get trustSecurityS5Body =>
      'AI chat (Google Gemini and DeepSeek), community, push notifications, and cloud sync are optional and require your consent. You can review and change these choices anytime in Privacy Center without affecting core local tracking.';

  @override
  String get trustSecurityS6Title => 'Crash reporting (Firebase Crashlytics)';

  @override
  String get trustSecurityS6Body =>
      'Lune uses Firebase Crashlytics to collect anonymized crash reports and basic diagnostic data when the app fails unexpectedly. This helps us fix bugs quickly. Crash reports do not include your cycle logs, wellness entries, or AI chat content.';

  @override
  String get trustSecurityS7Title => 'Cloud infrastructure';

  @override
  String get trustSecurityS7Body =>
      'Registered accounts, optional cloud backups, community content, and AI chat (for Premium users) run on Google Firebase — including Authentication, Firestore, Cloud Functions, Cloud Messaging, Hosting, App Check, and Crashlytics. Access to your data is restricted by Firebase security rules and your sign-in credentials.';

  @override
  String get trustSecurityS8Title => 'Stealth mode on your device';

  @override
  String get trustSecurityS8Body =>
      'Stealth mode disguises Lune as a calculator until you enter your PIN. This protects privacy on your phone if someone picks it up — it is a local lock only and does not encrypt data differently. You can enable or disable it in Privacy Center.';

  @override
  String get trustSecurityS9Title => 'Payment security';

  @override
  String get trustSecurityS9Body =>
      'Premium subscriptions on Android are processed by Google Play Billing. Lune never sees or stores your card number. Manage or cancel your subscription through your Google Play account settings.';

  @override
  String get trustSecurityS10Title => 'Android app permissions';

  @override
  String get trustSecurityS10Body =>
      'Lune requests only permissions needed for features you use: Internet (sign-in, optional cloud sync, AI, community), Notifications (optional cycle reminders), Google Play Billing (Premium), exact alarms and boot restart (reliable local reminders), and photos/media only when you choose to attach an image or set a profile photo. Android backup for app data is disabled (allowBackup=false) so cycle data is not copied to Google device backup by default.';

  @override
  String get trustCookiesTitle => 'Cookie & Storage Policy';

  @override
  String get trustCookiesIntro =>
      'Lune is a mobile app first. This page explains what is stored on your device, what our website keeps, and what we deliberately do not track. We believe clarity about storage is part of respecting your privacy.';

  @override
  String get trustCookiesS1Title => 'App local storage';

  @override
  String get trustCookiesS1Body =>
      'The Lune app stores your cycle logs, wellness entries, preferences, consent choices, and (if you are a guest) AI chat history on your device using encrypted local databases and secure storage. This is essential for offline tracking and fast daily logging.';

  @override
  String get trustCookiesS2Title => 'Website cookies';

  @override
  String get trustCookiesS2Body =>
      'Our website (lune-7d956.web.app) does not use advertising or tracking cookies. We may use essential technical storage — such as remembering your language choice on legal pages — so you do not have to re-select it every visit.';

  @override
  String get trustCookiesS3Title => 'No ad tracking';

  @override
  String get trustCookiesS3Body =>
      'We do not use third-party ad networks, cross-app trackers, or marketing pixels in the Lune app. Your health data is never used for targeted advertising, audience profiling, or retargeting campaigns.';

  @override
  String get trustCookiesS4Title => 'Managing storage';

  @override
  String get trustCookiesS4Body =>
      'You can clear local app data by uninstalling the app or deleting your account from Privacy Center. Exported backup files you save to your clipboard or elsewhere remain under your control — delete them when you no longer need them.';

  @override
  String get trustCookiesS5Title => 'Push notification tokens';

  @override
  String get trustCookiesS5Body =>
      'If you enable notifications, Firebase Cloud Messaging stores a device token so we can deliver cycle reminders and app updates you asked for. This token is used for delivery only — not for advertising or selling your identity to third parties.';

  @override
  String get trustCookiesS6Title => 'Community cache';

  @override
  String get trustCookiesS6Body =>
      'When you browse communities, posts and images may be cached temporarily on your device for smoother scrolling. This cache is part of normal app performance and is cleared when you uninstall the app or clear app data.';

  @override
  String get trustCookiesS7Title => 'Language & consent preferences';

  @override
  String get trustCookiesS7Body =>
      'Your language choice, Privacy Center consent toggles, and stealth-mode settings are saved locally so the app remembers your preferences between sessions. These settings stay on your device unless you sign in and sync account-level preferences.';

  @override
  String get trustCookiesS8Title => 'What we never store for ads';

  @override
  String get trustCookiesS8Body =>
      'We do not place ad cookies, social pixels, or behavioral tracking SDKs in Lune. We do not build marketing profiles from your cycle data, symptoms, moods, or AI conversations.';

  @override
  String get trustIpTitle => 'How We Use IP Addresses';

  @override
  String get trustIpIntro =>
      'When you use Lune or our website, your IP address may be processed by our infrastructure providers. This page explains why that happens, what we do not do with it, and the choices available to you.';

  @override
  String get trustIpS1Title => 'Why IP addresses are processed';

  @override
  String get trustIpS1Body =>
      'IP addresses help Firebase and our Cloud Functions deliver requests securely, route traffic to the correct server, and keep the service available. Without basic network metadata, cloud apps cannot function reliably.';

  @override
  String get trustIpS2Title => 'What we do not do';

  @override
  String get trustIpS2Body =>
      'We do not sell IP addresses, use them for advertising profiles, or attempt to determine your precise physical location from your IP alone. Your IP is not shared with data brokers or ad networks.';

  @override
  String get trustIpS3Title => 'Retention';

  @override
  String get trustIpS3Body =>
      'IP addresses in server and hosting logs are kept only as long as needed for security, abuse prevention, and troubleshooting. They are then rotated or deleted according to Firebase and Google Cloud retention policies.';

  @override
  String get trustIpS4Title => 'Your choices';

  @override
  String get trustIpS4Body =>
      'Using a VPN is your choice — we do not penalize VPN users. Deleting your account removes your profile and associated cloud content from our servers. For full details, see our Privacy Policy.';

  @override
  String get trustIpS5Title => 'Rate limits & abuse prevention';

  @override
  String get trustIpS5Body =>
      'We apply server-side rate limits on AI chat and community actions to prevent spam and protect all users. IP addresses and authenticated account IDs may be used together to detect abusive patterns — never to profile you for marketing.';

  @override
  String get trustIpS6Title => 'Where data may be processed';

  @override
  String get trustIpS6Body =>
      'Firebase and our AI providers may process requests in the United States and other regions where Google and DeepSeek operate data centers. This is standard for cloud-hosted health apps with optional sync.';

  @override
  String get trustIpS7Title => 'Legal requests';

  @override
  String get trustIpS7Body =>
      'We may disclose information — which could include IP-related server logs — only when required by valid legal process and to the minimum extent the law demands. We do not voluntarily share cycle health data with authorities.';

  @override
  String get trustIpS8Title => 'VPNs and privacy tools';

  @override
  String get trustIpS8Body =>
      'If you use a VPN, your visible IP may differ from your physical region. Lune does not block VPN connections. Some Firebase security checks may still apply to protect accounts from takeover attempts.';

  @override
  String get trustFaqTitle => 'Privacy FAQ';

  @override
  String get trustFaqIntro =>
      'Answers to the questions we hear most about privacy, security, and how Lune handles your cycle data. If you do not find your answer here, contact us anytime.';

  @override
  String get trustFaqQ1 => 'Who can see my cycle data?';

  @override
  String get trustFaqA1 =>
      'Only you. By default, your cycle data stays on your device in an encrypted local database. If you enable Premium cloud backup, encrypted copies are stored in your private Firebase account. We do not share cycle data with other users unless you explicitly post in community features.';

  @override
  String get trustFaqQ2 => 'Does Lune sell my data?';

  @override
  String get trustFaqA2 =>
      'No. We never sell your personal or health data. Lune is funded through optional Premium subscriptions processed by Google Play — not through advertising or data brokerage.';

  @override
  String get trustFaqQ3 => 'What happens when I delete my account?';

  @override
  String get trustFaqA3 =>
      'When you confirm deletion in Privacy Center, we immediately remove your Firestore profile, cloud backups, chat history, and community content from our servers, then delete your Firebase Authentication account. Local data on your device remains until you uninstall the app. Technical backups at Firebase may be retained briefly per their infrastructure policies.';

  @override
  String get trustFaqQ4 => 'Is AI chat private?';

  @override
  String get trustFaqA4 =>
      'AI chat requires Premium. Guest users keep chat on the device only. Registered Premium users may have messages stored in the cloud to restore conversations. Every AI message is sent to Google Gemini and/or DeepSeek for processing — see our Privacy Policy. We recommend not sharing information you would not want a third-party AI provider to process.';

  @override
  String get trustFaqQ5 => 'Can I use Lune without an account?';

  @override
  String get trustFaqA5 =>
      'Yes. You can use Lune as a guest with an anonymous Firebase account linked to your device — no email required. Core cycle tracking works fully offline. Cloud backup, Premium AI, cross-device chat history, and some community features require a registered account.';

  @override
  String get trustFaqQ6 => 'Where is my data stored?';

  @override
  String get trustFaqA6 =>
      'Locally on your phone by default in an AES-256 encrypted database. If you enable Premium cloud backup, encrypted backup payloads are stored in Google Firebase, which may process data in the United States and other regions.';

  @override
  String get trustFaqQ7 => 'How do I export my data?';

  @override
  String get trustFaqA7 =>
      'Open Privacy Center → Export Data to copy an encrypted local backup to your clipboard. You can save it in a password manager or secure notes app. For help with portability requests, email merrsoheb@gmail.com.';

  @override
  String get trustFaqQ8 => 'How do I contact you about privacy?';

  @override
  String get trustFaqA8 =>
      'Email merrsoheb@gmail.com or use Contact Support in Privacy Center. We aim to respond to privacy requests within 30 days.';

  @override
  String get trustFaqQ9 => 'Is AI chat free?';

  @override
  String get trustFaqA9 =>
      'No. Lune AI is a Premium feature. Premium subscribers can send up to 30 AI messages per calendar day — enforced on our servers. If a provider fails, we do not count that message against your limit.';

  @override
  String get trustFaqQ10 => 'What does Premium unlock?';

  @override
  String get trustFaqA10 =>
      'Premium includes cloud cycle backup, Lune AI chat (30 messages/day), and attaching photos or videos in community posts and stories. Core local tracking remains free for all users.';

  @override
  String get trustFaqQ11 => 'How does Stealth mode work?';

  @override
  String get trustFaqA11 =>
      'Stealth mode shows a calculator screen instead of Lune until you enter your secret PIN and press equals. It protects your privacy if someone opens your phone. It is a local disguise only — enable it in Privacy Center.';

  @override
  String get trustFaqQ12 => 'Who sees my community posts?';

  @override
  String get trustFaqA12 =>
      'Posts are visible to members of the Lune communities you join. You can report unsafe content; reported posts may be auto-hidden while we review them. Community participation is optional and requires consent.';

  @override
  String get trustFaqQ13 => 'Can I share a health report with my doctor?';

  @override
  String get trustFaqA13 =>
      'Yes. Lune can generate a health summary report from your logged data that you can review and share yourself. We do not send reports to doctors automatically — you choose what to share and with whom.';

  @override
  String get trustFaqQ14 => 'Does the magazine use my personal data?';

  @override
  String get trustFaqA14 =>
      'No. Educational articles in the Lune magazine are editorial content managed separately from your private cycle logs. Reading articles does not upload your personal health data for personalization.';

  @override
  String get trustFaqQ15 => 'What notifications does Lune send?';

  @override
  String get trustFaqA15 =>
      'If you opt in, we may send cycle reminders, wellness prompts, and important app updates via Firebase Cloud Messaging. We do not send promotional ads or sell notification audiences to third parties. You can disable notifications in device settings.';

  @override
  String get trustFaqQ16 => 'What are my GDPR rights?';

  @override
  String get trustFaqA16 =>
      'If you are in the EEA or UK, you may request access, correction, deletion, or export of your personal data. Delete your account in Privacy Center for immediate server removal, or email merrsoheb@gmail.com for assistance. We respond within 30 days.';

  @override
  String get trustFaqQ17 => 'What Android permissions does Lune use?';

  @override
  String get trustFaqA17 =>
      'Internet for sign-in and optional online features; Notifications for reminders you enable; Google Play Billing for Premium; exact alarms and boot restart for reliable local reminders. Photos or videos are requested only when you attach media in community (Premium) or choose a profile photo. We do not access your contacts, SMS, or call logs.';

  @override
  String get trustFaqQ18 => 'How do Google Play subscriptions work?';

  @override
  String get trustFaqA18 =>
      'Premium is billed through Google Play. Subscriptions auto-renew unless you cancel at least 24 hours before the period ends. Manage or cancel in Google Play → Subscriptions. Refunds follow Google Play\'s refund policy. Deleting your Lune account does not automatically stop billing — cancel the subscription separately.';

  @override
  String get trustFaqQ19 => 'What is the minimum age to use Lune?';

  @override
  String get trustFaqA19 =>
      'You must be at least 13 years old. Users under 13 cannot continue after the age gate. Some community features are restricted to users 18 and older. Parents who believe a child under 13 used Lune should contact us to request deletion.';

  @override
  String get trustFaqQ20 => 'Is Lune a medical device or medical advice?';

  @override
  String get trustFaqA20 =>
      'No. Lune is for informational wellness tracking only — not a medical device, diagnosis, or treatment. Cycle predictions, AI chat, community posts, and magazine articles are not medical advice. Always consult a qualified healthcare professional for medical decisions.';

  @override
  String get trustFaqQ21 =>
      'What data does Lune collect (Google Play Data Safety)?';

  @override
  String get trustFaqA21 =>
      'Data you provide: cycle dates, symptoms, moods, wellness notes, and optional community posts. Account data if registered (email, name, sign-in method). Technical data: device tokens for notifications, anonymized crash reports, and approximate activity timestamps. Premium AI messages are sent to Google Gemini/DeepSeek for processing. Data is not sold. Core tracking stays on your device unless you enable Premium cloud backup.';

  @override
  String get trustBodyDataTitle => 'Your Body, Your Data';

  @override
  String get trustBodyDataIntro =>
      'Your menstrual and wellness data is deeply personal. At Lune, you are in control — always. This page explains what you log, who owns it, and how optional features use it.';

  @override
  String get trustBodyDataS1Title => 'Ownership';

  @override
  String get trustBodyDataS1Body =>
      'You own the cycle, symptom, mood, flow, water intake, and wellness data you log. Lune is a tool to help you understand your body — not a platform that monetizes your health information or sells insights about you.';

  @override
  String get trustBodyDataS2Title => 'Local-first design';

  @override
  String get trustBodyDataS2Body =>
      'The app works fully offline. Your daily logs are written to an encrypted database on your device first. Nothing leaves your phone unless you choose cloud backup, AI chat, community, or other features that require a network connection.';

  @override
  String get trustBodyDataS3Title => 'Explicit consent';

  @override
  String get trustBodyDataS3Body =>
      'Cloud backup, AI features, community participation, and push notifications each require separate consent in Privacy Center. You can enable or disable them individually without losing your local cycle history.';

  @override
  String get trustBodyDataS4Title => 'No hidden sharing';

  @override
  String get trustBodyDataS4Body =>
      'We do not share your cycle data with employers, insurers, advertisers, or external social networks. Community posts and stories are visible only within Lune communities you choose to join.';

  @override
  String get trustBodyDataS5Title => 'What you can log';

  @override
  String get trustBodyDataS5Body =>
      'Lune lets you track periods, symptoms, moods, pain levels, water intake, and other wellness notes you choose to record. You decide how much detail to add each day. None of this is required beyond what you need for your own understanding.';

  @override
  String get trustBodyDataS6Title => 'How AI uses your cycle context';

  @override
  String get trustBodyDataS6Body =>
      'When you use Lune AI (Premium), relevant cycle context you approve may be sent to our servers and then to Google Gemini or DeepSeek to personalize responses. AI is optional — you can track your cycle without ever opening chat.';

  @override
  String get trustBodyDataS7Title => 'Magazine & education';

  @override
  String get trustBodyDataS7Body =>
      'Articles in the Lune magazine are general health education content. They are separate from your private logs and are not generated from your personal cycle data. Editors publish articles through our admin tools — not by reading your diary.';

  @override
  String get trustBodyDataS8Title => 'Portability';

  @override
  String get trustBodyDataS8Body =>
      'You can export an encrypted backup from Privacy Center at any time. Your data belongs to you — if you leave Lune, you can take a copy with you before deleting your account.';

  @override
  String get trustDataEndsTitle => 'Your Data Ends With You';

  @override
  String get trustDataEndsIntro =>
      'When you decide to leave Lune, your data should leave too. This page walks through every step — server deletion, local files, subscriptions, and what cannot be undone.';

  @override
  String get trustDataEndsS1Title => 'Delete anytime';

  @override
  String get trustDataEndsS1Body =>
      'You can delete your account from Privacy Center at any time. No phone calls, no dark patterns — just a clear confirmation step. Guest users can clear local data by uninstalling the app.';

  @override
  String get trustDataEndsS2Title => 'Immediate server deletion';

  @override
  String get trustDataEndsS2Body =>
      'When you confirm account deletion, our servers immediately remove your Firestore profile, cloud cycle backups, chat history, and community posts, then delete your Firebase Authentication account. This is not a 30-day waiting period — deletion starts right away.';

  @override
  String get trustDataEndsS3Title => 'Local data';

  @override
  String get trustDataEndsS3Body =>
      'Data on your device is not automatically erased when you delete your cloud account. Uninstall the app or use your phone\'s app settings to remove remaining local encrypted databases and preferences.';

  @override
  String get trustDataEndsS4Title => 'Backups you exported';

  @override
  String get trustDataEndsS4Body =>
      'If you exported a backup file to your clipboard or saved it elsewhere, that copy is outside our control. Delete those files if you no longer need them — we cannot reach into your notes app or cloud drive.';

  @override
  String get trustDataEndsS5Title => 'Permanent action';

  @override
  String get trustDataEndsS5Body =>
      'Account deletion cannot be undone. If you return to Lune later, you start fresh unless you restore from a local backup you saved before deleting.';

  @override
  String get trustDataEndsS6Title => 'Guest vs registered accounts';

  @override
  String get trustDataEndsS6Body =>
      'Guest accounts exist mainly on your device with a lightweight anonymous Firebase identity. Deleting a registered account triggers full server cleanup. Guests should uninstall the app to remove all local traces.';

  @override
  String get trustDataEndsS7Title => 'Premium subscriptions';

  @override
  String get trustDataEndsS7Body =>
      'Deleting your Lune account does not automatically cancel a Google Play subscription. Open Google Play → Subscriptions to cancel Premium billing separately so you are not charged after leaving.';

  @override
  String get trustDataEndsS8Title => 'Community content removal';

  @override
  String get trustDataEndsS8Body =>
      'When you delete your account, we remove your posts, comments, and stories from Lune communities through automated server cleanup. Remaining copies in other users\' caches disappear as they refresh or reinstall.';

  @override
  String get trustA11yTitle => 'Accessibility at Lune';

  @override
  String get trustA11yIntro =>
      'We believe everyone deserves access to cycle health tools — regardless of language, vision, or motor ability. Accessibility is an ongoing commitment, not a one-time feature.';

  @override
  String get trustA11yS1Title => 'Our commitment';

  @override
  String get trustA11yS1Body =>
      'We design Lune to be usable with screen readers, system font scaling, and both left-to-right and right-to-left layouts. Arabic and English receive equal attention in navigation, labels, and reading direction.';

  @override
  String get trustA11yS2Title => 'In-app features';

  @override
  String get trustA11yS2Body =>
      'Lune respects your device\'s text size, bold text, and contrast settings where supported by Flutter and your operating system. Navigation uses standard Material patterns for predictable screen-reader behavior across tabs and forms.';

  @override
  String get trustA11yS3Title => 'Request accommodations';

  @override
  String get trustA11yS3Body =>
      'If you encounter a barrier while using Lune, email merrsoheb@gmail.com with a description of the issue, your device model, and your preferred language. We take accessibility feedback seriously and prioritize fixes that block core tracking.';

  @override
  String get trustA11yS4Title => 'Ongoing improvements';

  @override
  String get trustA11yS4Body =>
      'We review new features for color contrast, touch target size, and screen reader labels before release. Past releases have improved RTL layouts, larger tap areas, and clearer error messages — and more improvements are planned.';

  @override
  String get trustA11yS5Title => 'Arabic & English parity';

  @override
  String get trustA11yS5Body =>
      'Switching between Arabic and English flips the entire interface direction — menus, cards, and legal pages included. You should not need to fight the layout to read content in your language.';

  @override
  String get trustA11yS6Title => 'Themes & system settings';

  @override
  String get trustA11yS6Body =>
      'Lune follows your device theme where possible and uses readable typography across light backgrounds. If system high-contrast mode is enabled, OS-level settings may further improve readability.';

  @override
  String get trustA11yS7Title => 'Roadmap';

  @override
  String get trustA11yS7Body =>
      'We are working toward broader WCAG-aligned improvements — including richer screen reader descriptions for charts, keyboard navigation enhancements, and user-tested contrast audits. Tell us what matters most to you.';
}
