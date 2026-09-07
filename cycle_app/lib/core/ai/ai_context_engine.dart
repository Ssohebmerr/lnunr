import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cycle/data/cycle_bridge_service.dart';
import '../../features/cycle/data/cycle_sync_service.dart';
import '../../features/cycle/data/today_log_service.dart';
import '../cycle/cycle_annotation_service.dart';
import '../cycle/luteal_calibration.dart';
import '../cycle/ovulation_log_service.dart';
import '../../features/pregnancy/data/pregnancy_development_content.dart';
import '../../features/pregnancy/data/pregnancy_tracking_service.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../menstrudel/models/period_logs/symptom.dart';
import '../../features/self_care/data/ritual_service.dart';
import '../../menstrudel_integration/menstrudel_init.dart';
import 'condition_context_collector.dart';
import 'models/health_snapshot.dart';
import 'wellness_hub_collector.dart';

/// The "brain stem" of the app: aggregates anonymized data from every
/// source (cycle widget DB, Menstrudel wellness DB, self-care prefs) into
/// a single [HealthSnapshot] that the AI layer consumes.
///
/// Any screen or service that needs AI context should use this engine —
/// never build context maps by hand.
class AiContextEngine {
  AiContextEngine({CycleSyncService? syncService})
    : _sync = syncService ?? CycleSyncService();

  final CycleSyncService _sync;

