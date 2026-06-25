// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Menstrudel';

  @override
  String get nextDue => 'Nächster Fälligkeitstermin';

  @override
  String get ongoing => 'Fortlaufend';

  @override
  String get overdue => 'Überfällig';

  @override
  String get total => 'Gesamt';

  @override
  String get shortest => 'Kürzeste';

  @override
  String get longest => 'Längste';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get date => 'Datum';

  @override
  String get time => 'Zeit';

  @override
  String get start => 'Beginn';

  @override
  String get end => 'Ende';

  @override
  String get next => 'Vorwärts';

  @override
  String get back => 'Zurück';

  @override
  String get today => 'Heute';

  @override
  String get day => 'Tag';

  @override
  String get days => 'Tage';

  @override
  String get hours => 'Stunden';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '$count Tag',
    );
    return '$_temp0';
  }

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Monate',
      one: '$count Monat',
    );
    return '$_temp0';
  }

  @override
  String yearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Jahre',
      one: '$count Jahr',
    );
    return '$_temp0';
  }

  @override
  String countdown_daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tage übrig',
      one: '$days Tag übrig',
    );
    return '$_temp0';
  }

  @override
  String countUp_day(int day) {
    return 'Tag $day';
  }

  @override
  String get logs => 'Protokolle';

  @override
  String get insights => 'Einblicke';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get clear => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get import => 'Importieren';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get set => 'Festlegen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get select => 'Auswählen';

  @override
  String get close => 'Schließen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get add => 'Hinzufügen';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get removed => 'Entfernt';

  @override
  String get totalLogs => 'Alle Protokolle';

  @override
  String get note => 'Hinweis';

  @override
  String get systemDefault => 'System Standard';

  @override
  String get flow => 'Ausfluss';

  @override
  String get type => 'Typ';

  @override
  String get other => 'Sonstiges';

  @override
  String get navBar_logs => 'Protokolle';

  @override
  String get navBar_sanitary => 'Hygiene';

  @override
  String get navBar_sexActivity => 'Sexaktivität';

  @override
  String get navBar_pill => 'Pille';

  @override
  String get navBar_reversibleContraceptive => 'Verhütungsmethoden';

  @override
  String get navBar_settings => 'Einstellungen';

  @override
  String get flowIntensity_none => 'Keine';

  @override
  String get flowIntensity_spotting => 'Schmierblutung';

  @override
  String get flowIntensity_light => 'Leicht';

  @override
  String get flowIntensity_moderate => 'Mäßig';

  @override
  String get flowIntensity_heavy => 'Stark';

  @override
  String get builtInSymptom_acne => 'Akne';

  @override
  String get builtInSymptom_backPain => 'Rückenschmerzen';

  @override
  String get builtInSymptom_bloating => 'Blähungen';

  @override
  String get builtInSymptom_cramps => 'Krämpfe';

  @override
  String get builtInSymptom_fatigue => 'Müdigkeit';

  @override
  String get builtInSymptom_headache => 'Kopfschmerzen';

  @override
  String get builtInSymptom_moodSwings => 'Stimmungsschwankungen';

  @override
  String get builtInSymptom_nausea => 'Übelkeit';

  @override
  String get builtInSymptom_tenderBreasts => 'Tender breasts';

  @override
  String get builtInSymptom_insomnia => 'Insomnia';

  @override
  String get builtInSymptom_depressed => 'Depressed';

  @override
  String get painLevel_title => 'Schmerzgrad';

  @override
  String get painLevel_none => 'Keine';

  @override
  String get painLevel_mild => 'Mild';

  @override
  String get painLevel_moderate => 'Mäßig';

  @override
  String get painLevel_severe => 'Schwerwiegend';

  @override
  String get pain_unbearable => 'Unerträglich';

  @override
  String get reversibleContraceptive_hormonalIud => 'Hormonspirale';

  @override
  String get reversibleContraceptive_copperIud => 'Kupferspirale';

  @override
  String get reversibleContraceptive_implant => 'Implantat';

  @override
  String get reversibleContraceptive_injection => 'Hormonspritze';

  @override
  String get reversibleContraceptive_ring => 'Hormonring';

  @override
  String get reversibleContraceptive_patch => 'Hormonpflaster';

  @override
  String get sanitaryProduct_tampon => 'Tampon';

  @override
  String get sanitaryProduct_pad => 'Binden';

  @override
  String get sanitaryProduct_menstrualCup => 'Menstruationstasse';

  @override
  String get sanitaryProduct_periodUnderwear => 'Periodenunterwäsche';

  @override
  String get sanitaryProducts_mostUsed => 'Meist Verwendet';

  @override
  String get sanitaryProducts_usageTrend => 'Verwendungstrend';

  @override
  String get sexProtection_none => 'Nichts';

  @override
  String get sexProtection_barrier => 'Schutz';

  @override
  String get sexProtection_hormonal => 'Hormonell';

  @override
  String get sexProtection_nonHormonal => 'Nicht Hormonell';

  @override
  String get sexProtection_natural => 'Natürlich';

  @override
  String get sexProtection_permanent => 'Dauerhaft';

  @override
  String get sexType_vaginal => 'Vaginal';

  @override
  String get sexType_anal => 'Anal';

  @override
  String get sexType_oral => 'Oral';

  @override
  String get sexType_manual => 'Per Hand';

  @override
  String get sexParticipation_solo => 'Alleine';

  @override
  String get sexParticipation_partner => 'Partner';

  @override
  String get sexParticipation_group => 'Gruppe';

  @override
  String get userGoal_general => 'Allg. Gesundheit';

  @override
  String get userGoal_sexual => 'Sexuelle Gesundheit';

  @override
  String get userGoal_conceive => 'Schwanger werden';

  @override
  String get userGoal_avoid => 'Schwangerschaft vermeiden';

  @override
  String get dayOfWeek_monday => 'Montag';

  @override
  String get dayOfWeek_tuesday => 'Dienstag';

  @override
  String get dayOfWeek_wednesday => 'Mittwoch';

  @override
  String get dayOfWeek_thursday => 'Donnerstag';

  @override
  String get dayOfWeek_friday => 'Freitag';

  @override
  String get dayOfWeek_saturday => 'Samstag';

  @override
  String get dayOfWeek_sunday => 'Sonntag';

  @override
  String get cyclePhase_menstruation => 'Menstruation';

  @override
  String get cyclePhase_follicular => 'Follikelphase';

  @override
  String get cyclePhase_fertileWindow => 'Fruchtbare Tage';

  @override
  String get cyclePhase_ovulation => 'Ovulation';

  @override
  String get cyclePhase_luteal => 'Lutealphase';

  @override
  String get cyclePhase_late => 'Verspätete Periode';

  @override
  String get cyclePhase_unknown => 'Unbekannt';

  @override
  String get cyclePhase_menstruationDescription => 'Deine Periode ist aktiv und die Gebärmutterschleimhaut wird abgestoßen.';

  @override
  String get cyclePhase_fertileWindowDescription => 'Du befindest dich in deinen fruchtbaren Tagen.';

  @override
  String get cyclePhase_follicularDescription => 'Der Östrogenspiegel steigt, um die Eizelle vorzubereiten; Dein Energieniveau steigt möglicherweise an.';

  @override
  String get cyclePhase_ovulationDescription => 'Ein Eisprung ist erfolgt. Dies ist deine fruchtbarste Zeit.';

  @override
  String get cyclePhase_lutealDescription => 'Progesteron überwiegt aktuell. Achte auf PMS-Symptome, wenn deine nächste Periode näher rückt.';

  @override
  String get cyclePhase_lateDescription => 'Deine Periode ist verspätet.';

  @override
  String get cyclePhase_unknownDescription => 'Wir benötigen mehr Daten, um deine Zyklusphasen vorherzusagen.';

  @override
  String get fertilityChance_high => 'Hoch';

  @override
  String get fertilityChance_medium => 'Mittel';

  @override
  String get fertilityChance_low => 'Gering';

  @override
  String get error_valueMustbePositive => 'Der Wert muss positiv sein';

  @override
  String get error_valueCannotBeNull => 'Der Wert darf nicht null sein';

  @override
  String get notification_periodTitle => 'Periode nähert sich';

  @override
  String notification_periodBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deine nächste Periode beginnt voraussichtlich in $count Tagen.',
      one: 'Deine nächste Periode beginnt voraussichtlich in 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String get notification_periodOverdueTitle => 'Fälligkeitstag überschritten';

  @override
  String notification_periodOverdueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deine nächste Periode ist seit $count Tagen überfällig.',
      one: 'Deine nächste Periode ist seit einem Tag überfällig.',
    );
    return '$_temp0';
  }

  @override
  String get notification_pillTitle => 'Pillenerinnerung';

  @override
  String get notification_pillBody => 'Vergiss nicht, Deine Pille für heute einzunehmen.';

  @override
  String get notification_reversibleContraceptiveTitle => 'Reversible Verhütungsmittelerinnerung';

  @override
  String notification_reversibleContraceptiveBody(String type, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Tagen',
      one: 'Tag',
    );
    return '$type muss ausgetauscht werden in $days $_temp0.';
  }

  @override
  String get notification_loggingReminderTitle => 'Protokollierungserinnerung';

  @override
  String get notification_loggingReminderBody => 'Tippe, um deinen Ausfluss für heute einzutragen.';

  @override
  String get notification_SanitaryProductReminderTitle => 'Erinnerung an Hygieneartikel';

  @override
  String get notification_SanitaryProductReminderBody => 'Denke daran, Dein Produkt zu wechseln.';

  @override
  String get notification_fertileWindowTitle => 'Fruchtbare Tage';

  @override
  String notification_fertileWindowBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deine fruchtbaren Tage starten in $count Tagen.',
      one: 'Deine fruchtbaren Tage starten in 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String get notification_ovulationDayReminderTitle => 'Eisprung';

  @override
  String notification_ovulationDayReminderBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dein nächster Eisprung startet in $count Tagen.',
      one: 'Dein nächster Eisprung startet in 1 Tag.',
    );
    return '$_temp0';
  }

  @override
  String get onboardingScreen_welcomeToMenstrudel => 'Willkommen bei Menstrudel';

  @override
  String get onboardingScreen_welcomeToMenstrudelDescription => 'Dein offline, privater Zyklustracker.';

  @override
  String get onBoardingScreen_byUsingMenstrudelYouAgreeTo => 'Durch die Verwendung von Menstrudel stimmst du folgendem zu: ';

  @override
  String get onBoardingScreen_privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get onboardingScreen_profileTitle => 'Über dich';

  @override
  String get onboardingScreen_profileName => 'Wie sollen wir dich nennen?';

  @override
  String get onboardingScreen_profileDate => 'Geburtstag (Optional)';

  @override
  String get onboardingScreen_profileDatePlaceholder => 'Anklicken um Geburtstag festzulegen';

  @override
  String get onboardingScreen_goalTitle => 'Was ist dein Ziel?';

  @override
  String get onboardingScreen_goalDescription => 'Dadurch können die angezeigten Informationen besser auf dich zugeschnitten werden.';

  @override
  String onboardingScreen_contraceptionHint(String sectionName) {
    return 'Hinweis: Du kannst die Verfolgung von der Pille oder reversiblen Verhütungsmitteln später in den App-Einstellungen unter \"$sectionName\" aktivieren, wenn du das möchtest.';
  }

  @override
  String get onboardingScreen_getStarted => 'Los geht\'s';

  @override
  String get fabToolTip_logs => 'Tag protokollieren';

  @override
  String get fabToolTip_sanitary => 'Protokolliere Hygieneartikel';

  @override
  String get fabToolTip_sexActivity => 'Protokolliere sexuelle Aktivitäten';

  @override
  String get fabToolTip_reversibleContraceptive => 'Protokolliere Reversible Verhütungsmittel';

  @override
  String get mainScreen_logsPageTitle => 'Protokolle';

  @override
  String get mainSceen_sexActivityPageTitle => 'Sexuelle Aktivität';

  @override
  String get mainScreen_sanitaryPageTitle => 'Hygieneartikel';

  @override
  String get mainScreen_pillsPageTitle => 'Pille';

  @override
  String get mainScreen_reversibleContraceptivesPageTitle => 'Reversible Verhütungsmittel';

  @override
  String get mainScreen_settingsPageTitle => 'Einstellungen';

  @override
  String get insightsScreen_errorPrefix => 'Fehler:';

  @override
  String get insightsScreen_noDataAvailable => 'Keine Daten verfügbar.';

  @override
  String get logsScreen_calculatingPrediction => 'Berechnung der Vorhersage...';

  @override
  String get logScreen_logAtLeastTwoPeriods => 'Protokolliere mindestens zwei Perioden, um den nächsten Zyklus zu schätzen.';

  @override
  String get logScreen_nextPeriodEstimate => 'Nächste Periode voraussichtlich';

  @override
  String get logScreen_periodDueToday => 'Heute fällige Periode';

  @override
  String logScreen_periodOverdueBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die Periode ist $count Tage überfällig',
      one: 'Die Periode ist 1 Tag überfällig',
    );
    return '$_temp0';
  }

  @override
  String get pillScreen_pillForTodayMarkedAsTaken => 'Pille für heute als eingenommen markiert.';

  @override
  String get pillScreen_pillForTodayMarkedAsSkipped => 'Pille für heute als ausgelassen markiert.';

  @override
  String get reversibleContraceptiveScreen_noRecordsFound => 'Keine Protokolle gefunden.';

  @override
  String reversibleContraceptiveScreen_history(int history) {
    return 'Vergangene ($history)';
  }

  @override
  String reversibleContraceptiveScreen_activeReversibleContraceptives(int activeCount) {
    return 'Aktive ($activeCount)';
  }

  @override
  String get reversibleContraceptiveScreen_activeReversibleContraceptivesDescription => 'Derzeit überwachte Einträge zu reversiblen Verhütungsmitteln.';

  @override
  String get reversibleContraceptiveScreen_noActiveRecords => 'Derzeit ist kein reversibles Verhütungsmittel in Gebrauch. Bitte erstelle einen neuen Eintrag.';

  @override
  String get reversibleContraceptiveScreen_noHistoryRecords => 'Es wurden keine früheren oder überfälligen reversiblen Verhütungsmittelaufzeichnungen gefunden.';

  @override
  String get sanitaryProductsScreen_noSanitaryProductRecordsFound => 'Keine Einträge zu Hygieneartikeln gefunden.';

  @override
  String sanitaryProductsScreen_history(int history) {
    return 'Verlauf ($history)';
  }

  @override
  String get sanitaryProductsScreen_noHistoryRecords => 'Es wurden keine früheren Aufzeichnungen zu Hygieneartikeln gefunden.';

  @override
  String sanitaryProductsScreen_activeProduct(String activeType) {
    return 'Aktiv $activeType';
  }

  @override
  String sanitaryProductsScreen_changeDueAt(String time) {
    return 'Änderung fällig um $time';
  }

  @override
  String get sexActivityScreen_noSexActivityRecordsFound => 'Keine Aufzeichnungen über sexuelle Aktivitäten gefunden.';

  @override
  String sexActivityScreen_history(int history) {
    return 'Historie ($history)';
  }

  @override
  String get sexActivityScreen_primaryMethod => 'Primäre Verhütungsmethode';

  @override
  String get sexActivityScreen_mostFrequent => 'Am Häufigsten';

  @override
  String get sexActivityScreen_protected => 'Geschützt';

  @override
  String get sexActivityScreen_activityTrend => 'Aktivitätstrend';

  @override
  String get sexActivityScreen_activityDistribution => 'Aktivitätsverteilung';

  @override
  String get sexActivityScreen_protectionDistribution => 'Verteilung von Verhütungsmitteln';

  @override
  String get settingsScreen_profile => 'Profil';

  @override
  String get settingsScreen_name => 'Name';

  @override
  String get settingsScreen_birthDate => 'Geburtstag';

  @override
  String get settingsScreen_notSet => 'Nicht hinterlegt';

  @override
  String get settingsScreen_appGoal => 'App Ziel';

  @override
  String get settingsScreen_profileUpdated => 'Profil erfolgreich upgedatet';

  @override
  String get settingsScreen_selectHistoryView => 'Vergangenheitsansicht auswählen';

  @override
  String get settingsScreen_deleteRegimen_question => 'Kuren löschen?';

  @override
  String get settingsScreen_deleteRegimenDescription => 'Dies wird deine aktuellen Pillenverpackungseinstellungen und alle zugehörigen Pillenaufzeichnungen löschen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get settingsScreen_allLogsHaveBeenCleared => 'Alle Protokolle wurden gelöscht.';

  @override
  String get settingsScreen_clearAllLogs_question => 'Alle Protokolle löschen?';

  @override
  String get settingsScreen_deleteAllLogsDescription => 'Dadurch werden alle Deine Periodenprotokolle dauerhaft gelöscht. Deine App-Einstellungen bleiben davon unberührt.';

  @override
  String get settingsScreen_appearance => 'Aussehen';

  @override
  String get settingsScreen_historyViewStyle => 'Art der Vergangenheitsansicht';

  @override
  String get settingsScreen_appTheme => 'App-Thema';

  @override
  String get settingsScreen_themeLight => 'Hell';

  @override
  String get settingsScreen_themeDark => 'Dunkel';

  @override
  String get settingsScreen_themeSystem => 'System';

  @override
  String get settingsScreen_dynamicTheme => 'Dynamisches Thema';

  @override
  String get settingsScreen_useWallpaperColors => 'Nutze Hintergrundfarben';

  @override
  String get settingsScreen_themeColor => 'Themenfarbe';

  @override
  String get settingsScreen_pickAColor => 'Eine Farbe auswählen';

  @override
  String get settingsScreen_view => 'Ansicht';

  @override
  String get settingsScreen_birthControl => 'Empfängnisverhütung';

  @override
  String get settingsScreen_enablePillTracking => 'Pillentracking einschalten';

  @override
  String get settingsScreen_pillDescription => 'Erfasse Deine tägliche Einnahme von Tabletten und erhalte Erinnerungen.';

  @override
  String get settingsScreen_setUpPillRegimen => 'Pilleneinnahme einrichten';

  @override
  String get settingsScreen_trackYourDailyPillIntake => 'Tägliche Pilleneinnahme tracken';

  @override
  String get settingsScreen_dailyPillReminder => 'Tägliche Pillenerinnerung';

  @override
  String get settingsScreen_reminderTime => 'Erinnerungszeit';

  @override
  String get settingsScreen_cycleNotificationsAndPredictions => 'Zyklusbenachrichtigungen & Voraussagen';

  @override
  String get settingsScreen_enablePhasePredictions => 'Zyklusvorhersagen aktivieren';

  @override
  String get settingsScreen_displayFertileChance => 'Schwangerschaftswahrscheinlichkeit Anzeigen';

  @override
  String get settingsScreen_displayFertileWindowOnCalendar => 'Fruchtbare Tage im Kalender anzeigen';

  @override
  String get settingsScreen_notificationTime => 'Benachrichtigungszeit';

  @override
  String get settingsScreen_remindMeBefore => 'Erinnere mich vorher';

  @override
  String get settingsScreen_remindMeAfter => 'Erinnere mich in';

  @override
  String get settingsScreen_upcomingPeriodReminder => 'Erinnerung an die bevorstehende Periode';

  @override
  String get settingsScreen_overduePeriodReminder => 'Erinnerung bei überfälliger Periode';

  @override
  String get settingsScreen_fertileWindowReminder => 'Erinnerung für fruchtbare Tage';

  @override
  String get settingsScreen_ovulationDayReminder => 'Erinnerung für den Eisprung';

  @override
  String get settingsScreen_enableReversibleContraceptiveTracking => 'Reversible Verhütungsmethode aktivieren';

  @override
  String get settingsScreen_reversibleContraceptiveDescription => 'Reversible Verhütungsmethode verfolgen.';

  @override
  String get settingsScreen_reversibleContraceptiveType => 'Verhütungsmethode';

  @override
  String get settingsScreen_setDuration => 'Dauer festlegen';

  @override
  String get settingsScreen_reversibleContraceptiveDuration => 'Haltbarkeit des Verhütungsmittels';

  @override
  String get settingsScreen_enableReversibleContraceptiveReminder => 'Verhütungsmittelerinnerung aktivieren';

  @override
  String get settingsScreen_currentDuration => 'Aktuelle Dauer';

  @override
  String get settingsScreen_durationInDays => 'Dauer (Tage)';

  @override
  String get settingsScreen_LoggingScreen => 'Protokollieren';

  @override
  String get settingsScreen_enableLoggingReminders => 'Protokollierung-Erinnerungen aktivieren';

  @override
  String get settingsScreen_loggingReminderDescription => 'Wenn du einen Tag mit Ausfluss protokollierst, erhältst du am nächsten Tag eine Benachrichtigung, um deinen Status zu verfolgen/zu protokollieren.';

  @override
  String get settingsScreen_loggingReminderTime => 'Uhrzeit der Erinnerung';

  @override
  String get settingsScreen_defaultSymptoms => 'Standardsymptome';

  @override
  String get settingsScreen_defaultSymptomsSubtitle => 'Diese sind immer sichtbar, wenn eine neue Periode eingetragen wird. Wähle ein bestehendes Symptom, um es zu löschen oder \'+\' um ein neues hinzuzufügen.';

  @override
  String settingsScreen_deleteDefaultSymptomQuestion(String symptom) {
    return '\'$symptom\' löschen?';
  }

  @override
  String get settingsScreen_resetSymptomsList => 'Symptomliste zurücksetzen?';

  @override
  String get settingsScreen_resetSymptomsListDescription => 'Dadurch werden alle benutzerdefinierten Symptome entfernt und die ursprüngliche integrierte Liste wiederhergestellt.\n\nDeine vorhandenen Protokolleinträge werden dadurch nicht geändert.';

  @override
  String settingsScreen_deleteDefaultSymptomDescription(String symptom, num usageCount) {
    String _temp0 = intl.Intl.pluralLogic(
      usageCount,
      locale: localeName,
      other: 'Es gibt $usageCount Periodenprotokolle mit diesem Symptom!\nDiese Protokolle werden nicht geändert.',
      one: 'Es gibt bereits 1 Periodenprotokoll mit diesem Symptom!\nDieses Protokoll wird nicht geänder.',
      zero: 'Derzeit gibt es keine Periodenprotokolle mit diesem Symptom!',
    );
    return '\'$symptom\' ist beim Protokollieren eines Zeitraums nicht mehr verfügbar.\n\n$_temp0';
  }

  @override
  String get settingsScreen_pillRegimens => 'Pilleneinstellung';

  @override
  String get settingsScreen_makeActive => 'Als aktiv festlegen';

  @override
  String get settingsScreen_activeRegimenReminder => 'Einstellungen für aktive Kurerinnerungen';

  @override
  String get settingsScreen_pack => 'Packung';

  @override
  String get settingsScreen_dataManagement => 'Datenverwaltung';

  @override
  String get settingsScreen_deleteZone => 'Datensätze löschen';

  @override
  String get settingsScreen_clearLogsAndPeriods => 'Löschen der Protokolle & Perioden';

  @override
  String get settingsScreen_clearLogsAndPeriodsSubtitle => 'Löscht Ihre gesamte Perioden- und Symptomhistorie.';

  @override
  String get settingsScreen_clearPillLogs => 'Löschen des Pillenprotokolls';

  @override
  String get settingsScreen_clearPillLogsSubtitle => 'Löschung deiner Pilleneinnahme und Einnahmehistorie.';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogs => 'Lösche die reversible Verhütungsmittelhistorie';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogsSubtitle => 'Entfernt die reversible Verhütungshistorie vollständig. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get settingsScreen_clearSanitaryProductLogs => 'Lösche die Hygieneartikelhistorie';

  @override
  String get settingsScreen_clearSanitaryProductLogsSubtitle => 'Entfernt die Hygieneartikelhistorie vollständig. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get settingsScreen_clearSexualActivityLogs => 'Lösche die sexuellen Aktivitätshistorie';

  @override
  String get settingsScreen_clearSexualActivityLogsSubtitle => 'Entfernt die sexuellen Aktivitätshistorie vollständig. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get settingsScreen_logsAndPeriods => 'Protokolle & Perioden';

  @override
  String get settingsScreen_pillLogs => 'Pillenprotokoll';

  @override
  String get settingsScreen_reversibleContraceptivesLogs => 'Reversible Verhütungsmittelhistorie';

  @override
  String get settingsScreen_sanitaryProductLogs => 'Hygieneartikelhistorie';

  @override
  String get settingsScreen_sexualActivityLogs => 'Sexuelle Aktivitätshistorie';

  @override
  String get settingsScreen_importSupportNote => 'Der Datenimport wird derzeit nur für Dateien unterstützt, die aus Menstrudel exportiert wurden.';

  @override
  String get settingsScreen_exportSuccessful => 'Daten erfolgreich exportiert.';

  @override
  String get settingsScreen_exportFailed => 'Export fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get settingsScreen_exportDataTitle => 'Daten exportieren';

  @override
  String get settingsScreen_importDataTitle => 'Daten importieren';

  @override
  String get settingsScreen_importDataSubtitle => 'Überschreibt vorhandene Daten.';

  @override
  String get settingsScreen_importSuccessful => 'Daten erfolgreich importiert!';

  @override
  String get settingsScreen_importFailed => 'Datenimport fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get settingsScreen_importErrorGeneral => 'Daten konnten nicht importiert werden. Bitte stelle sicher, dass die Datei lokal gespeichert ist.';

  @override
  String get settingsScreen_security => 'Sicherheit';

  @override
  String get securityScreen_enableBiometricLock => 'Biometrische Sperre aktivieren';

  @override
  String get securityScreen_enableBiometricLockSubtitle => 'Zum Öffnen der App ist eine Fingerabdruck- oder Gesichtserkennung erforderlich.';

  @override
  String get securityScreen_noBiometricsAvailable => 'Es wurde kein Passcode, Fingerabdruck oder Face ID gefunden. Bitte lege einen in den Einstellungen des Geräts fest.';

  @override
  String get settingsScreen_userProfile => 'Du';

  @override
  String get settingsScreen_preferences => 'Einstellungen';

  @override
  String get preferencesScreen_language => 'Sprache';

  @override
  String get preferencesScreen_enableSanitaryProductsScreen => 'Bildschirm für Hygieneartikel aktivieren';

  @override
  String get preferencesScreen_enableSanitaryProductsScreenSubtitle => 'Hygieneartikel in der Hauptnavigationsleiste anzeigen.';

  @override
  String get preferencesScreen_enableSexActivityScreen => 'Sex-Aktivitätsanzeige aktivieren';

  @override
  String get preferencesScreen_enableSexActivityScreenSubtitle => 'Zeige den Tab \"Sex Aktivitäten\" in der Hauptnavigationsbar an.';

  @override
  String get preferencesScreen_StartingDayOfWeek => 'Erster Wochentag';

  @override
  String get settingsScreen_about => 'Über';

  @override
  String get aboutScreen_version => 'Version';

  @override
  String get aboutScreen_legalAndSource => 'Rechtliches & Quelle';

  @override
  String get aboutScreen_communityAndUpdates => 'Community & Updates';

  @override
  String get aboutScreen_privacyPolicy => 'Datenschutzerklärung';

  @override
  String get aboutScreen_privacyPolicySubtitle => 'Lies unsere Datenschutzerklärung';

  @override
  String get aboutScreen_releaseNotes => 'Versionshinweise';

  @override
  String aboutScreen_releaseNotesSubtitle(String version) {
    return 'Was ist neu in $version';
  }

  @override
  String get aboutScreen_github => 'GitHub';

  @override
  String get aboutScreen_githubSubtitle => 'Quellcode und Fehlerverfolgung';

  @override
  String get aboutScreen_discord => 'Discord';

  @override
  String get aboutScreen_discordSubtitle => 'Unterstützung und Community';

  @override
  String get aboutScreen_share => 'Teilen';

  @override
  String get aboutScreen_shareText => 'Probiere Menstrudel aus, eine private und offline verfügbare App zur Verfolgung deines Zyklus!';

  @override
  String get aboutScreen_urlError => 'Der Link konnte nicht geöffnet werden.';

  @override
  String get logSummaryWidget_loggedDays => 'Erfasste Tage';

  @override
  String get logSummaryWidget_trackingHistory => 'Verlauf verfolgen';

  @override
  String get cycleLengthVarianceWidget_logAtLeastTwoPeriods => 'Es sind mindestens zwei Zyklen erforderlich, um Abweichungen zu zeigen.';

  @override
  String get cycleLengthVarianceWidget_title => 'Zykluslängenabweichung';

  @override
  String get cycleLengthVarianceWidget_averageCycle => 'Durchschnittlicher Zyklus';

  @override
  String get cycleLengthVarianceWidget_cycle => 'Zyklus';

  @override
  String get periodDurationWidget_logAtLeastTwoPeriods => 'Protokolliere mindestens zwei Perioden, um Periodenstatistiken anzuzeigen.';

  @override
  String get periodDurationWidget_title => 'Periode Dauer Abweichung';

  @override
  String get periodDurationWidget_averagePeriod => 'Durchschnittliche Periode';

  @override
  String get periodDurationWidget_period => 'Periode';

  @override
  String get flowIntensityWidget_flowIntensityBreakdown => 'Aufschlüsselung der Abflussintensität';

  @override
  String get flowIntensityWidget_noFlowDataLoggedYet => 'Es wurden noch keine Schmerzdaten erfasst.';

  @override
  String get painLevelWidget_noPainDataLoggedYet => 'Es wurden noch keine Schmerzdaten erfasst.';

  @override
  String get painLevelWidget_painLevelBreakdown => 'Schmerzgrad-Aufschlüsselung';

  @override
  String get monthlyFlowChartWidget_noDataToDisplay => 'Keine Daten zum Anzeigen.';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatterns => 'Zyklusverlaufsmuster';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatternsDescription => 'Jede Linie stellt einen vollständigen Zyklus dar';

  @override
  String get symptomFrequencyWidget_noSymptomsLoggedYet => 'Noch keine Symptome erfasst.';

  @override
  String get symptomFrequencyWidget_mostCommonSymptoms => 'Häufigste Symptome';

  @override
  String get journalViewWidget_logYourFirstPeriod => 'Trage deine erste Periode ein.';

  @override
  String get listViewWidget_noPeriodsLogged => 'Es wurden noch keine Perioden protokolliert.\nDrücke auf die Schaltfläche „+“, um eine hinzuzufügen.';

  @override
  String get listViewWidget_confirmDelete => 'Löschen bestätigen';

  @override
  String get listViewWidget_confirmDeleteDescription => 'Willst du diesen Eintrag wirklich löschen?';

  @override
  String get emptyPillStateWidget_noPillRegimenFound => 'Keine Pilleneinnahme gefunden.';

  @override
  String get emptyPillStateWidget_noPillRegimenFoundDescription => 'Um mit der Nachverfolgung zu beginnen, kannst du deine Pillenpackung in den Einstellungen einrichten.';

  @override
  String pillStatus_pillsOfTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'von $count Pillen',
      one: 'von 1 Pille',
    );
    return '$_temp0';
  }

  @override
  String get pillStatus_undo => 'Rückgängig';

  @override
  String get pillStatus_skip => 'Überspringen';

  @override
  String get pillStatus_markAsTaken => 'Als genommen notieren';

  @override
  String pillStatus_packStartInFuture(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Deine nächste Pillenpackung beginnt am $dateString.';
  }

  @override
  String get regimenSetupWidget_setUpPillRegimen => 'Pilleneinnahme festlegen';

  @override
  String get regimenSetupWidget_packName => 'Verpackungsname';

  @override
  String get regimenSetupWidget_pleaseEnterAName => 'Bitte einen Namen eingeben';

  @override
  String get regimenSetupWidget_activePills => 'Aktive Pillen';

  @override
  String get regimenSetupWidget_enterANumber => 'Eine Zahl eingeben';

  @override
  String get regimenSetupWidget_placeboPills => 'Placebo-Pillen';

  @override
  String get regimenSetupWidget_firstDayOfThisPack => 'Erster Tag dieser Packung';

  @override
  String get symptomEntrySheet_logYourDay => 'Protokolliere deinen Tag';

  @override
  String get symptomEntrySheet_symptomsOptional => 'Symptome (optional)';

  @override
  String get periodDetailsSheet_symptoms => 'Symptome';

  @override
  String get periodDetailsSheet_flow => 'Ausfluss';

  @override
  String get reversibleContraceptiveEntrySheet_logReversibleContraceptiveDetails => 'Details zum Verhütungsmittel protokollieren';

  @override
  String get sanitaryEntrySheet_logSanitaryProduct => 'Log-Hygieneartikel';

  @override
  String get sanitaryEntrySheet_setReminderDuration => 'Erinnerungsdauer festlegen';

  @override
  String sanitaryEntrySheet_maxDuration(int hours) {
    return 'Maximale Dauer: $hours Stunden';
  }

  @override
  String get sanitaryEntrySheet_futureLogTimeError => 'Die Protokollzeit darf nicht in der Zukunft liegen.';

  @override
  String get sanitaryEntrySheet_pastReminderTimeError => 'Die Erinnerungsendzeit kann nicht in der Vergangenheit liegen.';

  @override
  String periodPredictionCircle_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage',
      one: 'Tag',
    );
    return '$_temp0';
  }

  @override
  String get customSymptomDialog_newSymptom => 'Neues Symptom';

  @override
  String get customSymptomDialog_enterCustomSymptom => 'Ein individuelles Symptom eingeben';

  @override
  String get customSymptomDialog_temporarySymptom => 'Vorübergehendes Symptom';
}
