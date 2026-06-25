// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Menstrudel';

  @override
  String get nextDue => 'รอบถัดไป';

  @override
  String get ongoing => 'กำลังดำเนินอยู่';

  @override
  String get overdue => 'เลยกำหนด';

  @override
  String get total => 'รวมทั้งหมด';

  @override
  String get shortest => 'สั้นที่สุด';

  @override
  String get longest => 'ยาวที่สุด';

  @override
  String get unknown => 'ไม่ทราบ';

  @override
  String get date => 'วันที่';

  @override
  String get time => 'เวลา';

  @override
  String get start => 'เริ่มต้น';

  @override
  String get end => 'สิ้นสุด';

  @override
  String get next => 'ถัดไป';

  @override
  String get back => 'ย้อนกลับ';

  @override
  String get today => 'วันนี้';

  @override
  String get day => 'วัน';

  @override
  String get days => 'วัน';

  @override
  String get hours => 'ชั่วโมง';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count วัน',
      one: '$count วัน',
    );
    return '$_temp0';
  }

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count เดือน',
      one: '$count เดือน',
    );
    return '$_temp0';
  }

  @override
  String yearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ปี',
      one: '$count ปี',
    );
    return '$_temp0';
  }

  @override
  String countdown_daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'เหลืออีก $days วัน',
      one: 'เหลืออีก $days วัน',
    );
    return '$_temp0';
  }

  @override
  String countUp_day(int day) {
    return 'Day $day';
  }

  @override
  String get logs => 'บันทึก';

  @override
  String get insights => 'สรุปข้อมูลเชิงลึก';

  @override
  String get edit => 'แก้ไข';

  @override
  String get delete => 'ลบ';

  @override
  String get clear => 'ล้างข้อมูล';

  @override
  String get save => 'บันทึก';

  @override
  String get import => 'นำเข้า';

  @override
  String get ok => 'ตกลง';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get set => 'ตั้งค่า';

  @override
  String get yes => 'ใช่';

  @override
  String get no => 'ไม่ใช่';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get select => 'เลือก';

  @override
  String get close => 'ปิด';

  @override
  String get reset => 'รีเซ็ต';

  @override
  String get add => 'เพิ่ม';

  @override
  String get notSet => 'ยังไม่ได้ตั้งค่า';

  @override
  String get removed => 'ถูกลบแล้ว';

  @override
  String get totalLogs => 'บันทึกทั้งหมด';

  @override
  String get note => 'หมายเหตุ';

  @override
  String get systemDefault => 'ค่าเริ่มต้นของระบบ';

  @override
  String get flow => 'ปริมาณประจำเดือน';

  @override
  String get type => 'ประเภท';

  @override
  String get other => 'อื่น ๆ';

  @override
  String get navBar_logs => 'บันทึก';

  @override
  String get navBar_sanitary => 'ผลิตภัณฑ์สุขอนามัย';

  @override
  String get navBar_sexActivity => 'กิจกรรมทางเพศ';

  @override
  String get navBar_pill => 'ยาคุมกำเนิด';

  @override
  String get navBar_reversibleContraceptive => 'วิธีคุมกำเนิด';

  @override
  String get navBar_settings => 'การตั้งค่า';

  @override
  String get flowIntensity_none => 'ไม่มี';

  @override
  String get flowIntensity_spotting => 'เลือดกะปริดกะปรอย';

  @override
  String get flowIntensity_light => 'น้อย';

  @override
  String get flowIntensity_moderate => 'ปานกลาง';

  @override
  String get flowIntensity_heavy => 'มาก';

  @override
  String get builtInSymptom_acne => 'สิว';

  @override
  String get builtInSymptom_backPain => 'ปวดหลัง';

  @override
  String get builtInSymptom_bloating => 'ท้องอืด';

  @override
  String get builtInSymptom_cramps => 'ปวดท้องประจำเดือน';

  @override
  String get builtInSymptom_fatigue => 'อ่อนเพลีย';

  @override
  String get builtInSymptom_headache => 'ปวดศีรษะ';

  @override
  String get builtInSymptom_moodSwings => 'อารมณ์แปรปรวน';

  @override
  String get builtInSymptom_nausea => 'คลื่นไส้';

  @override
  String get builtInSymptom_tenderBreasts => 'Tender breasts';

  @override
  String get builtInSymptom_insomnia => 'Insomnia';

  @override
  String get builtInSymptom_depressed => 'Depressed';

  @override
  String get builtInSymptom_sleep => 'การนอนหลับ (ชั่วโมง)';

  @override
  String get builtInSymptom_water => 'น้ำ (แก้ว)';

  @override
  String get painLevel_title => 'ระดับความปวด';

  @override
  String get painLevel_none => 'ไม่ปวด';

  @override
  String get painLevel_mild => 'เล็กน้อย';

  @override
  String get painLevel_moderate => 'ปานกลาง';

  @override
  String get painLevel_severe => 'รุนแรง';

  @override
  String get pain_unbearable => 'รุนแรงมาก';

  @override
  String get reversibleContraceptive_hormonalIud => 'ห่วงคุมกำเนิดชนิดฮอร์โมน';

  @override
  String get reversibleContraceptive_copperIud => 'ห่วงคุมกำเนิดชนิดทองแดง';

  @override
  String get reversibleContraceptive_implant => 'ยาฝังคุมกำเนิด';

  @override
  String get reversibleContraceptive_injection => 'ยาฉีดคุมกำเนิด';

  @override
  String get reversibleContraceptive_ring => 'ห่วงคุมกำเนิดชนิดสอด';

  @override
  String get reversibleContraceptive_patch => 'แผ่นแปะคุมกำเนิด';

  @override
  String get sanitaryProduct_tampon => 'ผ้าอนามัยแบบสอด';

  @override
  String get sanitaryProduct_pad => 'ผ้าอนามัยแบบแผ่น';

  @override
  String get sanitaryProduct_menstrualCup => 'ถ้วยอนามัย';

  @override
  String get sanitaryProduct_periodUnderwear => 'กางเกงชั้นในซึมซับประจำเดือน';

  @override
  String get sanitaryProducts_mostUsed => 'ใช้บ่อยที่สุด';

  @override
  String get sanitaryProducts_usageTrend => 'แนวโน้มการใช้งาน';

  @override
  String get sexProtection_none => 'ไม่ใช้';

  @override
  String get sexProtection_barrier => 'แบบกั้น';

  @override
  String get sexProtection_hormonal => 'แบบฮอร์โมน';

  @override
  String get sexProtection_nonHormonal => 'ไม่ใช้ฮอร์โมน';

  @override
  String get sexProtection_natural => 'วิธีธรรมชาติ';

  @override
  String get sexProtection_permanent => 'ถาวร';

  @override
  String get sexType_vaginal => 'ทางช่องคลอด';

  @override
  String get sexType_anal => 'ทางทวารหนัก';

  @override
  String get sexType_oral => 'ทางปาก';

  @override
  String get sexType_manual => 'ใช้มือ';

  @override
  String get sexParticipation_solo => 'คนเดียว';

  @override
  String get sexParticipation_partner => 'กับคู่';

  @override
  String get sexParticipation_group => 'หลายคน';

  @override
  String get userGoal_general => 'สุขภาพทั่วไป';

  @override
  String get userGoal_sexual => 'สุขภาพทางเพศ';

  @override
  String get userGoal_conceive => 'กำลังพยายามตั้งครรภ์';

  @override
  String get userGoal_avoid => 'หลีกเลี่ยงการตั้งครรภ์';

  @override
  String get dayOfWeek_monday => 'วันจันทร์';

  @override
  String get dayOfWeek_tuesday => 'วันอังคาร';

  @override
  String get dayOfWeek_wednesday => 'วันพุธ';

  @override
  String get dayOfWeek_thursday => 'วันพฤหัสบดี';

  @override
  String get dayOfWeek_friday => 'วันศุกร์';

  @override
  String get dayOfWeek_saturday => 'วันเสาร์';

  @override
  String get dayOfWeek_sunday => 'วันอาทิตย์';

  @override
  String get cyclePhase_menstruation => 'มีประจำเดือน';

  @override
  String get cyclePhase_follicular => 'ก่อนตกไข่';

  @override
  String get cyclePhase_fertileWindow => 'Fertile Window';

  @override
  String get cyclePhase_ovulation => 'ช่วงเจริญพันธุ์สูงสุด';

  @override
  String get cyclePhase_luteal => 'หลังตกไข่';

  @override
  String get cyclePhase_late => 'ล่าช้า';

  @override
  String get cyclePhase_unknown => 'ไม่ทราบ';

  @override
  String get cyclePhase_menstruationDescription => 'คุณกำลังมีประจำเดือน และเยื่อบุโพรงมดลูกกำลังหลุดลอก';

  @override
  String get cyclePhase_fertileWindowDescription => 'Your fertile window is active.';

  @override
  String get cyclePhase_follicularDescription => 'ระดับเอสโตรเจนกำลังเพิ่มขึ้นเพื่อเตรียมไข่ ระดับพลังงานของคุณอาจเพิ่มขึ้นด้วย';

  @override
  String get cyclePhase_ovulationDescription => 'มีการตกไข่แล้ว นี่คือช่วงที่มีโอกาสตั้งครรภ์สูงที่สุด';

  @override
  String get cyclePhase_lutealDescription => 'ฮอร์โมนโปรเจสเตอโรนจะสูงในช่วงนี้ สังเกตอาการก่อนมีประจำเดือนเมื่อใกล้ถึงรอบถัดไป';

  @override
  String get cyclePhase_lateDescription => 'ประจำเดือนของคุณมาช้า';

  @override
  String get cyclePhase_unknownDescription => 'ต้องการข้อมูลเพิ่มเติมเพื่อคาดการณ์ระยะรอบเดือนอย่างแม่นยำ';

  @override
  String get fertilityChance_high => 'High';

  @override
  String get fertilityChance_medium => 'Medium';

  @override
  String get fertilityChance_low => 'Low';

  @override
  String get error_valueMustbePositive => 'ค่าต้องมากกว่า 0';

  @override
  String get error_valueCannotBeNull => 'ห้ามเว้นว่าง';

  @override
  String get notification_periodTitle => 'ใกล้ถึงรอบเดือน';

  @override
  String notification_periodBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'คาดว่าประจำเดือนครั้งถัดไปจะมาในอีก $count วัน',
      one: 'คาดว่าประจำเดือนครั้งถัดไปจะมาในอีก 1 วัน',
    );
    return '$_temp0';
  }

  @override
  String get notification_periodOverdueTitle => 'ประจำเดือนมาช้า';

  @override
  String notification_periodOverdueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ประจำเดือนครั้งถัดไปมาช้าไป $count วัน',
      one: 'ประจำเดือนครั้งถัดไปมาช้าไป 1 วัน',
    );
    return '$_temp0';
  }

  @override
  String get notification_pillTitle => 'เตือนการรับประทานยาคุม';

  @override
  String get notification_pillBody => 'อย่าลืมรับประทานยาคุมวันนี้';

  @override
  String get notification_reversibleContraceptiveTitle => 'เตือนการคุมกำเนิดแบบชั่วคราว';

  @override
  String notification_reversibleContraceptiveBody(String type, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'วัน',
      one: 'วัน',
    );
    return '$type ครบกำหนดต่ออายุในอีก $days $_temp0';
  }

  @override
  String get notification_loggingReminderTitle => 'เตือนการบันทึกข้อมูล';

  @override
  String get notification_loggingReminderBody => 'แตะเพื่อบันทึกปริมาณประจำเดือนวันนี้';

  @override
  String get notification_SanitaryProductReminderTitle => 'เตือนการเปลี่ยนผลิตภัณฑ์สุขอนามัย';

  @override
  String get notification_SanitaryProductReminderBody => 'อย่าลืมเปลี่ยนผลิตภัณฑ์';

  @override
  String get notification_fertileWindowTitle => 'Fertile Window Reminder';

  @override
  String notification_fertileWindowBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your next fertile window is estimated to start in $count days.',
      one: 'Your next fertile window is estimated to start in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get notification_ovulationDayReminderTitle => 'Ovulation Day Reminder';

  @override
  String notification_ovulationDayReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your next ovulation day is estimated to start in $count days.',
      one: 'Your next ovulation day is estimated to start in 1 day.',
    );
    return '$_temp0';
  }

  @override
  String get onboardingScreen_welcomeToMenstrudel => 'ยินดีต้อนรับสู่ Menstrudel';

  @override
  String get onboardingScreen_welcomeToMenstrudelDescription => 'แอปติดตามรอบเดือนแบบออฟไลน์และเป็นส่วนตัว';

  @override
  String get onBoardingScreen_byUsingMenstrudelYouAgreeTo => 'การใช้งาน Menstrudel ถือว่าคุณยอมรับ ';

  @override
  String get onBoardingScreen_privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get onboardingScreen_profileTitle => 'เกี่ยวกับคุณ';

  @override
  String get onboardingScreen_profileName => 'อยากให้เราเรียกคุณว่าอะไร?';

  @override
  String get onboardingScreen_profileDate => 'วันเกิด (ไม่บังคับ)';

  @override
  String get onboardingScreen_profileDatePlaceholder => 'แตะเพื่อตั้งค่าวันเกิด';

  @override
  String get onboardingScreen_goalTitle => 'เป้าหมายของคุณคืออะไร?';

  @override
  String get onboardingScreen_goalDescription => 'เพื่อปรับข้อมูลให้เหมาะกับคุณมากขึ้น';

  @override
  String onboardingScreen_contraceptionHint(String sectionName) {
    return 'หมายเหตุ: คุณสามารถเปิดการติดตามยาคุมหรือการคุมกำเนิดแบบชั่วคราวได้ภายหลังในการตั้งค่าแอปที่เมนู \'$sectionName\'';
  }

  @override
  String get onboardingScreen_getStarted => 'เริ่มต้นใช้งาน';

  @override
  String get fabToolTip_logs => 'บันทึกวันนี้';

  @override
  String get fabToolTip_sanitary => 'บันทึกผลิตภัณฑ์สุขอนามัย';

  @override
  String get fabToolTip_sexActivity => 'บันทึกกิจกรรมทางเพศ';

  @override
  String get fabToolTip_reversibleContraceptive => 'บันทึกการคุมกำเนิดแบบชั่วคราว';

  @override
  String get mainScreen_logsPageTitle => 'บันทึก';

  @override
  String get mainSceen_sexActivityPageTitle => 'กิจกรรมทางเพศ';

  @override
  String get mainScreen_sanitaryPageTitle => 'ผลิตภัณฑ์อนามัย';

  @override
  String get mainScreen_pillsPageTitle => 'ยาคุมกำเนิด';

  @override
  String get mainScreen_reversibleContraceptivesPageTitle => 'การคุมกำเนิดแบบชั่วคราว';

  @override
  String get mainScreen_settingsPageTitle => 'การตั้งค่า';

  @override
  String get insightsScreen_errorPrefix => 'ข้อผิดพลาด:';

  @override
  String get insightsScreen_noDataAvailable => 'ไม่มีข้อมูล';

  @override
  String get logsScreen_calculatingPrediction => 'กำลังคำนวณการคาดการณ์...';

  @override
  String get logScreen_logAtLeastTwoPeriods => 'กรุณาบันทึกรอบเดือนอย่างน้อย 2 ครั้ง เพื่อคำนวณรอบถัดไป';

  @override
  String get logScreen_nextPeriodEstimate => 'คาดการณ์รอบเดือนถัดไป';

  @override
  String get logScreen_periodDueToday => 'ประจำเดือนควรมาวันนี้';

  @override
  String logScreen_periodOverdueBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ประจำเดือนเลยกำหนด $count วัน',
      one: 'ประจำเดือนเลยกำหนด 1 วัน',
    );
    return '$_temp0';
  }

  @override
  String get pillScreen_pillForTodayMarkedAsTaken => 'บันทึกว่าวันนี้รับประทานยาคุมแล้ว';

  @override
  String get pillScreen_pillForTodayMarkedAsSkipped => 'บันทึกว่าวันนี้ข้ามการรับประทานยาคุม';

  @override
  String get reversibleContraceptiveScreen_noRecordsFound => 'ไม่พบบันทึก';

  @override
  String reversibleContraceptiveScreen_history(int history) {
    return 'ประวัติ ($history)';
  }

  @override
  String reversibleContraceptiveScreen_activeReversibleContraceptives(int activeCount) {
    return 'ที่ใช้อยู่ ($activeCount)';
  }

  @override
  String get reversibleContraceptiveScreen_activeReversibleContraceptivesDescription => 'รายการคุมกำเนิดแบบชั่วคราวที่กำลังติดตามอยู่';

  @override
  String get reversibleContraceptiveScreen_noActiveRecords => 'ขณะนี้ไม่มีการคุมกำเนิดแบบชั่วคราวที่กำลังใช้งาน กรุณาบันทึกรายการใหม่';

  @override
  String get reversibleContraceptiveScreen_noHistoryRecords => 'ไม่พบบันทึกการคุมกำเนิดแบบชั่วคราวในอดีตหรือที่เลยกำหนด';

  @override
  String get sanitaryProductsScreen_noSanitaryProductRecordsFound => 'ไม่พบบันทึกผลิตภัณฑ์อนามัย';

  @override
  String sanitaryProductsScreen_history(int history) {
    return 'ประวัติ ($history)';
  }

  @override
  String get sanitaryProductsScreen_noHistoryRecords => 'ไม่พบบันทึกผลิตภัณฑ์อนามัยในอดีต';

  @override
  String sanitaryProductsScreen_activeProduct(String activeType) {
    return 'กำลังใช้งาน $activeType';
  }

  @override
  String sanitaryProductsScreen_changeDueAt(String time) {
    return 'ควรเปลี่ยนเวลา $time';
  }

  @override
  String get sexActivityScreen_noSexActivityRecordsFound => 'ไม่พบบันทึกกิจกรรมทางเพศ';

  @override
  String sexActivityScreen_history(int history) {
    return 'ประวัติ ($history)';
  }

  @override
  String get sexActivityScreen_primaryMethod => 'วิธีหลัก';

  @override
  String get sexActivityScreen_mostFrequent => 'ใช้บ่อยที่สุด';

  @override
  String get sexActivityScreen_protected => 'มีการป้องกัน';

  @override
  String get sexActivityScreen_activityTrend => 'แนวโน้มกิจกรรม';

  @override
  String get sexActivityScreen_activityDistribution => 'สัดส่วนกิจกรรม';

  @override
  String get sexActivityScreen_protectionDistribution => 'สัดส่วนการป้องกัน';

  @override
  String get settingsScreen_profile => 'โปรไฟล์';

  @override
  String get settingsScreen_name => 'ชื่อ';

  @override
  String get settingsScreen_birthDate => 'วันเกิด';

  @override
  String get settingsScreen_notSet => 'ยังไม่ได้ตั้งค่า';

  @override
  String get settingsScreen_appGoal => 'เป้าหมายการใช้งาน';

  @override
  String get settingsScreen_profileUpdated => 'อัปเดตโปรไฟล์เรียบร้อยแล้ว';

  @override
  String get settingsScreen_selectHistoryView => 'เลือกรูปแบบการแสดงประวัติ';

  @override
  String get settingsScreen_deleteRegimen_question => 'ลบชุดการรับประทานยาคุมหรือไม่?';

  @override
  String get settingsScreen_deleteRegimenDescription => 'การดำเนินการนี้จะลบการตั้งค่าแผงยาคุมปัจจุบันและบันทึกที่เกี่ยวข้องทั้งหมด โดยไม่สามารถกู้คืนได้';

  @override
  String get settingsScreen_allLogsHaveBeenCleared => 'ลบบันทึกทั้งหมดเรียบร้อยแล้ว';

  @override
  String get settingsScreen_clearAllLogs_question => 'ลบบันทึกทั้งหมด?';

  @override
  String get settingsScreen_deleteAllLogsDescription => 'การดำเนินการนี้จะลบบันทึกรอบเดือนทั้งหมดอย่างถาวร โดยจะไม่กระทบการตั้งค่าแอป';

  @override
  String get settingsScreen_appearance => 'การแสดงผล';

  @override
  String get settingsScreen_historyViewStyle => 'รูปแบบการแสดงประวัติ';

  @override
  String get settingsScreen_appTheme => 'ธีมแอป';

  @override
  String get settingsScreen_themeLight => 'โหมดสว่าง';

  @override
  String get settingsScreen_themeDark => 'โหมดมืด';

  @override
  String get settingsScreen_themeSystem => 'ตามระบบ';

  @override
  String get settingsScreen_dynamicTheme => 'ธีมอัตโนมัติ';

  @override
  String get settingsScreen_useWallpaperColors => 'ใช้สีจากวอลเปเปอร์';

  @override
  String get settingsScreen_themeColor => 'สีธีม';

  @override
  String get settingsScreen_pickAColor => 'เลือกสี';

  @override
  String get settingsScreen_view => 'มุมมอง';

  @override
  String get settingsScreen_birthControl => 'การคุมกำเนิด';

  @override
  String get settingsScreen_enablePillTracking => 'เปิดติดตามการกินยาคุม';

  @override
  String get settingsScreen_pillDescription => 'บันทึกการกินยาคุมรายวัน พร้อมรับการแจ้งเตือน';

  @override
  String get settingsScreen_setUpPillRegimen => 'ตั้งค่ารอบการกินยาคุม';

  @override
  String get settingsScreen_trackYourDailyPillIntake => 'ติดตามการกินยาคุมรายวัน';

  @override
  String get settingsScreen_dailyPillReminder => 'แจ้งเตือนกินยาคุมรายวัน';

  @override
  String get settingsScreen_reminderTime => 'เวลาแจ้งเตือน';

  @override
  String get settingsScreen_cycleNotificationsAndPredictions => 'Cycle Notifications & Predictions';

  @override
  String get settingsScreen_enablePhasePredictions => 'Enable Phase Predictions';

  @override
  String get settingsScreen_displayFertileChance => 'Display Fertile Chance';

  @override
  String get settingsScreen_displayFertileWindowOnCalendar => 'Display Fertile Window on Calendar';

  @override
  String get settingsScreen_notificationTime => 'เวลาแจ้งเตือน';

  @override
  String get settingsScreen_remindMeBefore => 'แจ้งเตือนล่วงหน้า';

  @override
  String get settingsScreen_remindMeAfter => 'แจ้งเตือนหลังจาก';

  @override
  String get settingsScreen_upcomingPeriodReminder => 'แจ้งเตือนประจำเดือนใกล้มา';

  @override
  String get settingsScreen_overduePeriodReminder => 'แจ้งเตือนเมื่อประจำเดือนมาช้า';

  @override
  String get settingsScreen_fertileWindowReminder => 'Fertile Window Reminder';

  @override
  String get settingsScreen_ovulationDayReminder => 'Ovulation Day Reminder';

  @override
  String get settingsScreen_enableReversibleContraceptiveTracking => 'เปิดติดตามการคุมกำเนิดแบบถอดออกได้';

  @override
  String get settingsScreen_reversibleContraceptiveDescription => 'บันทึกการใช้การคุมกำเนิดแบบถอดออกได้';

  @override
  String get settingsScreen_reversibleContraceptiveType => 'ประเภทการคุมกำเนิด';

  @override
  String get settingsScreen_setDuration => 'กำหนดระยะเวลา';

  @override
  String get settingsScreen_reversibleContraceptiveDuration => 'ระยะเวลาเปลี่ยนการคุมกำเนิด';

  @override
  String get settingsScreen_enableReversibleContraceptiveReminder => 'เปิดแจ้งเตือนการคุมกำเนิด';

  @override
  String get settingsScreen_currentDuration => 'ระยะเวลาปัจจุบัน';

  @override
  String get settingsScreen_durationInDays => 'ระยะเวลา (วัน)';

  @override
  String get settingsScreen_LoggingScreen => 'การบันทึก';

  @override
  String get settingsScreen_enableLoggingReminders => 'เปิดแจ้งเตือนการบันทึก';

  @override
  String get settingsScreen_loggingReminderDescription => 'หากคุณบันทึกว่ามีประจำเดือน ระบบจะแจ้งเตือนในวันถัดไปให้บันทึกสถานะอีกครั้ง';

  @override
  String get settingsScreen_loggingReminderTime => 'เวลาแจ้งเตือนการบันทึก';

  @override
  String get settingsScreen_defaultSymptoms => 'อาการเริ่มต้น';

  @override
  String get settingsScreen_defaultSymptomsSubtitle => 'อาการเหล่านี้จะแสดงทุกครั้งเมื่อบันทึกประจำเดือน\nแตะที่อาการเพื่อลบ หรือกด \'+\' เพื่อเพิ่มอาการใหม่';

  @override
  String settingsScreen_deleteDefaultSymptomQuestion(String symptom) {
    return 'ลบ \'$symptom\' ใช่ไหม?';
  }

  @override
  String get settingsScreen_resetSymptomsList => 'รีเซ็ตรายการอาการ?';

  @override
  String get settingsScreen_resetSymptomsListDescription => 'การดำเนินการนี้จะลบอาการที่คุณเพิ่มเองทั้งหมด และคืนค่าเป็นรายการเริ่มต้น\n\nข้อมูลที่เคยบันทึกไว้จะไม่ถูกเปลี่ยนแปลง';

  @override
  String settingsScreen_deleteDefaultSymptomDescription(String symptom, num usageCount) {
    String _temp0 = intl.Intl.pluralLogic(
      usageCount,
      locale: localeName,
      other: 'มีบันทึกประจำเดือน $usageCount รายการที่มีอาการนี้\nรายการเหล่านี้จะไม่ถูกแก้ไข',
    );
    return '\'$symptom\' จะไม่สามารถเลือกได้อีกเมื่อบันทึกประจำเดือน\n\n$_temp0';
  }

  @override
  String get settingsScreen_pillRegimens => 'รูปแบบการกินยาคุม';

  @override
  String get settingsScreen_makeActive => 'ตั้งเป็นที่ใช้งานอยู่';

  @override
  String get settingsScreen_activeRegimenReminder => 'การตั้งค่าแจ้งเตือนสำหรับรูปแบบที่ใช้งานอยู่';

  @override
  String get settingsScreen_pack => 'แผงยา';

  @override
  String get settingsScreen_dataManagement => 'การจัดการข้อมูล';

  @override
  String get settingsScreen_deleteZone => 'พื้นที่ลบข้อมูล';

  @override
  String get settingsScreen_clearLogsAndPeriods => 'ลบบันทึกและประจำเดือนทั้งหมด';

  @override
  String get settingsScreen_clearLogsAndPeriodsSubtitle => 'ลบประวัติประจำเดือนและอาการทั้งหมดของคุณ';

  @override
  String get settingsScreen_clearPillLogs => 'ลบบันทึกยาคุม';

  @override
  String get settingsScreen_clearPillLogsSubtitle => 'ลบรูปแบบการกินยาและประวัติการกินยาคุมของคุณ';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogs => 'ลบบันทึกการคุมกำเนิดแบบถอดออกได้';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogsSubtitle => 'ลบประวัติการคุมกำเนิดแบบถอดออกได้ของคุณ';

  @override
  String get settingsScreen_clearSanitaryProductLogs => 'ล้างประวัติการใช้ผลิตภัณฑ์สุขอนามัย';

  @override
  String get settingsScreen_clearSanitaryProductLogsSubtitle => 'ลบประวัติการใช้ผลิตภัณฑ์สุขอนามัยของคุณ';

  @override
  String get settingsScreen_clearSexualActivityLogs => 'ล้างประวัติกิจกรรมทางเพศ';

  @override
  String get settingsScreen_clearSexualActivityLogsSubtitle => 'ลบประวัติกิจกรรมทางเพศของคุณ';

  @override
  String get settingsScreen_logsAndPeriods => 'บันทึกและรอบเดือน';

  @override
  String get settingsScreen_pillLogs => 'บันทึกการทานยาคุม';

  @override
  String get settingsScreen_reversibleContraceptivesLogs => 'บันทึกการคุมกำเนิดแบบชั่วคราว';

  @override
  String get settingsScreen_sanitaryProductLogs => 'บันทึกการใช้ผลิตภัณฑ์สุขอนามัย';

  @override
  String get settingsScreen_sexualActivityLogs => 'บันทึกกิจกรรมทางเพศ';

  @override
  String get settingsScreen_importSupportNote => 'ขณะนี้รองรับเฉพาะไฟล์ที่ส่งออกจาก Menstrudel เท่านั้น';

  @override
  String get settingsScreen_exportSuccessful => 'ส่งออกข้อมูลเรียบร้อยแล้ว';

  @override
  String get settingsScreen_exportFailed => 'ส่งออกข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';

  @override
  String get settingsScreen_exportDataTitle => 'ส่งออกข้อมูล';

  @override
  String get settingsScreen_importDataTitle => 'นำเข้าข้อมูล';

  @override
  String get settingsScreen_importDataSubtitle => 'ข้อมูลเดิมจะถูกเขียนทับ';

  @override
  String get settingsScreen_importSuccessful => 'นำเข้าข้อมูลเรียบร้อยแล้ว!';

  @override
  String get settingsScreen_importFailed => 'นำเข้าข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';

  @override
  String get settingsScreen_importErrorGeneral => 'นำเข้าข้อมูลไม่สำเร็จ โปรดตรวจสอบว่าไฟล์ถูกบันทึกไว้ในเครื่องแล้ว';

  @override
  String get settingsScreen_security => 'ความปลอดภัย';

  @override
  String get securityScreen_enableBiometricLock => 'เปิดใช้งานการล็อกด้วยชีวมิติ';

  @override
  String get securityScreen_enableBiometricLockSubtitle => 'ต้องใช้ลายนิ้วมือหรือ Face ID เพื่อเข้าแอป';

  @override
  String get securityScreen_noBiometricsAvailable => 'ไม่พบรหัสผ่าน ลายนิ้วมือ หรือ Face ID กรุณาตั้งค่าในอุปกรณ์ของคุณก่อน';

  @override
  String get settingsScreen_userProfile => 'คุณ';

  @override
  String get settingsScreen_preferences => 'การตั้งค่า';

  @override
  String get preferencesScreen_language => 'ภาษา';

  @override
  String get preferencesScreen_enableSanitaryProductsScreen => 'เปิดหน้าผลิตภัณฑ์สุขอนามัย';

  @override
  String get preferencesScreen_enableSanitaryProductsScreenSubtitle => 'แสดงแท็บผลิตภัณฑ์สุขอนามัยในแถบนำทางหลัก';

  @override
  String get preferencesScreen_enableSexActivityScreen => 'เปิดหน้ากิจกรรมทางเพศ';

  @override
  String get preferencesScreen_enableSexActivityScreenSubtitle => 'แสดงแท็บกิจกรรมทางเพศในแถบนำทางหลัก';

  @override
  String get preferencesScreen_StartingDayOfWeek => 'วันเริ่มต้นของสัปดาห์';

  @override
  String get settingsScreen_about => 'เกี่ยวกับ';

  @override
  String get aboutScreen_version => 'เวอร์ชัน';

  @override
  String get aboutScreen_legalAndSource => 'ข้อมูลทางกฎหมายและซอร์สโค้ด';

  @override
  String get aboutScreen_communityAndUpdates => 'ชุมชนและอัปเดต';

  @override
  String get aboutScreen_privacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get aboutScreen_privacyPolicySubtitle => 'อ่านนโยบายความเป็นส่วนตัว';

  @override
  String get aboutScreen_releaseNotes => 'บันทึกการอัปเดต';

  @override
  String aboutScreen_releaseNotesSubtitle(String version) {
    return 'มีอะไรใหม่ในเวอร์ชัน $version';
  }

  @override
  String get aboutScreen_github => 'GitHub';

  @override
  String get aboutScreen_githubSubtitle => 'ซอร์สโค้ดและการติดตามปัญหา';

  @override
  String get aboutScreen_discord => 'Discord';

  @override
  String get aboutScreen_discordSubtitle => 'การสนับสนุนและชุมชน';

  @override
  String get aboutScreen_share => 'แชร์';

  @override
  String get aboutScreen_shareText => 'ลองใช้ Menstrudel แอปติดตามรอบเดือนแบบออฟไลน์และเป็นส่วนตัว!';

  @override
  String get aboutScreen_urlError => 'ไม่สามารถเปิดลิงก์ได้';

  @override
  String get logSummaryWidget_loggedDays => 'จำนวนวันที่บันทึกแล้ว';

  @override
  String get logSummaryWidget_trackingHistory => 'ประวัติการติดตาม';

  @override
  String get cycleLengthVarianceWidget_logAtLeastTwoPeriods => 'ต้องมีอย่างน้อย 2 รอบเดือนเพื่อแสดงความแปรปรวน';

  @override
  String get cycleLengthVarianceWidget_title => 'ความแปรปรวนของความยาวรอบเดือน';

  @override
  String get cycleLengthVarianceWidget_averageCycle => 'รอบเดือนเฉลี่ย';

  @override
  String get cycleLengthVarianceWidget_cycle => 'รอบเดือน';

  @override
  String get periodDurationWidget_logAtLeastTwoPeriods => 'บันทึกรอบเดือนอย่างน้อย 2 ครั้งเพื่อดูสถิติ';

  @override
  String get periodDurationWidget_title => 'ความแปรปรวนของระยะเวลารอบเดือน';

  @override
  String get periodDurationWidget_averagePeriod => 'รอบเดือนเฉลี่ย';

  @override
  String get periodDurationWidget_period => 'รอบเดือน';

  @override
  String get flowIntensityWidget_flowIntensityBreakdown => 'สรุประดับปริมาณประจำเดือน';

  @override
  String get flowIntensityWidget_noFlowDataLoggedYet => 'ไม่มีข้อมูลปริมาณประจำเดือน';

  @override
  String get painLevelWidget_noPainDataLoggedYet => 'ไม่มีข้อมูลอาการปวด';

  @override
  String get painLevelWidget_painLevelBreakdown => 'สรุประดับความปวด';

  @override
  String get monthlyFlowChartWidget_noDataToDisplay => 'ไม่มีข้อมูลที่จะแสดง';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatterns => 'รูปแบบปริมาณประจำเดือนในแต่ละรอบ';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatternsDescription => 'แต่ละเส้นแทนหนึ่งรอบเดือนที่สมบูรณ์';

  @override
  String get symptomFrequencyWidget_noSymptomsLoggedYet => 'ยังไม่มีการบันทึกอาการ';

  @override
  String get symptomFrequencyWidget_mostCommonSymptoms => 'อาการที่พบบ่อยที่สุด';

  @override
  String get journalViewWidget_logYourFirstPeriod => 'บันทึกรอบเดือนครั้งแรกของคุณ';

  @override
  String get listViewWidget_noPeriodsLogged => 'ยังไม่มีการบันทึกรอบเดือน\nแตะปุ่ม + เพื่อเพิ่ม';

  @override
  String get listViewWidget_confirmDelete => 'ยืนยันการลบ';

  @override
  String get listViewWidget_confirmDeleteDescription => 'คุณแน่ใจหรือไม่ว่าต้องการลบรายการนี้?';

  @override
  String get emptyPillStateWidget_noPillRegimenFound => 'ไม่พบการตั้งค่าการใช้ยาคุม';

  @override
  String get emptyPillStateWidget_noPillRegimenFoundDescription => 'ตั้งค่าแผงยาในเมนูการตั้งค่าเพื่อเริ่มติดตาม';

  @override
  String pillStatus_pillsOfTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'จาก $count เม็ด',
      one: 'จาก 1 เม็ด',
    );
    return '$_temp0';
  }

  @override
  String get pillStatus_undo => 'เลิกทำ';

  @override
  String get pillStatus_skip => 'ข้าม';

  @override
  String get pillStatus_markAsTaken => 'ทำเครื่องหมายว่าได้รับประทานแล้ว';

  @override
  String pillStatus_packStartInFuture(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'แผงยาถัดไปของคุณจะเริ่มในวันที่ $dateString';
  }

  @override
  String get regimenSetupWidget_setUpPillRegimen => 'ตั้งค่าการใช้ยาคุม';

  @override
  String get regimenSetupWidget_packName => 'ชื่อแผงยา';

  @override
  String get regimenSetupWidget_pleaseEnterAName => 'กรุณากรอกชื่อ';

  @override
  String get regimenSetupWidget_activePills => 'เม็ดยาฮอร์โมน';

  @override
  String get regimenSetupWidget_enterANumber => 'กรอกตัวเลข';

  @override
  String get regimenSetupWidget_placeboPills => 'เม็ดแป้ง';

  @override
  String get regimenSetupWidget_firstDayOfThisPack => 'วันแรกของแผงนี้';

  @override
  String get symptomEntrySheet_logYourDay => 'บันทึกวันนี้';

  @override
  String get symptomEntrySheet_symptomsOptional => 'อาการ (ไม่บังคับ)';

  @override
  String get periodDetailsSheet_symptoms => 'อาการ';

  @override
  String get periodDetailsSheet_flow => 'ปริมาณประจำเดือน';

  @override
  String get reversibleContraceptiveEntrySheet_logReversibleContraceptiveDetails => 'บันทึกรายละเอียดการคุมกำเนิด';

  @override
  String get sanitaryEntrySheet_logSanitaryProduct => 'บันทึกการใช้ผลิตภัณฑ์สุขอนามัย';

  @override
  String get sanitaryEntrySheet_setReminderDuration => 'ตั้งค่าระยะเวลาแจ้งเตือน';

  @override
  String sanitaryEntrySheet_maxDuration(int hours) {
    return 'ระยะเวลาสูงสุด: $hours ชั่วโมง';
  }

  @override
  String get sanitaryEntrySheet_futureLogTimeError => 'เวลาที่บันทึกต้องไม่เป็นเวลาในอนาคต';

  @override
  String get sanitaryEntrySheet_pastReminderTimeError => 'เวลาสิ้นสุดการแจ้งเตือนต้องไม่เป็นเวลาในอดีต';

  @override
  String periodPredictionCircle_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'วัน',
      one: 'วัน',
    );
    return '$_temp0';
  }

  @override
  String get customSymptomDialog_newSymptom => 'เพิ่มอาการใหม่';

  @override
  String get customSymptomDialog_enterCustomSymptom => 'กรอกอาการที่ต้องการเพิ่ม';

  @override
  String get customSymptomDialog_temporarySymptom => 'อาการชั่วคราว';
}
