// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Lune';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLog => 'التسجيل';

  @override
  String get navInsights => 'التحليلات';

  @override
  String get navWellness => 'العناية';

  @override
  String get navCommunity => 'المجتمع';

  @override
  String get navAi => 'Lune AI';

  @override
  String get navAccount => 'الحساب';

  @override
  String get welcomeTitle => 'دورتكِ لها أطوار — كالقمر';

  @override
  String get welcomeSubtitle =>
      'بياناتك محلية. السحابة والذكاء الاصطناعي اختيارية ومشفّرة.';

  @override
  String get welcomeHubTitle => 'أهلاً بكِ في Lune';

  @override
  String get welcomeHubSubtitle =>
      'ابدئي بخصوصية باسمك فقط، أو سجّلي دخولك بإيميلك إن كان لديك حساب سابق.';

  @override
  String get welcomeNewUser => 'مستخدمة جديدة — إعداد خاص';

  @override
  String get welcomeHaveAccount => 'عندي حساب';

  @override
  String get welcomeCreateEmailAccount => 'إنشاء حساب بإيميل';

  @override
  String get accountLinkEmail => 'ربط الإيميل بالحساب';

  @override
  String get accountEmailNotLinked => 'لم يُربط إيميل بعد';

  @override
  String get getStarted => 'ابدئي الآن';

  @override
  String get cycleLength => 'طول الدورة (أيام)';

  @override
  String get periodDuration => 'مدة الحيض (أيام)';

  @override
  String get lastPeriodDate => 'تاريخ بداية آخر دورة';

  @override
  String get continueBtn => 'متابعة';

  @override
  String get loginTitle => 'تسجيل الدخول للميزات السحابية';

  @override
  String get loginSubtitle => 'اختياري — بياناتك تبقى على جهازك افتراضياً';

  @override
  String get registerTitle => 'إنشاء حسابك';

  @override
  String get registerSubtitle =>
      'أنشئي حسابكِ بالإيميل أو Google — بياناتكِ تبقى على جهازكِ افتراضياً';

  @override
  String get forgotPasswordTitle => 'إعادة تعيين كلمة المرور';

  @override
  String get forgotPasswordHint => 'أدخلي بريدك وسنرسل رابط إعادة التعيين.';

  @override
  String get resetPassword => 'إرسال رابط';

  @override
  String get resetSent => 'تم إرسال بريد إعادة التعيين.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get registerFieldsRequired => 'أدخلي البريد وكلمة المرور.';

  @override
  String get authPrivacyRequired =>
      'وافقي على سياسة الخصوصية وشروط الاستخدام للمتابعة.';

  @override
  String get authErrorInvalidCredentials => 'البريد أو كلمة المرور غير صحيحة.';

  @override
  String get authErrorUserNotFound => 'لا يوجد حساب بهذا البريد.';

  @override
  String get authErrorEmailInUse => 'هذا البريد مسجّل مسبقاً.';

  @override
  String get authErrorWeakPassword =>
      'كلمة المرور يجب أن تكون 6 أحرف على الأقل.';

  @override
  String get authErrorTooManyRequests => 'محاولات كثيرة. حاولي لاحقاً.';

  @override
  String get authErrorNetwork => 'خطأ في الشبكة. تحققي من الاتصال.';

  @override
  String get authErrorCancelled => 'تم إلغاء تسجيل الدخول.';

  @override
  String get authErrorGoogleConfig =>
      'تسجيل الدخول عبر Google غير مضبوط في هذه النسخة. ثبّتي آخر إصدار من التطبيق.';

  @override
  String get consentDataPurged => 'تم حذف البيانات السحابية لهذه الميزة.';

  @override
  String get consentRevokeTitle => 'إيقاف هذه الميزة؟';

  @override
  String get consentRevokeBody =>
      'سيتم سحب موافقتك وحذف البيانات السحابية لهذه الميزة من خوادمنا. البيانات المحلية على جهازك تبقى.';

  @override
  String get consentRevokeConfirm => 'إيقاف وحذف البيانات السحابية';

  @override
  String get communityBirthYearTooYoung =>
      'المجتمع للبالغين 18+ فقط. اختاري سنة ميلاد أقدم.';

  @override
  String get signIn => 'دخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signInGoogle => 'المتابعة مع Google';

  @override
  String get signInApple => 'المتابعة مع Apple';

  @override
  String get skipLogin => 'المتابعة بدون حساب';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get aiTitle => 'Lune';

  @override
  String get aiSubtitle =>
      'Lune تعني القمر — اسألي عن أطوار دورتكِ وأعراضكِ والعناية الذاتية — ليست نصيحة طبية.';

  @override
  String get aiWelcome => 'مرحباً! أنا Lune — رفيقتكِ لعافية أطوار دورتكِ.';

  @override
  String get aiWelcomeHint =>
      'إجابات مختصرة ومفيدة عن دورتكِ ومزاجكِ والعناية الذاتية.';

  @override
  String get aiSuggestion1 => 'ما الذي يساعد على تقلصات الدورة؟';

  @override
  String get aiSuggestion2 => 'ماذا آكل في مرحلتي الحالية؟';

  @override
  String get aiSuggestion3 => 'كيف تبدو دورتي؟';

  @override
  String get aiAnalyze => 'حلّلي دورتي';

  @override
  String get aiPlaceholder => 'اسألي عن دورتك...';

  @override
  String get aiThinking => 'Lune تفكر...';

  @override
  String get premiumTitle => 'Lune Premium';

  @override
  String get premiumSubtitle => 'تحليل AI متقدم ونسخ احتياطي سحابي';

  @override
  String get premiumFeature1 => 'محادثة Lune وتحليل دورة غير محدود';

  @override
  String get premiumFeature2 => 'نسخ احتياطي سحابي مشفّر';

  @override
  String get premiumFeature3 => 'دعم أولوية';

  @override
  String get premiumPlayHint =>
      'الدفع يتم بأمان عبر Google Play. يمكنكِ إدارة الاشتراك أو إلغاؤه من إعدادات متجر Play في أي وقت.';

  @override
  String get premiumPlayOnly => 'الاشتراك متاح على أندرويد عبر Google Play.';

  @override
  String get premiumProductUnavailable =>
      'المنتج غير متاح حالياً. تأكدي من إعداد الاشتراك في Play Console.';

  @override
  String get restorePurchases => 'استعادة المشتريات';

  @override
  String get restorePurchasesDone => 'تمت مراجعة مشترياتك.';

  @override
  String get restorePurchasesChecking => 'جارٍ التحقق من مشترياتك…';

  @override
  String postpartumRecoveryWeek(int week) {
    return 'التعافي · الأسبوع $week';
  }

  @override
  String get postpartumTodayFocus => 'تركيز اليوم';

  @override
  String get postpartumYourBody => 'جسمكِ في هذه المرحلة';

  @override
  String get postpartumYourBaby => 'طفلكِ في هذه المرحلة';

  @override
  String get postpartumDailyRituals => 'طقوس يومية';

  @override
  String get postpartumWellbeingTitle => 'كيف حالكِ حقاً؟';

  @override
  String get postpartumWellbeingBody =>
      'تقلّبات المزاج في الأسابيع الأولى شائعة. لكن إذا استمر الحزن أو القلق أو الشعور بالفراغ أكثر من أسبوعين، تواصلي مع طبيبتكِ — اكتئاب ما بعد الولادة حقيقي وقابل للعلاج.';

  @override
  String get postpartumSetDateTitle => 'متى وُلد طفلكِ؟';

  @override
  String get postpartumSetDatePrompt =>
      'حدّدي تاريخ ولادة طفلكِ لنرافق تعافيكِ أسبوعاً بأسبوع.';

  @override
  String get postpartumSetDateCta => 'تحديد تاريخ الولادة';

  @override
  String get postpartumBirthDateLabel => 'تاريخ ولادة الطفل';

  @override
  String get conditionWhatToTrack => 'ماذا تتبعين';

  @override
  String get conditionUnderstanding => 'افهمي جسمكِ';

  @override
  String get conditionDailyRituals => 'طقوس يومية';

  @override
  String get conditionWhenToSeeDoctor => 'متى تراجعين الطبيبة';

  @override
  String get goalMenopauseTitle => 'رحلة سنّ الأمل';

  @override
  String get goalPcosTitle => 'إدارة تكيّس المبايض';

  @override
  String get conditionHowAreYouToday => 'كيف حالكِ اليوم؟';

  @override
  String get conditionTapToLog => 'انقري ما تشعرين به — يُحفَظ لليوم.';

  @override
  String conditionLoggedNamed(String name) {
    return 'سُجِّل: $name';
  }

  @override
  String conditionRemovedNamed(String name) {
    return 'أُزيل: $name';
  }

  @override
  String conditionRitualsDoneToday(int done, int total) {
    return 'أنجزتِ $done من $total اليوم';
  }

  @override
  String conditionStreakDays(int days) {
    return '$days يوم متتالٍ من التسجيل';
  }

  @override
  String get menopauseHotFlashesToday => 'الهبّات الساخنة اليوم';

  @override
  String get menopauseHotFlashHint => 'انقري − / + مع كل هبّة';

  @override
  String get menopauseDaysSincePeriodTitle => 'منذ آخر دورة';

  @override
  String conditionDaysCount(int days) {
    return '$days يوم';
  }

  @override
  String get menopauseMilestoneHint => '12 شهراً بلا دورة تُعلن انقطاع الطمث.';

  @override
  String get menopauseMilestoneReached =>
      '12 شهراً بلا دورة — بلغتِ انقطاع الطمث. 🌿';

  @override
  String get menopauseNeedPeriodData => 'سجّلي دورة لبدء عدّ الفجوة.';

  @override
  String get pcosCycleGapTitle => 'فجوة الدورة';

  @override
  String pcosTypicalCycle(int days) {
    return 'دورتكِ المعتادة نحو $days يوماً.';
  }

  @override
  String get pcosGapNormal => 'أنتِ ضمن نطاقكِ المعتاد.';

  @override
  String get pcosGapLong =>
      'أطول من المعتاد — شائع مع التكيّس. استمري بتسجيل كل دورة.';

  @override
  String get pcosGapUnknown => 'سجّلي دورتين لنقارن فجواتكِ.';

  @override
  String get postpartumMoodTitle => 'كيف تشعرين اليوم؟';

  @override
  String get postpartumMoodSaved => 'شكراً لمشاركتكِ 🤍';

  @override
  String get postpartumMoodLowSupport =>
      'لا بأس ألّا تكوني بخير. إن استمر هذا الشعور، تواصلي مع شخص تثقين به أو مع طبيبتكِ.';

  @override
  String get postpartumJourneyTitle => 'رحلة التعافي';

  @override
  String postpartumJourneyCaption(int percent) {
    return 'نحو $percent% من عامكِ الأول.';
  }

  @override
  String get moodVeryLow => 'منخفض جداً';

  @override
  String get moodLow => 'منخفض';

  @override
  String get moodOkay => 'لا بأس';

  @override
  String get moodGood => 'جيد';

  @override
  String get moodGreat => 'رائع';

  @override
  String get activatePremiumTest => 'تفعيل Premium (تجريبي)';

  @override
  String get planYearlyTitle => 'سنوي';

  @override
  String get planMonthlyTitle => 'شهري';

  @override
  String get planPerYear => 'سنوياً';

  @override
  String get planPerMonth => 'شهرياً';

  @override
  String planSaveBadge(int percent) {
    return 'وفّري $percent%';
  }

  @override
  String get communityMediaDisabled =>
      'رفع الصور والفيديو متوقف مؤقتاً لحماية المجتمع.';

  @override
  String get privacyTitle => 'خصوصيتك مهمة';

  @override
  String get privacyBody =>
      'بيانات الدورة مشفّرة على جهازك. المزامنة السحابية والAI تعمل فقط عند تسجيل الدخول والموافقة.';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeSystem => 'النظام';

  @override
  String get premiumActive => 'اشتراك Premium فعّال';

  @override
  String get notPremium => 'الخطة المجانية';

  @override
  String get phaseToday => 'مرحلة اليوم';

  @override
  String get nextPeriod => 'الدورة القادمة';

  @override
  String get send => 'إرسال';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorGeneric => 'حدث خطأ. حاولي مرة أخرى.';

  @override
  String get loginRequiredAi => 'سجّلي الدخول للمحادثة مع مساعدة لُون الذكية';

  @override
  String get authOrEmail => 'أو تابعي بالبريد الإلكتروني';

  @override
  String get authOr => 'أو';

  @override
  String get adminPromoTitle => 'أكواد الهدية';

  @override
  String get adminPromoManageBtn => 'إدارة أكواد الهدية';

  @override
  String get adminPromoCreateHeader => 'إنشاء كود';

  @override
  String get adminPromoCodeHint => 'الكود (مثال LUNE30)';

  @override
  String get adminPromoDaysLabel => 'أيام البريميوم';

  @override
  String get adminPromoMaxUsesLabel => 'أقصى عدد استخدامات';

  @override
  String get adminPromoNoteHint => 'ملاحظة (اختياري)';

  @override
  String get adminPromoCreateBtn => 'إنشاء الكود';

  @override
  String get adminPromoCreatedMsg => 'تم إنشاء الكود';

  @override
  String get adminPromoExistingHeader => 'الأكواد الحالية';

  @override
  String get adminPromoEmpty => 'لا توجد أكواد بعد';

  @override
  String get adminPromoRevokeBtn => 'إلغاء';

  @override
  String get adminPromoRevokedMsg => 'تم إلغاء الكود';

  @override
  String get adminPromoActiveLabel => 'فعّال';

  @override
  String get adminPromoRevokedLabel => 'غير فعّال';

  @override
  String get adminPromoUsedLabel => 'مستخدم';

  @override
  String get adminPromoCodeTooShort => 'الكود يجب أن يكون 3 أحرف على الأقل';

  @override
  String get premiumDaysShort => 'يوم';

  @override
  String get adminRolesTitle => 'المشرفون والمراقبون';

  @override
  String get adminRolesManageBtn => 'إدارة المشرفين';

  @override
  String get adminRolesAddHeader => 'إضافة مشرف';

  @override
  String get adminRolesEmailHint => 'بريد المستخدم';

  @override
  String get adminRolesRoleModerator => 'مراقب';

  @override
  String get adminRolesRoleAdmin => 'مشرف';

  @override
  String get adminRolesRoleOwner => 'مالك';

  @override
  String get adminRolesGrant => 'منح الصلاحية';

  @override
  String get adminRolesGranted => 'تم تحديث الصلاحية';

  @override
  String get adminRolesCurrentHeader => 'المشرفون الحاليون';

  @override
  String get adminRolesEmpty => 'لا يوجد مشرفون بعد';

  @override
  String get adminRolesRemove => 'إزالة';

  @override
  String get adminRolesRemoved => 'تمت إزالة المشرف';

  @override
  String get adminRolesOwnerOnly => 'فقط المالك يمكنه إضافة أو إزالة المشرفين.';

  @override
  String get adminRolesUserNotFound => 'لا يوجد مستخدم بهذا البريد';

  @override
  String get loginRequiredPremium => 'سجّلي الدخول للاشتراك';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsEnable => 'تفعيل التذكيرات';

  @override
  String get periodReminder => 'تذكير الدورة';

  @override
  String get dailyLogReminder => 'تذكير التسجيل اليومي';

  @override
  String get cloudSync => 'نسخ احتياطي سحابي';

  @override
  String get cloudSyncEnable => 'تفعيل النسخ الاحتياطي المشفّر';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncSuccess => 'تمت المزامنة بنجاح.';

  @override
  String get syncFailed => 'فشلت المزامنة. حاولي مرة أخرى.';

  @override
  String get syncNeedsPremium => 'النسخ الاحتياطي السحابي ميزة بريميوم.';

  @override
  String get syncNeedsConsent => 'فعّلي موافقة النسخ السحابي أولاً.';

  @override
  String get syncNotSignedIn =>
      'سجّلي الدخول لاستخدام النسخ الاحتياطي السحابي.';

  @override
  String get syncCycleUnavailable =>
      'بيانات الدورة غير جاهزة بعد. افتحي الرئيسية ثم حاولي مرة أخرى.';

  @override
  String get syncNoBackupFound => 'لا توجد نسخة احتياطية سحابية بعد.';

  @override
  String get localBackupExportSuccess => 'النسخة المحلية جاهزة للمشاركة.';

  @override
  String get localBackupExportFailed => 'تعذر تصدير النسخة الاحتياطية المحلية.';

  @override
  String get localBackupImportFailed => 'تعذر استيراد ملف النسخة الاحتياطية.';

  @override
  String get logSaved => 'تم حفظ السجل!';

  @override
  String get logSavedHint =>
      'البيانات محفوظة على جهازك. ستظهر في «تسجيل اليوم» بالرئيسية، و«تقارير»، و«رؤى».';

  @override
  String get logChangesDiscarded => 'تم إلغاء التغييرات';

  @override
  String get logChangesDiscardedHint =>
      'أُعيد تحميل آخر بيانات محفوظة لهذا اليوم — لم يُحفظ شيء جديد.';

  @override
  String get logSaveFailedHint => 'تأكّدي من الاتصال وحاولي مرة أخرى.';

  @override
  String get homeTodayLogTitle => 'تسجيل اليوم';

  @override
  String get homeTodayLogEmpty =>
      'لم تسجّلي شيئاً اليوم. اضغطي + لتسجيل مشاعركِ وأعراضكِ.';

  @override
  String get homeTodayLogSymptoms => 'المشاعر والأعراض';

  @override
  String homeTodayLogWater(int count) {
    return '$count أكواب ماء';
  }

  @override
  String get homeTodayLogStoredHint =>
      'محفوظ على جهازك — اعرضي التفاصيل في تقارير ← رؤى';

  @override
  String get homeAiChipLabel => 'Lune AI';

  @override
  String get homeAiCardTitle => 'Lune AI';

  @override
  String get homeAiCardTap => 'اضغطي لبدء المحادثة';

  @override
  String get homeAiCardSubtitlePremium =>
      'مساعدتكِ الذكية — حتى 30 رسالة يومياً';

  @override
  String get homeAiCardSubtitlePremiumOnly =>
      'للمشتركات في Premium — اضغطي لعرض الخطط';

  @override
  String get onboardingBirthDateLabel => 'تاريخ الميلاد';

  @override
  String get onboardingBirthDateHint => 'اختاري تاريخ ميلادك';

  @override
  String get onboardingBirthDateRequired => 'يرجى اختيار تاريخ الميلاد';

  @override
  String get subscriptionPlansTitle => 'Lune Premium';

  @override
  String get subscriptionPlansHeadline => 'Lune AI مخصصة لحسابات Premium';

  @override
  String get subscriptionPlansSubtitle =>
      'افتحي المحادثة بلا حدود، تحليل الدورة، النسخ السحابي المشفّر، والدعم ذو الأولوية.';

  @override
  String get subscriptionPlansCta => 'اشتركي عبر Google Play';

  @override
  String get subscriptionPlansAccountHint => 'إدارة الاشتراك من الحساب';

  @override
  String get logTabTitle => 'التسجيل اليومي';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get weeklyCalendar => 'عرض أسبوعي';

  @override
  String get graphsWeight => 'الوزن';

  @override
  String get graphsSleep => 'النوم';

  @override
  String get graphsWater => 'الماء';

  @override
  String get graphsTemperature => 'درجة الحرارة';

  @override
  String get graphsMeditation => 'التأمل';

  @override
  String get haveAccount => 'لديك حساب؟ سجّلي الدخول';

  @override
  String get noAccount => 'ليس لديك حساب؟ أنشئي واحداً';

  @override
  String get geminiKeyLabel => 'مفتاح Gemini (اختياري)';

  @override
  String get communityTitle => 'مجتمعات صغيرة';

  @override
  String get communityLoginRequired => 'سجّلي الدخول لإدارة الحظر والإبلاغ';

  @override
  String get communityPrivacyNote =>
      'سجلات دورتك لا تغادر جهازك. المجتمعات تستخدم اسمًا مستعارًا فقط.';

  @override
  String get communityYourAlias => 'اسمك المستعار';

  @override
  String get communityBrowse => 'تصفّح المجموعات';

  @override
  String get communityRecommendedTitle => 'موصى لك';

  @override
  String get communityJoinedBadge => 'منضمة';

  @override
  String get communityDiscoverNew => 'مجموعات جديدة';

  @override
  String get communityDiscoverJoined => 'مجموعاتك';

  @override
  String get communityDiscoverNoResults =>
      'لا توجد مجموعات مطابقة. جرّبي فئة أخرى أو امسحي البحث.';

  @override
  String get communityClosedBadge => 'مغلقة';

  @override
  String get communityFeedBrowseTitle => 'تصفّحي كل المجموعات';

  @override
  String get communityFeedBrowseSubtitle =>
      'الخلاصة تعرض مجموعاتك فقط — اكتشفي مجتمعات أخرى من هنا.';

  @override
  String get communitySetupTitle => 'اختاري اسمًا مستعارًا';

  @override
  String get communitySetupSubtitle =>
      'استخدمي لقبًا — لا اسمك الحقيقي. بيانات الدورة لا تُشارك أبدًا.';

  @override
  String get communityAliasLabel => 'اللقب';

  @override
  String get communityAliasHint => 'مثال: لونا_92';

  @override
  String get communityJoin => 'انضمام للمجموعة';

  @override
  String get communityLeave => 'مغادرة المجموعة';

  @override
  String get communityJoined => 'انضممتِ للمجموعة';

  @override
  String get communityLeft => 'غادرتِ المجموعة';

  @override
  String get communityNewPost => 'منشور جديد';

  @override
  String get communityPostHint => 'شاركي الدعم أو اسألي سؤالًا...';

  @override
  String get communityPublish => 'نشر';

  @override
  String get communityPostPublished => 'تم نشر المنشور';

  @override
  String get communityModerationFailed => 'لم يُقبل المنشور';

  @override
  String get communityDisclaimer =>
      'دعم جماعي فقط — ليس نصيحة طبية. المنشورات تُراجع بالذكاء الاصطناعي.';

  @override
  String get communityNoPosts => 'لا منشورات بعد. كوني الأولى!';

  @override
  String get communityPostDetail => 'منشور';

  @override
  String get communityComments => 'التعليقات';

  @override
  String get communityNoComments => 'لا تعليقات بعد';

  @override
  String get communityCommentHint => 'اكتبي تعليقًا داعمًا...';

  @override
  String get cancel => 'إلغاء';

  @override
  String get navReports => 'التقارير';

  @override
  String get navAnalysis => 'تحليل';

  @override
  String get accountMenuReports => 'الرسوم البيانية والتقارير';

  @override
  String get accountMenuAi => 'محادثة Lune';

  @override
  String get accountMenuCalendar => 'التنبؤ بالدورة والتقويم';

  @override
  String get accountMenuInsights => 'تحليلات الدورة';

  @override
  String get accountMenuEducation => 'التعليم والإرشاد';

  @override
  String get accountMenuCommunity => 'المجتمع';

  @override
  String get accountMenuReminders => 'التذكيرات';

  @override
  String get accountMenuSettings => 'الإعدادات';

  @override
  String get accountMenuHelp => 'التعليمات والمساعدة';

  @override
  String get homeExplore => 'استكشفي';

  @override
  String get homeUpdatesTitle => 'تحديثات وأخبار';

  @override
  String get homeUpdatesSubtitle => 'إعلانات وعروض';

  @override
  String get homeMoreThisWeek => 'المزيد هذا الأسبوع';

  @override
  String get homeGoalMoreTitle => 'المزيد حسب هدفك';

  @override
  String get homeGoalMoreGeneral => 'إحصائيات، مواعيد، نصائح وتعليم';

  @override
  String get homeGoalMoreConceive => 'خصوبة، نصائح وإرشادات';

  @override
  String get homeGoalMoreAvoid => 'حماية، نصائح وإرشادات';

  @override
  String get homeQuickLog => 'تسجيل';

  @override
  String get homeQuickAi => 'محادثة AI';

  @override
  String get homeQuickCalendar => 'تقويم';

  @override
  String get reportsMoreTitle => 'رسوم وتفاصيل إضافية';

  @override
  String get reportsMoreSubtitle => 'إحصائيات كاملة، سجل الدورة والأنماط';

  @override
  String get reportsChecklistHint => 'قائمة مهام مخصّصة لك';

  @override
  String get reportsHeaderTitle => 'تقاريرك';

  @override
  String get reportsHeaderSubtitle =>
      'نظرة واضحة على دورتكِ، اتجاهاتكِ، وملخّص جاهز للطبيب.';

  @override
  String get reportsQuickActions => 'إجراءات سريعة';

  @override
  String get reportsAnalyticsCardTitle => 'التحليلات الكاملة';

  @override
  String get reportsAnalyticsCardSubtitle =>
      'كل المؤشرات والرسوم والنتائج حسب هدفكِ.';

  @override
  String get reportsPregnancyOverview => 'نظرة على الحمل';

  @override
  String get reportsMenopauseOverview => 'نظرة على سنّ الأمل';

  @override
  String get reportsPcosOverview => 'نظرة على إدارة PCOS';

  @override
  String get reportsRecoveryOverview => 'نظرة على الاستشفاء';

  @override
  String get goalModeGeneralReportStats => 'نظرة على الدورة';

  @override
  String get goalModeConceiveReportStats => 'نظرة على الخصوبة';

  @override
  String get goalModeAvoidReportStats => 'نظرة على الحماية';

  @override
  String get selfCareMoreTitle => 'المزيد — عناية';

  @override
  String get selfCareMoreSubtitle => 'نصائح ذكية، تحديات، طقوس ومركز العناية';

  @override
  String get accountSectionTools => 'أدوات وميزات';

  @override
  String get accountSectionPersonal => 'شخصي';

  @override
  String get accountSectionSupport => 'الدعم والإعدادات';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get wellnessHubTitle => 'مركز العناية';

  @override
  String get wellnessHubSubtitle =>
      'منع الحمل والأعراض والعناية اليومية — في مكان واحد.';

  @override
  String get wellnessCustomize => 'تخصيص الأهداف';

  @override
  String get wellnessSetupFailed =>
      'تعذّر تحميل ميزات العناية. حاولي مرة أخرى.';

  @override
  String get wellnessDailyLog => 'يوميات الأعراض';

  @override
  String get wellnessDailyLogDesc => 'سجّلي المزاج والألم والأعراض اليومية';

  @override
  String get wellnessPills => 'حبوب منع الحمل';

  @override
  String get wellnessPillsDesc => 'تتبّعي الشريطة والتذكيرات';

  @override
  String get wellnessSanitary => 'المنتجات الصحية';

  @override
  String get wellnessSanitaryDesc => 'المنتجات والمؤقتات والعناية';

  @override
  String get wellnessSex => 'النشاط الجنسي';

  @override
  String get wellnessSexDesc => 'سجل خاص وتحليلات';

  @override
  String get wellnessLarc => 'الوسائل طويلة المفعول';

  @override
  String get wellnessLarcDesc => 'اللولب ووسائل منع الحمل طويلة الأمد';

  @override
  String get navSelfCare => 'رعاية ذاتية';

  @override
  String get selfCareTitle => 'مساحة الرعاية الذاتية';

  @override
  String get selfCareSubtitle => 'تنفسي، تأملي، واعتني بنفسك في كل مرحلة.';

  @override
  String get selfCareTodayTip => 'نصيحة اليوم';

  @override
  String get selfCareActivities => 'أنشطة';

  @override
  String get selfCareBreathe => 'تنفس';

  @override
  String get selfCareBreatheDesc => 'تنفس مربع — 4 ثوانٍ لكل مرحلة';

  @override
  String get selfCareStart => 'ابدئي';

  @override
  String get selfCarePause => 'إيقاف';

  @override
  String get selfCareAffirmations => 'تأكيدات';

  @override
  String get selfCareJournal => 'يوميات';

  @override
  String get selfCareJournalPrompt => 'سؤال';

  @override
  String get selfCareJournalHint => 'اكتبي بحرية — تُحفظ على جهازك فقط';

  @override
  String get selfCareJournalSave => 'حفظ';

  @override
  String get selfCareJournalSaved => 'تم الحفظ';

  @override
  String get selfCareStretch => 'تمدد لطيف';

  @override
  String get selfCareStretchTip => 'جرّبي 5 دقائق تمدد للرقبة والورك اليوم.';

  @override
  String get selfCareRituals => 'طقوس يومية';

  @override
  String get selfCareRitualWater => 'شربتُ ماءً كافياً';

  @override
  String get selfCareRitualRest => 'أخذتُ وقت راحة';

  @override
  String get selfCareRitualStretch => 'حركة لطيفة';

  @override
  String get selfCareRitualMindful => '5 دقائق تأمل';

  @override
  String get selfCareHealthTools => 'تتبع الصحة';

  @override
  String get selfCareHealthToolsDesc => 'حبوب، منتجات صحية، وأكثر';

  @override
  String get selfCareWhisperTitle => 'همسة اليوم';

  @override
  String get selfCareWhisperLocked =>
      'افتحي همسة Lune الشخصية مع النسخة المميّزة.';

  @override
  String get selfCareWhisperPrompt =>
      'امنحيني همسة رعاية ذاتية لطيفة لليوم حسب مرحلتي ومزاجي.';

  @override
  String get moodCheckInTitle => 'كيف تشعرين اليوم؟';

  @override
  String get moodCheckInDone => 'تم تسجيل مزاج اليوم 🌸';

  @override
  String get moodTrendTitle => 'هذا الأسبوع';

  @override
  String get selfCareAffirmationGenerate => 'تأكيد شخصي من Lune';

  @override
  String get selfCareAffirmationPrompt =>
      'اكتبي لي تأكيداً واحداً قصيراً وملهماً بصيغة المتكلّم حسب مرحلتي ومزاجي.';

  @override
  String get selfCareMovement => 'حركة لطيفة';

  @override
  String selfCareMovementStep(int current, int total) {
    return 'خطوة $current من $total';
  }

  @override
  String get selfCareMovementDone => 'أحسنتِ 🌸';

  @override
  String get selfCareMovementDoneCue => 'خذي لحظة لتلاحظي شعور جسدك.';

  @override
  String get selfCareRestart => 'من جديد';

  @override
  String get selfCareSkip => 'تخطّي';

  @override
  String selfCareBreatheCycles(int count) {
    return '$count دورات مكتملة';
  }

  @override
  String get selfCareCopied => 'تم النسخ';

  @override
  String get selfCareLibraryTitle => 'دليل العناية حسب الدورة';

  @override
  String get selfCareLibrarySubtitle => 'تغذية وحركة وراحة ومزاج لكل مرحلة.';

  @override
  String get selfCareLibraryCurrent => 'أنتِ هنا';

  @override
  String get selfCareJournalHistory => 'مدوّناتك السابقة';

  @override
  String get selfCareJournalEmpty =>
      'لا مدوّنات بعد. اكتبي أول تأمّل لكِ بالأعلى.';

  @override
  String get selfCareJournalDelete => 'حذف';

  @override
  String get selfCareJournalReflect => 'تأمّل مع Lune';

  @override
  String get selfCareJournalReflecting => 'Lune تتأمّل كلماتك…';

  @override
  String selfCareRitualStreak(int days) {
    return '$days يوم';
  }

  @override
  String selfCareRitualsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get showMore => 'عرض المزيد';

  @override
  String get showLess => 'عرض أقل';

  @override
  String get aiUnavailable => 'Lune غير متاحة الآن. حاولي لاحقاً.';

  @override
  String get communityTabFeed => 'الخلاصة';

  @override
  String get communityTabDiscover => 'استكشاف';

  @override
  String get communityTabMine => 'مجموعاتي';

  @override
  String get communityFeedEmpty => 'انضمي لمجموعة لرؤية منشورات مجتمعاتك هنا.';

  @override
  String get communityMineEmpty => 'لم تنضمي لأي مجموعة بعد.';

  @override
  String get communitySearchHint => 'ابحثي عن مجتمعات...';

  @override
  String get communityCatAll => 'الكل';

  @override
  String get communityCatGeneral => 'عام';

  @override
  String get communityCatConception => 'خصوبة';

  @override
  String get communityCatContraception => 'منع حمل';

  @override
  String get communityCatCondition => 'حالات';

  @override
  String get communityCatSupport => 'دعم';

  @override
  String get communityPostsTab => 'منشورات';

  @override
  String get communityAboutTab => 'عن المجموعة';

  @override
  String get communityRules => 'قواعد المجموعة';

  @override
  String get communityPostType => 'نوع المنشور';

  @override
  String get communityReported => 'تم إرسال البلاغ. شكراً لك.';

  @override
  String get communityAliasTooShort =>
      'الاسم المستعار يجب أن يكون حرفين على الأقل';

  @override
  String get communityAliasInvalid =>
      'استخدمي اسمًا مستعارًا بدون مسافات أو بريد إلكتروني';

  @override
  String get communityBirthYearLabel => 'سنة الميلاد';

  @override
  String get communityBirthYearRequired => 'يرجى اختيار سنة ميلادك';

  @override
  String get communityBirthYearWhy =>
      'تُستخدم فقط للحفاظ على أمان المجتمع للعضوات الأصغر سنًا، ولا تظهر لأي أحد إطلاقًا.';

  @override
  String get communityMinorBanner =>
      'يمكنك قراءة المنشورات، أما الانضمام والنشر والتعليق فتُفتح من عمر 18 — وذلك لحمايتك.';

  @override
  String get communityMinorRestricted =>
      'الانضمام والنشر متاحان من عمر 18 سنة.';

  @override
  String get communityBannedMessage =>
      'تم حظر حسابك من المجتمع. تواصلي مع الدعم إذا كان هذا خطأ.';

  @override
  String get communityFull => 'هذا المجتمع ممتلئ. جرّبي مجموعة أخرى.';

  @override
  String get communityPostNotFound => 'هذا المنشور لم يعد متاحًا.';

  @override
  String get communityBlockUser => 'حظر الكاتبة';

  @override
  String get communityBlocked => 'تم حظر الكاتبة. لن تري منشوراتها بعد الآن.';

  @override
  String get communityReportPost => 'الإبلاغ عن المنشور';

  @override
  String get communityReportComment => 'الإبلاغ عن التعليق';

  @override
  String get communityReportTitle => 'لماذا تبلّغين؟';

  @override
  String get communityReportReasonHarassment => 'تحرش أو تنمّر';

  @override
  String get communityReportReasonHate => 'خطاب كراهية';

  @override
  String get communityReportReasonSpam => 'سبام أو إعلانات';

  @override
  String get communityReportReasonInappropriate => 'محتوى غير لائق';

  @override
  String get communityReportReasonMisinformation => 'معلومات مضلّلة';

  @override
  String get communityReportReasonSelfHarm => 'إيذاء النفس أو خطر';

  @override
  String get communityReportReasonOther => 'سبب آخر';

  @override
  String get communityBlockConfirmTitle => 'حظر الكاتبة؟';

  @override
  String communityBlockConfirmMessage(String alias) {
    return 'لن تري منشورات أو تعليقات $alias بعد الآن.';
  }

  @override
  String get communityBlockConfirmAction => 'حظر';

  @override
  String get communityBlockCancel => 'إلغاء';

  @override
  String get communityBlockedUsersTitle => 'المستخدمات المحظورات';

  @override
  String get communityBlockedUsersSubtitle => 'إدارة من حظرتِهن في المجتمعات';

  @override
  String get communityBlockedUsersEmpty => 'لا يوجد مستخدمات محظورات.';

  @override
  String get communityBlockedUserUnknown => 'مستخدمة مجهولة';

  @override
  String get communityUnblockUser => 'إلغاء الحظر';

  @override
  String get communityUnblocked => 'تم إلغاء الحظر.';

  @override
  String get accountBlockedUsers => 'المحظورات في المجتمع';

  @override
  String get aiInsightDailyTitle => 'نصيحة اليوم لكِ';

  @override
  String get aiInsightMoodTitle => 'طقسكِ العاطفي';

  @override
  String get aiInsightCycleTitle => 'صحة دورتكِ';

  @override
  String get aiInsightWeeklyTitle => 'أسبوعكِ باختصار';

  @override
  String get aiInsightBadge => 'ذكاء أورا';

  @override
  String get aiInsightRefresh => 'رؤية جديدة';

  @override
  String get aiInsightDisclaimer =>
      'اقتراح عافية مولّد بالذكاء الاصطناعي — ليس نصيحة طبية.';

  @override
  String get doctorReportTitle => 'تقرير الدورة الشهرية';

  @override
  String get doctorReportButton => 'عرض التقرير الكامل';

  @override
  String get doctorReportGenerating => 'جارٍ تحضير التقرير...';

  @override
  String get doctorReportFailed =>
      'بيانات الدورة غير جاهزة بعد. افتحي الشاشة الرئيسية ثم حاولي مجدداً.';

  @override
  String get doctorReportRetry => 'إعادة المحاولة';

  @override
  String get doctorReportLimitedData =>
      'هذا التقرير مبني على بيانات محدودة. بعد حوالي شهر من التسجيل اليومي، تصبح التوقعات والأنماط أدق بكثير.';

  @override
  String get doctorReportAiTitle => 'ملاحظات المساعد الذكي';

  @override
  String get doctorReportAiSubtitle =>
      'سياق مفيد لزيارة الطبيب — وليس تشخيصاً.';

  @override
  String get doctorReportAiLoading => 'الذكاء الاصطناعي يراجع بياناتك…';

  @override
  String get doctorReportAiFailed =>
      'تعذر توليد ملاحظات الذكاء الاصطناعي الآن. بيانات الدورة أعلاه ما زالت متاحة.';

  @override
  String get doctorReportAiNeedsConsent =>
      'فعّلي الذكاء الاصطناعي من إعدادات الخصوصية للحصول على ملاحظات مساعدة للتقرير.';

  @override
  String get doctorReportAiEnable => 'تفعيل المساعد الذكي';

  @override
  String get doctorReportCopy => 'نسخ';

  @override
  String get doctorReportCopied => 'تم نسخ التقرير';

  @override
  String get doctorReportShare => 'مشاركة';

  @override
  String get doctorReportDownload => 'تنزيل';

  @override
  String get doctorReportExportTitle => 'تصدير التقرير';

  @override
  String get doctorReportExportSubtitle =>
      'اختاري صيغة الملف للحفظ أو المشاركة';

  @override
  String get doctorReportExportPdf => 'ملف PDF';

  @override
  String get doctorReportExportPdfHint => 'مناسب للطباعة أو إرساله للطبيبة';

  @override
  String get doctorReportExportTxt => 'ملف نصي (.txt)';

  @override
  String get doctorReportExportTxtHint => 'نص عادي — يعمل على أي جهاز';

  @override
  String get doctorReportExportCsv => 'جدول (.csv)';

  @override
  String get doctorReportExportCsvHint => 'يفتح في Excel أو Google Sheets';

  @override
  String get doctorReportExportJson => 'بيانات JSON (.json)';

  @override
  String get doctorReportExportJsonHint =>
      'بيانات منظّمة للتطبيقات والنسخ الاحتياطي';

  @override
  String get doctorReportExporting => 'جارٍ تحضير الملف...';

  @override
  String get doctorReportExportShared => 'الملف جاهز — اختاري مكان الحفظ';

  @override
  String get doctorReportExportFailed => 'فشل التصدير. حاولي مرة أخرى.';

  @override
  String get doctorReportDisclaimer =>
      'ملخص تتبّع شخصي من التطبيق — ليس تشخيصاً طبياً. استشيري مقدّمة الرعاية دائماً.';

  @override
  String get healthReportTitle => 'تقرير الصحة';

  @override
  String get healthReportClinicalSummary => 'الملخص السريري';

  @override
  String get healthReportObservedPatterns => 'الأنماط الملاحظة';

  @override
  String get healthReportDiscussionPoints => 'نقاط للمناقشة';

  @override
  String get doctorReportRefining => 'جاري إعداد الملخص السريري…';

  @override
  String get healthReportCreatedBy => 'صنع بواسطة Lune';

  @override
  String healthReportExportedOn(String date) {
    return 'تم التصدير في: $date';
  }

  @override
  String get healthReportCyclePeriodLength => 'طول الدورة والفترة';

  @override
  String get healthReportPredictions => 'التوقعات';

  @override
  String get healthReportCycleHistorySummary => 'ملخص تاريخ الدورة';

  @override
  String get healthReportSymptomPatternsSummary => 'ملخص أنماط الأعراض';

  @override
  String get healthReportPrevCycleLength => 'طول الدورة السابقة';

  @override
  String get healthReportPrevPeriodDuration => 'مدة الفترة السابقة';

  @override
  String get healthReportCycleRegularityScore => 'درجة انتظام الدورة';

  @override
  String get healthReportPeriodRegularityScore => 'درجة انتظام الدورة الشهرية';

  @override
  String get healthReportNextPeriodDay => 'دورة يوم التالي';

  @override
  String get healthReportNextOvulationDay => 'يوم الإباضة القادم';

  @override
  String healthReportDaysCycle(int count) {
    return 'دورة من $count يوماً';
  }

  @override
  String get healthReportUntilNow => 'الآن';

  @override
  String get healthReportFooter => '© Lune';

  @override
  String get healthReportPatientSection => 'المريضة';

  @override
  String get healthReportMode => 'نمط التتبّع';

  @override
  String get healthReportModeCycle => 'تتبّع الدورة';

  @override
  String get healthReportModePregnancy => 'تتبّع الحمل';

  @override
  String get healthReportReportId => 'رقم التقرير';

  @override
  String get healthReportMenstrualHistory => 'تاريخ الحيض';

  @override
  String get healthReportLastPeriod => 'آخر دورة (LMP)';

  @override
  String get healthReportDataPeriod => 'فترة البيانات';

  @override
  String get healthReportCyclesAnalyzed => 'عدد الدورات المُحلَّلة';

  @override
  String get healthReportCycleLengthRange => 'مدى طول الدورة';

  @override
  String get healthReportCycleVariability => 'تباين الدورة';

  @override
  String get healthReportPeriodLengthRange => 'مدى مدة الطمث';

  @override
  String get healthReportPatternsToDiscuss => 'أنماط تستحق النقاش';

  @override
  String get healthReportSymptomBurden => 'ملخّص الأعراض والألم';

  @override
  String get healthReportAveragePain => 'متوسط الألم (آخر 30 يوماً)';

  @override
  String get healthReportWellnessEntries => 'عدد سجلات العافية';

  @override
  String get healthReportRedFlags => 'يُستحسن ذكرها للطبيب';

  @override
  String get healthReportVitalsAdherence => 'المؤشرات الحيوية والالتزام';

  @override
  String get healthReportLatestWeight => 'آخر وزن';

  @override
  String get healthReportLatestTemperature => 'آخر حرارة';

  @override
  String get healthReportAvgWater => 'متوسط الماء (30 يوماً)';

  @override
  String get healthReportPillAdherence => 'الالتزام بالحبوب (آخر 7 أيام)';

  @override
  String clinicalFlagShortCycle(int days) {
    return 'متوسط الدورة $days يوماً — أقصر من النطاق المرجعي 24–38 يوماً؛ يُستحسن مناقشته مع طبيبكِ.';
  }

  @override
  String clinicalFlagLongCycle(int days) {
    return 'متوسط الدورة $days يوماً — أطول من النطاق المرجعي 24–38 يوماً؛ يُستحسن مناقشته مع طبيبكِ.';
  }

  @override
  String clinicalFlagIrregularCycle(int days) {
    return 'يختلف طول الدورة بنحو $days يوماً بين دورة وأخرى — يُستحسن مناقشة الانتظام مع طبيبكِ.';
  }

  @override
  String clinicalFlagProlongedPeriod(int days) {
    return 'متوسط مدة الطمث $days أيام — أطول من المدة المرجعية (8 أيام)؛ يُستحسن مناقشته مع طبيبكِ.';
  }

  @override
  String get clinicalFlagHighPain =>
      'متوسط الألم المُسجَّل في النطاق الشديد — يُستحسن مناقشة إدارة الألم مع طبيبكِ.';

  @override
  String get doctorReportPatientTitle => 'بيانات المريضة';

  @override
  String get doctorReportPatientSubtitle =>
      'اختياري — يظهر أعلى التقرير للطبيب. يُحفظ على جهازكِ فقط.';

  @override
  String get doctorReportPatientName => 'الاسم';

  @override
  String get doctorReportPatientAge => 'العمر';

  @override
  String get doctorReportPatientNote => 'ملاحظة للطبيب';

  @override
  String get doctorReportPatientNoteHint => 'مثال: سبب الزيارة، الأدوية، مخاوف';

  @override
  String get doctorReportPatientSave => 'حفظ';

  @override
  String get doctorReportEditPatient => 'تعديل بيانات المريضة';

  @override
  String get communityAdultsOnlyTitle => 'المجتمعات للبالغات';

  @override
  String get communityAdultsOnly =>
      'ميزات المجتمع متاحة من عمر 18. يمكنكِ استخدام باقي التطبيق بشكل كامل.';

  @override
  String get communityGuidelinesTitle => 'إرشادات المجتمع';

  @override
  String get communityGuidelinesIntro =>
      'قبل الانضمام، اقرئي ووافقي على قواعد المجتمع:';

  @override
  String get communityGuidelinesAgree => 'أوافق على الالتزام بإرشادات المجتمع';

  @override
  String get communityGuidelinesAccept => 'انضمام للمجتمع';

  @override
  String get challengesTitle => 'تحدياتي';

  @override
  String get challengesToday => 'تحديات اليوم';

  @override
  String get challengesAllDone => 'رائع! أكملتِ كل تحديات اليوم.';

  @override
  String get challengeDone => 'اكتمل التحدي';

  @override
  String get challengeStreakLabel => 'أيام متتالية';

  @override
  String get challengePointsLabel => 'النقاط';

  @override
  String challengeStreakValue(int count) {
    return '$count أيام';
  }

  @override
  String get challengeHydrate => 'اشربي 6-8 أكواب ماء';

  @override
  String get challengeStretch => 'تمدد لطيف لمدة 5 دقائق';

  @override
  String get challengeWalk => 'مشي لمدة 10 دقائق';

  @override
  String get challengeMindful => 'استراحة تنفس واعٍ واحدة';

  @override
  String get challengeLogToday => 'سجلي أعراضك ومزاجك';

  @override
  String get challengeSleepEarly => 'اخلدي للنوم قبل 11 مساءً';

  @override
  String get badgesTitle => 'الإنجازات';

  @override
  String get badgeEarned => 'إنجاز جديد';

  @override
  String get badgeFirstStep => 'الخطوة الأولى';

  @override
  String get badgeStreak3 => '3 أيام متتالية';

  @override
  String get badgeStreak7 => 'أسبوع من العناية';

  @override
  String get badgeStreak30 => 'بطلة الـ 30 يومًا';

  @override
  String get badgePoints100 => '100 نقطة';

  @override
  String get badgePoints500 => '500 نقطة';

  @override
  String get badgeAllInADay => 'يوم مثالي';

  @override
  String get educationTitle => 'تعلمي';

  @override
  String get magazineTitle => 'مجلة Lune';

  @override
  String get magazineFeatured => 'مقال مميز';

  @override
  String get magazineFromLune => 'من المجلة';

  @override
  String get magazineReadMore => 'اقرئي المزيد';

  @override
  String get educationSubtitle =>
      'مقالات موثوقة ومناسبة لعمرك عن دورتك وجسمك وصحتك النفسية.';

  @override
  String get educationCatAll => 'الكل';

  @override
  String get educationCatBasics => 'أساسيات الدورة';

  @override
  String get educationCatHealth => 'الصحة والأعراض';

  @override
  String get educationCatNutrition => 'الغذاء والحركة';

  @override
  String get educationCatMind => 'العقل والمزاج';

  @override
  String get educationCatAdult => 'مواضيع +18';

  @override
  String educationMinutes(int count) {
    return '$count د قراءة';
  }

  @override
  String get educationDisclaimer =>
      'محتوى تعليمي فقط — ليس بديلًا عن الاستشارة الطبية.';

  @override
  String get educationArticles => 'مقالات';

  @override
  String get educationNoArticles => 'لا توجد مقالات متاحة';

  @override
  String get educationPoweredByAi => 'مدعوم بالذكاء الاصطناعي';

  @override
  String get educationAskAi => 'اسأل الذكاء الاصطناعي';

  @override
  String get educationAskAnything => 'اسأل أي سؤال صحي';

  @override
  String get educationAskHint => 'اسأل عن أي موضوع صحي...';

  @override
  String get educationThinking => 'جاري التفكير...';

  @override
  String get educationTopicPhase => 'مرحلتي الحالية';

  @override
  String get educationTopicPhasePrompt =>
      'أخبريني عن مرحلتي الحالية من الدورة وما يجب أن أعرفه';

  @override
  String get educationTopicNutrition => 'نصائح غذائية';

  @override
  String get educationTopicNutritionPrompt =>
      'ما هي الأطعمة المناسبة لمرحلتي الحالية من الدورة؟';

  @override
  String get educationTopicExercise => 'تمارين رياضية';

  @override
  String get educationTopicExercisePrompt =>
      'ما هي التمارين المناسبة لمرحلتي الحالية؟';

  @override
  String get educationTopicPain => 'إدارة الألم';

  @override
  String get educationTopicPainPrompt =>
      'كيف أتعامل مع آلام الدورة بشكل طبيعي؟';

  @override
  String get educationTopicSleep => 'تحسين النوم';

  @override
  String get educationTopicSleepPrompt => 'كيف أحسّن نومي خلال الدورة الشهرية؟';

  @override
  String get educationTopicMood => 'المزاج والتوتر';

  @override
  String get educationTopicMoodPrompt =>
      'كيف أتعامل مع تغيرات المزاج خلال الدورة؟';

  @override
  String get reportCycleHealth => 'صحة الدورة';

  @override
  String get hormoneIndicatorsTitle => 'مؤشرات الهرمونات';

  @override
  String get hormoneIndicatorsSubtitle => 'الإستروجين والبروجستيرون خلال دورتك';

  @override
  String get hormoneIndicatorsCaption =>
      'مستويات هرمونية تقديرية بناءً على يوم الدورة وطولها.';

  @override
  String get reportFertility => 'الخصوبة والحمل';

  @override
  String get reportFullHistory => 'سجل الدورات الكامل';

  @override
  String get reportSymptomPatterns => 'أنماط الأعراض';

  @override
  String get reportsEmpty =>
      'لا توجد تقارير بعد. سجّلي دورتكِ وأعراضكِ من زر + لبضعة أيام، ثم ارجعي هنا.';

  @override
  String get reportsLoadPartial =>
      'بعض بيانات التقارير لم تُحمّل. اسحبي للأسفل للتحديث.';

  @override
  String get reportsSetupRequired =>
      'أكملي إعداد الدورة أولاً من التسجيل الأولي، ثم افتحي التقارير مرة أخرى.';

  @override
  String get doctorReportQrHint => 'امسحي الكود لمشاركة ملخص التقرير';

  @override
  String get doctorReportUpgradeUnlimited => 'تقارير غير محدودة مع برو';

  @override
  String get reportCycleSummary => 'ملخص الدورة';

  @override
  String get reportCycleDay => 'يوم الدورة';

  @override
  String get reportPeriodDay => 'يوم الحيض';

  @override
  String get reportAvgCycle => 'متوسط الدورة';

  @override
  String get reportAvgPeriod => 'متوسط الحيض';

  @override
  String get reportTotalCycles => 'إجمالي الدورات';

  @override
  String get reportRegularity => 'الانتظام';

  @override
  String get reportOvulation => 'الإباضة';

  @override
  String get reportPregnancyChance => 'فرصة الحمل';

  @override
  String get reportDueDate => 'موعد الولادة';

  @override
  String get reportPregnancyWeek => 'أسبوع الحمل';

  @override
  String get reportTrimester => 'الثلث';

  @override
  String get accountExportBackup => 'تصدير نسخة احتياطية محلية';

  @override
  String get accountImportBackup => 'استيراد نسخة احتياطية محلية';

  @override
  String get accountRestoreCloud => 'استعادة من السحابة';

  @override
  String get accountAdvanced => 'متقدم';

  @override
  String get accountGeminiKeySaved => 'تم حفظ مفتاح Gemini';

  @override
  String get accountGeminiKeyHelp =>
      'مفتاح Gemini API اختياري كبديل إذا لم تُنشر الـ Cloud Functions.';

  @override
  String get accountGeminiKeyLabel => 'مفتاح Gemini API';

  @override
  String get accountGeminiKeySave => 'حفظ مفتاح Gemini';

  @override
  String get reportPatternFallback => 'نمط';

  @override
  String reportPercentOfCycles(Object percent) {
    return '$percent% من الدورات';
  }

  @override
  String get postTypeSupport => 'دعم';

  @override
  String get postTypeQuestion => 'سؤال';

  @override
  String get postTypeTip => 'نصيحة';

  @override
  String get postTypeVent => 'تفريغ';

  @override
  String get postTypeMilestone => 'إنجاز';

  @override
  String get postTypePoll => 'تصويت';

  @override
  String get weeklyRecapTitle => 'أسبوعك مع Lune';

  @override
  String get weeklyRecapPrompt =>
      'لخّصي لي آخر 7 أيام بناءً على البيانات — ما الجميل وما الذي أركّز عليه الأسبوع المقبل.';

  @override
  String get weeklyRecapLoading => 'أحضّر ملخّصك الأسبوعي…';

  @override
  String get weeklyRecapRefresh => 'تحديث';

  @override
  String get dayLabelToday => 'اليوم';

  @override
  String get dayLabelYesterday => 'أمس';

  @override
  String aiActionLogged(String label) {
    return 'تم التسجيل: $label';
  }

  @override
  String aiActionLogMood(String mood) {
    return 'سجّلي المزاج: $mood';
  }

  @override
  String aiActionLogSymptom(String symptom) {
    return 'سجّلي: $symptom';
  }

  @override
  String aiActionLogWater(String count) {
    return 'أضيفي $count ماء';
  }

  @override
  String aiActionLogPain(String level) {
    return 'سجّلي ألم $level/10';
  }

  @override
  String get aiActionOpenLog => 'افتحي السجل';

  @override
  String get aiActionOpenInsights => 'عرض الإحصاءات';

  @override
  String get aiActionLogFailed => 'تعذّر الحفظ — افتحي السجل لإضافته';

  @override
  String get aiSuggestHowsMyDay => 'كيف يومي؟';

  @override
  String get aiSuggestMoodCheck => 'ساعديني أراجع مزاجي';

  @override
  String get aiSuggestFoodIdeas => 'أفكار طعام لليوم';

  @override
  String get aiSuggestExplainPhase => 'اشرحي لي المرحلة الحالية';

  @override
  String get aiSuggestSymptomCheck => 'هل هذه الأعراض طبيعية؟';

  @override
  String get aiSuggestPrep => 'حضّريني لزيارة الطبيب';

  @override
  String get aiSuggestEnergyBoost => 'بسرعة شدّي حيلي!';

  @override
  String get aiSuggestMoveToday => 'خطة حركة لليوم';

  @override
  String get aiSuggestSetGoal => 'حدّدي لي هدفاً صغيراً';

  @override
  String get adminTabUsers => 'المستخدمون';

  @override
  String get adminTabQA => 'أسئلة وأجوبة';

  @override
  String get adminTabBroadcast => 'إشعار جماعي';

  @override
  String get adminFilterPending => 'قيد الانتظار';

  @override
  String get adminFilterAnswered => 'تمت الإجابة';

  @override
  String get adminFilterAll => 'الكل';

  @override
  String adminQuestionsEmpty(String filter) {
    return 'لا توجد أسئلة $filter بعد.';
  }

  @override
  String get adminQAExpertAnswer => 'إجابة الخبير';

  @override
  String get adminPostsToday => 'منشورات اليوم';

  @override
  String get adminAiToday => 'طلبات AI اليوم';

  @override
  String get adminQuickActions => 'إجراءات سريعة';

  @override
  String get adminQuickViewReports => 'مراجعة البلاغات';

  @override
  String get adminQuickSendBroadcast => 'إرسال إشعار';

  @override
  String get adminQuickEditSettings => 'إعدادات التطبيق';

  @override
  String get adminConfirmBan => 'حظر هذا المستخدم؟';

  @override
  String get adminConfirmBanMsg =>
      'سيفقد فوراً صلاحية المشاركة في المجتمعات. يمكنك إلغاء الحظر لاحقاً.';

  @override
  String get adminConfirmBroadcast => 'إرسال للجميع؟';

  @override
  String get adminConfirmBroadcastMsg =>
      'سيُسلَّم هذا الإشعار لكل مستخدم مسجَّل. تأكد من العنوان والمحتوى قبل الإرسال.';

  @override
  String adminBroadcastSent(String sent, String failed) {
    return 'تم الإرسال · $sent تم تسليمه، $failed فشل';
  }

  @override
  String get adminConfirm => 'تأكيد';

  @override
  String get adminCancel => 'إلغاء';

  @override
  String get adminGroupFeatures => 'الميزات';

  @override
  String get adminGroupAnnouncement => 'إعلان';

  @override
  String get adminGroupLinks => 'الروابط';

  @override
  String get adminSending => 'جاري الإرسال…';

  @override
  String get adminSendBroadcast => 'إرسال إشعار';

  @override
  String get adminNotifPreview => 'معاينة';

  @override
  String get adminNoEmail => 'بدون بريد';

  @override
  String get adminBannedBadge => 'محظور';

  @override
  String get adminGrantPremium => 'تفعيل الاشتراك المميز';

  @override
  String get adminRevokePremium => 'إلغاء الاشتراك المميز';

  @override
  String get adminPremiumUpdated => 'تم تحديث حالة الاشتراك';

  @override
  String get adminAiCost30d => 'تكلفة الذكاء الاصطناعي (آخر 30 يوماً)';

  @override
  String adminAiTokensCount(String count) {
    return '$count توكن';
  }

  @override
  String adminAiRequestsCount(String count) {
    return '$count طلب';
  }

  @override
  String get adminTimeNow => 'الآن';

  @override
  String adminTimeMinutes(int n) {
    return '$n د';
  }

  @override
  String adminTimeHours(int n) {
    return '$n س';
  }

  @override
  String adminTimeDays(int n) {
    return '$n ي';
  }

  @override
  String get onboardingPrivacyAgree =>
      'أوافق على سياسة الخصوصية. بيانات الدورة تبقى على جهازي افتراضياً. النسخ السحابي والذكاء الاصطناعي والمجتمع اختياريان ويتطلبان موافقة منفصلة من مركز الخصوصية.';

  @override
  String get privacyCenterTitle => 'الخصوصية والبيانات';

  @override
  String get privacyCenterIntro =>
      'Lune يضع الخصوصية أولاً. البيانات الصحية محفوظة محلياً ومشفّرة. السحابة والذكاء الاصطناعي والمجتمعات اختيارية وتتطلب موافقتك.';

  @override
  String get privacyDataLocal => 'محفوظة على جهازك';

  @override
  String get privacyDataOptional => 'اختيارية (بموافقتك)';

  @override
  String get privacyDataNotCollected => 'لن نقوم أبداً بـ';

  @override
  String get privacyBulletLocal =>
      'سجلات الدورة واليوميات وبيانات العناية تبقى على هاتفك افتراضياً.';

  @override
  String get privacyBulletEncrypt =>
      'مفاتيح التشفير في Android Keystore / iOS Keychain.';

  @override
  String get privacyBulletCloud =>
      'النسخ السحابي فقط عند تسجيل الدخول وتفعيل المزامنة.';

  @override
  String get privacyBulletAi =>
      'محادثة AI ترسل الرسائل إلى Google Gemini فقط عند موافقتك.';

  @override
  String get privacyBulletCommunity =>
      'المجتمعات تستخدم اسماً مستعاراً — لا اسمك الحقيقي ولا بيانات دورتك.';

  @override
  String get privacyBulletNoSell => 'بيع أو مشاركة بياناتك الصحية مع المعلنين.';

  @override
  String get privacyBulletNoTrack => 'تتبعك عبر تطبيقات أخرى للإعلانات.';

  @override
  String get privacyPolicyLink => 'قراءة سياسة الخصوصية الكاملة';

  @override
  String get privacyMedicalDisclaimer =>
      'Lune ليس جهازاً طبياً. استشيري دائماً مختصاً صحياً.';

  @override
  String get deleteAccountTitle => 'حذف الحساب';

  @override
  String get deleteAccountSubtitle =>
      'يحذف بيانات السحابة وتسجيل الدخول نهائياً.';

  @override
  String get deleteAccountWarning =>
      'يُحذف حسابك نهائياً من السيرفر: النسخ الاحتياطي، محادثات AI، منشورات وتعليقات المجتمع، بيانات الشريك، وصور الملف. البيانات المحلية على الجهاز تبقى حتى تحذفي التطبيق.';

  @override
  String get deleteAccountConfirm => 'حذف نهائي';

  @override
  String get deleteAccountDone => 'تم حذف الحساب';

  @override
  String get deleteAccountReauth => 'سجّلي الدخول مجدداً ثم أعيدي المحاولة.';

  @override
  String get deleteAccountFailed =>
      'تعذر حذف الحساب. حاولي مرة أخرى أو تواصلي مع الدعم.';

  @override
  String get termsOfServiceLink => 'شروط الاستخدام';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get contactSupportSubtitle => 'استفسارات، إبلاغات، أو مساعدة الحساب';

  @override
  String get accountMenuFeedback => 'الدعم والملاحظات';

  @override
  String get accountMenuFeedbackSubtitle =>
      'أرسلي ملاحظة أو استخدمي كوداً ترويجياً';

  @override
  String get accountMenuAiDiagnostic => 'تشخيص الذكاء الاصطناعي';

  @override
  String get accountMenuAiDiagnosticSubtitle =>
      'اختبري الاتصال أو حدّثي مفتاح Gemini';

  @override
  String get consentManageTitle => 'موافقاتك';

  @override
  String get consentManageBody =>
      'أوقفي الميزات الاختيارية في أي وقت. التتبع الأساسي على جهازك لا يتأثر.';

  @override
  String get premiumRequiredCloud =>
      'النسخ السحابي ميزة Premium. اشتركي من الحساب.';

  @override
  String get premiumRequiredAi =>
      'هذه ميزة AI تتطلب Premium. اشتركي من الحساب.';

  @override
  String get premiumAiLimitReached =>
      'استنفدتِ رسائل AI المجانية اليوم. Premium يمنحك محادثة غير محدودة.';

  @override
  String get aiDailyLimitReached =>
      'استنفدتِ 30 رسالة Lune AI اليومية. يتجدد رصيدك تلقائياً غداً.';

  @override
  String premiumAiFreeRemaining(int count) {
    return 'متبقٍ $count رسائل AI مجانية اليوم';
  }

  @override
  String get openPrivacyCenter => 'إعدادات الخصوصية والبيانات';

  @override
  String get consentCloudTitle => 'تفعيل النسخ السحابي؟';

  @override
  String get consentCloudBody =>
      'سيتم تخزين نسخ احتياطية مشفّرة في حساب Firebase. يمكنك إيقافها في أي وقت.';

  @override
  String get consentAiTitle => 'تفعيل ميزات الذكاء الاصطناعي؟';

  @override
  String get consentAiBody =>
      'تُرسل رسائل المحادثة وسياق الدورة المجهول (الأعراض، المزاج، الطور) إلى مزوّدي ذكاء اصطناعي موثوقين (DeepSeek / Google) عبر خادمنا الآمن. ليست نصيحة طبية. بدون إعلانات. يمكنك الإيقاف في أي وقت.';

  @override
  String get aiAdultsOnly => 'Lune AI للبالغات 18+ فقط.';

  @override
  String get consentCommunityTitle => 'الانضمام للمجتمعات؟';

  @override
  String get consentCommunityBody =>
      'ستستخدمين اسماً مستعاراً. المنشورات تُراجع بالذكاء الاصطناعي. بيانات دورتك لا تُشارك أبداً.';

  @override
  String get consentAccept => 'أوافق';

  @override
  String get consentRequired => 'يرجى الموافقة للمتابعة';

  @override
  String get homeGreeting => 'أهلاً بعودتك';

  @override
  String homeGreetingName(String name) {
    return 'مرحباً، $name';
  }

  @override
  String homeSubtitleDay(int day, String phase) {
    return 'اليوم $day · $phase';
  }

  @override
  String get homeOvulation => 'الإباضة القادمة';

  @override
  String get homeRegularity => 'انتظام الدورة';

  @override
  String homeCycleDay(int day) {
    return 'يوم الدورة $day';
  }

  @override
  String homePeriodDay(int day) {
    return 'يوم الحيض $day';
  }

  @override
  String get homeOvulationToday => 'إباضة اليوم';

  @override
  String get homeKeyDates => 'تواريخ مهمة';

  @override
  String get homeDueDate => 'تاريخ الولادة المتوقع';

  @override
  String get homeCycleProgress => 'تقدّم الدورة';

  @override
  String get homeWeeklyCalendar => 'هذا الأسبوع';

  @override
  String get homeTipsSection => 'نصائح ورؤى';

  @override
  String get homeLearnSection => 'تعلّمي وشاهدي';

  @override
  String get homeVideoLabel => 'فيديو';

  @override
  String get homeArticleLabel => 'مقال';

  @override
  String get homeCycleView => 'نظرة على الدورة';

  @override
  String get homeOpenCalendar => 'عرض التقويم الكامل';

  @override
  String get homeStatsError => 'تعذّر تحميل المؤشرات. اسحبي للتحديث.';

  @override
  String get homeLoadingStats => 'جاري تحميل بيانات دورتك…';

  @override
  String get homeDayShort => 'يوم';

  @override
  String onboardingStepLabel(int current, int total) {
    return 'الخطوة $current من $total';
  }

  @override
  String get onboardingWelcomeTitle => 'مرحباً بكِ في Lune';

  @override
  String get onboardingWelcomeSubtitle =>
      'Lune تعني القمر — رفيقة خاصة لكل أطوار دورتكِ وعافيتكِ';

  @override
  String get onboardingWelcomeHelps => 'سنساعدكِ في:';

  @override
  String get onboardingWelcomeTrack => 'تسجيل الدورة والأعراض والمزاج';

  @override
  String get onboardingWelcomeAi => 'محادثة ذكية مع AI تجيب عن أسئلتك';

  @override
  String get onboardingWelcomeCommunity => 'مجتمع داعم من النساء';

  @override
  String get onboardingWelcomePregnancy => 'متابعة الحمل أسبوعاً بأسبوع';

  @override
  String get onboardingWelcomeSelfCare => 'نصائح عناية ذاتية مخصصة';

  @override
  String get onboardingFeaturesTitle => 'تطبيقكِ بين يديك';

  @override
  String get onboardingFeaturesSubtitle => 'هذه شاشات التطبيق الرئيسية:';

  @override
  String get onboardingReadyHint =>
      'اضغطي «ابدئي الآن» بالأسفل للدخول إلى التطبيق';

  @override
  String get onboardingFeatureHome => 'الرئيسية';

  @override
  String get onboardingFeatureHomeDesc =>
      'نظرة سريعة على دورتك، تسجيل سريع، وتوقعات';

  @override
  String get onboardingFeatureSelfCare => 'العناية';

  @override
  String get onboardingFeatureSelfCareDesc =>
      'تمارين تنفس، تأكيدات، يوميات، وتحديات';

  @override
  String get onboardingFeatureCommunity => 'المجتمع';

  @override
  String get onboardingFeatureCommunityDesc =>
      'مجموعات دعم، أسئلة ونقاشات مع نساء مثلك';

  @override
  String get onboardingFeatureReports => 'التقارير';

  @override
  String get onboardingFeatureReportsDesc =>
      'تحليل دورتك، رسوم بيانية، وتقرير للطبيب';

  @override
  String get onboardingFeatureAccount => 'الحساب';

  @override
  String get onboardingFeatureAccountDesc => 'الملف الشخصي، الإعدادات، Premium';

  @override
  String get educationNotAvailable => 'قسم التعليم غير متاح حالياً';

  @override
  String get selfCareWelcomeTitle => 'أهلاً بكِ في مساحة العناية';

  @override
  String get selfCareWelcomeSubtitle =>
      'سجّلي دورتك لتحصلي على نصائح مخصصة، أو تصفّحي الأنشطة الآن.';

  @override
  String get onboardingProfileTitle => 'لنتعرّف عليك';

  @override
  String get onboardingProfileSubtitle =>
      'اسمك يخصّص نصائح AI والعناية الذاتية والشاشة الرئيسية.';

  @override
  String get onboardingNameLabel => 'اسمك';

  @override
  String get onboardingNameHint => 'كيف نرحّب بك؟';

  @override
  String get onboardingGoalTitle => 'ما هدفك؟';

  @override
  String get onboardingGoalSubtitle =>
      'تتبّعي دورتك أو حملك أو خطّطي للحمل أو تجنّبيه — التطبيق كله يتكيّف مع اختيارك.';

  @override
  String get onboardingCycleTitle => 'أساسيات دورتك';

  @override
  String get onboardingCycleSubtitle =>
      'تُشغّل التوقعات والتذكيرات والتقارير والAI في كل التطبيق.';

  @override
  String get onboardingPregnancyDataTitle => 'متابعة الحمل';

  @override
  String get onboardingPregnancyDataSubtitle =>
      'نستخدم أول يوم من آخر دورة لتقدير أسبوع الحمل وموعد الولادة ونمو الجنين.';

  @override
  String get onboardingPregnancyLmp => 'أول يوم من آخر دورة شهرية';

  @override
  String get pregnancyModeTitle => 'متابعة الحمل';

  @override
  String pregnancyWeekDay(int week, int day) {
    return 'الأسبوع $week · اليوم $day';
  }

  @override
  String pregnancyTrimester(int n) {
    return 'الثلث $n';
  }

  @override
  String pregnancyDueDate(String date) {
    return 'الولادة المتوقعة $date';
  }

  @override
  String get pregnancyBabyThisWeek => 'الجنين هذا الأسبوع';

  @override
  String get pregnancyBabyVisualTitle => 'شكل جنينكِ الآن';

  @override
  String get pregnancyBabyNextWeek => 'معاينة الأسبوع القادم';

  @override
  String get pregnancyWeekShort => 'أسبوع';

  @override
  String get pregnancyExploreWeeks => 'استكشفي حسب الأسبوع';

  @override
  String pregnancyWeekLabel(int week) {
    return 'الأسبوع $week';
  }

  @override
  String pregnancySizeLike(String item) {
    return 'جنينكِ بحجم $item';
  }

  @override
  String get pregnancySizeComparison => 'مقارنة الحجم';

  @override
  String get pregnancyGrowthTitle => 'النمو التقريبي';

  @override
  String get pregnancyLengthLabel => 'الطول';

  @override
  String get pregnancyWeightLabel => 'الوزن';

  @override
  String get pregnancyYourBody => 'جسمك هذا الأسبوع';

  @override
  String get pregnancySelfCareTitle => 'العناية في الحمل';

  @override
  String get pregnancySelfCareSubtitle => 'طقوس ونصائح لطيفة حسب ثلث الحمل.';

  @override
  String get pregnancyReportOverview => 'نظرة على الحمل';

  @override
  String get pregnancyReportChecklist => 'قائمة الثلث';

  @override
  String pregnancyDaysToDue(int days) {
    return '$days يوم للولادة المتوقعة';
  }

  @override
  String get pregnancyCheckFirstVisit => 'احجزي أول زيارة متابعة حمل';

  @override
  String get pregnancyCheckPrenatalVitamins =>
      'فيتامينات الحمل حسب نصيحة الطبيب';

  @override
  String get pregnancyCheckRest => 'ارتحي عند التعب';

  @override
  String get pregnancyCheckAnatomyScan => 'سونار تفصيلي حوالي الأسبوع 20';

  @override
  String get pregnancyCheckMovement => 'لاحظي حركة الجنين يومياً';

  @override
  String get pregnancyCheckHydration => 'اشربي ماءً كافياً طوال اليوم';

  @override
  String get pregnancyCheckBirthPlan => 'ناقشي خطة الولادة مع طبيبكِ';

  @override
  String get pregnancyCheckHospitalBag => 'ابدئي تجهيز حقيبة المستشفى';

  @override
  String get pregnancyCheckKickCounts => 'عدّي الركلات يومياً في الثلث الأخير';

  @override
  String get aiInsightPrenatalTitle => 'نصيحة حمل';

  @override
  String get aiInsightConceiveTitle => 'نصيحة خصوبة';

  @override
  String get aiInsightAvoidTitle => 'نصيحة وقاية';

  @override
  String get aiInsightWellnessTitle => 'نصيحة صحية';

  @override
  String get goalModeConceiveTitle => 'محاولة الحمل';

  @override
  String get goalModeAvoidTitle => 'تجنّب الحمل';

  @override
  String get goalModeGeneralTitle => 'الصحة العامة';

  @override
  String get goalModeTodayFocus => 'تركيز اليوم';

  @override
  String get goalModeChecklist => 'قائمتك';

  @override
  String get goalModeReportInsights => 'رؤى لهدفك';

  @override
  String get goalModeFertilityToday => 'الخصوبة اليوم';

  @override
  String get goalModeFertilityHigh => 'عالية';

  @override
  String get goalModeFertilityModerate => 'متوسطة';

  @override
  String get goalModeFertilityLow => 'منخفضة';

  @override
  String get goalModeFertilityUnknown => 'سجّلي أكثر';

  @override
  String get goalModeTestDate => 'اختبار حمل';

  @override
  String get goalModeOvulationToday => 'يوم الإباضة اليوم';

  @override
  String get goalModeConceiveSelfCare => 'عناية الخصوبة';

  @override
  String get goalModeConceiveSelfCareSub =>
      'عادات يومية صغيرة تدعم محاولة الحمل.';

  @override
  String get goalModeAvoidSelfCare => 'عناية الوقاية';

  @override
  String get goalModeAvoidSelfCareSub =>
      'ابقي واعية لأيام الخصوبة وروتين منع الحمل.';

  @override
  String get goalModeGeneralSelfCare => 'صحة الدورة';

  @override
  String get goalModeGeneralSelfCareSub => 'عناية شاملة لجسمك في كل المراحل.';

  @override
  String get pregnancyTrackingTitle => 'تتبّع حملك';

  @override
  String get pregnancyTrackingSubtitle =>
      'سجّلي الوزن وعدّي الركلات ووقتي الانقباضات — أسبوعاً بأسبوع مع Lune.';

  @override
  String get pregnancyWeightTitle => 'الوزن';

  @override
  String get pregnancyWeightHint => 'وزن اليوم';

  @override
  String get pregnancyWeightUnit => 'كغ';

  @override
  String get pregnancyWeightSave => 'حفظ';

  @override
  String get pregnancyWeightSaved => 'تم حفظ الوزن';

  @override
  String get pregnancyWeightInvalid => 'أدخلي وزناً صحيحاً بين 30 و 200 كغ';

  @override
  String pregnancyWeightLatest(double kg) {
    return '$kg كغ (آخر قياس)';
  }

  @override
  String get pregnancyKicksTitle => 'عداد الركلات';

  @override
  String get pregnancyKicksHint =>
      'عدّي 10 ركلات — اضغطي عند كل حركة. اتصلي بطبيبكِ إذا قلّت الحركة.';

  @override
  String get pregnancyKicksStart => 'ابدئي العد';

  @override
  String get pregnancyKicksTap => 'ركلة!';

  @override
  String get pregnancyKicksEnd => 'إيقاف';

  @override
  String pregnancyKicksToday(int count) {
    return '$count ركلة اليوم';
  }

  @override
  String get pregnancyContractionsTitle => 'مؤقت الانقباضات';

  @override
  String get pregnancyContractionsHint =>
      'ابدئي عند بداية الانقباض وأوقفيه عند الانتهاء. اتصلي بطبيبكِ إذا أصبحت منتظمة قبل الأسبوع 37.';

  @override
  String get pregnancyContractionStart => 'بدأ الانقباض';

  @override
  String get pregnancyContractionEnd => 'انتهى الانقباض';

  @override
  String pregnancyContractionsToday(int count) {
    return '$count اليوم';
  }

  @override
  String pregnancyContractionAvg(int seconds) {
    return 'متوسط $seconds ث';
  }

  @override
  String pregnancyContractionInterval(int minutes) {
    return 'كل $minutes د';
  }

  @override
  String get pregnancyContractionRecent => 'الأحدث اليوم';

  @override
  String pregnancyContractionDuration(int seconds) {
    return '$seconds ث';
  }

  @override
  String get onboardingDateFormat => 'تنسيق التاريخ';

  @override
  String get cycleSettingsTitle => 'إعدادات الدورة';

  @override
  String get cycleSettingsSubtitle =>
      'تُحدّث الرئيسية وAI والتذكيرات في كل التطبيق.';

  @override
  String get cycleSettingsSave => 'حفظ ومزامنة';

  @override
  String get onboardingNoEmailNote =>
      'لا حاجة للإيميل — بياناتك تبقى على جهازك.';

  @override
  String get onboardingPartialSave =>
      'تم حفظ الإعداد محليًا. يمكنك تعديل إعدادات الدورة من الحساب في أي وقت.';

  @override
  String get accountRerunSetup => 'إعادة الإعداد';

  @override
  String get accountRerunSetupSubtitle =>
      'أدخلي اسمك وهدفك وأساسيات الدورة من جديد';

  @override
  String get rerunSetupConfirmTitle => 'هل أنت متأكدة؟';

  @override
  String get rerunSetupConfirmBody =>
      'سيتم إعادة تشغيل الإعداد الأولي. بياناتك الحالية لن تضيع، لكن ستحتاجين لإعادة إدخال تفضيلاتك.';

  @override
  String get rerunSetupConfirmYes => 'نعم، إعادة الإعداد';

  @override
  String get rerunSetupConfirmCancel => 'إلغاء';

  @override
  String get accountChangeGoal => 'هدفك';

  @override
  String get accountChangeGoalHint =>
      'التطبيق يتكيّف فوراً — الرئيسية والتقارير والعناية والـ AI.';

  @override
  String get goalChangedSnackbar => 'تم تحديث الهدف — التطبيق صار مخصّصاً لكِ';

  @override
  String accountUserId(String id) {
    return 'معرّف الحساب: $id';
  }

  @override
  String get premiumRefreshStatus => 'التحقق من حالة الاشتراك';

  @override
  String get signOutConfirmTitle => 'تسجيل الخروج؟';

  @override
  String get signOutConfirmBody =>
      'بياناتك المحلية ستبقى على هذا الجهاز. يمكنك تسجيل الدخول مجدداً في أي وقت.';

  @override
  String get guestModeTitle => 'وضع ضيف خاص';

  @override
  String get guestModeLabel => 'ملف محلي · بدون إيميل';

  @override
  String get guestModeBody =>
      'تستخدمين Lune بخصوصية. سجّلي الدخول فقط للمجتمعات أو Premium أو النسخ السحابي.';

  @override
  String get signInOptionalTitle => 'تسجيل الدخول (اختياري)';

  @override
  String get signInOptionalSubtitle =>
      'للمجتمعات والاشتراك Premium والنسخ السحابي';

  @override
  String get communityRequiresAccount =>
      'المجتمعات تحتاج تسجيل دخول لحماية الخصوصية. بيانات دورتك لا تُشارك أبداً.';

  @override
  String get aiGuestHint =>
      'يعمل على جهازك. سجّلي الدخول لتفعيل ميزات الذكاء الاصطناعي السحابية.';

  @override
  String get editProfileTitle => 'ملفك الشخصي';

  @override
  String get avatarPickTitle => 'اختاري شخصيتك';

  @override
  String get avatarUsePhoto => 'استخدمي صورتي';

  @override
  String get communityAttachPhoto => 'أضيفي صورة';

  @override
  String get communityAttachVideo => 'أضيفي فيديو';

  @override
  String get editProfileSubtitle => 'اختاري شخصية ممتعة أو صورتك الشخصية.';

  @override
  String get editProfileSave => 'حفظ الملف';

  @override
  String get partnerTitle => 'وضع الشريك';

  @override
  String get partnerSubtitle => 'شاركي ما تختارينه فقط مع شريك واحد موثوق';

  @override
  String get partnerIntro =>
      'شريكك يشوف بطاقة محدودة: مرحلة الدورة وعدد الأيام للدورة القادمة — لا شيء غير ذلك. أنتِ تتحكمين بكل عنصر وتقدرين تفكين الربط بأي وقت.';

  @override
  String get partnerSignInPrompt =>
      'وضع الشريك يحتاج تسجيل دخول ليبقى الربط خاصًا وآمنًا.';

  @override
  String get partnerOwnerSection => 'مشاركة دورتي';

  @override
  String get partnerYourCode => 'كود الدعوة الخاص بك';

  @override
  String get partnerCodeCopied => 'تم نسخ الكود';

  @override
  String get partnerRegenerate => 'كود جديد';

  @override
  String get partnerShareWhat => 'ماذا يستطيع شريكك أن يرى';

  @override
  String get partnerSharePhase => 'مرحلة الدورة واليوم';

  @override
  String get partnerShareNextPeriod => 'الأيام حتى الدورة القادمة';

  @override
  String get partnerSharePain => 'مستوى الألم الأخير';

  @override
  String get partnerLinked => 'الشريك مرتبط';

  @override
  String get partnerNotLinked => 'لا يوجد شريك مرتبط بعد — شاركي الكود';

  @override
  String get partnerUnlink => 'فك ربط الشريك';

  @override
  String get partnerUnlinked => 'تم فك الربط';

  @override
  String get partnerPublishNow => 'تحديث البطاقة المشتركة الآن';

  @override
  String get partnerPublished => 'تم تحديث البطاقة المشتركة';

  @override
  String get partnerNothingToPublish => 'لا توجد مشاركة — اربطي شريكًا أولًا';

  @override
  String get partnerPartnerSection => 'أنا الشريك';

  @override
  String get partnerEnterCode => 'أدخل كود الدعوة الخاص بها';

  @override
  String get partnerCodeHint => 'مثال: K7XF2M';

  @override
  String get partnerJoin => 'ربط';

  @override
  String get partnerJoinedOk => 'تم الربط بنجاح';

  @override
  String get partnerInvalidCode => 'الكود غير صحيح أو منتهي';

  @override
  String get partnerLeave => 'إزالة الربط';

  @override
  String get partnerStatusTitle => 'دورتها اليوم';

  @override
  String get partnerStatusPhase => 'المرحلة';

  @override
  String get partnerStatusCycleDay => 'يوم الدورة';

  @override
  String partnerStatusNextPeriod(int days) {
    return '$days يوم حتى الدورة القادمة';
  }

  @override
  String get partnerStatusPain => 'مستوى الألم الأخير';

  @override
  String get partnerStatusPeriodActive => 'الدورة نشطة الآن';

  @override
  String get partnerStatusEmpty =>
      'لا يوجد شيء مشترك بعد — اطلب منها تحديث البطاقة المشتركة.';

  @override
  String partnerStatusUpdated(String time) {
    return 'آخر تحديث $time';
  }

  @override
  String get partnerTipTitle => 'كيف تدعمها اليوم';

  @override
  String get partnerTipMenstruation =>
      'طاقتها قد تكون منخفضة. مشروب دافئ وصبر وتخفيف المهام عنها يصنعون فرقًا كبيرًا.';

  @override
  String get partnerTipFollicular =>
      'الطاقة في ارتفاع — وقت رائع لتخططا لشيء ممتع معًا.';

  @override
  String get partnerTipOvulation =>
      'غالبًا تشعر بأفضل حالاتها. استمتعا بوقت نوعي معًا.';

  @override
  String get partnerTipLuteal =>
      'قد تظهر أعراض ما قبل الدورة: كن صبورًا ولطيفًا أكثر، اللفتات الصغيرة أهم ما يكون الآن.';

  @override
  String get partnerTipDefault => 'اطمئن عليها واسألها كيف تشعر اليوم.';

  @override
  String get communityFilterAll => 'الكل';

  @override
  String get communityAnswered => 'تمت الإجابة';

  @override
  String get communityTabSaved => 'المحفوظ';

  @override
  String get communitySavedEmpty =>
      'لا منشورات محفوظة بعد. اضغطي على أيقونة الحفظ في أي منشور.';

  @override
  String get communityShare => 'مشاركة';

  @override
  String get communityShareVia => 'مشاركة من Lune';

  @override
  String get communityPostSaved => 'تم حفظ المنشور';

  @override
  String get communityPostUnsaved => 'أُزيل من المحفوظ';

  @override
  String get communityDeletePost => 'حذف المنشور';

  @override
  String get communityDeleteComment => 'حذف التعليق';

  @override
  String get communityDeletePostConfirm => 'حذف هذا المنشور نهائياً؟';

  @override
  String get communityDeleteCommentConfirm =>
      'هل أنت متأكد من حذف هذا التعليق؟';

  @override
  String get communityPostDeleted => 'تم حذف المنشور';

  @override
  String get communityCommentDeleted => 'تم حذف التعليق';

  @override
  String get communityReply => 'رد';

  @override
  String communityReplyingTo(String alias) {
    return 'رد على $alias';
  }

  @override
  String get communityMarkBestAnswer => 'تعيين كأفضل إجابة';

  @override
  String get communityBestAnswer => 'أفضل إجابة';

  @override
  String get communityCatCulture => 'ثقافة';

  @override
  String get communityCatAge => 'شابات';

  @override
  String get communityHomeCardTitle => 'المجتمع';

  @override
  String get communityHomeCardSubtitle => 'دعم وأسئلة وأخوة — باسم مستعار فقط';

  @override
  String get communityNotifTitle => 'نشاط المجتمع';

  @override
  String get communityNotifSubtitle => 'إعجابات وتعليقات على منشوراتك';

  @override
  String get communityTextOnlyNote =>
      'الصور والفيديو للمشتركين المميزين. البلاغات تخفي المنشورات غير الآمنة تلقائياً.';

  @override
  String get communityEditPost => 'تعديل المنشور';

  @override
  String get communityPostUpdated => 'تم تحديث المنشور';

  @override
  String get communityEdited => 'معدّل';

  @override
  String get communityActivityTitle => 'النشاط';

  @override
  String get communityActivityEmpty =>
      'لا نشاط بعد. عندما يعجب أحد أو يعلّق على منشوراتك، يظهر هنا.';

  @override
  String communityActivityComment(String alias) {
    return '$alias علّقت على منشورك';
  }

  @override
  String communityActivityLike(String alias) {
    return '$alias أعجبت بمنشورك';
  }

  @override
  String communityActivityReply(String alias) {
    return '$alias ردّت على تعليقك';
  }

  @override
  String get communityMarkAllRead => 'تعليم الكل كمقروء';

  @override
  String get communitySortNewest => 'الأحدث';

  @override
  String get communitySortDiscussed => 'الأكثر نقاشاً';

  @override
  String get communityFilterMyPosts => 'منشوراتي';

  @override
  String get communitySearchPosts => 'ابحثي في المنشورات...';

  @override
  String get communityCopied => 'تم النسخ';

  @override
  String get communityCopy => 'نسخ النص';

  @override
  String get communityGuidelinesShort => 'القواعد';

  @override
  String get communityPollAddOption => 'إضافة خيار';

  @override
  String communityPollOptionHint(int number) {
    return 'الخيار $number';
  }

  @override
  String get communityPollNeedsOptions => 'أضيفي خيارين على الأقل للاستطلاع';

  @override
  String communityPollVotesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صوت',
      many: '$count صوتًا',
      few: '$count أصوات',
      two: 'صوتان',
      one: 'صوت واحد',
      zero: 'لا أصوات بعد',
    );
    return '$_temp0';
  }

  @override
  String get communityPollTapToVote => 'اضغطي على خيار للتصويت';

  @override
  String get communityFilters => 'الفلاتر';

  @override
  String get communityFilterCategory => 'الفئة';

  @override
  String get communityFilterPostType => 'نوع المنشور';

  @override
  String get communityFilterReset => 'إعادة تعيين';

  @override
  String get communityFilterApply => 'تطبيق';

  @override
  String get storyChooseCommunity => 'مشاركة القصة في...';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'أمس',
    );
    return '$_temp0';
  }

  @override
  String get reactionHeart => 'حب';

  @override
  String get reactionHug => 'احتضان';

  @override
  String get reactionCelebrate => 'احتفال';

  @override
  String get reactionStrong => 'قوة';

  @override
  String get communityMemberProfile => 'ملف العضوة';

  @override
  String get communityRecentPosts => 'آخر المنشورات';

  @override
  String get communityNoRecentPosts => 'لا منشورات عامة بعد';

  @override
  String get communityWeeklyQuestion => 'سؤال الأسبوع';

  @override
  String get communityWeeklyAnswer => 'شاركي إجابتك';

  @override
  String get premiumUpsellTitle => 'Lune Premium';

  @override
  String get premiumUpsellSubscribe => 'عرض الاشتراك';

  @override
  String get premiumUpsellNotNow => 'ليس الآن';

  @override
  String get moderationRejectedTitle => 'لم يُقبل المحتوى';

  @override
  String get moderationRejectedBody =>
      'لم تتم الموافقة على منشورك أو تعليقك بعد مراجعة إرشادات المجتمع.';

  @override
  String get moderationRejectedTips =>
      'نصائح: لا تشاركي أرقام هواتف أو روابط أو بريد إلكتروني. حافظي على الدعم والاحترام. المحتوى الطبي يحتاج استشارة مختص.';

  @override
  String get moderationContactSupport => 'تواصل مع الدعم';

  @override
  String get moderationTryAgain => 'تعديل وإعادة المحاولة';

  @override
  String get aboutTitle => 'عن التطبيق';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get aboutTagline =>
      'Lune تعني القمر — رفيقتكِ الخاصة لعافية أطوار دورتكِ. بياناتك على جهازك؛ السحابة والذكاء الاصطناعي والمجتمعات اختيارية.';

  @override
  String get insightsCycleRegularityScore => 'انتظام الدورة (CRS)';

  @override
  String get insightsPeriodRegularityScore => 'انتظام الحيض (PRS)';

  @override
  String get insightsGraphEmpty =>
      'سجّلي المزيد لعرض هذا الرسم — تتبّعي الأعراض والوزن والنوم وغيرها في التسجيل اليومي.';

  @override
  String get predictedSymptomsTitle => 'أعراض محتملة';

  @override
  String get predictedSymptomsDisclaimer =>
      'بناءً على دوراتك السابقة في نفس يوم الدورة — ليست تنبؤاً طبياً.';

  @override
  String get predictedSymptomsToday => 'اليوم';

  @override
  String get predictedSymptomsTomorrow => 'غداً';

  @override
  String predictedSymptomsLikelihood(int percent) {
    return 'احتمال $percent%';
  }

  @override
  String get reportCycleHistoryTable => 'الدورات الأخيرة';

  @override
  String get reportCycleHistoryStart => 'البداية';

  @override
  String get reportCycleHistoryCycle => 'الدورة';

  @override
  String get reportCycleHistoryPeriod => 'الحيض';

  @override
  String get reportPregnancyTestDate => 'تاريخ اختبار الحمل المتوقع';

  @override
  String get ovulationReminder => 'تذكير الإباضة';

  @override
  String get notificationsWellnessNote =>
      'تذكيرات الحبوب والمنتجات الصحية واللولب في العناية تتبع المفتاح الرئيسي أعلاه.';

  @override
  String get smartPhaseReminder => 'تذكيرات ذكية حسب المرحلة';

  @override
  String get smartPhaseReminderSubtitle =>
      'نصيحة يومية داعمة تتكيف مع مرحلتك في الدورة أو أسبوع الحمل.';

  @override
  String get latePeriodReminder => 'تحذير تأخّر الدورة';

  @override
  String get latePeriodReminderSubtitle =>
      'تنبيه لطيف إذا تأخّرت دورتك يومين عن الموعد المتوقع.';

  @override
  String get sendTestNotification => 'إرسال إشعار تجريبي';

  @override
  String get testNotificationSent => 'تم الإرسال! تحقّقي من شريط الإشعارات.';

  @override
  String get testNotificationBlocked =>
      'الإشعارات مغلقة لتطبيق Lune. فعّليها من إعدادات النظام.';

  @override
  String get graphExportShared => 'الرسم جاهز للمشاركة.';

  @override
  String get adminTitle => 'لوحة الإدارة';

  @override
  String get adminAccessDenied => 'ليس لديك صلاحيات الإدارة.';

  @override
  String get adminDashboard => 'لوحة المعلومات';

  @override
  String get adminReports => 'التقارير';

  @override
  String get adminSettings => 'الإعدادات';

  @override
  String get adminTotalUsers => 'إجمالي المستخدمين';

  @override
  String get adminPendingReports => 'تقارير معلقة';

  @override
  String get adminRecentActivity => 'آخر النشاطات';

  @override
  String get adminNoActivity => 'لا نشاطات بعد.';

  @override
  String get adminReportAuthor => 'الكاتب';

  @override
  String get adminReportReason => 'السبب';

  @override
  String get adminReportStatus => 'الحالة';

  @override
  String get adminReportPending => 'معلّق';

  @override
  String get adminReportResolved => 'تمت المعالجة';

  @override
  String get adminReportDismiss => 'رفض التقرير';

  @override
  String get adminHidePost => 'إخفاء المنشور';

  @override
  String get adminBanUser => 'حظر المستخدم';

  @override
  String get adminUnbanUser => 'إلغاء حظر المستخدم';

  @override
  String get adminUserBanned => 'تم حظر المستخدم';

  @override
  String get adminUserUnbanned => 'تم إلغاء حظر المستخدم';

  @override
  String get adminPostHidden => 'تم إخفاء المنشور';

  @override
  String get adminSettingsSaved => 'تم حفظ الإعدادات';

  @override
  String get adminCommunityEnabled => 'المجتمع مفعل';

  @override
  String get adminAiEducation => 'التعليم بالذكاء الاصطناعي';

  @override
  String get adminAnnouncement => 'إعلان';

  @override
  String get adminAnnouncementTitleEn => 'العنوان (إنجليزي)';

  @override
  String get adminAnnouncementTitleAr => 'العنوان (عربي)';

  @override
  String get adminAnnouncementBodyEn => 'المحتوى (إنجليزي)';

  @override
  String get adminAnnouncementBodyAr => 'المحتوى (عربي)';

  @override
  String get adminSupportUrl => 'رابط الدعم';

  @override
  String get adminPrivacyUrl => 'رابط الخصوصية';

  @override
  String get adminSave => 'حفظ الإعدادات';

  @override
  String get communityEditComment => 'تعديل التعليق';

  @override
  String get communityCommentUpdated => 'تم تحديث التعليق';

  @override
  String get communityPickImage => 'اختر صورة';

  @override
  String get communityPickVideo => 'اختر فيديو';

  @override
  String get communityAddMedia => 'إضافة صورة أو فيديو';

  @override
  String get communityPostAnonymously => 'نشر بشكل مجهول';

  @override
  String get communityMediaPremiumGate =>
      'إرفاق الصور والفيديوهات ميزة حصرية للمشتركين المميزين. قم بالترقية لإلغاء قفل منشورات الوسائط.';

  @override
  String get premiumFeatureTitle => 'ميزة مميزة';

  @override
  String get upgradeToPremium => 'ترقية';

  @override
  String get communityPendingReview => 'بانتظار المراجعة';

  @override
  String get communityThreadTitle => 'الردود';

  @override
  String get communityNoReplies => 'لا توجد ردود بعد';

  @override
  String communityViewReplies(int count) {
    return 'عرض $count رد';
  }

  @override
  String get adminPendingModeration => 'بانتظار المراجعة';

  @override
  String get adminApprovePost => 'قبول المنشور';

  @override
  String get adminRejectPost => 'رفض المنشور';

  @override
  String get adminNoReports => 'لا تقارير أو مراجعات معلقة';

  @override
  String get adminPendingComments => 'تعليقات بانتظار المراجعة';

  @override
  String get adminApproveComment => 'قبول التعليق';

  @override
  String get adminRejectComment => 'رفض التعليق';

  @override
  String get storyCreate => 'إنشاء قصة';

  @override
  String get storyPickImage => 'صورة من المعرض';

  @override
  String get storyPickMultiple => 'عدة صور';

  @override
  String get storyTextOnly => 'قصة نصية';

  @override
  String get storyTextOnlyHint => 'خلفية ملونة مع نص';

  @override
  String get storyTextHint => 'ماذا تفكرين؟';

  @override
  String get storyPublish => 'مشاركة القصة';

  @override
  String get storyPublished => 'تم مشاركة القصة!';

  @override
  String get storyPremiumRequired => 'القصص بالوسائط للمشتركين المميزين';

  @override
  String get storyYourStory => 'قصتك';

  @override
  String get storyViewAll => 'عرض كل القصص';

  @override
  String get aiQuickActionsTitle => 'شو بدكِ اليوم؟';

  @override
  String get aiFeatureBriefing => 'ملخص اليوم';

  @override
  String get aiFeatureBriefingPrompt => 'اعطيني ملخص يومي';

  @override
  String get aiFeaturePatterns => 'أنماط دورتي';

  @override
  String get aiFeaturePatternsPrompt => 'حللي أنماط دورتي من الأشهر الأخيرة';

  @override
  String get aiFeatureNutrition => 'نصائح غذائية';

  @override
  String get aiFeatureNutritionPrompt => 'شو أكل اليوم حسب مرحلة دورة؟';

  @override
  String get aiFeaturePartner => 'رسالة لشريكي';

  @override
  String get aiFeaturePartnerPrompt => 'ساعدني أحكيل شريكي كيف بحس اليوم';

  @override
  String get aiFeatureMood => 'يوميات المزاج';

  @override
  String get aiFeatureMoodPrompt => 'بدي أكتب كيف بحس';

  @override
  String get aiFeatureEmergency => 'مساعدة عاجلة';

  @override
  String get aiEmergencyPrompt => 'أنا بألم وبدني مساعدة حالاً';

  @override
  String get aiEmergencyTooltip => 'إرشادات سريعة لتخفيف الألم';

  @override
  String get aiFeatureFertility => 'رؤى الخصوبة';

  @override
  String get aiFeatureFertilityPrompt => 'ساعديني أفهم أيام الخصوبة';

  @override
  String get aiFeatureWeight => 'الوزن والتغذية';

  @override
  String get aiFeatureWeightPrompt => 'شو أكل حسب مرحلتي؟';

  @override
  String get aiFeatureIntimacy => 'إرشادات العلاقة';

  @override
  String get aiFeatureIntimacyPrompt => 'نصائح للعلاقة أثناء دورتي';

  @override
  String get dailyBriefingTitle => 'ملخص اليوم';

  @override
  String get dailyBriefingLoading => 'جاري تحضير ملخص يومكِ...';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get privacyEffectiveDate => 'تاريخ السريان';

  @override
  String get privacyOpenExternal => 'فتح في المتصفح';

  @override
  String get privacyContactTitle => 'تواصلي معنا';

  @override
  String privacyContactBody(Object email) {
    return 'إذا كانت لديكِ أسئلة حول سياسة الخصوصية هذه أو ترغبين في ممارسة حقوق بياناتك، تواصلي معنا عبر: $email';
  }

  @override
  String get privacyP1Title => '١. المقدمة';

  @override
  String get privacyP1Body =>
      'Lune (\"نحن\" أو \"التطبيق\") هو تطبيق لتتبع الدورة الشهرية مصمم لمساعدة المستخدمات على مراقبة صحتهن وعافيتهن. توضح سياسة الخصوصية هذه كيف نجمع ونستخدم ونكشف ونحمي معلوماتك الشخصية عند استخدامك لتطبيقنا وخدماتنا ذات الصلة. باستخدام Lune، فإنكِ توافقين على الممارسات الموضحة في هذه السياسة. إذا لم توافقين، يرجى التوقف عن استخدام التطبيق.';

  @override
  String get privacyP2Title => '٢. المعلومات التي نجمعها';

  @override
  String get privacyP2Body =>
      'نجمع الأنواع التالية من المعلومات:\n\n• بيانات الصحة والدورة: تواريخ الدورة الشهرية والأعراض والمزاج ومستويات النزف والبيانات الصحية الأخرى التي تسجلينها طوعاً.\n• معلومات الحساب: البريد الإلكتروني والاسم وطريقة تسجيل الدخول عند التسجيل (بريد/كلمة مرور، Google، أو Apple). عند استخدام التطبيق كضيفة، ننشئ حساباً مجهولاً عبر Firebase مرتبطاً بجهازكِ دون جمع بريدك الإلكتروني.\n• محتوى المجتمع: المنشورات والتعليقات والتفاعلات والمعلومات الشخصية التي تشاركينها في ميزات المجتمع (إذا اخترتِ المشاركة).\n• معلومات الجهاز: معرفات الجهاز الأساسية المطلوبة للإشعارات وأمان التطبيق (Firebase App Check) وعمل التطبيق.\n• بيانات المحادثة الذكية: الرسائل التي ترسلينها للمساعد الذكي تُعالَج عبر مزوّدي ذكاء اصطناعي من أطراف ثالثة. الضيفات: سجل المحادثة يبقى على الجهاز فقط. المسجّلات: قد يُخزَّن سجل المحادثة في حسابكِ السحابي (Firebase) لاستعادة المحادثات.\n• الاستخدام والتشخيص: وقت آخر نشاط تقريبي وتقارير الأعطال عبر Firebase Crashlytics في الإصدارات النهائية لمساعدتنا على إصلاح الأخطاء. لا نستخدم متتبعات إعلانات من أطراف ثالثة.';

  @override
  String get privacyP3Title => '٣. كيف نستخدم معلوماتك';

  @override
  String get privacyP3Body =>
      'تُستخدم معلوماتك من أجل:\n\n• توفير تتبع الدورة والتنبؤات والرؤى الشخصية الأساسية.\n• تقديم إرشادات صحية مدعومة بالذكاء الاصطناعي وملخصات يومية.\n• تمكين ميزات المجتمع (المنشورات، التعليقات، القصص) إذا اخترتِ المشاركة.\n• معالجة النسخ الاحتياطي السحابي إذا فعلتِ النسخ الاحتياطي المشفر.\n• إرسال إشعارات اختيارية (تذكيرات الدورة، تذكيرات الحبوب).\n• تحسين أداء التطبيق وتشخيص الأعطال وإصلاح الأخطاء.\n• ضمان السلامة ومنع سوء استخدام ميزات المجتمع.';

  @override
  String get privacyP4Title => '٤. تخزين البيانات والأمان';

  @override
  String get privacyP4Body =>
      'يتم تخزين بيانات الدورة والصحة محلياً على جهازكِ افتراضياً. إذا فعلتِ المزامنة السحابية، يتم تشفير بياناتكِ باستخدام تشفير AES-256 وتخزينها بشكل آمن في Google Firebase (Firestore). يتم تخزين مفاتيح التشفير في التخزين الآمن لجهازكِ (Android Keystore / iOS Keychain). نطبق تدابير أمان معتمدة تشمل التشفير (TLS) والمصادقة الآمنة وضوابط الوصول.';

  @override
  String get privacyP5Title => '٥. خدمات الطرف الثالث';

  @override
  String get privacyP5Body =>
      'نستخدم خدمات الطرف الثالث التالية:\n\n• Google Firebase (المصادقة، Firestore، الدوال السحابية، Cloud Messaging، الاستضافة، App Check، Crashlytics): الحسابات وتخزين البيانات والإشعارات والأمان وتقارير الأعطال.\n• Google Gemini AI: محادثة الذكاء الاصطناعي ومعالجة المحتوى. تُرسَل الرسائل إلى Google للمعالجة وفق شروط واجهة Google.\n• DeepSeek AI: مزوّد ذكاء اصطناعي بديل للمحادثة والتحليل عند استخدامه من الواجهة الخلفية. تُرسَل الرسائل إلى DeepSeek للمعالجة وفق شروطهم.\n• Google Play Billing: مدفوعات الاشتراك المميز على Android (تُعالَج عبر Google).\n\nلكل مزوّد سياسة خصوصية خاصة. نشجعكِ على مراجعتها. لا نبيع بياناتكِ الشخصية.';

  @override
  String get privacyP6Title => '٦. حقوقك في البيانات';

  @override
  String get privacyP6Body =>
      'لكِ الحق في:\n\n• الوصول إلى بياناتك: عرض جميع البيانات المخزنة عنكِ داخل التطبيق.\n• تصدير بياناتك: تنزيل بيانات الدورة كملف نسخة احتياطية محلية.\n• حذف بياناتك: حذف حسابكِ وجميع البيانات المرتبطة به نهائياً من مركز الخصوصية.\n• سحب الموافقة: سحب الموافقة على المزامنة السحابية أو ميزات الذكاء الاصطناعي أو المشاركة في المجتمع في أي وقت.\n• إلغاء الاشتراك من الإشعارات: تعطيل أي نوع من الإشعارات من الإعدادات.\n\nإذا كنتِ في الاتحاد الأوروبي/المملكة المتحدة، قد تكون لكِ حقوق إضافية بموجب GDPR/UK GDPR. لممارسة هذه الحقوق، استخدمي مركز الخصوصية في التطبيق أو تواصلي معنا عبر البريد الإلكتروني أدناه.';

  @override
  String get privacyP7Title => '٧. خصوصية الأطفال';

  @override
  String get privacyP7Body =>
      'Lune غير مخصص للأطفال دون سن 13 عاماً (أو سن الموافقة المعمول به في نطاقك القضائي). لا نجمع عن علم معلومات شخصية من الأطفال. إذا اكتشفنا أن طفلاً قد قدم لنا بيانات شخصية، سنحذفها فوراً. يجب على الآباء أو الأوصياء الذين يعتقدون أن طفلاً قد استخدم Lune الاتصال بنا فوراً.';

  @override
  String get privacyP8Title => '٨. الاحتفاظ بالبيانات';

  @override
  String get privacyP8Body =>
      'نحتفظ ببياناتكِ طالما تحتفظين بحساب نشط أو حسب الحاجة لتقديم الخدمات. إذا حذفتِ حسابكِ، نزيل فوراً ملفك في Firestore والنسخ السحابية وسجل المحادثة ومحتوى المجتمع من خوادمنا ونحذف حساب Firebase Authentication. تبقى البيانات المحلية على جهازكِ حتى تلغي التثبيت أو تحذفيها يدوياً. قد تحتفظ Firebase أو Google Cloud بنسخ تقنية مؤقتة وفق سياسات بنيتها. تُحفَظ تقارير الأعطال في Crashlytics وفق إعدادات الاحتفاظ في Firebase.';

  @override
  String get privacyP9Title => '٩. النقل الدولي للبيانات';

  @override
  String get privacyP9Body =>
      'قد تتم معالجة بياناتكِ في دول غير دولتكِ، بما في ذلك الولايات المتحدة حيث قد تقع خوادم Google Firebase ومزوّدي الذكاء الاصطناعي. باستخدام Lune، فإنكِ توافقين على نقل بياناتكِ إلى هذه المواقع. نضمن وجود ضمانات مناسبة للنقل الدولي. إذا كنتِ في الاتحاد الأوروبي/المملكة المتحدة، قد تكون لكِ حقوق إضافية بموجب GDPR/UK GDPR كما هو موضّح في القسم 6.';

  @override
  String get privacyP10Title => '١٠. إخلاء المسؤولية الطبية';

  @override
  String get privacyP10Body =>
      'Lune مصمم لأغراض المعلومات وتتبع العافية فقط. ليس جهازاً طبياً ولا يقدم نصائح طبية أو تشخيصاً أو علاجاً. استشيري دائماً متخصص رعاية صحية مؤهل للمسائل الطبية. لا تعتمدي فقط على تنبؤات Lune أو المحتوى الذي ينشئه الذكاء الاصطناعي للقرارات الصحية.';

  @override
  String get privacyP11Title => '١١. التغييرات على هذه السياسة';

  @override
  String get privacyP11Body =>
      'قد نحدّث سياسة الخصوصية هذه من وقت لآخر. سنخطركِ بالتغييرات الجوهرية عبر إشعارات داخل التطبيق أو البريد الإلكتروني. استمراركِ في استخدام Lune بعد التغييرات يشكل قبولاً للسياسة المحدثة. نشجعكِ على مراجعة هذه السياسة بشكل دوري.';

  @override
  String get privacyP12Title => '١٢. تواصلي معنا';

  @override
  String get privacyP12Body =>
      'للأسئلة أو المخاوف أو طلبات البيانات المتعلقة بسياسة الخصوصية هذه، يرجى التواصل معنا عبر:';

  @override
  String get termsTitle => 'شروط الخدمة';

  @override
  String get termsP1Title => '١. قبول الشروط';

  @override
  String get termsP1Body =>
      'بتنزيل أو تثبيت أو استخدام Lune (ال\"تطبيق\")، فإنكِ توافقين على الالتزام بشروط الخدمة هذه (ال\"شروط\"). إذا لم توافقين على هذه الشروط، لا تستخدمي التطبيق. تشكل هذه الشروط اتفاقية ملزمة قانونياً بينكِ وبين Lune.';

  @override
  String get termsP2Title => '٢. وصف الخدمة';

  @override
  String get termsP2Body =>
      'Lune هو تطبيق لتتبع الدورة الشهرية يوفر:\n\n• أدوات تسجيل الدورة والتنبؤ.\n• رؤى صحية مدعومة بالذكاء الاصطناعي ومساعدة المحادثة.\n• محتوى العافية ذاتية الرعاية وتوصيات الصحة.\n• ميزات المجتمع لمشاركة التجارب.\n• خدمات النسخ الاحتياطي والمزامنة للبيانات.\n• محتوى تعليمي صحي ومقالات المجلة.\n\nالتطبيق مخصص للاستخدام الشخصي وغير التجاري فقط.';

  @override
  String get termsP3Title => '٣. حسابات المستخدمين';

  @override
  String get termsP3Body =>
      'يمكنكِ استخدام Lune كضيفة بحساب مجهول مرتبط بالجهاز، أو إنشاء حساب مسجّل عبر البريد/كلمة المرور أو Google أو Sign in with Apple (حيث يتوفر). أنتِ مسؤولة عن الحفاظ على سرية بيانات اعتماد حسابكِ. توافقين على إخطارنا فوراً بأي استخدام غير مصرح به لحسابكِ. يجب أن تكوني بعمر 13 عاماً على الأقل لاستخدام التطبيق. نحتفظ بالحق في تعليق أو إنهاء الحسابات التي تنتهك هذه الشروط.';

  @override
  String get termsP4Title => '٤. سلوك المستخدم';

  @override
  String get termsP4Body =>
      'توافقين على عدم:\n\n• استخدام التطبيق لأي غرض غير قانوني.\n• نشر محتوى ضار أو مسيء أو مضلل في ميزات المجتمع.\n• انتحال شخصية شخص أو كيان آخر.\n• محاولة الوصول إلى حسابات أو بيانات مستخدمين آخرين.\n• رفع فيروسات أو تعليمات برمجية خبيثة.\n• محاولة هندسة عكسية أو تفكيك التطبيق.\n• استخدام أدوات آلية للتفاعل مع التطبيق.\n• إرسال رسائل مزعجة أو مضايقة أعضاء المجتمع الآخرين.\n\nانتهاك هذه القواعد قد يؤدي إلى إنهاء الحساب فوراً.';

  @override
  String get termsP5Title => '٥. ميزات المجتمع';

  @override
  String get termsP5Body =>
      'يقدم Lune ميزات مجتمع اختيارية حيث يمكن للمستخدمات مشاركة المنشورات والتعليقات والقصص. بنشر المحتوى، تمنحين Lune ترخيصاً غير حصري وبدون عوائد لعرض وتوزيع وتخزين محتواكِ داخل التطبيق. تحتفظين بملكية محتواكِ. نحتفظ بالحق في إزالة المحتوى الذي ينتهك هذه الشروط أو الذي يبلغ عنه مستخدمون آخرون. يمكنكِ حظر مستخدمين آخرين وإدارة إعدادات خصوصية المجتمع في أي وقت.';

  @override
  String get termsP6Title => '٦. الاشتراكات والمدفوعات';

  @override
  String get termsP6Body =>
      'يقدم Lune ميزات مميزة من خلال الاشتراكات داخل التطبيق المعالجة عبر Google Play Billing. تتجدد الاشتراكات تلقائياً ما لم يتم إلغاؤها قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يمكنكِ إدارة الاشتراكات من خلال إعدادات حساب Google Play. تتم معالجة الاستردادات وفقاً لسياسة استرداد Google Play. تبقى الميزات المجانية متاحة بدون اشتراك.';

  @override
  String get termsP7Title => '٧. الملكية الفكرية';

  @override
  String get termsP7Body =>
      'التطبيق، بما في ذلك تصميمه وبرامجه ورسوماته وشعاراته ومحتواه، هو ملكية فكرية لـ Lune ومحمي بموجب حقوق النشر والعلامة التجارية وغيرها من القوانين. لا يجوز لكِ نسخ أو تعديل أو توزيع أو إنشاء أعمال مشتقة بناءً على التطبيق دون إذن خطي صريح منا. اسم Lune وشعاره والعلامات ذات الصلة هي علامات تجارية لـ Lune.';

  @override
  String get termsP8Title => '٨. إخلاء ضمانات';

  @override
  String get termsP8Body =>
      'يُقدم التطبيق \"كما هو\" و\"حسب التوفر\" دون أي ضمانات من أي نوع، سواء صريحة أو ضمنية. لا نضمن أن التطبيق سيكون دون انقطاع أو خالي من الأخطاء أو آمناً. التطبيق ليس جهازاً طبياً ولا يجب استخدامه كبديل عن النصيحة الطبية المهنية أو التشخيص أو العلاج. تنبؤات الدورة هي تقديرات وقد لا تكون دقيقة.';

  @override
  String get termsP9Title => '٩. تحديد المسؤولية';

  @override
  String get termsP9Body =>
      'إلى أقصى حد يسمح به القانون، لا تتحمل Lune المسؤولية عن أي أضرار غير مباشرة أو عرضية أو خاصة أو تبعية أو عقابية تنشأ عن استخدامكِ للتطبيق. لا تتجاوز مسؤوليتنا الإجمالية المبلغ الذي دفعتيه للتطبيق في الاثني عشر شهراً السابقة للمطالبة. هذا التحديد ينطبق بغض النظر عن النظرية القانونية.';

  @override
  String get termsP10Title => '١٠. الإنهاء';

  @override
  String get termsP10Body =>
      'يمكنكِ التوقف عن استخدام التطبيق في أي وقت وحذف حسابكِ من مركز الخصوصية. قد نعلق أو ننهي وصولكِ إذا انتهكتِ هذه الشروط أو انخرطتِ في سلوك ضار. عند الإنهاء، يتوقف حقكِ في استخدام التطبيق فوراً. تظل الأقسام المتعلقة بالملكية الفكرية وإخلاء المسؤولية وتحديد المسؤولية سارية بعد الإنهاء.';

  @override
  String get termsP11Title => '١١. القانون الحاكم والتواصل';

  @override
  String get termsP11Body =>
      'تخضع هذه الشروط للقوانين المعمول بها في نطاق مشغّل Lune، إلا حيث توفر قوانين حماية المستهلك الإلزامية في بلد إقامتكِ حمايةً إضافية. يُحل أي نزاع أولاً من خلال التفاوض بحسن نية. إذا كانت لديكِ أسئلة حول هذه الشروط، تواصلي معنا عبر:';

  @override
  String get notifRationaleTitle => 'ابقي على اطلاع';

  @override
  String get notifRationaleBody =>
      'يمكن لـ Lune إرسال تذكيرات لطيفة حول دورتك القادمة والإباضة والفحوص اليومية. يمكنكِ تخصيص أو إيقاف الإشعارات في أي وقت من الإعدادات.';

  @override
  String get notifRationaleAllow => 'السماح بالإشعارات';

  @override
  String get notifRationaleSkip => 'ليس الآن';

  @override
  String get notifOsDisabledBanner =>
      'الإشعارات مغلقة لتطبيق Lune في إعدادات النظام. لن تظهر التذكيرات حتى تفعّليها.';

  @override
  String get notifRequestPermission => 'السماح بالإشعارات';

  @override
  String get notifExactAlarmsHint =>
      'للتذكيرات في وقتها، فعّلي «المنبهات والتذكيرات» لتطبيق Lune في إعدادات أندرويد.';

  @override
  String get notifEnableExactAlarms => 'تفعيل التذكيرات الدقيقة';

  @override
  String notifScheduledCount(int count) {
    return '$count تذكيرات مجدولة';
  }

  @override
  String get notifNoScheduled =>
      'لا توجد تذكيرات مجدولة بعد. اسمحي بالإشعارات وسجّلي دورتكِ.';

  @override
  String get notifTestExactAlarmsHint =>
      'تم الإرسال، لكن التذكيرات الدقيقة معطّلة — قد تتأخر التذكيرات.';

  @override
  String notifNextReminder(String when) {
    return 'التذكير التالي: $when';
  }

  @override
  String get ageGateTitle => 'كم عمركِ؟';

  @override
  String get ageGateBody =>
      'Lune مصمم للمستخدمات بعمر 13 عاماً فأكثر. بعض الميزات مثل مناقشات المجتمع محصورة للمستخدمات فوق 18 عاماً.';

  @override
  String get ageGateUnder13 => 'أقل من 13';

  @override
  String get ageGate13to17 => '13 – 17';

  @override
  String get ageGate18plus => '18 أو أكبر';

  @override
  String get ageGateUnder13Message =>
      'نأسف، لكن Lune غير متاح للمستخدمات تحت 13 عاماً. يرجى طلب المساعدة من ولي الأمر.';

  @override
  String get ageGateMinorNote =>
      'بعض الميزات مثل مناقشات المجتمع محصورة للمستخدمات فوق 18 عاماً.';

  @override
  String get adminActive => 'نشط';

  @override
  String get adminSearch => 'بحث';

  @override
  String get adminSearchHint => 'ابحث بالبريد الإلكتروني أو UID...';

  @override
  String get adminSearchUsers => 'ابحث عن مستخدمات بالبريد أو UID';

  @override
  String get adminNoUsers => 'لا توجد مستخدمات';

  @override
  String get adminBanReporter => 'حظر المبلغ';

  @override
  String get adminFailedSave => 'فشل حفظ الإعدادات';

  @override
  String get adminError => 'خطأ';

  @override
  String get adminQuestionRejected => 'تم رفض السؤال';

  @override
  String get adminPublishAnswer => 'نشر الإجابة';

  @override
  String get adminReject => 'رفض';

  @override
  String get adminExpertAnswerHint => 'اكتبي إجابة الخبير...';

  @override
  String get adminNotifTitle => 'عنوان الإشعار';

  @override
  String get adminNotifBody => 'محتوى الإشعار';

  @override
  String get adminTitleEnglish => 'العنوان (إنجليزي)';

  @override
  String get adminTitleArabic => 'العنوان (عربي)';

  @override
  String get adminBodyEnglish => 'المحتوى (إنجليزي)';

  @override
  String get adminBodyArabic => 'المحتوى (عربي)';

  @override
  String get stealthSetPin => 'تعيين PIN التخفي';

  @override
  String get stealthPinHint =>
      'أدخلي PIN من 4-6 أرقام لفتح التطبيق الحقيقي من الآلة الحاسبة.';

  @override
  String get stealthPin => 'PIN';

  @override
  String get stealthConfirmPin => 'تأكيد PIN';

  @override
  String get stealthCancel => 'إلغاء';

  @override
  String get stealthSave => 'حفظ';

  @override
  String get stealthPinMismatch =>
      'يجب أن يتطابق PIN وأن يكون 4 أرقام على الأقل';

  @override
  String get stealthEnable => 'تفعيل وضع التخفي';

  @override
  String get stealthActivated => 'تم تفعيل وضع التخفي! أعدي تشغيل التطبيق.';

  @override
  String get premiumActivated => 'تم تفعيل Premium!';

  @override
  String get gotIt => 'فهمت';

  @override
  String get accountWatchAppleSubtitle => 'دعم Apple Watch';

  @override
  String get accountWatchWearSubtitle => 'المزامنة مع ساعات Wear OS الذكية';

  @override
  String get insightHeadlineFirstTrimester => 'الثلث الأول';

  @override
  String get insightBodyFirstTrimester =>
      'الحركة الخفيفة والترطيب والراحة أفضل رفقاءك هذا الأسبوع.';

  @override
  String get insightHeadlineSecondTrimester => 'الثلث الثاني';

  @override
  String get insightBodySecondTrimester =>
      'الطاقة عادةً ترتفع هنا — وقت مثالي للمشي الخفيف والتمدد.';

  @override
  String get insightHeadlineThirdTrimester => 'الثلث الثالث';

  @override
  String get insightBodyThirdTrimester =>
      'استريحي كثيراً، رطّبي جسمك، وتواصلي مع طبيبك عند أي قلق.';

  @override
  String get insightHeadlinePeriodDay => 'يوم الدورة';

  @override
  String get insightBodyPeriodDay =>
      'المشروبات الدافئة والأطعمة الغنية بالمغنيسيوم تخفف التشنجات. كوني لطيفة مع نفسك اليوم.';

  @override
  String get insightHeadlineFollicular => 'مرحلة الجُريبي';

  @override
  String get insightBodyFollicular =>
      'الطاقة تميل للارتفاع — جربي تمريناً جديداً أو أنجزي مهمة صعبة اليوم.';

  @override
  String get insightHeadlineOvulation => 'التبويض';

  @override
  String get insightBodyOvulation =>
      'ذروة الطاقة والثقة. يوم مناسب لتمرين قوي أو خطة اجتماعية.';

  @override
  String get insightHeadlineLuteal => 'المرحلة الأصفرية';

  @override
  String get insightBodyLutealEarly =>
      'المرحلة الأصفرية — احتاجي الهدوء: قللي القهوة، زيدي الراحة، وحركة لطيفة.';

  @override
  String get insightBodyLutealLate =>
      'أسبوع المرحلة الأصفرية — الكربوهيدرات المعقدة والنوم المبكر يدعمان مزاجك الآن.';

  @override
  String get insightHeadlineLatePeriod => 'الدورة متأخرة';

  @override
  String get insightBodyLatePeriod =>
      'التوتر أو تغير النوم قد يؤخر الدورة. انتظري 2-3 أيام — وسجّلي أي أعراض.';

  @override
  String get insightHeadlineWelcome => 'أهلاً بكِ 🌸';

  @override
  String get insightBodyWelcome =>
      'حددي تاريخ آخر دورة لفتح رؤى يومية مخصصة لك.';

  @override
  String get smartWatch => 'الساعة الذكية';

  @override
  String get anonymousQa => 'أسئلة مجهولة';

  @override
  String get anonymousQaDesc => 'اسألي أسئلة صحية بشكل خاص';

  @override
  String get accountWatchSheetTitle => 'المزامنة مع الساعة الذكية';

  @override
  String get accountWatchSheetBody =>
      'تتم مزامنة بيانات دورتك تلقائياً مع ساعتك الذكية المقترنة. يمكنك متابعة تقدم الدورة وتسجيل الحيض مباشرة من الساعة.';

  @override
  String get accountWatchFeatureSync =>
      'مزامنة تلقائية لبيانات الدورة مع الساعة';

  @override
  String get accountWatchFeatureRing => 'حلقة الدورة على واجهة الساعة';

  @override
  String get accountWatchFeatureLog => 'تسجيل الحيض من الساعة';

  @override
  String get accountWatchFeaturePhase => 'عرض المرحلة الحالية';

  @override
  String get watchSyncNow => 'مزامنة الآن';

  @override
  String get watchSyncSuccess => 'تمت مزامنة بيانات الساعة بنجاح!';

  @override
  String get watchSyncFailed => 'فشلت المزامنة: تأكدي من اقتران الساعة.';

  @override
  String get dateFormatDDMMYYYY => 'DD/MM/YYYY';

  @override
  String get dateFormatMMDDYYYY => 'MM/DD/YYYY';

  @override
  String get dateFormatYYYYMMDD => 'YYYY/MM/DD';

  @override
  String get fileTooLarge => 'الملف كبير جداً (الحد الأقصى 15 MB)';

  @override
  String get healthQuestionHint => 'اكتبي سؤالك الصحي هنا...';

  @override
  String get geminiKeyHint => 'الصقي مفتاح API هنا';

  @override
  String get stealthTitle => 'وضع التخفي';

  @override
  String get stealthDescription =>
      'إخفاء التطبيق على شكل آلة حاسبة. أدخلي PIN السري ثم اضغطي = لفتح التطبيق.';

  @override
  String get stealthUnlockHint =>
      'للفتح: افتحي الآلة الحاسبة، اكتبي PIN، ثم اضغطي =';

  @override
  String get stealthHideNow => 'إخفاء التطبيق الآن';

  @override
  String get stealthHideNowHint => 'تحوّلي فوراً إلى واجهة الآلة الحاسبة.';

  @override
  String get anonymousQaTooltip => 'أسئلة مجهولة';

  @override
  String get anonymousQaTitle => 'أسئلة صحية مجهولة';

  @override
  String get anonymousQaIntro =>
      'اسألي سؤالك الصحي بشكل مجهول تماماً. سيجيب عليه مختصّ معتمد وسيُنشر الجواب في قسم التعليم والإرشاد.';

  @override
  String get anonymousQaPurposeTitle => 'ليش هالصفحة؟';

  @override
  String get anonymousQaStep1 => 'اكتبي سؤالك الصحي — اسمك ما بيظهر أبداً';

  @override
  String get anonymousQaStep2 => 'فريق Lune بيراجع السؤال وبيجهّز الجواب';

  @override
  String get anonymousQaStep3 =>
      'الجواب بينشر في التعليم والإرشاد لمساعدة الجميع';

  @override
  String get anonymousQaDisclaimer =>
      'المحتوى للإرشاد والتعليم فقط — مو تشخيص أو علاج طبي. للحالات العاجلة راجعي طبيبك أو الطوارئ.';

  @override
  String get anonymousQaCategoryLabel => 'التصنيف';

  @override
  String get anonymousQaQuestionLabel => 'سؤالك';

  @override
  String get anonymousQaPrivacyNote =>
      'هويتك مجهولة 100%. لا يتم حفظ أي اسم أو بريد إلكتروني أو معرّف.';

  @override
  String get anonymousQaSubmit => 'إرسال السؤال';

  @override
  String get anonymousQaSubmitting => 'جارٍ الإرسال...';

  @override
  String get anonymousQaSubmitted => 'تم إرسال سؤالك. شكراً لكِ!';

  @override
  String get anonymousQaTooShort => 'الرجاء كتابة 10 أحرف على الأقل.';

  @override
  String get anonymousQaError => 'تعذّر إرسال سؤالك. حاولي مرة أخرى.';

  @override
  String get qaCatGeneral => 'عام';

  @override
  String get qaCatCycle => 'الدورة والطمث';

  @override
  String get qaCatPregnancy => 'الحمل';

  @override
  String get qaCatPcos => 'تكيّس المبايض';

  @override
  String get qaCatContraception => 'منع الحمل';

  @override
  String get qaCatMental => 'الصحة النفسية';

  @override
  String get qaCatNutrition => 'التغذية';

  @override
  String get dailyBriefingPrompt => 'أعطيني ملخص اليوم';

  @override
  String get accountSectionPremium => 'بريميوم';

  @override
  String get accountViewPlans => 'عرض خطط الاشتراك';

  @override
  String get accountPremiumThanks => 'أنتِ عضوة بريميوم — شكراً لدعمك Lune!';

  @override
  String get accountManageSubscription => 'إدارة الاشتراك';

  @override
  String get accountManageSubscriptionHint => 'يفتح اشتراكات Google Play';

  @override
  String get accountSectionInfo => 'معلومات الحساب';

  @override
  String get accountUsernameTitle => 'اسم المستخدم';

  @override
  String get accountUsernameNotSet => 'غير محدد — عدّلي ملفك الشخصي لإضافته';

  @override
  String get accountEmailTitle => 'البريد الإلكتروني';

  @override
  String get accountEmailVerified => 'موثّق';

  @override
  String get accountEmailNotVerified => 'غير موثّق';

  @override
  String get accountVerificationSent => 'أُرسلت رسالة التوثيق. تفقّدي بريدك.';

  @override
  String get accountIdTitle => 'معرّف الحساب';

  @override
  String get accountMemberSinceTitle => 'عضوة منذ';

  @override
  String get accountTypeGuest => 'حساب ضيفة';

  @override
  String get accountTypeEmail => 'حساب بريد إلكتروني';

  @override
  String get accountCopied => 'تم النسخ';

  @override
  String get accountUsernameLabel => 'اسم المستخدم';

  @override
  String get accountUsernameHint => 'مثال: luna_star';

  @override
  String get accountUsernameInvalid =>
      'من 3 إلى 20 حرفاً: أحرف إنجليزية أو أرقام أو نقطة أو شرطة سفلية';

  @override
  String get trustHubTitle => 'الثقة والخصوصية';

  @override
  String get trustHubSubtitle =>
      'إجابات واضحة عن كيف تحمي Lune بياناتك الصحية — الأمان، ملفات الارتباط، إمكانية الوصول، والمزيد.';

  @override
  String get trustHubLink => 'مركز الثقة والخصوصية';

  @override
  String get trustLinkSecurity => 'الأمان في Lune';

  @override
  String get trustLinkSecuritySub => 'التشفير والمصادقة وكيف نحمي بياناتك';

  @override
  String get trustLinkBodyData => 'جسدك، بياناتك';

  @override
  String get trustLinkBodyDataSub => 'بيانات دورتك ملككِ — لا نبيعها أبداً';

  @override
  String get trustLinkDataEnds => 'بياناتك تنتهي معكِ';

  @override
  String get trustLinkDataEndsSub => 'احذفي حسابكِ وبياناتك السحابية في أي وقت';

  @override
  String get trustLinkFaq => 'الأسئلة الشائعة حول الخصوصية';

  @override
  String get trustLinkFaqSub => 'أسئلة متكررة عن خصوصية Lune';

  @override
  String get trustLinkCookies => 'سياسة ملفات الارتباط';

  @override
  String get trustLinkCookiesSub => 'كيف نستخدم التخزين المحلي وملفات الموقع';

  @override
  String get trustLinkIp => 'استخدام عنوان IP';

  @override
  String get trustLinkIpSub => 'لماذا نعالج عناوين IP وما لا نفعله';

  @override
  String get trustLinkAccessibility => 'إمكانية الوصول';

  @override
  String get trustLinkAccessibilitySub => 'التزامنا بتجربة شاملة للجميع';

  @override
  String get trustSecurityTitle => 'الأمان في Lune';

  @override
  String get trustSecurityIntro =>
      'بياناتك الصحية تستحق عناية بمستوى عالٍ. الأمان مدمج في كل طبقة من Lune — وليس إضافة لاحقة. توضّح هذه الصفحة كيف نحمي سجلات دورتك وحسابك والميزات السحابية الاختيارية بلغة واضحة.';

  @override
  String get trustSecurityS1Title => 'التشفير على جهازك';

  @override
  String get trustSecurityS1Body =>
      'قاعدة بيانات دورتك مشفّرة محلياً باستخدام AES-256 قبل تخزينها على هاتفك. الأعراض والمزاج والتدفق وسجلات العافية تُخزَّن داخل هذا المخزن المحمي. مفاتيح التشفير تُنشأ على جهازك وتُحفظ في Android Keystore أو iOS Keychain — ولا تغادر جهازك دون حماية.';

  @override
  String get trustSecurityS2Title => 'مزامنة سحابية مشفّرة (اختيارية، Premium)';

  @override
  String get trustSecurityS2Body =>
      'النسخ الاحتياطي السحابي اختياري ويتطلب Premium وموافقتك الصريحة. عند التفعيل، تُشفَّر حمولة النسخة الاحتياطية على الجهاز قبل الرفع وتُخزَّن في حساب Firebase الخاص بكِ. لا ندّعي أن كل حقل في Firestore يستخدم نفس تشفير AES-256 — لكن حمولة الدورة الحساسة نفسها مشفّرة قبل مغادرة هاتفك.';

  @override
  String get trustSecurityS3Title => 'اتصالات آمنة وسلامة التطبيق';

  @override
  String get trustSecurityS3Body =>
      'كل حركة الشبكة تستخدم تشفير TLS. يساعد Firebase App Check على التحقق من طلبات التطبيق الأصيلة. يمكنكِ تسجيل الدخول بالبريد أو Google أو Apple أو المتابعة كضيفة مجهولة — كل طريقة تمر عبر Firebase Authentication بحماية معيارية.';

  @override
  String get trustSecurityS4Title => 'لا إعلانات، لا وسطاء بيانات';

  @override
  String get trustSecurityS4Body =>
      'Lune لا تعرض إعلانات طرف ثالث ولا تبيع بياناتك الشخصية أو الصحية. لا نشارك بيانات دورتك مع المعلنين أو وسطاء البيانات أو جهات العمل أو شركات التأمين. إيراداتنا من اشتراكات Premium الاختيارية — وليس من بيع معلوماتك الصحية.';

  @override
  String get trustSecurityS5Title => 'أنتِ تتحكمين بالميزات الاختيارية';

  @override
  String get trustSecurityS5Body =>
      'المحادثة الذكية (Google Gemini وDeepSeek) والمجتمع والإشعارات والمزامنة السحابية اختيارية وتتطلب موافقتك. يمكنكِ مراجعتها وتغييرها في أي وقت من مركز الخصوصية دون التأثير على التتبع المحلي الأساسي.';

  @override
  String get trustSecurityS6Title => 'تقارير الأعطال (Firebase Crashlytics)';

  @override
  String get trustSecurityS6Body =>
      'تستخدم Lune Firebase Crashlytics لجمع تقارير أعطال مجهولة وبيانات تشخيصية أساسية عند تعطل التطبيق بشكل غير متوقع. يساعدنا ذلك على إصلاح الأخطاء بسرعة. تقارير الأعطال لا تتضمن سجلات دورتك أو العافية أو محادثات الذكاء الاصطناعي.';

  @override
  String get trustSecurityS7Title => 'البنية التحتية السحابية';

  @override
  String get trustSecurityS7Body =>
      'الحسابات المسجّلة والنسخ السحابية الاختيارية ومحتوى المجتمع والمحادثة الذكية (لمشتركات Premium) تعمل على Google Firebase — بما فيها المصادقة وFirestore وCloud Functions والإشعارات والاستضافة وApp Check وCrashlytics. الوصول إلى بياناتك مقيد بقواعد أمان Firebase وبيانات تسجيل دخولك.';

  @override
  String get trustSecurityS8Title => 'وضع التخفي على جهازك';

  @override
  String get trustSecurityS8Body =>
      'وضع التخفي يُظهر آلة حاسبة بدلاً من Lune حتى تُدخلي رقم PIN السري. يحمي خصوصيتك إذا أمسك أحد هاتفك — وهو قفل محلي فقط ولا يغيّر طريقة التشفير. يمكنكِ تفعيله أو إيقافه من مركز الخصوصية.';

  @override
  String get trustSecurityS9Title => 'أمان المدفوعات';

  @override
  String get trustSecurityS9Body =>
      'اشتراكات Premium على Android تُعالَج عبر Google Play Billing. Lune لا ترى رقم بطاقتك ولا تخزّنه. أديري أو ألغي اشتراكك من إعدادات حساب Google Play.';

  @override
  String get trustSecurityS10Title => 'أذونات تطبيق Android';

  @override
  String get trustSecurityS10Body =>
      'تطلب Lune فقط الأذونات اللازمة للميزات التي تستخدمينها: الإنترنت (تسجيل الدخول، المزامنة الاختيارية، AI، المجتمع)، الإشعارات (تذكيرات الدورة الاختيارية)، Google Play Billing (Premium)، المنبهات الدقيقة وإعادة التشغيل (تذكيرات محلية موثوقة)، والصور/الوسائط فقط عند إرفاق صورة أو تعيين صورة ملف شخصي. النسخ الاحتياطي لبيانات التطبيق على Android معطّل (allowBackup=false) حتى لا تُنسخ بيانات الدورة تلقائياً إلى نسخ Google الاحتياطية.';

  @override
  String get trustCookiesTitle => 'سياسة ملفات الارتباط والتخزين';

  @override
  String get trustCookiesIntro =>
      'Lune تطبيق جوال أولاً. توضّح هذه الصفحة ما يُخزَّن على جهازك وما يحتفظ به موقعنا وما لا نتتبعه عمداً. الوضوح حول التخزين جزء من احترام خصوصيتك.';

  @override
  String get trustCookiesS1Title => 'التخزين المحلي في التطبيق';

  @override
  String get trustCookiesS1Body =>
      'يخزّن تطبيق Lune سجلات دورتك وعافيتك وتفضيلاتك وخيارات الموافقة و(إذا كنتِ ضيفة) سجل المحادثة الذكية على جهازك عبر قواعد بيانات محلية مشفّرة. هذا ضروري للتتبع دون إنترنت والتسجيل اليومي السريع.';

  @override
  String get trustCookiesS2Title => 'ملفات ارتباط الموقع';

  @override
  String get trustCookiesS2Body =>
      'موقعنا (lune-7d956.web.app) لا يستخدم ملفات ارتباط إعلانية أو تتبع. قد نستخدم تخزيناً تقنياً أساسياً — مثل تذكّر لغتك في الصفحات القانونية — حتى لا تعيدي الاختيار في كل زيارة.';

  @override
  String get trustCookiesS3Title => 'لا تتبع إعلاني';

  @override
  String get trustCookiesS3Body =>
      'لا نستخدم شبكات إعلانات طرف ثالث أو متتبعات عبر التطبيقات أو بكسلات تسويقية في تطبيق Lune. بياناتك الصحية لا تُستخدم للإعلان المستهدف أو بناء ملفات سلوكية أو إعادة استهداف.';

  @override
  String get trustCookiesS4Title => 'إدارة التخزين';

  @override
  String get trustCookiesS4Body =>
      'يمكنكِ مسح بيانات التطبيق المحلية بإلغاء التثبيت أو حذف الحساب من مركز الخصوصية. ملفات النسخ الاحتياطي التي تحفظينها في الحافظة أو خارج التطبيق تبقى تحت سيطرتك — احذفيها عندما لا تحتاجينها.';

  @override
  String get trustCookiesS5Title => 'رموز الإشعارات';

  @override
  String get trustCookiesS5Body =>
      'إذا فعّلتِ الإشعارات، يخزّن Firebase Cloud Messaging رمز جهاز لتسليم تذكيرات الدورة وتحديثات التطبيق التي طلبتِها. يُستخدم الرمز للتسليم فقط — وليس للإعلان أو بيع هويتك لأطراف ثالثة.';

  @override
  String get trustCookiesS6Title => 'ذاكرة المجتمع المؤقتة';

  @override
  String get trustCookiesS6Body =>
      'عند تصفح المجتمعات، قد تُخزَّن المنشورات والصور مؤقتاً على جهازك لتمرير أسلس. تُمسح هذه الذاكرة عند إلغاء التثبيت أو مسح بيانات التطبيق.';

  @override
  String get trustCookiesS7Title => 'اللغة وخيارات الموافقة';

  @override
  String get trustCookiesS7Body =>
      'يُحفظ اختيار اللغة وخيارات مركز الخصوصية وإعدادات وضع التخفي محلياً ليتذكر التطبيق تفضيلاتك بين الجلسات. تبقى على جهازك ما لم تسجّلي دخولاً وتزامني تفضيلات الحساب.';

  @override
  String get trustCookiesS8Title => 'ما لا نخزّنه للإعلانات';

  @override
  String get trustCookiesS8Body =>
      'لا نضع ملفات ارتباط إعلانية أو بكسلات اجتماعية أو أدوات تتبع سلوكي في Lune. لا نبني ملفات تسويقية من بيانات دورتك أو أعراضك أو مزاجك أو محادثات الذكاء الاصطناعي.';

  @override
  String get trustIpTitle => 'كيف نستخدم عنوان IP';

  @override
  String get trustIpIntro =>
      'عند استخدامك Lune أو موقعنا، قد يُعالَج عنوان IP عبر مزوّدي البنية التحتية. توضّح هذه الصفحة لماذا يحدث ذلك وما لا نفعله به والخيارات المتاحة لكِ.';

  @override
  String get trustIpS1Title => 'لماذا نعالج عناوين IP';

  @override
  String get trustIpS1Body =>
      'تساعد عناوين IP في Firebase ودوالنا السحابية على تسليم الطلبات بأمان وتوجيه الحركة إلى الخادم الصحيح وإبقاء الخدمة متاحة. بدون بيانات شبكة أساسية، لا يمكن للتطبيقات السحابية العمل بموثوقية.';

  @override
  String get trustIpS2Title => 'ما لا نفعله';

  @override
  String get trustIpS2Body =>
      'لا نبيع عناوين IP، ولا نستخدمها لملفات إعلانية، ولا نحاول تحديد موقعك الجغرافي الدقيق من IP وحده. لا نشارك IP مع وسطاء بيانات أو شبكات إعلانات.';

  @override
  String get trustIpS3Title => 'الاحتفاظ';

  @override
  String get trustIpS3Body =>
      'عناوين IP في سجلات الخادم والاستضافة تُحفَظ فقط للمدة اللازمة للأمان ومنع إساءة الاستخدام واستكشاف الأخطاء، ثم تُدوَّر أو تُحذف وفق سياسات Firebase وGoogle Cloud.';

  @override
  String get trustIpS4Title => 'خياراتك';

  @override
  String get trustIpS4Body =>
      'استخدام VPN اختيارك — لا نعاقب مستخدمات VPN. حذف حسابك يزيل ملفك ومحتواك السحابي من خوادمنا. للتفاصيل الكاملة، راجعي سياسة الخصوصية.';

  @override
  String get trustIpS5Title => 'حدود المعدل ومنع الإساءة';

  @override
  String get trustIpS5Body =>
      'نطبّق حدود معدل على جانب الخادم للمحادثة الذكية وإجراءات المجتمع لمنع البريد المزعج وحماية الجميع. قد تُستخدم عناوين IP مع معرّفات الحساب معاً لاكتشاف أنماط إساءة — وليس لتسويقك.';

  @override
  String get trustIpS6Title => 'أين قد تُعالَج البيانات';

  @override
  String get trustIpS6Body =>
      'قد يعالج Firebase ومزوّدو الذكاء الاصطناعي الطلبات في الولايات المتحدة ومناطق أخرى حيث تعمل مراكز بيانات Google وDeepSeek. هذا معياري لتطبيقات الصحة السحابية ذات المزامنة الاختيارية.';

  @override
  String get trustIpS7Title => 'الطلبات القانونية';

  @override
  String get trustIpS7Body =>
      'قد نكشف معلومات — قد تشمل سجلات خادم مرتبطة بـ IP — فقط عند وجود إجراء قانوني صالح وبأقل مدى يفرضه القانون. لا نشارك طوعاً بيانات صحة الدورة مع السلطات.';

  @override
  String get trustIpS8Title => 'VPN وأدوات الخصوصية';

  @override
  String get trustIpS8Body =>
      'إذا استخدمتِ VPN، قد يختلف IP الظاهر عن منطقتك الفعلية. Lune لا تحجب اتصالات VPN. قد تبقى بعض فحوصات أمان Firebase لحماية الحسابات من الاستيلاء.';

  @override
  String get trustFaqTitle => 'الأسئلة الشائعة حول الخصوصية';

  @override
  String get trustFaqIntro =>
      'إجابات على أكثر الأسئلة شيوعاً حول الخصوصية والأمان وكيف تتعامل Lune مع بيانات دورتك. إذا لم تجدي إجابتك هنا، تواصلي معنا في أي وقت.';

  @override
  String get trustFaqQ1 => 'من يرى بيانات دورتي؟';

  @override
  String get trustFaqA1 =>
      'أنتِ فقط. افتراضياً، بيانات دورتك تبقى على جهازك في قاعدة بيانات محلية مشفّرة. إذا فعّلتِ النسخ الاحتياطي السحابي Premium، تُخزَّن نسخ مشفّرة في حساب Firebase الخاص بكِ. لا نشارك بيانات الدورة مع مستخدمين آخرين إلا إذا نشرتِ صراحة في ميزات المجتمع.';

  @override
  String get trustFaqQ2 => 'هل تبيع Lune بياناتي؟';

  @override
  String get trustFaqA2 =>
      'لا. لا نبيع بياناتك الشخصية أو الصحية أبداً. Lune ممولة عبر اشتراكات Premium الاختيارية عبر Google Play — وليس عبر الإعلانات أو بيع البيانات.';

  @override
  String get trustFaqQ3 => 'ماذا يحدث عند حذف حسابي؟';

  @override
  String get trustFaqA3 =>
      'عند تأكيد الحذف في مركز الخصوصية، نزيل فوراً ملفك في Firestore والنسخ السحابية وسجل المحادثة ومحتوى المجتمع من خوادمنا، ثم نحذف حساب Firebase Authentication. البيانات المحلية على جهازك تبقى حتى تلغي التثبيت. قد تحتفظ Firebase بنسخ تقنية مؤقتة وفق سياسات بنيتها.';

  @override
  String get trustFaqQ4 => 'هل المحادثة الذكية خاصة؟';

  @override
  String get trustFaqA4 =>
      'المحادثة الذكية تتطلب Premium. الضيفات: المحادثة تبقى على الجهاز فقط. المشتركات المسجّلات: قد تُخزَّن الرسائل في السحابة لاستعادة المحادثات. تُرسَل كل رسالة إلى Google Gemini و/أو DeepSeek — راجعي سياسة الخصوصية. ننصح بعدم مشاركة معلومات لا تريدين أن يعالجها مزوّد AI خارجي.';

  @override
  String get trustFaqQ5 => 'هل يمكنني استخدام Lune بدون حساب؟';

  @override
  String get trustFaqA5 =>
      'نعم. يمكنكِ الاستخدام كضيفة بحساب Firebase مجهول مرتبط بجهازك — بدون بريد. التتبع الأساسي يعمل بالكامل دون إنترنت. النسخ السحابي وAI Premium وسجل المحادثة عبر الأجهزة وبعض ميزات المجتمع تتطلب حساباً مسجّلاً.';

  @override
  String get trustFaqQ6 => 'أين تُخزَّن بياناتي؟';

  @override
  String get trustFaqA6 =>
      'محلياً على هاتفك افتراضياً في قاعدة بيانات مشفّرة AES-256. إذا فعّلتِ النسخ الاحتياطي السحابي Premium، تُخزَّن حمولات مشفّرة في Google Firebase (قد تُعالَج في الولايات المتحدة ومناطق أخرى).';

  @override
  String get trustFaqQ7 => 'كيف أصدّر بياناتي؟';

  @override
  String get trustFaqA7 =>
      'افتحي مركز الخصوصية ← تصدير البيانات لنسخ نسخة احتياطية محلية مشفّرة إلى الحافظة. يمكنكِ حفظها في مدير كلمات مرور أو ملاحظات آمنة. للمساعدة في طلبات النقل، راسلينا على merrsoheb@gmail.com.';

  @override
  String get trustFaqQ8 => 'كيف أتواصل بخصوص الخصوصية؟';

  @override
  String get trustFaqA8 =>
      'راسلينا على merrsoheb@gmail.com أو استخدمي «تواصل مع الدعم» في مركز الخصوصية. نهدف للرد على طلبات الخصوصية خلال 30 يوماً.';

  @override
  String get trustFaqQ9 => 'هل المحادثة الذكية مجانية؟';

  @override
  String get trustFaqA9 =>
      'لا. Lune AI ميزة Premium. المشتركات يمكنهن إرسال حتى 30 رسالة ذكاء اصطناعي في اليوم التقويمي — يُفرض على خوادمنا. إذا فشل المزوّد، لا نحسب الرسالة ضمن حدك.';

  @override
  String get trustFaqQ10 => 'ماذا يفتح Premium؟';

  @override
  String get trustFaqA10 =>
      'Premium يشمل النسخ الاحتياطي السحابي لدورتك ومحادثة Lune AI (30 رسالة/يوم) وإرفاق صور أو فيديو في منشورات وقصص المجتمع. التتبع المحلي الأساسي يبقى مجانياً للجميع.';

  @override
  String get trustFaqQ11 => 'كيف يعمل وضع التخفي؟';

  @override
  String get trustFaqA11 =>
      'وضع التخفي يُظهر شاشة آلة حاسبة بدلاً من Lune حتى تُدخلي رقم PIN السري وتضغطي يساوي. يحمي خصوصيتك إذا فتح أحد هاتفك. إنه تمويه محلي فقط — فعّليه من مركز الخصوصية.';

  @override
  String get trustFaqQ12 => 'من يرى منشوراتي في المجتمع؟';

  @override
  String get trustFaqA12 =>
      'المنشورات تظهر لأعضاء مجتمعات Lune التي تنضمين إليها. يمكنكِ الإبلاغ عن محتوى غير آمن؛ قد تُخفى المنشورات المبلّغ عنها تلقائياً أثناء المراجعة. المشاركة في المجتمع اختيارية وتتطلب موافقة.';

  @override
  String get trustFaqQ13 => 'هل يمكنني مشاركة تقرير صحي مع طبيبي؟';

  @override
  String get trustFaqA13 =>
      'نعم. يمكن لـ Lune إنشاء ملخص صحي من بياناتك المسجّلة لمراجعته ومشاركته بنفسك. لا نرسل تقارير للأطباء تلقائياً — أنتِ تختارين ما تشاركينه ومع من.';

  @override
  String get trustFaqQ14 => 'هل تستخدم المجلة بياناتي الشخصية؟';

  @override
  String get trustFaqA14 =>
      'لا. مقالات المجلة التعليمية في Lune محتوى تحريري منفصل عن سجلات دورتك الخاصة. قراءة المقالات لا ترفع بياناتك الصحية للتخصيص.';

  @override
  String get trustFaqQ15 => 'ما الإشعارات التي ترسلها Lune؟';

  @override
  String get trustFaqA15 =>
      'إذا وافقتِ، قد نرسل تذكيرات الدورة وموجز العافية وتحديثات مهمة عبر Firebase Cloud Messaging. لا نرسل إعلانات ترويجية ولا نبيع جمهور الإشعارات لأطراف ثالثة. يمكنكِ إيقاف الإشعارات من إعدادات الجهاز.';

  @override
  String get trustFaqQ16 => 'ما حقوقي بموجب GDPR؟';

  @override
  String get trustFaqA16 =>
      'إذا كنتِ في المنطقة الاقتصادية الأوروبية أو المملكة المتحدة، يمكنكِ طلب الوصول أو التصحيح أو الحذف أو التصدير لبياناتك. احذفي حسابك من مركز الخصوصية للحذف الفوري من الخوادم، أو راسلينا على merrsoheb@gmail.com. نرد خلال 30 يوماً.';

  @override
  String get trustFaqQ17 => 'ما أذونات Android التي يستخدمها Lune؟';

  @override
  String get trustFaqA17 =>
      'الإنترنت لتسجيل الدخول والميزات الاختيارية عبر الإنترنت؛ الإشعارات للتذكيرات التي تفعّلينها؛ Google Play Billing لـ Premium؛ المنبهات الدقيقة وإعادة التشغيل لتذكيرات محلية موثوقة. الصور أو الفيديو تُطلب فقط عند إرفاق وسائط في المجتمع (Premium) أو اختيار صورة ملف شخصي. لا نصل إلى جهات الاتصال أو الرسائل أو سجل المكالمات.';

  @override
  String get trustFaqQ18 => 'كيف تعمل اشتراكات Google Play؟';

  @override
  String get trustFaqA18 =>
      'Premium يُفوتر عبر Google Play. الاشتراكات تتجدد تلقائياً ما لم تلغي قبل 24 ساعة من نهاية الفترة. أديري أو ألغي من Google Play ← الاشتراكات. الاستردادات وفق سياسة Google Play. حذف حساب Lune لا يوقف الفوترة تلقائياً — ألغي الاشتراك بشكل منفصل.';

  @override
  String get trustFaqQ19 => 'ما الحد الأدنى للعمر لاستخدام Lune؟';

  @override
  String get trustFaqA19 =>
      'يجب أن يكون عمرك 13 عاماً على الأقل. من دون 13 لا يمكن المتابعة بعد بوابة العمر. بعض ميزات المجتمع مقيّدة لمستخدمات 18 فما فوق. على الوالدين التواصل معنا إذا اعتقدوا أن طفلاً دون 13 استخدم Lune لطلب الحذف.';

  @override
  String get trustFaqQ20 => 'هل Lune جهازاً طبياً أو نصيحة طبية؟';

  @override
  String get trustFaqA20 =>
      'لا. Lune للتتبع الصحي المعلوماتي فقط — وليس جهازاً طبياً أو تشخيصاً أو علاجاً. توقعات الدورة ومحادثة AI ومنشورات المجتمع ومقالات المجلة ليست نصيحة طبية. استشيري دائماً مختص رعاية صحية مؤهل للقرارات الطبية.';

  @override
  String get trustFaqQ21 =>
      'ما البيانات التي تجمعها Lune (Google Play Data Safety)؟';

  @override
  String get trustFaqA21 =>
      'البيانات التي تقدّمينها: تواريخ الدورة والأعراض والمزاج وملاحظات العافية ومنشورات المجتمع الاختيارية. بيانات الحساب إذا سجّلتِ (بريد، اسم، طريقة دخول). بيانات تقنية: رموز الجهاز للإشعارات، تقارير أعطال مجهولة، وطوابع نشاط تقريبية. رسائل AI Premium تُرسَل إلى Google Gemini/DeepSeek. لا نبيع البيانات. التتبع الأساسي يبقى على جهازك ما لم تفعّلي النسخ السحابي Premium.';

  @override
  String get trustBodyDataTitle => 'جسدك، بياناتك';

  @override
  String get trustBodyDataIntro =>
      'بيانات دورتك وعافيتك شخصية جداً. في Lune، أنتِ المتحكمة — دائماً. توضّح هذه الصفحة ما تسجّلينه ومن يملكه وكيف تستخدمه الميزات الاختيارية.';

  @override
  String get trustBodyDataS1Title => 'الملكية';

  @override
  String get trustBodyDataS1Body =>
      'أنتِ تملكين بيانات الدورة والأعراض والمزاج والتدفق وشرب الماء والعافية التي تسجلينها. Lune أداة لفهم جسدك — وليست منصة تربح من معلوماتك الصحية أو تبيع رؤى عنك.';

  @override
  String get trustBodyDataS2Title => 'تصميم محلي أولاً';

  @override
  String get trustBodyDataS2Body =>
      'التطبيق يعمل بالكامل دون إنترنت. سجلاتك اليومية تُكتب أولاً في قاعدة بيانات مشفّرة على جهازك. لا يغادر شيء هاتفك إلا إذا اخترتِ النسخ السحابي أو الذكاء الاصطناعي أو المجتمع أو ميزات تتطلب شبكة.';

  @override
  String get trustBodyDataS3Title => 'موافقة صريحة';

  @override
  String get trustBodyDataS3Body =>
      'النسخ الاحتياطي السحابي وميزات الذكاء الاصطناعي والمجتمع والإشعارات تتطلب موافقة منفصلة في مركز الخصوصية. يمكنكِ تفعيلها أو تعطيلها دون فقدان سجل دورتك المحلي.';

  @override
  String get trustBodyDataS4Title => 'لا مشاركة خفية';

  @override
  String get trustBodyDataS4Body =>
      'لا نشارك بيانات دورتك مع جهات العمل أو التأمين أو المعلنين أو الشبكات الاجتماعية الخارجية. منشورات وقصص المجتمع تظهر فقط داخل مجتمعات Lune التي تختارين الانضمام إليها.';

  @override
  String get trustBodyDataS5Title => 'ما يمكنكِ تسجيله';

  @override
  String get trustBodyDataS5Body =>
      'تتيح Lune تتبع الدورة والأعراض والمزاج ومستويات الألم وشرب الماء وملاحظات عافية أخرى تختارينها. أنتِ تقررين مقدار التفاصيل كل يوم. لا شيء إلزامي سوى ما تحتاجينه لفهم جسدك.';

  @override
  String get trustBodyDataS6Title => 'كيف يستخدم AI سياق دورتك';

  @override
  String get trustBodyDataS6Body =>
      'عند استخدام Lune AI (Premium)، قد يُرسَل سياق الدورة ذو الصلة الذي توافقين عليه إلى خوادمنا ثم إلى Google Gemini أو DeepSeek لتخصيص الإجابات. الذكاء الاصطناعي اختياري — يمكنكِ تتبع دورتك دون فتح المحادثة أبداً.';

  @override
  String get trustBodyDataS7Title => 'المجلة والتعليم';

  @override
  String get trustBodyDataS7Body =>
      'مقالات مجلة Lune محتوى تعليمي صحي عام. منفصلة عن سجلاتك الخاصة ولا تُنشأ من بيانات دورتك الشخصية. المحررون ينشرون المقالات عبر أدوات الإدارة — وليس بقراءة يومياتك.';

  @override
  String get trustBodyDataS8Title => 'قابلية النقل';

  @override
  String get trustBodyDataS8Body =>
      'يمكنكِ تصدير نسخة احتياطية مشفّرة من مركز الخصوصية في أي وقت. بياناتك ملكك — إذا غادرتِ Lune، يمكنكِ أخذ نسخة معك قبل حذف حسابك.';

  @override
  String get trustDataEndsTitle => 'بياناتك تنتهي معكِ';

  @override
  String get trustDataEndsIntro =>
      'عندما تقررين مغادرة Lune، يجب أن تغادر بياناتك أيضاً. تشرح هذه الصفحة كل خطوة — حذف الخوادم والملفات المحلية والاشتراكات وما لا يمكن التراجع عنه.';

  @override
  String get trustDataEndsS1Title => 'احذفي في أي وقت';

  @override
  String get trustDataEndsS1Body =>
      'يمكنكِ حذف حسابك من مركز الخصوصية في أي وقت. بدون مكالمات ولا حيل — خطوة تأكيد واضحة فقط. الضيفات يمكنهن مسح البيانات المحلية بإلغاء تثبيت التطبيق.';

  @override
  String get trustDataEndsS2Title => 'حذف فوري من الخوادم';

  @override
  String get trustDataEndsS2Body =>
      'عند تأكيد حذف الحساب، تزيل خوادمنا فوراً ملفك في Firestore والنسخ السحابية لدورتك وسجل المحادثة ومنشورات المجتمع، ثم تحذف حساب Firebase Authentication. هذا ليس فترة انتظار 30 يوماً — الحذف يبدأ مباشرة.';

  @override
  String get trustDataEndsS3Title => 'البيانات المحلية';

  @override
  String get trustDataEndsS3Body =>
      'البيانات على جهازك لا تُمسح تلقائياً عند حذف الحساب السحابي. ألغي تثبيت التطبيق أو استخدمي إعدادات التطبيق في هاتفك لإزالة قواعد البيانات المشفّرة والتفضيلات المتبقية.';

  @override
  String get trustDataEndsS4Title => 'النسخ التي صدّرتِها';

  @override
  String get trustDataEndsS4Body =>
      'إذا صدّرتِ ملف نسخة احتياطية وحفظتِه في الحافظة أو خارج التطبيق، فهذه النسخة خارج سيطرتنا. احذفيها إذا لم تعدِ تحتاجينها — لا نستطيع الوصول إلى تطبيق ملاحظاتك أو سحابتك.';

  @override
  String get trustDataEndsS5Title => 'إجراء دائم';

  @override
  String get trustDataEndsS5Body =>
      'حذف الحساب لا يمكن التراجع عنه. إذا عدتِ إلى Lune لاحقاً، تبدأين من جديد إلا إذا استعدتِ من نسخة محلية حفظتِها قبل الحذف.';

  @override
  String get trustDataEndsS6Title => 'الضيفة مقابل المسجّلة';

  @override
  String get trustDataEndsS6Body =>
      'حسابات الضيف موجودة أساساً على جهازك مع هوية Firebase مجهولة خفيفة. حذف الحساب المسجّل يُطلق تنظيفاً كاملاً للخوادم. على الضيفات إلغاء التثبيت لإزالة كل الآثار المحلية.';

  @override
  String get trustDataEndsS7Title => 'اشتراكات Premium';

  @override
  String get trustDataEndsS7Body =>
      'حذف حساب Lune لا يلغي تلقائياً اشتراك Google Play. افتحي Google Play ← الاشتراكات لإلغاء فوترة Premium بشكل منفصل حتى لا تُخصم بعد المغادرة.';

  @override
  String get trustDataEndsS8Title => 'إزالة محتوى المجتمع';

  @override
  String get trustDataEndsS8Body =>
      'عند حذف حسابك، نزيل منشوراتك وتعليقاتك وقصصك من مجتمعات Lune عبر تنظيف آلي على الخادم. النسخ في ذاكرة مستخدمات أخرى تختفي عند تحديثهم أو إعادة التثبيت.';

  @override
  String get trustA11yTitle => 'إمكانية الوصول في Lune';

  @override
  String get trustA11yIntro =>
      'نؤمن بأن الجميع يستحقون أدوات صحة الدورة — بغض النظر عن اللغة أو البصر أو الحركة. إمكانية الوصول التزام مستمر وليس ميزة لمرة واحدة.';

  @override
  String get trustA11yS1Title => 'التزامنا';

  @override
  String get trustA11yS1Body =>
      'نصمّم Lune لتكون قابلة للاستخدام مع قارئات الشاشة وتكبير خط النظام والتخطيط من اليمين لليسار والعكس. العربية والإنجليزية تحصلان على اهتمام متساوٍ في التنقل والتسميات واتجاه القراءة.';

  @override
  String get trustA11yS2Title => 'ميزات داخل التطبيق';

  @override
  String get trustA11yS2Body =>
      'تحترم Lune حجم خط جهازك وإعدادات التباين حيث يدعمها Flutter ونظام التشغيل. التنقل يستخدم أنماط Material القياسية لسلوك متوقع مع قارئ الشاشة عبر التبويبات والنماذج.';

  @override
  String get trustA11yS3Title => 'طلبات الدعم';

  @override
  String get trustA11yS3Body =>
      'إذا واجهتِ عائقاً أثناء استخدام Lune، راسلينا على merrsoheb@gmail.com مع وصف المشكلة وطراز جهازك ولغتك المفضلة. نأخذ ملاحظات إمكانية الوصول بجدية ونُعطي أولوية لما يعيق التتبع الأساسي.';

  @override
  String get trustA11yS4Title => 'تحسينات مستمرة';

  @override
  String get trustA11yS4Body =>
      'نراجع الميزات الجديدة للتباين وحجم أهداف اللمس وتسميات قارئ الشاشة قبل الإصدار. إصدارات سابقة حسّنت تخطيط RTL ومناطق اللمس الأكبر ورسائل الخطأ أوضح — والمزيد مخطّط.';

  @override
  String get trustA11yS5Title => 'تكافؤ العربية والإنجليزية';

  @override
  String get trustA11yS5Body =>
      'التبديل بين العربية والإنجليزية يقلب اتجاه الواجهة بالكامل — القوائم والبطاقات والصفحات القانونية. لا ينبغي أن تضطري لمحاربة التخطيط لقراءة المحتوى بلغتك.';

  @override
  String get trustA11yS6Title => 'السمات وإعدادات النظام';

  @override
  String get trustA11yS6Body =>
      'تتبع Lune سمة جهازك حيث أمكن وتستخدم خطوطاً مقروءة على خلفيات فاتحة. إذا فُعّل وضع التباين العالي في النظام، قد تحسّن إعدادات OS القراءة أكثر.';

  @override
  String get trustA11yS7Title => 'خارطة الطريق';

  @override
  String get trustA11yS7Body =>
      'نعمل على تحسينات أوسع بمحاذاة WCAG — بما فيها أوصاف أغنى لقارئ الشاشة للرسوم البيانية وتحسينات التنقل بلوحة المفاتيح ومراجعات تباين باختبار مستخدمات. أخبرينا ما يهمكِ أكثر.';
}
