// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Menstrudel';

  @override
  String get nextDue => 'Prochaine échéance';

  @override
  String get ongoing => 'En cours';

  @override
  String get overdue => 'Retard';

  @override
  String get total => 'Total';

  @override
  String get shortest => 'Le plus court';

  @override
  String get longest => 'Le plus long';

  @override
  String get unknown => 'Inconnu';

  @override
  String get date => 'Date';

  @override
  String get time => 'Heure';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get next => 'Prochain';

  @override
  String get back => 'Retour';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get day => 'Jour';

  @override
  String get days => 'Jours';

  @override
  String get hours => 'Heures';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String monthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '$count mois',
    );
    return '$_temp0';
  }

  @override
  String yearCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count années',
      one: '$count année',
    );
    return '$_temp0';
  }

  @override
  String countdown_daysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Jours restants',
      one: '$days Jours restants',
    );
    return '$_temp0';
  }

  @override
  String countUp_day(int day) {
    return 'Jour $day';
  }

  @override
  String get logs => 'Données';

  @override
  String get insights => 'Aperçu';

  @override
  String get edit => 'Éditer';

  @override
  String get delete => 'Supprimer';

  @override
  String get clear => 'Effacer';

  @override
  String get save => 'Sauvegarder';

  @override
  String get import => 'Importer';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirmer';

  @override
  String get set => 'Définir';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get cancel => 'Annuler';

  @override
  String get select => 'Sélectionner';

  @override
  String get close => 'Fermer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get add => 'Ajouter';

  @override
  String get notSet => 'Non-défini';

  @override
  String get removed => 'Supprimé';

  @override
  String get totalLogs => 'Total des enregistrements';

  @override
  String get note => 'Note';

  @override
  String get systemDefault => 'Valeur par défaut du système';

  @override
  String get flow => 'Flux /';

  @override
  String get type => 'Écrire';

  @override
  String get other => 'Autre';

  @override
  String get navBar_logs => 'Suivis';

  @override
  String get navBar_sanitary => 'Sanitaire';

  @override
  String get navBar_sexActivity => 'Activité Sexuelle';

  @override
  String get navBar_pill => 'Pilule';

  @override
  String get navBar_reversibleContraceptive => 'Contraceptifs';

  @override
  String get navBar_settings => 'Paramètres';

  @override
  String get flowIntensity_none => 'Aucun';

  @override
  String get flowIntensity_spotting => 'Saignement léger';

  @override
  String get flowIntensity_light => 'Léger';

  @override
  String get flowIntensity_moderate => 'Modéré';

  @override
  String get flowIntensity_heavy => 'Abondant';

  @override
  String get builtInSymptom_acne => 'Acné';

  @override
  String get builtInSymptom_backPain => 'Mal de dos';

  @override
  String get builtInSymptom_bloating => 'Ballonnements';

  @override
  String get builtInSymptom_cramps => 'Crampes';

  @override
  String get builtInSymptom_fatigue => 'Fatigue';

  @override
  String get builtInSymptom_headache => 'Migraine';

  @override
  String get builtInSymptom_moodSwings => 'Sauts d\'humeur';

  @override
  String get builtInSymptom_nausea => 'Nausée';

  @override
  String get builtInSymptom_tenderBreasts => 'Tender breasts';

  @override
  String get builtInSymptom_insomnia => 'Insomnia';

  @override
  String get builtInSymptom_depressed => 'Depressed';

  @override
  String get painLevel_title => 'Intensité de la douleur';

  @override
  String get painLevel_none => 'Aucune';

  @override
  String get painLevel_mild => 'Légère';

  @override
  String get painLevel_moderate => 'Modérée';

  @override
  String get painLevel_severe => 'Forte';

  @override
  String get pain_unbearable => 'Insupportable';

  @override
  String get reversibleContraceptive_hormonalIud => 'DIU Hormonal';

  @override
  String get reversibleContraceptive_copperIud => 'DIU au Cuivre';

  @override
  String get reversibleContraceptive_implant => 'Implant';

  @override
  String get reversibleContraceptive_injection => 'Injection';

  @override
  String get reversibleContraceptive_ring => 'Anneau';

  @override
  String get reversibleContraceptive_patch => 'Patch';

  @override
  String get sanitaryProduct_tampon => 'Tampon';

  @override
  String get sanitaryProduct_pad => 'Serviette hygiénique';

  @override
  String get sanitaryProduct_menstrualCup => 'Coupe menstruelle';

  @override
  String get sanitaryProduct_periodUnderwear => 'Lingerie menstruelle';

  @override
  String get sanitaryProducts_mostUsed => 'Le plus utilisé';

  @override
  String get sanitaryProducts_usageTrend => 'Tendance d\'utilisation';

  @override
  String get sexProtection_none => 'Aucune';

  @override
  String get sexProtection_barrier => 'Barrière';

  @override
  String get sexProtection_hormonal => 'Hormonale';

  @override
  String get sexProtection_nonHormonal => 'Pas hormonale';

  @override
  String get sexProtection_natural => 'Naturelle';

  @override
  String get sexProtection_permanent => 'Permanente';

  @override
  String get sexType_vaginal => 'Vaginal';

  @override
  String get sexType_anal => 'Anal';

  @override
  String get sexType_oral => 'Oral';

  @override
  String get sexType_manual => 'Manuel';

  @override
  String get sexParticipation_solo => 'Seul';

  @override
  String get sexParticipation_partner => 'Partenaire';

  @override
  String get sexParticipation_group => 'Groupe';

  @override
  String get userGoal_general => 'Santé globale';

  @override
  String get userGoal_sexual => 'Santé sexuelle';

  @override
  String get userGoal_conceive => 'Tomber enceinte';

  @override
  String get userGoal_avoid => 'Éviter la grossesse';

  @override
  String get dayOfWeek_monday => 'Lundi';

  @override
  String get dayOfWeek_tuesday => 'Mardi';

  @override
  String get dayOfWeek_wednesday => 'Mercredi';

  @override
  String get dayOfWeek_thursday => 'Jeudi';

  @override
  String get dayOfWeek_friday => 'Vendredi';

  @override
  String get dayOfWeek_saturday => 'Samedi';

  @override
  String get dayOfWeek_sunday => 'Dimanche';

  @override
  String get cyclePhase_menstruation => 'Règles';

  @override
  String get cyclePhase_follicular => 'Pré-ovulation';

  @override
  String get cyclePhase_fertileWindow => 'Fertile Window';

  @override
  String get cyclePhase_ovulation => 'Pic de fertilité';

  @override
  String get cyclePhase_luteal => 'Post-ovulation';

  @override
  String get cyclePhase_late => 'En retard';

  @override
  String get cyclePhase_unknown => 'Inconnue';

  @override
  String get cyclePhase_menstruationDescription => 'Vos règles sont actives et la muqueuse utérine est en train de se détacher.';

  @override
  String get cyclePhase_fertileWindowDescription => 'Your fertile window is active.';

  @override
  String get cyclePhase_follicularDescription => 'Le taux d’œstrogènes augmente pour préparer l\'ovule ; votre niveau d\'énergie peut être en hausse.';

  @override
  String get cyclePhase_ovulationDescription => 'Un ovule a été libéré. C\'est votre période la plus fertile.';

  @override
  String get cyclePhase_lutealDescription => 'La progestérone est dominante. Surveillez l\'apparition de symptômes de syndrome prémenstruel (SPM) car vous approchez de vos prochaines règles. ';

  @override
  String get cyclePhase_lateDescription => 'Vos règles sont en retards';

  @override
  String get cyclePhase_unknownDescription => 'Nous avons besoin de plus de données pour prédire précisément votre phase de cycle.';

  @override
  String get fertilityChance_high => 'High';

  @override
  String get fertilityChance_medium => 'Medium';

  @override
  String get fertilityChance_low => 'Low';

  @override
  String get error_valueMustbePositive => 'La valeur doit être supérieure à zéro';

  @override
  String get error_valueCannotBeNull => 'La valeur ne peut pas être vide';

  @override
  String get notification_periodTitle => 'Règles imminentes';

  @override
  String notification_periodBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vos prochaines règles devraient commencer dans $count jours.',
      one: 'Vos prochaines règles devraient commencer dans 1 jour.',
    );
    return '$_temp0';
  }

  @override
  String get notification_periodOverdueTitle => 'Règles en retard';

  @override
  String notification_periodOverdueBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vos prochaines règles sont en retard de $count jours.',
      one: 'Vos prochaines règles sont en retard d\'un jour.',
    );
    return '$_temp0';
  }

  @override
  String get notification_pillTitle => 'Rappel de pilule';

  @override
  String get notification_pillBody => 'N’oubliez pas de prendre votre pilule aujourd’hui.';

  @override
  String get notification_reversibleContraceptiveTitle => 'Rappel de contraception réversible';

  @override
  String notification_reversibleContraceptiveBody(String type, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'jours',
      one: 'jour',
    );
    return '$type doit être renouvelée dans $days $_temp0.';
  }

  @override
  String get notification_loggingReminderTitle => 'Rappel de suivi';

  @override
  String get notification_loggingReminderBody => 'Appuyer pour enregistrer votre flux d\'aujourd\'hui.';

  @override
  String get notification_SanitaryProductReminderTitle => 'Rappel des produits hygiénique';

  @override
  String get notification_SanitaryProductReminderBody => 'N\'oubliez pas de changer votre produit hygiénique.';

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
  String get onboardingScreen_welcomeToMenstrudel => 'Bienvenue sur Menstrudel';

  @override
  String get onboardingScreen_welcomeToMenstrudelDescription => 'Votre traqueur hors ligne et privé.';

  @override
  String get onBoardingScreen_byUsingMenstrudelYouAgreeTo => 'En utilisant Menstrudel, vous acceptez nos';

  @override
  String get onBoardingScreen_privacyPolicy => 'Politique de confidentialité';

  @override
  String get onboardingScreen_profileTitle => 'A propos de vous';

  @override
  String get onboardingScreen_profileName => 'Comment doit-on vous appeler ?';

  @override
  String get onboardingScreen_profileDate => 'Date de naissance (optionnel)';

  @override
  String get onboardingScreen_profileDatePlaceholder => 'Appuyer pour paramétrer la date de naissance';

  @override
  String get onboardingScreen_goalTitle => 'Quel est votre objectif ?';

  @override
  String get onboardingScreen_goalDescription => 'Cela permet de personnaliser les informations que vous voyez.';

  @override
  String onboardingScreen_contraceptionHint(String sectionName) {
    return 'Note: You can enable Pill or LARC tracking later in the app settings under \'$sectionName\' if wanted.';
  }

  @override
  String get onboardingScreen_getStarted => 'Pour commencer';

  @override
  String get fabToolTip_logs => 'Enregistrer donnée journalière';

  @override
  String get fabToolTip_sanitary => 'Enregistrer protection menstruelle';

  @override
  String get fabToolTip_sexActivity => 'Enregistrer activité sexuelle';

  @override
  String get fabToolTip_reversibleContraceptive => 'Enregistrer une contraception réversible';

  @override
  String get mainScreen_logsPageTitle => 'Enregistrement';

  @override
  String get mainSceen_sexActivityPageTitle => 'Activité sexuelle';

  @override
  String get mainScreen_sanitaryPageTitle => 'Produits hygiéniques';

  @override
  String get mainScreen_pillsPageTitle => 'Pilules';

  @override
  String get mainScreen_reversibleContraceptivesPageTitle => 'Contraception réversible';

  @override
  String get mainScreen_settingsPageTitle => 'Paramètres';

  @override
  String get insightsScreen_errorPrefix => 'Erreur:';

  @override
  String get insightsScreen_noDataAvailable => 'Aucune donnée disponible.';

  @override
  String get logsScreen_calculatingPrediction => 'Calcul de la prédication...';

  @override
  String get logScreen_logAtLeastTwoPeriods => 'Enregistrer au moins deux périodes pour estimer le prochain cycle.';

  @override
  String get logScreen_nextPeriodEstimate => 'Prochaine période estimée';

  @override
  String get logScreen_periodDueToday => 'Règles prévues pour aujourd’hui';

  @override
  String logScreen_periodOverdueBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Règles en retard de $count jours',
      one: 'Règles en retard d’un jour',
    );
    return '$_temp0';
  }

  @override
  String get pillScreen_pillForTodayMarkedAsTaken => 'Pilule du jour marquée comme prise.';

  @override
  String get pillScreen_pillForTodayMarkedAsSkipped => 'Pilule du jour marquée comme sautée.';

  @override
  String get reversibleContraceptiveScreen_noRecordsFound => 'Aucune donnée trouvée';

  @override
  String reversibleContraceptiveScreen_history(int history) {
    return 'Historique ($history)';
  }

  @override
  String reversibleContraceptiveScreen_activeReversibleContraceptives(int activeCount) {
    return 'Actif ($activeCount)';
  }

  @override
  String get reversibleContraceptiveScreen_activeReversibleContraceptivesDescription => 'Contraceptions réversibles actuellement monitorées';

  @override
  String get reversibleContraceptiveScreen_noActiveRecords => 'Aucune contraception réversible n\'est actuellement active. Veuillez rentrer un nouvel enregistrement.';

  @override
  String get reversibleContraceptiveScreen_noHistoryRecords => 'Aucune contraception réversible passée ou en retard trouvée';

  @override
  String get sanitaryProductsScreen_noSanitaryProductRecordsFound => 'Aucun enregistrement de produit hygiénique n\'a été trouvé.';

  @override
  String sanitaryProductsScreen_history(int history) {
    return 'Historique ($history)';
  }

  @override
  String get sanitaryProductsScreen_noHistoryRecords => 'Aucun enregistrement de produit hygiénique n\'a été trouvé.';

  @override
  String sanitaryProductsScreen_activeProduct(String activeType) {
    return 'Actif$activeType';
  }

  @override
  String sanitaryProductsScreen_changeDueAt(String time) {
    return 'Changement prévu à $time';
  }

  @override
  String get sexActivityScreen_noSexActivityRecordsFound => 'Aucune donnée d\'activité sexuelle trouvée';

  @override
  String sexActivityScreen_history(int history) {
    return 'Historique';
  }

  @override
  String get sexActivityScreen_primaryMethod => 'Méthode principale';

  @override
  String get sexActivityScreen_mostFrequent => 'Le plus fréquent';

  @override
  String get sexActivityScreen_protected => 'Protégé';

  @override
  String get sexActivityScreen_activityTrend => 'Tendance d\'activité';

  @override
  String get sexActivityScreen_activityDistribution => 'Répartition des activités';

  @override
  String get sexActivityScreen_protectionDistribution => 'Répartition des protections';

  @override
  String get settingsScreen_profile => 'Profil';

  @override
  String get settingsScreen_name => 'Nom';

  @override
  String get settingsScreen_birthDate => 'Date de naissance';

  @override
  String get settingsScreen_notSet => 'Non définie';

  @override
  String get settingsScreen_appGoal => 'But de l\'application';

  @override
  String get settingsScreen_profileUpdated => 'Profil mis à jour avec succès';

  @override
  String get settingsScreen_selectHistoryView => 'Sélectionner la vue de l\'historique';

  @override
  String get settingsScreen_deleteRegimen_question => 'Supprimer le traitement ?';

  @override
  String get settingsScreen_deleteRegimenDescription => 'Cela supprimera les réglages de votre plaquette actuelle ainsi que tous les journaux de pilules associés. Cette action est irréversible.';

  @override
  String get settingsScreen_allLogsHaveBeenCleared => 'Tout l’historique a été supprimé.';

  @override
  String get settingsScreen_clearAllLogs_question => 'Supprimer tout l’historique ?';

  @override
  String get settingsScreen_deleteAllLogsDescription => 'Tous vos suivis de règles seront définitivement supprimés, mais vos paramètres resteront inchangés.';

  @override
  String get settingsScreen_appearance => 'Apparence';

  @override
  String get settingsScreen_historyViewStyle => 'Style d’affichage de l’historique';

  @override
  String get settingsScreen_appTheme => 'Thème de l’application';

  @override
  String get settingsScreen_themeLight => 'Clair';

  @override
  String get settingsScreen_themeDark => 'Sombre';

  @override
  String get settingsScreen_themeSystem => 'Système';

  @override
  String get settingsScreen_dynamicTheme => 'Thème dynamique';

  @override
  String get settingsScreen_useWallpaperColors => 'Utiliser les couleurs du fond d’écran';

  @override
  String get settingsScreen_themeColor => 'Couleur du thème';

  @override
  String get settingsScreen_pickAColor => 'Sélectionner une couleur';

  @override
  String get settingsScreen_view => 'Vue';

  @override
  String get settingsScreen_birthControl => 'Contraception';

  @override
  String get settingsScreen_enablePillTracking => 'Activer le suivi des pilules';

  @override
  String get settingsScreen_pillDescription => 'Suivez votre prise quotidienne de pilule et recevez des rappels.';

  @override
  String get settingsScreen_setUpPillRegimen => 'Configurer le régime de pilule';

  @override
  String get settingsScreen_trackYourDailyPillIntake => 'Suivi quotidien de la pilule';

  @override
  String get settingsScreen_dailyPillReminder => 'Rappel pour la pilule quotidienne';

  @override
  String get settingsScreen_reminderTime => 'Heure du rappel';

  @override
  String get settingsScreen_cycleNotificationsAndPredictions => 'Cycle Notifications & Predictions';

  @override
  String get settingsScreen_enablePhasePredictions => 'Enable Phase Predictions';

  @override
  String get settingsScreen_displayFertileChance => 'Display Fertile Chance';

  @override
  String get settingsScreen_displayFertileWindowOnCalendar => 'Display Fertile Window on Calendar';

  @override
  String get settingsScreen_notificationTime => 'Heure de la notification';

  @override
  String get settingsScreen_remindMeBefore => 'M’avertir avant';

  @override
  String get settingsScreen_remindMeAfter => 'Me rappeler après';

  @override
  String get settingsScreen_upcomingPeriodReminder => 'Rappel des prochaines règles';

  @override
  String get settingsScreen_overduePeriodReminder => 'Alerte de retard de règles';

  @override
  String get settingsScreen_fertileWindowReminder => 'Fertile Window Reminder';

  @override
  String get settingsScreen_ovulationDayReminder => 'Ovulation Day Reminder';

  @override
  String get settingsScreen_enableReversibleContraceptiveTracking => 'Activer le suivi des contraceptions réversibles';

  @override
  String get settingsScreen_reversibleContraceptiveDescription => 'Suivre les contraceptions réversibles.';

  @override
  String get settingsScreen_reversibleContraceptiveType => 'Type de contraceptif';

  @override
  String get settingsScreen_setDuration => 'Déterminer une durée';

  @override
  String get settingsScreen_reversibleContraceptiveDuration => 'Durée de remplacement de la contraception';

  @override
  String get settingsScreen_enableReversibleContraceptiveReminder => 'Activer le rappel de contraception';

  @override
  String get settingsScreen_currentDuration => 'Durée actuelle';

  @override
  String get settingsScreen_durationInDays => 'Durée (Jours)';

  @override
  String get settingsScreen_LoggingScreen => 'Suivi';

  @override
  String get settingsScreen_enableLoggingReminders => 'Activer un rappel de suivis';

  @override
  String get settingsScreen_loggingReminderDescription => 'Si vous enregistrez un jour avec flux, vous recevrez une notification le lendemain pour enregistrer votre statut.';

  @override
  String get settingsScreen_loggingReminderTime => 'Heure du rappel de suivi';

  @override
  String get settingsScreen_defaultSymptoms => 'Symptômes par défaut';

  @override
  String get settingsScreen_defaultSymptomsSubtitle => 'Ceux-ci sont toujours disponibles lorsque vous enregistrez de nouveaux cycles de règles.\nAppuyez sur un symptôme existant pour le supprimer ou sur « + » pour en ajouter un nouveau.';

  @override
  String settingsScreen_deleteDefaultSymptomQuestion(String symptom) {
    return 'Supprimer \'$symptom\'?';
  }

  @override
  String get settingsScreen_resetSymptomsList => 'Réinitialiser la liste des symptômes ?';

  @override
  String get settingsScreen_resetSymptomsListDescription => 'Cela supprimera tous vos symptômes personnalisés et restaurera la liste d\'origine.\n\nVos entrées existantes ne seront pas modifiées.';

  @override
  String settingsScreen_deleteDefaultSymptomDescription(String symptom, num usageCount) {
    String _temp0 = intl.Intl.pluralLogic(
      usageCount,
      locale: localeName,
      other: 'Il y a $usageCount enrengistrements avec ces symptômes. Ces enregistrements ne seront pas changés.',
      one: 'Il y a déjà un enregistrement avec ces symptômes ! Cet enregistrement ne sera pas changé.',
      zero: 'Il n\'y a actuellement aucun enregistrement avec ces symptômes!',
    );
    return '\'$symptom\' ne seront plus disponible lors de l\'enregistrement d\'une donnée.\n\n$_temp0';
  }

  @override
  String get settingsScreen_pillRegimens => 'Suivis de pilule';

  @override
  String get settingsScreen_makeActive => 'Définir comme actif';

  @override
  String get settingsScreen_activeRegimenReminder => 'Paramètres de rappel du régime actif';

  @override
  String get settingsScreen_pack => 'Pack';

  @override
  String get settingsScreen_dataManagement => 'Gestion des données';

  @override
  String get settingsScreen_deleteZone => 'Supprimer une période';

  @override
  String get settingsScreen_clearLogsAndPeriods => 'Effacer le journal et le suivi des règles';

  @override
  String get settingsScreen_clearLogsAndPeriodsSubtitle => 'Efface l\'entièreté de l\'historique des règles et des symptômes.';

  @override
  String get settingsScreen_clearPillLogs => 'Effacer le journal des pillules';

  @override
  String get settingsScreen_clearPillLogsSubtitle => 'Efface le régime de pillule et l\'historique de prises.';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogs => 'Effacer le journal de contraceptions réversibles';

  @override
  String get settingsScreen_clearReversibleContraceptiveLogsSubtitle => 'Efface l\'historique des contraceptions réversibles.';

  @override
  String get settingsScreen_clearSanitaryProductLogs => 'Effacer le journal de produits sanitaires';

  @override
  String get settingsScreen_clearSanitaryProductLogsSubtitle => 'Efface l\'historique des produits sanitaires.';

  @override
  String get settingsScreen_clearSexualActivityLogs => 'Effacer le journal d\'activités sexuelles';

  @override
  String get settingsScreen_clearSexualActivityLogsSubtitle => 'Efface l\'historique des activités sexuelles.';

  @override
  String get settingsScreen_logsAndPeriods => 'Journal & règles';

  @override
  String get settingsScreen_pillLogs => 'Journal de pillule';

  @override
  String get settingsScreen_reversibleContraceptivesLogs => 'Journal de contraception réversible';

  @override
  String get settingsScreen_sanitaryProductLogs => 'Journal de produits sanitaires';

  @override
  String get settingsScreen_sexualActivityLogs => 'Journal d\'activités sexuelles';

  @override
  String get settingsScreen_importSupportNote => 'L\'import n\'est pour le moment supporté que pour des fichiers exportés depuis Menstrudel.';

  @override
  String get settingsScreen_exportSuccessful => 'Données exportées avec succès.';

  @override
  String get settingsScreen_exportFailed => 'L\'exportation a échoué. Veuillez réessayer.';

  @override
  String get settingsScreen_exportDataTitle => 'Exportation Des Données';

  @override
  String get settingsScreen_importDataTitle => 'Importation Des Données';

  @override
  String get settingsScreen_importDataSubtitle => 'Écraser les données existantes.';

  @override
  String get settingsScreen_importSuccessful => 'Données importées avec succès !';

  @override
  String get settingsScreen_importFailed => 'Échec de l\'importation des données. Veuillez réessayer.';

  @override
  String get settingsScreen_importErrorGeneral => 'Échec de l\'importation des données. Veuillez vous assurer que le fichier est enregistré localement.';

  @override
  String get settingsScreen_security => 'Sécurité';

  @override
  String get securityScreen_enableBiometricLock => 'Activer le verrouillage biométrique';

  @override
  String get securityScreen_enableBiometricLockSubtitle => 'Nécessite une empreinte digitale ou un identifiant facial pour ouvrir l\'application.';

  @override
  String get securityScreen_noBiometricsAvailable => 'Aucun code d\'accès, empreinte digitale ou Face ID n\'a été trouvé. Veuillez en configurer un dans les paramètres de votre appareil.';

  @override
  String get settingsScreen_userProfile => 'Vous';

  @override
  String get settingsScreen_preferences => 'Préférences';

  @override
  String get preferencesScreen_language => 'Langue';

  @override
  String get preferencesScreen_enableSanitaryProductsScreen => 'Activer l\'écran des protections menstruelles';

  @override
  String get preferencesScreen_enableSanitaryProductsScreenSubtitle => 'Afficher l\'onglet des protections menstruelles sur la barre de navigation principale.';

  @override
  String get preferencesScreen_enableSexActivityScreen => 'Activer l\'écran d\'activités sexuelles';

  @override
  String get preferencesScreen_enableSexActivityScreenSubtitle => 'Afficher l\'écran d\'activités sexuelles dans la barre de navigation principale.';

  @override
  String get preferencesScreen_StartingDayOfWeek => 'Jour de début de semaine';

  @override
  String get settingsScreen_about => 'À propos';

  @override
  String get aboutScreen_version => 'Version';

  @override
  String get aboutScreen_legalAndSource => 'Mentions légales et sources';

  @override
  String get aboutScreen_communityAndUpdates => 'Communauté & Mise à jour';

  @override
  String get aboutScreen_privacyPolicy => 'Politique de confidentialité';

  @override
  String get aboutScreen_privacyPolicySubtitle => 'Lire notre politique de confidentialité';

  @override
  String get aboutScreen_releaseNotes => 'Note de mise à jour';

  @override
  String aboutScreen_releaseNotesSubtitle(String version) {
    return 'Quoi de nouveau dans $version';
  }

  @override
  String get aboutScreen_github => 'GitHub';

  @override
  String get aboutScreen_githubSubtitle => 'Code source et suivis des erreurs';

  @override
  String get aboutScreen_discord => 'Discord';

  @override
  String get aboutScreen_discordSubtitle => 'Support et communauté';

  @override
  String get aboutScreen_share => 'Partager';

  @override
  String get aboutScreen_shareText => 'Découvre Menstrudel, une application de suivi des règles privée et hors ligne!';

  @override
  String get aboutScreen_urlError => 'Impossible d\'ouvrir le lien.';

  @override
  String get logSummaryWidget_loggedDays => 'Jours suivis';

  @override
  String get logSummaryWidget_trackingHistory => 'Historique de suivi';

  @override
  String get cycleLengthVarianceWidget_logAtLeastTwoPeriods => 'Il faut au moins deux cycles pour observer une variance.';

  @override
  String get cycleLengthVarianceWidget_title => 'Variance de la durée du cycle';

  @override
  String get cycleLengthVarianceWidget_averageCycle => 'Cycle Moyen';

  @override
  String get cycleLengthVarianceWidget_cycle => 'Cycle';

  @override
  String get periodDurationWidget_logAtLeastTwoPeriods => 'Enregistrez au moins deux cycles pour voir les statistiques de règles.';

  @override
  String get periodDurationWidget_title => 'Variance de la durée des règles';

  @override
  String get periodDurationWidget_averagePeriod => 'Moyenne de règles';

  @override
  String get periodDurationWidget_period => 'Règles';

  @override
  String get flowIntensityWidget_flowIntensityBreakdown => 'Décomposition de l\'intensité du flux';

  @override
  String get flowIntensityWidget_noFlowDataLoggedYet => 'Aucune donnée du flux enregistrée pour le moment.';

  @override
  String get painLevelWidget_noPainDataLoggedYet => 'Aucune donnée sur la douleur n\'a encore été enregistrée.';

  @override
  String get painLevelWidget_painLevelBreakdown => 'Répartition du niveau de douleur';

  @override
  String get monthlyFlowChartWidget_noDataToDisplay => 'Aucune donnée à afficher.';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatterns => 'Modèles du flux cycliques';

  @override
  String get monthlyFlowChartWidget_cycleFlowPatternsDescription => 'Chaque ligne représente un cycle complet';

  @override
  String get symptomFrequencyWidget_noSymptomsLoggedYet => 'Aucun symptôme n\'a encore été enregistré.';

  @override
  String get symptomFrequencyWidget_mostCommonSymptoms => 'Symptômes les plus courants';

  @override
  String get journalViewWidget_logYourFirstPeriod => 'Enregistrer vos premières règles.';

  @override
  String get listViewWidget_noPeriodsLogged => 'Aucun cycle menstruel enregistré pour le moment.\nAppuyez sur le bouton + pour en ajouter une.';

  @override
  String get listViewWidget_confirmDelete => 'Confirmer la suppression';

  @override
  String get listViewWidget_confirmDeleteDescription => 'Êtes-vous sûr de vouloir supprimer cette entrée ?';

  @override
  String get emptyPillStateWidget_noPillRegimenFound => 'Aucun traitement de pilule trouvé.';

  @override
  String get emptyPillStateWidget_noPillRegimenFoundDescription => 'Configurez votre plaquette de pilules dans les paramètres pour commencer le suivi.';

  @override
  String pillStatus_pillsOfTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'de $count pilules',
      one: 'd\'une pilule',
    );
    return '$_temp0';
  }

  @override
  String get pillStatus_undo => 'Annuler';

  @override
  String get pillStatus_skip => 'Sauter';

  @override
  String get pillStatus_markAsTaken => 'Marquer Comme Prise';

  @override
  String pillStatus_packStartInFuture(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Votre prochaine plaquette de pilules commence le $dateString.';
  }

  @override
  String get regimenSetupWidget_setUpPillRegimen => 'Mettre en place un régime de pilules';

  @override
  String get regimenSetupWidget_packName => 'Nom du paquet de pilules';

  @override
  String get regimenSetupWidget_pleaseEnterAName => 'Veuillez saisir un nom';

  @override
  String get regimenSetupWidget_activePills => 'Pilules actives';

  @override
  String get regimenSetupWidget_enterANumber => 'Entrez un nombre';

  @override
  String get regimenSetupWidget_placeboPills => 'Pilules placebo';

  @override
  String get regimenSetupWidget_firstDayOfThisPack => 'Premier jour de cette plaquette';

  @override
  String get symptomEntrySheet_logYourDay => 'Enregistrez votre journée';

  @override
  String get symptomEntrySheet_symptomsOptional => 'Symptômes (Optionnel)';

  @override
  String get periodDetailsSheet_symptoms => 'Symptômes';

  @override
  String get periodDetailsSheet_flow => 'Flux';

  @override
  String get reversibleContraceptiveEntrySheet_logReversibleContraceptiveDetails => 'Enregistrer les détails contraceptifs';

  @override
  String get sanitaryEntrySheet_logSanitaryProduct => 'Enregistrer une protection menstruelle';

  @override
  String get sanitaryEntrySheet_setReminderDuration => 'Définir la durée du rappel';

  @override
  String sanitaryEntrySheet_maxDuration(int hours) {
    return 'Durée maximale: $hours heures';
  }

  @override
  String get sanitaryEntrySheet_futureLogTimeError => 'Un suivi ne peut pas être dans le futur.';

  @override
  String get sanitaryEntrySheet_pastReminderTimeError => 'La fin d\'un rappel ne peut pas être dans le passé.';

  @override
  String periodPredictionCircle_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Jours',
      one: 'Jour',
    );
    return '$_temp0';
  }

  @override
  String get customSymptomDialog_newSymptom => 'Nouveau symptôme';

  @override
  String get customSymptomDialog_enterCustomSymptom => 'Please enter a custom symptom';

  @override
  String get customSymptomDialog_temporarySymptom => 'Symptôme temporaire';
}
