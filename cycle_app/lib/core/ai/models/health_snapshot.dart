/// A unified, anonymized snapshot of the user's health state, aggregated
/// from every data source in the app (cycle widget DB, Menstrudel wellness
/// DB, self-care prefs). This is the single "context" object handed to the
/// AI layer — screens never build their own ad-hoc context maps.
class HealthSnapshot {
  const HealthSnapshot({
    this.cycleLength,
    this.periodDuration,
    this.currentPhase,
    this.currentCycleDay,
    this.nextPeriodDate,
    this.ovulationDate,
    this.cycleRegularity,
    this.isPeriodActive = false,
    this.isOvulationDay = false,
    this.pregnancyChances,
    this.userGoal,
    this.pregnancyWeek,
    this.trimester,
    this.expectedDueDate,
    this.gestationalDay,
    this.fetalDevelopmentSnippet,
    this.maternalSnippet,
    this.summary = const {},
    this.recentSymptoms = const {},
    this.wellnessLogCount = 0,
    this.lastLoggedFlow,
    this.daysSinceLastLog,
    this.averagePainLevel,
    this.dailyRitualsCompleted = 0,
    this.wellnessHub = const {},
    this.pregnancyTracking = const {},
    this.todayLog = const {},
    this.cycleHistory = const {},
    this.localTimeOfDay,
    this.userLocale = 'ar',
  });

  // --- Cycle (widget DB) ---
  final int? cycleLength;
  final int? periodDuration;
  final String? currentPhase;
  final int? currentCycleDay;
  final String? nextPeriodDate;
  final String? ovulationDate;
  final String? cycleRegularity;
  final bool isPeriodActive;
  final bool isOvulationDay;
  final String? pregnancyChances;
  final String? userGoal;
  final int? pregnancyWeek;
  final int? trimester;
  final String? expectedDueDate;
  final int? gestationalDay;
  final String? fetalDevelopmentSnippet;
  final String? maternalSnippet;
  final Map<String, dynamic> summary;

  // --- Wellness (Menstrudel DB) ---
  /// Symptom name -> occurrences in the last 30 days.
  final Map<String, int> recentSymptoms;
  final int wellnessLogCount;
  final String? lastLoggedFlow;
  final int? daysSinceLastLog;

  /// Average logged pain level over the last 30 days (null when no data).
  final double? averagePainLevel;

  // --- Self care ---
  final int dailyRitualsCompleted;

  /// Wellness Hub (مركز العناية): pills, sanitary, intimacy counts,
  /// reversible contraceptive, and daily vitals from the log tab.
  final Map<String, dynamic> wellnessHub;

  /// Weight, kicks, contractions (pregnancy mode).
  final Map<String, dynamic> pregnancyTracking;

  /// Mood/symptoms/water logged today (home + log tab).
  final Map<String, dynamic> todayLog;

  /// Real historical series (recent cycle lengths + period durations) so the
  /// AI can spot patterns — sourced from CycleBridgeService analytics history.
  final Map<String, dynamic> cycleHistory;

  /// morning | afternoon | evening | night — lets the AI tailor tips to the
  /// user's local time (energy in the morning, wind-down at night).
  final String? localTimeOfDay;

  /// ar | en — matches UI language for snippets.
  final String userLocale;

  bool get isPregnancyMode => userGoal == 'pregnant';

  bool get isEmpty =>
      cycleLength == null &&
      wellnessLogCount == 0 &&
      wellnessHub.isEmpty &&
      !isPregnancyMode;

  /// Map shape consumed by the Gemini prompts (cloud function + direct).
  /// Keys are kept identical to the legacy context map so the deployed
  /// Cloud Function keeps working unchanged.
  Map<String, dynamic> toPromptMap() => {
        'cycleLength': cycleLength,
        'periodDuration': periodDuration,
        'currentPhase': currentPhase,
        'currentCycleDay': currentCycleDay,
        'nextPeriodDate': nextPeriodDate,
        'ovulationDate': ovulationDate,
        'cycleRegularity': cycleRegularity,
        'isPeriodActive': isPeriodActive,
        'isOvulationDay': isOvulationDay,
        'pregnancyChances': pregnancyChances,
        'userGoal': userGoal,
        if (pregnancyWeek != null) 'pregnancyWeek': pregnancyWeek,
        if (trimester != null) 'trimester': trimester,
        if (expectedDueDate != null) 'expectedDueDate': expectedDueDate,
        if (gestationalDay != null) 'gestationalDay': gestationalDay,
        if (fetalDevelopmentSnippet != null)
          'fetalDevelopmentSnippet': fetalDevelopmentSnippet,
        if (maternalSnippet != null) 'maternalSnippet': maternalSnippet,
        'summary': summary,
        if (recentSymptoms.isNotEmpty) 'recentSymptoms': recentSymptoms,
        'wellnessLogCount': wellnessLogCount,
        if (lastLoggedFlow != null) 'lastLoggedFlow': lastLoggedFlow,
        if (daysSinceLastLog != null) 'daysSinceLastLog': daysSinceLastLog,
        if (averagePainLevel != null) 'averagePainLevel': averagePainLevel,
        'dailyRitualsCompleted': dailyRitualsCompleted,
        if (wellnessHub.isNotEmpty) 'wellnessHub': wellnessHub,
        if (pregnancyTracking.isNotEmpty) 'pregnancyTracking': pregnancyTracking,
        if (todayLog.isNotEmpty) 'todayLog': todayLog,
        if (cycleHistory.isNotEmpty) 'cycleHistory': cycleHistory,
        if (localTimeOfDay != null) 'localTimeOfDay': localTimeOfDay,
        'userLocale': userLocale,
      };
}