  Future<HealthSnapshot> buildSnapshot() async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) return const HealthSnapshot();

    String? phase;
    int? cycleDay;
    String? nextPeriod;
    String? ovulation;
    String? regularity;
    bool periodActive = false;
    bool ovulationDay = false;
    String? pregnancyChances;
    Map<String, dynamic> summary = const {};
    CycleDashboardData? dashboard;

    try {
      final rawSummary = await widget.getMenstrualCycleSummary();
      dashboard = await _sync.loadDashboard();

      phase = dashboard?.phase ?? await widget.getCurrentPhaseName();
      cycleDay = dashboard?.cycleDay ?? await widget.getCurrentCycleDay();
      nextPeriod =
          dashboard?.nextPeriod ?? await widget.getNextPredictedPeriodDate();
      ovulation = dashboard?.ovulation ?? await widget.getNextOvulationDate();
      regularity = dashboard?.cycleRegularityStatus;
      periodActive = dashboard?.isPeriodStarted ?? false;
      ovulationDay = dashboard?.isOvulationDay ?? false;
      pregnancyChances = dashboard?.pregnancyChances;
      summary = _stripPII(rawSummary);
    } catch (_) {
      try {
        phase = await widget.getCurrentPhaseName();
      } catch (_) {}
    }

    final wellness = await _collectWellness();
    final rituals = await _countCompletedRituals();
    final hub = await WellnessHubCollector.collect();
    final goal = await _sync.getUserGoal();
    final locale = await _userLocale();
    final cycleHistory = await _collectCycleHistory();
    final patternSignals = <String>[
      for (final f in (cycleHistory['cyclePatternSignals'] as List? ?? const []))
        f.toString(),
    ];
    final thermalShift =
        await LutealCalibration.sharedBbtService.currentCycleShift();
    final conditionTracking = await ConditionContextCollector.collect(
      goal,
      lang: locale,
    );
    Map<String, dynamic> pregnancyTracking = const {};
    Map<String, dynamic> todayLog = const {};

    int? pregnancyWeek;
    int? trimester;
    String? expectedDueDate;
    int? gestationalDay;
    String? fetalSnippet;
    String? maternalSnippet;

    if (goal.isPregnancyMode && dashboard != null) {
      pregnancyWeek = dashboard.pregnancyWeek;
      trimester = dashboard.trimester;
      expectedDueDate = dashboard.expectedDueDate;
      gestationalDay = dashboard.cycleDay;
      final info = PregnancyDevelopmentContent.forWeek(
        pregnancyWeek.clamp(4, 42),
        locale,
      );
      fetalSnippet = info.bodyFor(locale);
      maternalSnippet = info.maternalFor(locale);
      pregnancyTracking = (await PregnancyTrackingService().buildSummary())
          .toPromptMap();
    }

    final today = await TodayLogService().loadToday();
    if (today != null && today.hasEntry) {
      todayLog = {
        'symptoms': today.symptoms,
        'waterCups': today.waterCups,
        if (today.weight != null) 'weight': today.weight,
        if (today.bodyTemperature != null)
          'bodyTemperature': today.bodyTemperature,
        if (today.sleepTime != null) 'sleepTime': today.sleepTime,
        if (today.meditationTime != null)
          'meditationTime': today.meditationTime,
        if (today.notes != null) 'notes': today.notes,
      };
    }

    int? learnedCycleLength;
    try {
      learnedCycleLength = await widget.getEffectiveCycleLength();
    } catch (_) {}

    return HealthSnapshot(
      cycleLength: learnedCycleLength ?? widget.getCycleLength(),
      periodDuration: widget.getPeriodDuration(),
      currentPhase: phase,
      currentCycleDay: cycleDay,
      nextPeriodDate: nextPeriod?.toString(),
      ovulationDate: ovulation?.toString(),
      cycleRegularity: regularity,
      isPeriodActive: periodActive,
      isOvulationDay: ovulationDay,
      pregnancyChances: pregnancyChances,
      userGoal: goal.dbName,
      pregnancyWeek: pregnancyWeek,
      trimester: trimester,
      expectedDueDate: expectedDueDate,
      gestationalDay: gestationalDay,
      fetalDevelopmentSnippet: fetalSnippet,
      maternalSnippet: maternalSnippet,
      summary: summary,
      recentSymptoms: wellness.symptoms,
      wellnessLogCount: wellness.logCount,
      lastLoggedFlow: wellness.lastFlow,
      daysSinceLastLog: wellness.daysSinceLastLog,
      averagePainLevel: wellness.averagePain,
      dailyRitualsCompleted: rituals,
      wellnessHub: hub,
      pregnancyTracking: pregnancyTracking,
      todayLog: todayLog,
      cycleHistory: cycleHistory,
      conditionTracking: conditionTracking,
      patternSignals: patternSignals,
      ovulationConfirmedByTemperature: thermalShift != null,
      temperatureRiseCelsius: thermalShift?.shift.riseCelsius,
      localTimeOfDay: _localTimeOfDay(),
      userLocale: locale,
    );
  }

  /// Coarse local-time bucket so the AI can tailor tips (energy in the
  /// morning, wind-down in the evening) without knowing the exact clock.
  String _localTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 22) return 'evening';
    return 'night';
  }

  /// Recent completed-cycle history (lengths + period durations, last 6) for
  /// AI pattern spotting. Sourced from the same real data the Analytics
  /// charts use; failures degrade to an empty map, never break the snapshot.
  Future<Map<String, dynamic>> _collectCycleHistory() async {
    try {
      final history = await CycleBridgeService().tryLoadAnalyticsHistory();
      List<int> lastSix(List<int> list) =>
          list.length > 6 ? list.sublist(list.length - 6) : list;
      final lengths = lastSix(history.cycleLengths);
      final durations = lastSix(history.periodDurations);
      final ovulationService = OvulationLogService();
      final measuredLuteal = await LutealCalibration().measuredLutealLengths();
      final ovulationLogsCount = await ovulationService.entryCount();
      final thermalShift =
          await LutealCalibration.sharedBbtService.currentCycleShift();
      final tempSeries = await LutealCalibration.sharedBbtService
          .latestCycleSeries(minReadings: 3);
      final prediction = await MenstrualCycleWidget.instance
          ?.getCurrentPeriodPrediction();
      if (lengths.isEmpty &&
          durations.isEmpty &&
          measuredLuteal.isEmpty &&
          prediction == null) {
        return const {};
      }
      // What the user says disrupted her cycles. This is the only part of the
      // context the app could never derive on its own, and it turns "your
      // cycles are getting longer" into "your cycles run long when you travel".
      final causeCounts = await CycleAnnotationService().causeFrequencies();
      final window = SmartCyclePredictor.predictionWindowDays(lengths);
      final score = lengths.length >= 2
          ? SmartCyclePredictor.regularityScore(lengths)
          : 0.0;
      return {
        if (lengths.isNotEmpty) 'recentCycleLengths': lengths,
        if (durations.isNotEmpty) 'recentPeriodDurations': durations,
        if (measuredLuteal.isNotEmpty) 'measuredLutealDays': measuredLuteal,
        'ovulationLogsCount': ovulationLogsCount,
        'ovulationCalibrated': measuredLuteal.length >= 2,
        // Temperature is the only at-home proof ovulation actually happened,
        // so tell the model when it exists — and equally when it does not.
        'ovulationConfirmedByTemperature': thermalShift != null,
        // The readings themselves, so "why didn't my temperature rise?" gets a
        // real answer instead of generic advice.
        if (tempSeries != null) ...{
          'temperatureReadingsThisCycle': tempSeries.points.length,
          'temperatureByCycleDay': {
            for (final p in tempSeries.points)
              p.cycleDay.toString(): p.celsius,
          },
          if (tempSeries.coverline != null)
            'temperatureCoverline': tempSeries.coverline,
        },
        if (thermalShift != null) ...{
          'temperatureConfirmedOvulationDate': thermalShift
              .shift
              .ovulationDate
              .toIso8601String()
              .substring(0, 10),
          'temperatureRiseCelsius': thermalShift.shift.riseCelsius,
          'temperatureShiftIsFull': thermalShift.shift.isFullShift,
        },
        'predictionWindowDays': window,
        if (causeCounts.isNotEmpty) 'reportedCycleDisruptions': causeCounts,
        'cycleRegularityScore': score.round(),
        if (prediction != null) ...{
          'predictionConfidence': prediction.confidence.name,
          'predictionConfidenceScore': double.parse(
            prediction.confidenceScore.toStringAsFixed(2),
          ),
          'predictionWindowStart': prediction.windowStart
              .toIso8601String()
              .substring(0, 10),
          'predictionWindowEnd': prediction.windowEnd
              .toIso8601String()
              .substring(0, 10),
          'isPeriodLate': prediction.isLate,
          'daysPastExpectedWindow': prediction.daysLate,
          'possibleMissingLog': prediction.possibleMissingLog,
          'backtestedCycles': prediction.accuracy.evaluatedCycles,
          'backtestsWithinTwoDays': prediction.accuracy.withinTwoDays,
          'medianAbsoluteErrorDays': double.parse(
            prediction.accuracy.medianAbsoluteError.toStringAsFixed(1),
          ),
          // Signals to raise with the user, never a diagnosis. The prompt
          // rules forbid the model from naming a condition on its own.
          if (prediction.learnsFromExplanations)
            'cyclesSetAsideByUser': prediction.explainedCycleCount,
          if (prediction.hasPatternFlags)
            'cyclePatternSignals': [
              for (final f in prediction.patternFlags) f.name,
            ],
        },
        'predictionNote': score < 75
            ? 'irregular_cycles_use_median_and_wider_window'
            : 'regular_cycles_use_weighted_recent_average',
      };
    } catch (_) {
      return const {};
    }
  }

  Future<String> _userLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('app_locale') ?? 'ar';
    } catch (_) {
      return 'ar';
    }
  }

  /// Legacy-shaped map for callers that still expect `Map<String, dynamic>`
  /// (chat Cloud Function payload).
  Future<Map<String, dynamic>> buildAnonymizedContext() async =>
      (await buildSnapshot()).toPromptMap();

  Future<
    ({
      Map<String, int> symptoms,
      int logCount,
      String? lastFlow,
      int? daysSinceLastLog,
      double? averagePain,
    })
  >
  _collectWellness() async {
    final logsRepo = MenstrudelInit.logsRepository;
    if (logsRepo == null) {
      return (
        symptoms: const <String, int>{},
        logCount: 0,
        lastFlow: null,
        daysSinceLastLog: null,
        averagePain: null,
      );
    }

    try {
      final since = DateTime.now().subtract(const Duration(days: 30));
      final freq = await logsRepo.getSymptomFrequencySince(since);
      final symptoms = <String, int>{
        for (final e in freq.entries) e.key.getDbName(): e.value,
      };

      final logs = await logsRepo.readAllLogs();

      double? averagePain;
      final recentPain = logs
          .where((l) => !l.date.isBefore(since) && l.painLevel != null)
          .map((l) => l.painLevel!)
          .toList();
      if (recentPain.isNotEmpty) {
        averagePain = recentPain.reduce((a, b) => a + b) / recentPain.length;
        averagePain = double.parse(averagePain.toStringAsFixed(1));
      }

      return (
        symptoms: symptoms,
        logCount: logs.length,
        lastFlow: logs.isNotEmpty ? logs.first.flow.toString() : null,
        daysSinceLastLog: logs.isNotEmpty
            ? DateTime.now().difference(logs.first.date).inDays
            : null,
        averagePain: averagePain,
      );
    } catch (_) {
      return (
        symptoms: const <String, int>{},
        logCount: 0,
        lastFlow: null,
        daysSinceLastLog: null,
        averagePain: null,
      );
    }
  }

  Future<int> _countCompletedRituals() async {
    try {
      // Rituals now reset daily and are stored date-scoped by RitualService.
      return await RitualService.completedTodayCount();
    } catch (_) {
      return 0;
    }
  }

  Map<String, dynamic> _stripPII(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    for (final key in ['customerId', 'userId', 'email', 'name']) {
      copy.remove(key);
    }
    return copy;
  }
}
