// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Menstrudel';

  @override
  String get nextDue => 'الموعد القادم';

  @override
  String get ongoing => 'جارية';

  @override
  String get overdue => 'متأخرة';

  @override
  String get total => 'الإجمالي';

  @override
  String get shortest => 'الأقصر';

  @override
  String get longest => 'الأطول';

  @override
  String get unknown => 'غير معروف';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String get start => 'البداية';

  @override
  String get end => 'النهاية';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get today => 'اليوم';

  @override
  String get day => 'يوم';

  @override
  String get days => 'أيام';

  @override
  String get hours => 'ساعات';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يوم',
      many: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شهر',
      many: '$count شهرًا',
      few: '$count أشهر',
      two: 'شهران',
      one: 'شهر واحد',
    );
    return '$_temp0';
  }

  @override
  String yearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سنة',
      many: '$count سنة',
      few: '$count سنوات',
      two: 'سنتان',
      one: 'سنة واحدة',
    );
    return '$_temp0';
  }

  @override
  String countdown_daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days يوم متبقٍ',
      many: '$days يومًا متبقيًا',
      few: '$days أيام متبقية',
      two: 'يومان متبقيان',
      one: 'يوم واحد متبقٍ',
    );
    return '$_temp0';
  }

  @override
  String countUp_day(int day) {
    return 'اليوم $day';
  }

  @override
  String get logs => 'السجلات';

  @override
  String get insights => 'التحليلات';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get clear => 'مسح';

  @override
  String get save => 'حفظ';

  @override
  String get import => 'استيراد';

  @override
  String get ok => 'حسنًا';

  @override
  String get confirm => 'تأكيد';

  @override
  String get set => 'تعيين';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get cancel => 'إلغاء';

  @override
  String get select => 'اختيار';

  @override
  String get close => 'إغلاق';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get add => 'إضافة';

  @override
  String get notSet => 'غير محدد';

  @override
  String get removed => 'تمت الإزالة';

  @override
  String get totalLogs => 'إجمالي السجلات';

  @override
  String get note => 'ملاحظة';

  @override
  String get systemDefault => 'افتراضي النظام';

  @override
  String get flow => 'التدفق';

  @override
  String get type => 'النوع';

  @override
  String get other => 'أخرى';

  @override
  String get navBar_logs => 'السجلات';

  @override
  String get navBar_sanitary => 'المنتجات الصحية';

  @override
  String get navBar_sexActivity => 'النشاط الجنسي';

  @override
  String get navBar_pill => 'الحبوب';

  @override
  String get navBar_reversibleContraceptive => 'وسائل منع الحمل';

  @override
  String get navBar_settings => 'الإعدادات';

  @override
  String get flowIntensity_none => 'لا يوجد';

  @override
  String get flowIntensity_spotting => 'تنقيط';

  @override
  String get flowIntensity_light => 'خفيف';

  @override
  String get flowIntensity_moderate => 'متوسط';

  @override
  String get flowIntensity_heavy => 'غزير';

  @override
  String get builtInSymptom_acne => 'حب الشباب';

  @override
  String get builtInSymptom_backPain => 'ألم الظهر';

  @override
  String get builtInSymptom_bloating => 'انتفاخ';

  @override
  String get builtInSymptom_cramps => 'تشنجات';

  @override
  String get builtInSymptom_fatigue => 'إرهاق';

  @override
  String get builtInSymptom_headache => 'صداع';

  @override
  String get builtInSymptom_moodSwings => 'تقلبات مزاجية';

  @override
  String get builtInSymptom_nausea => 'غثيان';

  @override
  String get builtInSymptom_tenderBreasts => 'ألم في الثديين';

  @override
  String get builtInSymptom_insomnia => 'أرق';

  @override
  String get builtInSymptom_depressed => 'اكتئاب';

  @override
  String get painLevel_title => 'مستوى الألم';

  @override
  String get painLevel_none => 'لا يوجد';

  @override
  String get painLevel_mild => 'خفيف';

  @override
  String get painLevel_moderate => 'متوسط';

  @override
  String get painLevel_severe => 'شديد';

  @override
  String get pain_unbearable => 'لا يُحتمل';

  @override
  String get reversibleContraceptive_hormonalIud => 'لولب هرموني';

  @override
  String get reversibleContraceptive_copperIud => 'لولب نحاسي';

  @override
  String get reversibleContraceptive_implant => 'غرسة';

  @override
  String get reversibleContraceptive_injection => 'حقنة';

  @override
  String get reversibleContraceptive_ring => 'حلقة مهبلية';

  @override
  String get reversibleContraceptive_patch => 'لصقة';

  @override
  String get sanitaryProduct_tampon => 'سدادة قطنية';

  @override
  String get sanitaryProduct_pad => 'فوطة صحية';

  @override
  String get sanitaryProduct_menstrualCup => 'كأس الحيض';

  @override
  String get sanitaryProduct_periodUnderwear => 'ملابس داخلية للدورة';

  @override
  String get sanitaryProducts_mostUsed => 'الأكثر استخدامًا';

  @override
  String get sanitaryProducts_usageTrend => 'اتجاه الاستخدام';

  @override
  String get sexProtection_none => 'بدون وقاية';

  @override
  String get sexProtection_barrier => 'وسيلة عازلة';

  @override
  String get sexProtection_hormonal => 'هرمونية';

  @override
  String get sexProtection_nonHormonal => 'غير هرمونية';

  @override
  String get sexProtection_natural => 'طبيعية';

  @override
  String get sexProtection_permanent => 'دائمة';

  @override
  String get sexType_vaginal => 'مهبلي';

  @override
  String get sexType_anal => 'شرجي';

  @override
  String get sexType_oral => 'فموي';

  @override
  String get sexType_manual => 'يدوي';

  @override
  String get sexParticipation_solo => 'فردي';

  @override
  String get sexParticipation_partner => 'مع شريك';

  @override
  String get sexParticipation_group => 'جماعي';

  @override
  String get userGoal_general => 'الصحة العامة';

  @override
  String get userGoal_sexual => 'الصحة الجنسية';

  @override
  String get userGoal_conceive => 'محاولة الحمل';

  @override
  String get userGoal_avoid => 'تجنب الحمل';

  @override
  String get dayOfWeek_monday => 'الاثنين';

  @override
  String get dayOfWeek_tuesday => 'الثلاثاء';

  @override
  String get dayOfWeek_wednesday => 'الأربعاء';

  @override
  String get dayOfWeek_thursday => 'الخميس';

  @override
  String get dayOfWeek_friday => 'الجمعة';

  @override
  String get dayOfWeek_saturday => 'السبت';

  @override
  String get dayOfWeek_sunday => 'الأحد';

  @override
  String get cyclePhase_menstruation => 'في فترة الحيض';

  @override
  String get cyclePhase_follicular => 'ما قبل التبويض';

  @override
  String get cyclePhase_fertileWindow => 'نافذة الخصوبة';

  @override
  String get cyclePhase_ovulation => 'ذروة الخصوبة';

  @override
  String get cyclePhase_luteal => 'ما بعد التبويض';

  @override
  String get cyclePhase_late => 'متأخرة';

  @override
  String get cyclePhase_unknown => 'غير معروفة';

  @override
  String get cyclePhase_menstruationDescription => 'دورتك الشهرية نشطة ويجري التخلص من بطانة الرحم.';

  @override
  String get cyclePhase_fertileWindowDescription => 'نافذة الخصوبة لديكِ نشطة حاليًا.';

  @override
  String get cyclePhase_follicularDescription => 'يرتفع هرمون الإستروجين لتهيئة البويضة؛ وقد تشعرين بازدياد مستويات طاقتك.';

  @override
  String get cyclePhase_ovulationDescription => 'تم إطلاق بويضة. هذه أكثر فتراتك خصوبة.';

  @override
  String get cyclePhase_lutealDescription => 'هرمون البروجسترون هو السائد. راقبي أعراض ما قبل الدورة مع اقتراب موعد دورتك القادمة.';

  @override
  String get cyclePhase_lateDescription => 'دورتك الشهرية متأخرة.';

  @override
  String get cyclePhase_unknownDescription => 'نحتاج إلى مزيد من البيانات للتنبؤ بمرحلة دورتك بدقة.';

  @override
  String get fertilityChance_high => 'مرتفعة';

  @override
  String get fertilityChance_medium => 'متوسطة';

  @override
  String get fertilityChance_low => 'منخفضة';

  @override
  String get error_valueMustbePositive => 'يجب أن تكون القيمة موجبة';

  @override
  String get error_valueCannotBeNull => 'لا يمكن أن تكون القيمة فارغة';

  @override
  String get notification_periodTitle => 'اقتراب موعد الدورة';

  @override
  String notification_periodBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من المتوقع أن تبدأ دورتك القادمة خلال $count يوم.',
      many: 'من المتوقع أن تبدأ دورتك القادمة خلال $count يومًا.',
      few: 'من المتوقع أن تبدأ دورتك القادمة خلال $count أيام.',
      two: 'من المتوقع أن تبدأ دورتك القادمة خلال يومين.',
      one: 'من المتوقع أن تبدأ دورتك القادمة خلال يوم واحد.',
    );
    return '$_temp0';
  }

  @override
  String get notification_periodOverdueTitle => 'تأخر الدورة';

  @override
  String notification_periodOverdueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'دورتك القادمة متأخرة بـ $count يوم.',
      many: 'دورتك القادمة متأخرة بـ $count يومًا.',
      few: 'دورتك القادمة متأخرة بـ $count أيام.',
      two: 'دورتك القادمة متأخرة بيومين.',
      one: 'دورتك القادمة متأخرة بيوم واحد.',
    );
    return '$_temp0';
  }

  @override
  String get notification_pillTitle => 'تذكير بالحبة';

  @override
  String get notification_pillBody => 'لا تنسي تناول حبتك لهذا اليوم.';

  @override
  String get notification_reversibleContraceptiveTitle => 'تذكير بوسيلة منع الحمل';

  @override
  String notification_reversibleContraceptiveBody(String type, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يوم',
      one: 'يوم',
    );
    return 'يحين موعد تجديد $type خلال $days $_temp0.';
  }

  @override
  String get notification_loggingReminderTitle => 'تذكير بالتسجيل';

  @override
  String get notification_loggingReminderBody => 'اضغطي لتسجيل تدفقك لهذا اليوم.';

  @override
  String get notification_SanitaryProductReminderTitle => 'تذكير بالمنتج الصحي';

  @override
  String get notification_SanitaryProductReminderBody => 'تذكري تغيير منتجك الصحي.';

  @override
  String get notification_fertileWindowTitle => 'تذكير بنافذة الخصوبة';

  @override
  String notification_fertileWindowBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من المتوقع أن تبدأ نافذة الخصوبة القادمة خلال $count يوم.',
      many: 'من المتوقع أن تبدأ نافذة الخصوبة القادمة خلال $count يومًا.',
      few: 'من المتوقع أن تبدأ نافذة الخصوبة القادمة خلال $count أيام.',
      two: 'من المتوقع أن تبدأ نافذة الخصوبة القادمة خلال يومين.',
      one: 'من المتوقع أن تبدأ نافذة الخصوبة القادمة خلال يوم واحد.',
    );
    return '$_temp0';
  }

  @override
  String get notification_ovulationDayReminderTitle => 'تذكير بيوم التبويض';

  @override
  String notification_ovulationDayReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من المتوقع أن يحل يوم التبويض القادم خلال $count يوم.',
      many: 'من المتوقع أن يحل يوم التبويض القادم خلال $count يومًا.',
      few: 'من المتوقع أن يحل يوم التبويض القادم خلال $count أيام.',
      two: 'من المتوقع أن يحل يوم التبويض القادم خلال يومين.',
      one: 'من المتوقع أن يحل يوم التبويض القادم خلال يوم واحد.',
    );
    return '$_temp0';
  }

  @override
  String get onboardingScreen_welcomeToMenstrudel => 'مرحبًا بكِ في Menstrudel';

  @override
  String get onboardingScreen_welcomeToMenstrudelDescription => 'متتبع دورتك الشهرية الخاص الذي يعمل دون اتصال بالإنترنت.';

  @override
  String get onBoardingScreen_byUsingMenstrudelYouAgreeTo => 'باستخدامكِ Menstrudel، فإنكِ توافقين على ';

  @override
  String get onBoardingScreen_privacyPolicy => 'سياسة الخصوصية';

  @override
  String get onboardingScreen_profileTitle => 'نبذة عنكِ';

  @override
  String get onboardingScreen_profileName => 'بماذا نناديكِ؟';

  @override
  String get onboardingScreen_profileDate => 'تاريخ الميلاد (اختياري)';

  @override
  String get onboardingScreen_profileDatePlaceholder => 'اضغطي لتحديد تاريخ ميلادك';

  @override
  String get onboardingScreen_goalTitle => 'ما هدفك؟';

  @override
  String get onboardingScreen_goalDescription => 'يساعدنا هذا في تخصيص التحليلات التي تظهر لكِ.';

  @override
  String onboardingScreen_contraceptionHint(String sectionName) {
    return 'ملاحظة: يمكنكِ تفعيل تتبع الحبوب أو وسائل منع الحمل لاحقًا من إعدادات التطبيق ضمن \'$sectionName\' إذا رغبتِ.';
  }

  @override
  String get onboardingScreen_getStarted => 'ابدئي الآن';

  @override
  String get fabToolTip_logs => 'تسجيل اليوم';

  @override
  String get fabToolTip_sanitary => 'تسجيل منتج صحي';

  @override
  String get fabToolTip_sexActivity => 'تسجيل نشاط جنسي';

  @override
  String get fabToolTip_reversibleContraceptive => 'تسجيل وسيلة منع حمل';

  @override
  String get mainScreen_logsPageTitle => 'السجلات';

  @override
  String get mainSceen_sexActivityPageTitle => 'النشاط الجنسي';

  @override
  String get mainScreen_sanitaryPageTitle => 'المنتجات الصحية';

  @override
  String get mainScreen_pillsPageTitle => 'الحبوب';

  @override
  String get mainScreen_reversibleContraceptivesPageTitle => 'وسائل منع الحمل';

  @override
  String get mainScreen_settingsPageTitle => 'الإعدادات';

  @override
  String get insightsScreen_errorPrefix => 'خطأ:';

  @override
  String get insightsScreen_noDataAvailable => 'لا توجد بيانات متاحة.';

  @override
  String get logsScreen_calculatingPrediction => 'جارٍ حساب التوقعات...';

  @override
  String get logScreen_logAtLeastTwoPeriods => 'سجّلي دورتين على الأقل لتقدير موعد الدورة القادمة.';

  @override
  String get logScreen_nextPeriodEstimate => 'الدورة القادمة المتوقعة';

  @override
  String get logScreen_periodDueToday => 'موعد الدورة اليوم';

  @override
  String logScreen_periodOverdueBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'الدورة متأخرة بـ $count يوم',
      many: 'الدورة متأخرة بـ $count يومًا',
      few: 'الدورة متأخرة بـ $count أيام',
      two: 'الدورة متأخرة بيومين',
      one: 'الدورة متأخرة بيوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get pillScreen_pillForTodayMarkedAsTaken => 'تم تسجيل حبة اليوم على أنها أُخذت.';

  @override
  String get pillScreen_pillForTodayMarkedAsSkipped => 'تم تسجيل حبة اليوم على أنها تم تخطيها.';

  @override
  String get reversibleContraceptiveScreen_noRecordsFound => 'لم يتم العثور على سجلات.';

  @override
  String reversibleContraceptiveScreen_history(int history) {
    return 'السجل ($history)';
  }

  @override
  String reversibleContraceptiveScreen_activeReversibleContraceptives(int activeCount) {
    return 'النشطة ($activeCount)';
  }

  @override
  String get reversibleContraceptiveScreen_activeReversibleContraceptivesDescription => 'إدخالات وسائل منع الحمل قيد المتابعة حاليًا.';

  @override
  String get reversibleContraceptiveScreen_noActiveRecords => 'لا توجد وسيلة منع حمل نشطة حاليًا. يرجى تسجيل إدخال جديد.';

  @override
  String get reversibleContraceptiveScreen_noHistoryRecords => 'لم يتم العثور على سجلات سابقة أو متأخرة لوسائل منع الحمل.';

  @override
  String get sanitaryProductsScreen_noSanitaryProductRecordsFound => 'لم يتم العثور على سجلات للمنتجات الصحية.';

  @override
  String sanitaryProductsScreen_history(int history) {
    return 'السجل ($history)';
  }

  @override
  String get sanitaryProductsScreen_noHistoryRecords => 'لم يتم العثور على سجلات سابقة للمنتجات الصحية.';

  @override
  String sanitaryProductsScreen_activeProduct(String activeType) {
    return 'النشط حاليًا: $activeType';
  }

  @override
  String sanitaryProductsScreen_changeDueAt(String time) {
    return 'موعد التغيير في $time';
  }

  @override
  String get sexActivityScreen_noSexActivityRecordsFound => 'لم يتم العثور على سجلات للنشاط الجنسي.';

  @override
  String sexActivityScreen_history(int history) {
    return 'السجل ($history)';
  }

  @override
  String get sexActivityScreen_primaryMethod => 'الوسيلة الأساسية';

  @override
  String get sexActivityScreen_mostFrequent => 'الأكثر تكرارًا';

  @override
  String get sexActivityScreen_protected => 'بوقاية';

  @override
  String get sexActivityScreen_activityTrend => 'اتجاه النشاط';

  @override
  String get sexActivityScreen_activityDistribution => 'توزيع النشاط';

  @override
  String get sexActivityScreen_protectionDistribution => 'توزيع وسائل الوقاية';

  @override
  String get settingsScreen_profile => 'الملف الشخصي';

  @override
  String get settingsScreen_name => 'الاسم';

  @override
  String get settingsScreen_birthDate => 'تاريخ الميلاد';

  @override
  String get settingsScreen_notSet => 'غير محدد';

  @override
  String get settingsScreen_appGoal => 'هدف التطبيق';

  @override
  String get settingsScreen_profileUpdated => 'تم تحديث الملف الشخصي بنجاح';

  @override
  String get settingsScreen_selectHistoryView => 'اختاري طريقة عرض السجل';

  @override
  String get settingsScreen_deleteRegimen_question => 'حذف نظام الحبوب؟';

  @override
  String get settingsScreen_deleteRegimenDescription => 'سيؤدي هذا إلى حذف إعدادات شريط الحبوب الحالي وجميع سجلات الحبوب المرتبطة به. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get settingsScreen_allLogsHaveBeenCleared => 'تم مسح جميع السجلات.';

  @override
  String get settingsScreen_clearAllLogs_question => 'مسح جميع السجلات؟';

  @override
  String get settingsScreen_deleteAllLogsDescription => 'سيؤدي هذا إلى حذف جميع سجلات دورتك الشهرية نهائيًا. لن تتأثر إعدادات التطبيق.';

  @override
  String get settingsScreen_appearance => 'المظهر';

  @override
  String get settingsScreen_historyViewStyle => 'نمط عرض السجل';

  @override
  String get settingsScreen_appTheme => 'سمة التطبيق';

  @override
  String get settingsScreen_themeLight => 'فاتح';

  @override
  String get settingsScreen_themeDark => 'داكن';

  @override
  String get settingsScreen_themeSystem => 'النظام';

  @override
  String get settingsScreen_dynamicTheme => 'سمة ديناميكية';

  @override
  String get settingsScreen_useWallpaperColors => 'استخدام ألوان الخلفية';

  @override
  String get settingsScreen_themeColor => 'لون السمة';

  @override
  String get settingsScreen_pickAColor => 'اختاري لونًا';

  @override
  String get settingsScreen_view => 'عرض';

  @override
  String get settingsScreen_birthControl => 'منع الحمل';

  @override
  String get settingsScreen_enablePillTracking => 'تفعيل تتبع الحبوب';

  @override
  String get settingsScreen_pillDescription => 'تتبعي تناولك اليومي للحبوب واحصلي على تذكيرات.';

  @override
  String get settingsScreen_setUpPillRegimen => 'إعداد نظام الحبوب';

  @override
  String get settingsScreen_trackYourDailyPillIntake => 'تتبعي تناولك اليومي للحبوب';

  @override
  String get settingsScreen_dailyPillReminder => 'تذكير الحبوب اليومي';

  @override
  String get settingsScreen_reminderTime => 'وقت التذكير';

  @override
  String get settingsScreen_cycleNotificationsAndPredictions => 'إشعارات الدورة والتوقعات';

  @override
  String get settingsScreen_enablePhasePredictions => 'تفعيل توقعات مراحل الدورة';

  @override
  String get settingsScreen_displayFertileChance => 'عرض فرصة الخصوبة';

  @override
  String get settingsScreen_displayFertileWindowOnCalendar => 'عرض نافذة الخصوبة في التقويم';

  @override
  String get settingsScreen_notificationTime => 'وقت الإشعار';

  @override
  String get settingsScreen_remindMeBefore => 'ذكّرني قبل';

  @override
  String get settingsScreen_remindMeAfter => 'ذكّرني بعد';

  @override
  String get settingsScreen_upcomingPeriodReminder => 'تذكير بالدورة القادمة';

  @override
  String get settingsScreen_overduePeriodReminder => 'تذكير بالدورة المتأخرة';

  @override
  String get settingsScreen_fertileWindowReminder => 'تذكير بنافذة الخصوبة';

  @override
  String get settingsScreen_ovulationDayReminder => 'تذكير بيوم التبويض';

  @override
  String get settingsScreen_enableReversibleContraceptiveTracking => 'تفعيل تتبع وسائل منع الحمل';

  @override
  String get settingsScreen_reversibleContraceptiveDescription => 'تتبعي وسائل منع الحمل طويلة المفعول.';

  @override
  String get settingsScreen_reversibleContraceptiveType => 'نوع وسيلة منع الحمل';

  @override
  String get settingsScreen_setDuration => 'تحديد المدة';

  @override
  String get settingsScreen_reversibleContraceptiveDuration => 'مدة استبدال وسيلة منع الحمل';

  @override
  String get settingsScreen_enableReversibleContraceptiveReminder => 'تفعيل تذكير وسيلة منع الحمل';

  @override
  String get settingsScreen_currentDuration => 'المدة الحالية';

  @override
  String get settingsScreen_durationInDays => 'المدة (بالأيام)';

  @override
  String get settingsScreen_LoggingScreen => 'التسجيل';

  @override
  String get settingsScreen_enableLoggingReminders => 'تفعيل تذكيرات التسجيل';

  @override
  String get settingsScreen_loggingReminderDescription => 'إذا سجّلتِ يومًا به تدفق، فستتلقين إشعارًا في اليوم التالي لتسجيل حالتك.';

  @override
  String get settingsScreen_loggingReminderTime => 'وقت تذكير التسجيل';

  @override
  String get settingsScreen_defaultSymptoms => 'الأعراض الافتراضية';

  @override
  String get settingsScreen_defaultSymptomsSubtitle => 'تكون هذه الأعراض متاحة دائمًا عند تسجيل دورات جديدة.\nاضغطي على عرَض موجود لحذفه أو على \'+\' لإضافة عرَض جديد.';

  @override
  String settingsScreen_deleteDefaultSymptomQuestion(String symptom) {
    return 'حذف \'$symptom\'؟';
  }

  @override
  String get settingsScreen_resetSymptomsList => 'إعادة تعيين قائمة الأعراض؟';

  @override
  String get settingsScreen_resetSymptomsListDescription => 'سيؤدي هذا إلى إزالة جميع الأعراض المخصصة واستعادة القائمة الأصلية المدمجة.\n\nلن تتغير إدخالات السجل الحالية.';

  @override
  String settingsScreen_deleteDefaultSymptomDescription(String symptom, num usageCount) {
    String _temp0 = intl.Intl.pluralLogic(
      usageCount,
      locale: localeName,
      other: 'يوجد $usageCount سجل دورة بهذا العرَض!\nلن تتغير هذه السجلات.',
      many: 'يوجد $usageCount سجل دورة بهذا العرَض!\nلن تتغير هذه السجلات.',
      few: 'توجد $usageCount سجلات دورة بهذا العرَض!\nلن تتغير هذه السجلات.',
      two: 'يوجد سجلا دورة بهذا العرَض!\nلن يتغير هذان السجلان.',
      one: 'يوجد بالفعل سجل دورة واحد بهذا العرَض!\nلن يتغير هذا السجل.',
      zero: 'لا توجد حاليًا أي سجلات دورة بهذا العرَض!',
    );
    return 'لن يكون \'$symptom\' متاحًا بعد الآن عند تسجيل الدورة.\n\n$_temp0';
  }

  @override
  String get settingsScreen_pillRegimens => 'أنظمة الحبوب';

  @override
  String get settingsScreen_makeActive => 'تعيين كنشط';

  @override
  String get settingsScreen_activeRegimenReminder => 'إعدادات تذكير النظام النشط';

  @override
  String get settingsScreen_pack => 'الشريط';

  @override
  String get settingsScreen_dataManagement => 'إدارة البيانات';

  @override
  String get settingsScreen_deleteZone => 'منطقة الحذف';

  @override
  String get settingsScreen_clearLogsAndPeriods => 'مسح السجلات والدورات';

  @override
  String get settingsScreen_clearLogsAndPeriodsSubtitle => 'يحذف كامل سجل دوراتك وأعراضك.';

  @override
  String get settingsScreen_clearPillLogs => 'مسح سجلات الحبوب';

  @override
  String get settingsScreen_clearPillLogsSubtitle => 'يزيل نظام الحبوب وسجل تناولها.';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogs => 'مسح سجلات وسائل منع الحمل';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogsSubtitle => 'يزيل سجل وسائل منع الحمل الخاص بكِ.';

  @override
  String get settingsScreen_clearSanitaryProductLogs => 'مسح سجلات المنتجات الصحية';

  @override
  String get settingsScreen_clearSanitaryProductLogsSubtitle => 'يزيل سجل منتجاتك الصحية.';

  @override
  String get settingsScreen_clearSexualActivityLogs => 'مسح سجلات النشاط الجنسي';

  @override
  String get settingsScreen_clearSexualActivityLogsSubtitle => 'يزيل سجل نشاطك الجنسي.';

  @override
  String get settingsScreen_logsAndPeriods => 'السجلات والدورات';

  @override
  String get settingsScreen_pillLogs => 'سجلات الحبوب';

  @override
  String get settingsScreen_reversibleContraceptivesLogs => 'سجلات وسائل منع الحمل';

  @override
  String get settingsScreen_sanitaryProductLogs => 'سجلات المنتجات الصحية';

  @override
  String get settingsScreen_sexualActivityLogs => 'سجلات النشاط الجنسي';

  @override
  String get settingsScreen_importSupportNote => 'الاستيراد مدعوم حاليًا فقط للملفات المصدَّرة من Menstrudel.';

  @override
  String get settingsScreen_exportSuccessful => 'تم تصدير البيانات بنجاح.';

  @override
  String get settingsScreen_exportFailed => 'فشل التصدير. يرجى المحاولة مرة أخرى.';

  @override
  String get settingsScreen_exportDataTitle => 'تصدير البيانات';

  @override
  String get settingsScreen_importDataTitle => 'استيراد البيانات';

  @override
  String get settingsScreen_importDataSubtitle => 'يستبدل البيانات الحالية.';

  @override
  String get settingsScreen_importSuccessful => 'تم استيراد البيانات بنجاح!';

  @override
  String get settingsScreen_importFailed => 'فشل استيراد البيانات. يرجى المحاولة مرة أخرى.';

  @override
  String get settingsScreen_importErrorGeneral => 'فشل استيراد البيانات. يرجى التأكد من أن الملف محفوظ محليًا.';

  @override
  String get settingsScreen_security => 'الأمان';

  @override
  String get securityScreen_enableBiometricLock => 'تفعيل القفل البيومتري';

  @override
  String get securityScreen_enableBiometricLockSubtitle => 'طلب بصمة الإصبع أو بصمة الوجه لفتح التطبيق.';

  @override
  String get securityScreen_noBiometricsAvailable => 'لم يتم العثور على رمز مرور أو بصمة إصبع أو بصمة وجه. يرجى إعداد إحداها في إعدادات جهازك.';

  @override
  String get settingsScreen_userProfile => 'أنتِ';

  @override
  String get settingsScreen_preferences => 'التفضيلات';

  @override
  String get preferencesScreen_language => 'اللغة';

  @override
  String get preferencesScreen_enableSanitaryProductsScreen => 'تفعيل شاشة المنتجات الصحية';

  @override
  String get preferencesScreen_enableSanitaryProductsScreenSubtitle => 'إظهار تبويب المنتجات الصحية في شريط التنقل الرئيسي.';

  @override
  String get preferencesScreen_enableSexActivityScreen => 'تفعيل شاشة النشاط الجنسي';

  @override
  String get preferencesScreen_enableSexActivityScreenSubtitle => 'إظهار تبويب النشاط الجنسي في شريط التنقل الرئيسي.';

  @override
  String get preferencesScreen_StartingDayOfWeek => 'أول أيام الأسبوع';

  @override
  String get settingsScreen_about => 'حول التطبيق';

  @override
  String get aboutScreen_version => 'الإصدار';

  @override
  String get aboutScreen_legalAndSource => 'الشؤون القانونية والمصدر';

  @override
  String get aboutScreen_communityAndUpdates => 'المجتمع والتحديثات';

  @override
  String get aboutScreen_privacyPolicy => 'سياسة الخصوصية';

  @override
  String get aboutScreen_privacyPolicySubtitle => 'اقرئي سياسة الخصوصية';

  @override
  String get aboutScreen_releaseNotes => 'ملاحظات الإصدار';

  @override
  String aboutScreen_releaseNotesSubtitle(String version) {
    return 'ما الجديد في $version';
  }

  @override
  String get aboutScreen_github => 'GitHub';

  @override
  String get aboutScreen_githubSubtitle => 'الشيفرة المصدرية وتتبع المشكلات';

  @override
  String get aboutScreen_discord => 'Discord';

  @override
  String get aboutScreen_discordSubtitle => 'الدعم والمجتمع';

  @override
  String get aboutScreen_share => 'مشاركة';

  @override
  String get aboutScreen_shareText => 'جرّبي Menstrudel، تطبيق خاص لتتبع الدورة الشهرية يعمل دون اتصال بالإنترنت!';

  @override
  String get aboutScreen_urlError => 'تعذر فتح الرابط.';

  @override
  String get logSummaryWidget_loggedDays => 'الأيام المسجلة';

  @override
  String get logSummaryWidget_trackingHistory => 'سجل التتبع';

  @override
  String get cycleLengthVarianceWidget_logAtLeastTwoPeriods => 'نحتاج إلى دورتين على الأقل لعرض التفاوت.';

  @override
  String get cycleLengthVarianceWidget_title => 'تفاوت طول الدورة';

  @override
  String get cycleLengthVarianceWidget_averageCycle => 'متوسط الدورة';

  @override
  String get cycleLengthVarianceWidget_cycle => 'الدورة';

  @override
  String get periodDurationWidget_logAtLeastTwoPeriods => 'سجّلي دورتين على الأقل لعرض إحصاءات الحيض.';

  @override
  String get periodDurationWidget_title => 'تفاوت مدة الحيض';

  @override
  String get periodDurationWidget_averagePeriod => 'متوسط الحيض';

  @override
  String get periodDurationWidget_period => 'الحيض';

  @override
  String get flowIntensityWidget_flowIntensityBreakdown => 'توزيع شدة التدفق';

  @override
  String get flowIntensityWidget_noFlowDataLoggedYet => 'لم يتم تسجيل بيانات تدفق بعد.';

  @override
  String get painLevelWidget_noPainDataLoggedYet => 'لم يتم تسجيل بيانات ألم بعد.';

  @override
  String get painLevelWidget_painLevelBreakdown => 'توزيع مستوى الألم';

  @override
  String get monthlyFlowChartWidget_noDataToDisplay => 'لا توجد بيانات للعرض.';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatterns => 'أنماط تدفق الدورة';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatternsDescription => 'يمثل كل خط دورة كاملة واحدة';

  @override
  String get symptomFrequencyWidget_noSymptomsLoggedYet => 'لم يتم تسجيل أعراض بعد.';

  @override
  String get symptomFrequencyWidget_mostCommonSymptoms => 'الأعراض الأكثر شيوعًا';

  @override
  String get journalViewWidget_logYourFirstPeriod => 'سجّلي دورتك الأولى.';

  @override
  String get listViewWidget_noPeriodsLogged => 'لم يتم تسجيل أي دورات بعد.\nاضغطي على زر + لإضافة واحدة.';

  @override
  String get listViewWidget_confirmDelete => 'تأكيد الحذف';

  @override
  String get listViewWidget_confirmDeleteDescription => 'هل أنتِ متأكدة من رغبتك في حذف هذا الإدخال؟';

  @override
  String get emptyPillStateWidget_noPillRegimenFound => 'لم يتم العثور على نظام حبوب.';

  @override
  String get emptyPillStateWidget_noPillRegimenFoundDescription => 'أعدّي شريط حبوبك في الإعدادات لبدء التتبع.';

  @override
  String pillStatus_pillsOfTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count حبة',
      many: 'من $count حبة',
      few: 'من $count حبوب',
      two: 'من حبتين',
      one: 'من حبة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get pillStatus_undo => 'تراجع';

  @override
  String get pillStatus_skip => 'تخطي';

  @override
  String get pillStatus_markAsTaken => 'تحديد كمأخوذة';

  @override
  String pillStatus_packStartInFuture(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'يبدأ شريط حبوبك التالي في $dateString.';
  }

  @override
  String get regimenSetupWidget_setUpPillRegimen => 'إعداد نظام الحبوب';

  @override
  String get regimenSetupWidget_packName => 'اسم الشريط';

  @override
  String get regimenSetupWidget_pleaseEnterAName => 'يرجى إدخال اسم';

  @override
  String get regimenSetupWidget_activePills => 'الحبوب الفعالة';

  @override
  String get regimenSetupWidget_enterANumber => 'أدخلي رقمًا';

  @override
  String get regimenSetupWidget_placeboPills => 'الحبوب الوهمية';

  @override
  String get regimenSetupWidget_firstDayOfThisPack => 'اليوم الأول لهذا الشريط';

  @override
  String get symptomEntrySheet_logYourDay => 'سجّلي يومك';

  @override
  String get symptomEntrySheet_symptomsOptional => 'الأعراض (اختياري)';

  @override
  String get periodDetailsSheet_symptoms => 'الأعراض';

  @override
  String get periodDetailsSheet_flow => 'التدفق';

  @override
  String get reversibleContraceptiveEntrySheet_logReversibleContraceptiveDetails => 'تسجيل تفاصيل وسيلة منع الحمل';

  @override
  String get sanitaryEntrySheet_logSanitaryProduct => 'تسجيل منتج صحي';

  @override
  String get sanitaryEntrySheet_setReminderDuration => 'تحديد مدة التذكير';

  @override
  String sanitaryEntrySheet_maxDuration(int hours) {
    return 'الحد الأقصى للمدة: $hours ساعة';
  }

  @override
  String get sanitaryEntrySheet_futureLogTimeError => 'لا يمكن أن يكون وقت التسجيل في المستقبل.';

  @override
  String get sanitaryEntrySheet_pastReminderTimeError => 'لا يمكن أن يكون وقت انتهاء التذكير في الماضي.';

  @override
  String periodPredictionCircle_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يوم',
      many: 'يومًا',
      few: 'أيام',
      two: 'يومان',
      one: 'يوم',
    );
    return '$_temp0';
  }

  @override
  String get customSymptomDialog_newSymptom => 'عرَض جديد';

  @override
  String get customSymptomDialog_enterCustomSymptom => 'أدخلي عرَضًا مخصصًا';

  @override
  String get customSymptomDialog_temporarySymptom => 'عرَض مؤقت';
}
