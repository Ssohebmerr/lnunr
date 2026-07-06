import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/cycle/data/cycle_bridge_service.dart';
import '../../features/cycle/data/cycle_sync_service.dart';
import '../../features/cycle/data/today_log_service.dart';
import '../../features/pregnancy/data/pregnancy_development_content.dart';
import '../../features/pregnancy/data/pregnancy_tracking_service.dart';
import '../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../menstrudel/models/period_logs/symptom.dart';
import '../../features/self_care/data/ritual_service.dart';
import '../../menstrudel_integration/menstrudel_init.dart';
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
      pregnancyTracking =
          (await PregnancyTrackingService().buildSummary()).toPromptMap();
    }

    final today = await TodayLogService().loadToday();
    if (today != null && today.hasEntry) {
      todayLog = {
        'symptoms': today.symptoms,
        'waterCups': today.waterCups,
        if (today.weight != null) 'weight': today.weight,
        if (today.bodyTemperature != null) 'bodyTemperature': today.bodyTemperature,
        if (today.sleepTime != null) 'sleepTime': today.sleepTime,
        if (today.meditationTime != null) 'meditationTime': today.meditationTime,
        if (today.notes != null) 'notes': today.notes,
      };
    }

    return HealthSnapshot(
      cycleLength: widget.getCycleLength(),
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
      userLocale: locale,
    );
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

  Future<({
    Map<String, int> symptoms,
    int logCount,
    String? lastFlow,
    int? daysSinceLastLog,
    double? averagePain,
  })> _collectWellness() async {
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
