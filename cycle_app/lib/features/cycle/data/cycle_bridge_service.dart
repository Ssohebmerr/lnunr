import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/model/symptoms_patterns.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cycle/bbt_ovulation_service.dart';
import '../../../core/cycle/cycle_annotation_service.dart';
import '../../../core/cycle/luteal_calibration.dart';
import '../../../core/cycle/prediction_display.dart';
import '../../../core/security/cycle_encryption_keys.dart';
import '../../analytics/wellness_scores.dart';

/// Bridges Cycle Aura app with menstrual_cycle_widget package APIs.
class CycleBridgeService {
  MenstrualCycleWidget get _api {
    final api = MenstrualCycleWidget.instance;
    if (api == null) {
      throw StateError('MenstrualCycleWidget is not initialized');
    }
    return api;
  }

  /// Re-apply the widget customerId on startup / auth changes.
  ///
  /// The local encrypted cycle store always uses a single stable partition id
  /// ([CycleEncryptionKeys.localCustomerId]) regardless of sign-in state, so
  /// period dates entered during onboarding are never orphaned when the user
  /// signs in or the app is relaunched.
  Future<void> linkAuthenticatedUser(User? user) async {
    await _api.updateConfiguration(
      cycleLength: _api.getCycleLength(),
      periodDuration: _api.getPeriodDuration(),
      customerId: CycleEncryptionKeys.localCustomerId,
    );
  }

  Future<void> applyLocale(String languageCode) async {
    _api.updateLanguageConfiguration(
      defaultLanguage: _mapLanguage(languageCode),
    );
  }

  Future<void> configure({
    required int cycleLength,
    required int periodDuration,
    required DateTime lastPeriodDate,
    required String languageCode,
    DateFormats dateFormat = DateFormats.dmy,
    String? customerId,
  }) async {
    await _api.updateConfiguration(
      cycleLength: cycleLength,
      periodDuration: periodDuration,
      lastPeriodDate: lastPeriodDate,
      customerId: customerId ?? CycleEncryptionKeys.localCustomerId,
      defaultLanguage: _mapLanguage(languageCode),
      dateFormat: dateFormat,
      fontFamily: 'Default',
    );
  }

  Languages _mapLanguage(String code) => switch (code) {
    'ar' => Languages.arabic,
    'hi' => Languages.hindi,
    'es' => Languages.spanish,
    'zh' => Languages.mandarin,
    'fr' => Languages.french,
    'bn' => Languages.bengali,
    'ru' => Languages.russian,
    'pt' => Languages.portuguese,
    'ja' => Languages.japanese,
    'de' => Languages.german,
    'pa' => Languages.punjabi,
    'jv' => Languages.javanese,
    'ko' => Languages.korean,
    'ta' => Languages.tamil,
    'tr' => Languages.turkish,
    'ur' => Languages.urdu,
    'vi' => Languages.vietnamese,
    'it' => Languages.italian,
    _ => Languages.english,
  };

  static const supportedLanguageCodes = ['en', 'ar'];

  static String languageLabel(String code) => switch (code) {
    'en' => 'English',
    'ar' => 'العربية',
    _ => code,
  };

  Future<CycleDashboardData?> tryLoadDashboard() async {
    try {
      return await loadDashboard();
    } catch (e, st) {
      debugPrint('CycleBridgeService.loadDashboard failed: $e\n$st');
      return null;
    }
  }

  Future<CycleReportData?> tryLoadStructuredReport() async {
    try {
      return await loadStructuredReport();
    } catch (e, st) {
      debugPrint('CycleBridgeService.loadStructuredReport failed: $e\n$st');
      return null;
    }
  }

  /// Runs a single dashboard field query, returning [fallback] if it throws so
  /// one failing metric never blanks the whole analytics screen.
  Future<T> _safeField<T>(Future<T> Function() fn, T fallback) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('CycleBridgeService dashboard field failed: $e');
      return fallback;
    }
  }

  Future<CycleDashboardData> loadDashboard({String? languageCode}) async {
    final lang = languageCode ?? await _readLocale();
    final history = await tryLoadAnalyticsHistory();
    final completed = SmartCyclePredictor.prepareCycleLengths(
      history.cycleLengths,
    );
    final prediction = await _safeField<CyclePredictionEstimate?>(
      () => _api.getCurrentPeriodPrediction(),
      null,
    );
    final window =
        prediction?.windowDays ??
        SmartCyclePredictor.predictionWindowDays(completed);
    final calibration = LutealCalibration();
    final measured = await calibration.measuredLutealLengths();
    final ovulationCalibrated = measured.length >= 2;

    // Temperature is the only at-home evidence that ovulation actually
    // happened. When this cycle already shows a confirmed thermal shift it
    // replaces the statistical estimate outright.
    final confirmedShift = await _safeField<BbtCycleShift?>(
      () => LutealCalibration.sharedBbtService.currentCycleShift(),
      null,
    );

    final nextPeriod = await _safeField(_api.getNextPredictedPeriodDate, '');
    final estimatedOvulation = await _safeField(
      _api.getCurrentCycleOvulationEstimateDate,
      '',
    );

    final nextDt = PredictionDisplay.tryParseDashboardDate(nextPeriod);
    final confirmedOvulationDate = confirmedShift?.shift.ovulationDate;
    final ovDt =
        confirmedOvulationDate ??
        PredictionDisplay.tryParseDashboardDate(estimatedOvulation);
    final ovulation = confirmedOvulationDate != null
        ? PredictionDisplay.formatDashboardDate(confirmedOvulationDate)
        : estimatedOvulation;
    final nextPeriodRange = nextDt != null && window > 0
        ? PredictionDisplay.formatPredictionRange(
            center: nextDt,
            windowDays: window,
            languageCode: lang,
          )
        : '';
    // A confirmed thermal shift is an observation, not a forecast — collapse
    // the ±window to a single day instead of implying uncertainty we no longer
    // have. Otherwise the ovulation band tracks the cycle-length uncertainty.
    final ovulationWindow = confirmedOvulationDate != null
        ? 0
        : (ovulationCalibrated || window >= 3 ? window : 3);
    final ovulationRange = ovDt != null && ovulationWindow > 0
        ? PredictionDisplay.formatPredictionRange(
            center: ovDt,
            windowDays: ovulationWindow,
            languageCode: lang,
          )
        : '';

    return CycleDashboardData(
      phase: await _safeField(_api.getCurrentPhaseName, ''),
      nextPeriod: nextPeriod,
      nextPeriodRange: nextPeriodRange,
      ovulation: ovulation,
      ovulationRange: ovulationRange,
      predictionWindowDays: window,
      ovulationCalibrated: ovulationCalibrated,
      ovulationConfirmedByTemperature: confirmedOvulationDate != null,
      temperatureShiftCelsius: confirmedShift?.shift.riseCelsius,
      measuredLutealSignals: measured.length,
      predictionConfidence:
          prediction?.confidence ?? CyclePredictionConfidence.learning,
      predictionConfidenceScore: prediction?.confidenceScore ?? 0,
      predictionAccuracy: prediction?.accuracy ?? CyclePredictionAccuracy.empty,
      completedCycleCount: prediction?.completedCycleCount ?? completed.length,
      excludedCycleCount: prediction?.excludedCycleCount ?? 0,
      isPredictionWindowActive: prediction?.isWithinExpectedWindow ?? false,
      isPeriodLate: prediction?.isLate ?? false,
      daysLate: prediction?.daysLate ?? 0,
      possibleMissingLog: prediction?.possibleMissingLog ?? false,
      patternFlags: prediction?.patternFlags ?? const {},
      cycleDay: await _safeField(_api.getCurrentCycleDay, 0),
      periodDay: await _safeField(_api.getCurrentPeriodDay, 0),
      cycleRegularity: await _safeField(_api.getCycleRegularityScore, 0.0),
      cycleRegularityStatus: await _safeField(
        _api.getCycleRegularityScoreStatus,
        '',
      ),
      periodRegularity: await _safeField(_api.getPeriodRegularityScore, 0.0),
      periodRegularityStatus: await _safeField(
        _api.getPeriodRegularityScoreStatus,
        '',
      ),
      avgCycleLength: await _safeField(_api.getAvgCycleLength, 0),
      avgPeriodDuration: await _safeField(_api.getAvgPeriodDuration, 0),
      totalCycles: await _safeField(_api.getTotalNumberOfCycle, 0),
      pregnancyChances: await _safeField(_api.getPregnancyChances, ''),
      expectedDueDate: await _safeField(_api.getExpectedDueDate, ''),
      pregnancyWeek: await _safeField(_api.getCurrentPregnancyWeek, 0),
      trimester: await _safeField(_api.getCurrentTrimester, 0),
      isPeriodStarted: await _safeField(_api.isPeriodStarted, false),
      isOvulationDay: await _safeField(_api.isOvulationDay, false),
      expectedPregnancyTestDate: await _safeField(
        _api.getExpectedPregnancyTestDate,
        '',
      ),
    );
  }

  Future<String> _readLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('app_locale') ?? 'ar';
    } catch (_) {
      return 'ar';
    }
  }

  /// Wires every measured ovulation signal — manual ovulation/LH logs *and*
  /// basal body temperature shifts — into the widget engine's luteal
  /// calibration.
  static void wireOvulationCalibration() {
    MenstrualCycleWidget.measuredLutealProvider =
        LutealCalibration().measuredLutealLengths;
    MenstrualCycleWidget.explainedCyclesProvider =
        CycleAnnotationService().explainedFlagsFor;
  }

  /// Drops the cached temperature scan so the next dashboard refresh sees
  /// newly logged temperatures. Call after any daily-log write.
  static void invalidateBbtCache() =>
      LutealCalibration.sharedBbtService.invalidate();

  Future<Map<String, dynamic>> loadFullSummary() =>
      _api.getMenstrualCycleSummary();

  Future<Map<String, dynamic>> loadReportData() =>
      _api.getMenstrualCycleReportData();

  Future<List<SymptomsPatterns>> loadSymptomPatterns() =>
      _api.getSymptomsPatternForReport();

  Future<List<PredictedSymptom>> loadPredictedSymptoms({
    bool tomorrow = false,
  }) async {
    final raw = await _api.getSymptomsPattern(isForTomorrow: tomorrow);
    return raw
        .where((s) => (s.name ?? '').trim().isNotEmpty)
        .map(
          (s) => PredictedSymptom(
            name: s.name!.trim(),
            occurrences: s.occurrences ?? 0,
            accuracy: s.accuracy ?? 0,
          ),
        )
        .toList();
  }

  Future<GraphAvailability> loadGraphAvailability() async {
    final results = await Future.wait([
      _safeField(_api.hasCycleTrendsGraphData, false),
      _safeField(_api.hasPeriodGraphData, false),
      _safeField(_api.hasCycleHistoryGraphData, false),
      _safeField(_api.hasBodyTemperatureGraphData, false),
      _safeField(_api.hasWeightGraphData, false),
      _safeField(_api.hasSleepGraphData, false),
      _safeField(_api.hasWaterGraphData, false),
      _safeField(_api.hasMeditationGraphData, false),
    ]);
    return GraphAvailability(
      trends: results[0],
      periods: results[1],
      history: results[2],
      temperature: results[3],
      weight: results[4],
      sleep: results[5],
      water: results[6],
      meditation: results[7],
    );
  }

  Future<CycleReportData> loadStructuredReport() async {
    final raw = await _api.getMenstrualCycleReportData();
    final keyMatrix = Map<String, dynamic>.from(
      raw['key_matrix'] as Map? ?? {},
    );
    final predictionMatrix = Map<String, dynamic>.from(
      raw['prediction_matrix'] as Map? ?? {},
    );
    final cycleRaw = raw['cycle_summary'] as List? ?? [];
    final cycles = <PeriodsDateRange>[];
    for (final item in cycleRaw) {
      if (item is! Map) continue;
      try {
        cycles.add(PeriodsDateRange.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {}
    }
    final patternRaw = raw['symptom_patterns_summary'] as List? ?? [];
    final patterns = patternRaw
        .whereType<Map>()
        .map(
          (e) => SymptomsPatterns(
            name: e['symptom_name'] as String?,
            percentageOfCycles: e['percentage_of_cycles'] as int?,
          ),
        )
        .toList();
    return CycleReportData(
      keyMatrix: keyMatrix,
      predictionMatrix: predictionMatrix,
      cycles: cycles,
      symptomPatterns: patterns,
    );
  }

  Future<Map<String, dynamic>> exportEncryptedBackup() =>
      _api.getBackupOfMenstrualCycleData(isEncryptData: true);

  Future<bool> importEncryptedBackup(Map<String, dynamic> backup) =>
      _api.restoreBackupOfMenstrualCycleData(
        backupData: backup,
        customerId: _api.getCustomerId(),
      );

  /// Loads the real historical series used by the Analytics charts, swallowing
  /// any error so a failing history query never blanks the dashboard.
  Future<AnalyticsHistory> tryLoadAnalyticsHistory() async {
    try {
      return await loadAnalyticsHistory();
    } catch (e, st) {
      debugPrint('CycleBridgeService.loadAnalyticsHistory failed: $e\n$st');
      return AnalyticsHistory.empty;
    }
  }

  /// Real cycle-length / period-duration history plus monthly body-temperature
  /// averages. Everything here comes from the user's own logged data — no
  /// synthetic or placeholder values.
  Future<AnalyticsHistory> loadAnalyticsHistory() async {
    final periods = await _safeField(
      _api.getAllPeriodsDetails,
      <PeriodsDateRange>[],
    );

    // getAllPeriodsDetails() returns newest → oldest; flip to chronological so
    // charts read left (older) → right (newer).
    final chrono = periods.reversed.toList();

    // The most recent entry is the *ongoing* cycle: its cycleLength is only
    // "days elapsed so far", so it would render as an artificially short bar.
    // Drop it and keep only completed cycles for the length/duration history.
    final completed = chrono.length > 1
        ? chrono.sublist(0, chrono.length - 1)
        : const [];

    final cycleLengths = <int>[];
    final periodDurations = <int>[];
    for (final p in completed) {
      final len = p.cycleLength ?? 0;
      if (len > 0 && len < 120) cycleLengths.add(len);
      final dur = p.periodDuration ?? 0;
      if (dur > 0 && dur < 30) periodDurations.add(dur);
    }

    final monthlyTemps = await _safeField(
      _loadMonthlyTemperatures,
      <MonthlyTemperature>[],
    );
    // The cycle-relative curve is the one that actually shows the thermal
    // shift; the monthly average is kept only as a fallback for users with
    // scattered readings.
    final cycleTemps = await _safeField<CycleTemperatureSeries?>(
      LutealCalibration.sharedBbtService.latestCycleSeries,
      null,
    );
    final wellness = await _safeField(
      _loadWellnessScores,
      const RealWellnessScores(),
    );

    return AnalyticsHistory(
      cycleLengths: _lastN(cycleLengths, 12),
      periodDurations: _lastN(periodDurations, 12),
      monthlyTemps: monthlyTemps,
      cycleTemperature: cycleTemps,
      wellness: wellness,
    );
  }

  /// Real mood/energy/sleep from the last 60 days of daily logs (feeling and
  /// energy symptom selections + logged sleep windows). Empty scores when the
  /// user never logs those dimensions — analytics falls back to the phase
  /// estimates.
  Future<RealWellnessScores> _loadWellnessScores() async {
    final now = DateTime.now();
    final logs = await _api.getSymptomsLogReport(
      startDate: now.subtract(const Duration(days: 60)),
      endDate: now,
    );

    final dayLogs = <WellnessDayLog>[
      for (final log in logs)
        WellnessDayLog(
          symptomIds: {
            for (final s in log.symptomsData ?? const <SymptomsData>[])
              if (s.symptomId != null && s.symptomId != 0) s.symptomId!,
          },
          sleepTime: log.sleepTime,
        ),
    ];

    return WellnessScoreEngine.fromLogs(dayLogs);
  }

  List<int> _lastN(List<int> list, int n) =>
      list.length > n ? list.sublist(list.length - n) : list;

  /// Buckets every temperature log from the past ~12 months into monthly
  /// averages (°C). The app stores temperatures in Celsius by default; any
  /// obviously-Fahrenheit value is converted defensively.
  Future<List<MonthlyTemperature>> _loadMonthlyTemperatures() async {
    final now = DateTime.now();
    final start = DateTime(now.year - 1, now.month, 1);
    final logs = await _api.getSymptomsLogReport(
      startDate: start,
      endDate: now,
    );

    final sums = <String, double>{};
    final counts = <String, int>{};
    final meta = <String, List<int>>{}; // key -> [year, month]
    for (final log in logs) {
      final date = log.logDate;
      final raw = log.bodyTemperature;
      if (date == null || raw == null) continue;
      final value = double.tryParse(raw.trim());
      if (value == null || value <= 0) continue;
      final celsius = value > 45 ? (value - 32) * 5 / 9 : value;
      final key = '${date.year}-${date.month}';
      sums[key] = (sums[key] ?? 0) + celsius;
      counts[key] = (counts[key] ?? 0) + 1;
      meta[key] = [date.year, date.month];
    }

    final result = <MonthlyTemperature>[];
    for (final entry in meta.entries) {
      final avg = sums[entry.key]! / counts[entry.key]!;
      result.add(
        MonthlyTemperature(
          year: entry.value[0],
          month: entry.value[1],
          avgCelsius: double.parse(avg.toStringAsFixed(1)),
        ),
      );
    }
    result.sort(
      (a, b) => a.year != b.year
          ? a.year.compareTo(b.year)
          : a.month.compareTo(b.month),
    );
    return result.length > 12 ? result.sublist(result.length - 12) : result;
  }
}

class CycleDashboardData {
  const CycleDashboardData({
    required this.phase,
    required this.nextPeriod,
    required this.nextPeriodRange,
    required this.ovulation,
    required this.ovulationRange,
    required this.predictionWindowDays,
    required this.ovulationCalibrated,
    required this.cycleDay,
    required this.periodDay,
    required this.cycleRegularity,
    required this.cycleRegularityStatus,
    required this.periodRegularity,
    required this.periodRegularityStatus,
    required this.avgCycleLength,
    required this.avgPeriodDuration,
    required this.totalCycles,
    required this.pregnancyChances,
    required this.expectedDueDate,
    required this.pregnancyWeek,
    required this.trimester,
    required this.isPeriodStarted,
    required this.isOvulationDay,
    required this.expectedPregnancyTestDate,
    this.predictionConfidence = CyclePredictionConfidence.learning,
    this.predictionConfidenceScore = 0,
    this.predictionAccuracy = CyclePredictionAccuracy.empty,
    this.completedCycleCount = 0,
    this.excludedCycleCount = 0,
    this.isPredictionWindowActive = false,
    this.isPeriodLate = false,
    this.daysLate = 0,
    this.possibleMissingLog = false,
    this.ovulationConfirmedByTemperature = false,
    this.temperatureShiftCelsius,
    this.measuredLutealSignals = 0,
    this.patternFlags = const {},
  });

  final String phase;
  final String nextPeriod;
  final String nextPeriodRange;
  final String ovulation;
  final String ovulationRange;
  final int predictionWindowDays;
  final bool ovulationCalibrated;
  final int cycleDay;
  final int periodDay;
  final double cycleRegularity;
  final String cycleRegularityStatus;
  final double periodRegularity;
  final String periodRegularityStatus;
  final int avgCycleLength;
  final int avgPeriodDuration;
  final int totalCycles;
  final String pregnancyChances;
  final String expectedDueDate;
  final int pregnancyWeek;
  final int trimester;
  final bool isPeriodStarted;
  final bool isOvulationDay;
  final String expectedPregnancyTestDate;
  final CyclePredictionConfidence predictionConfidence;
  final double predictionConfidenceScore;
  final CyclePredictionAccuracy predictionAccuracy;
  final int completedCycleCount;
  final int excludedCycleCount;
  final bool isPredictionWindowActive;
  final bool isPeriodLate;
  final int daysLate;
  final bool possibleMissingLog;

  /// True when a basal body temperature shift confirmed ovulation in the
  /// cycle currently running — an observation, not an estimate.
  final bool ovulationConfirmedByTemperature;

  /// How far the confirming temperature rose above the coverline (°C).
  final double? temperatureShiftCelsius;

  /// Number of measured ovulation signals (manual logs + thermal shifts)
  /// backing the personalized luteal phase.
  final int measuredLutealSignals;

  /// Clinically meaningful cycle patterns worth surfacing (prolonged, short,
  /// highly variable or absent cycles). Never a diagnosis.
  final Set<CyclePatternFlag> patternFlags;

  String get periodDisplay =>
      nextPeriodRange.isNotEmpty ? nextPeriodRange : nextPeriod;

  String get ovulationDisplay =>
      ovulationRange.isNotEmpty ? ovulationRange : ovulation;
}

class PredictedSymptom {
  const PredictedSymptom({
    required this.name,
    required this.occurrences,
    required this.accuracy,
  });

  final String name;
  final int occurrences;
  final double accuracy;
}

class GraphAvailability {
  const GraphAvailability({
    required this.trends,
    required this.periods,
    required this.history,
    required this.temperature,
    required this.weight,
    required this.sleep,
    required this.water,
    required this.meditation,
  });

  final bool trends;
  final bool periods;
  final bool history;
  final bool temperature;
  final bool weight;
  final bool sleep;
  final bool water;
  final bool meditation;
}

class CycleReportData {
  const CycleReportData({
    required this.keyMatrix,
    required this.predictionMatrix,
    required this.cycles,
    required this.symptomPatterns,
  });

  final Map<String, dynamic> keyMatrix;
  final Map<String, dynamic> predictionMatrix;
  final List<PeriodsDateRange> cycles;
  final List<SymptomsPatterns> symptomPatterns;
}

/// One month's averaged basal body temperature (°C).
class MonthlyTemperature {
  const MonthlyTemperature({
    required this.year,
    required this.month,
    required this.avgCelsius,
  });

  final int year;
  final int month; // 1..12
  final double avgCelsius;
}

/// Real historical series backing the Analytics charts. Every field is derived
/// from the user's own logged data, so charts reflect reality instead of
/// placeholder values.
class AnalyticsHistory {
  const AnalyticsHistory({
    required this.cycleLengths,
    required this.periodDurations,
    required this.monthlyTemps,
    this.cycleTemperature,
    this.wellness,
  });

  /// Completed cycle lengths (days), oldest → newest. Excludes the ongoing
  /// cycle. Empty when the user has fewer than two completed cycles.
  final List<int> cycleLengths;

  /// Period durations (days) per completed cycle, oldest → newest.
  final List<int> periodDurations;

  /// Up to 12 most recent monthly body-temperature averages, oldest → newest.
  final List<MonthlyTemperature> monthlyTemps;

  /// Temperature curve for the most recent cycle with enough readings, with
  /// the coverline and detected ovulation day when a shift was found.
  final CycleTemperatureSeries? cycleTemperature;

  /// Real mood/energy/sleep scores from the last 60 days of daily logs;
  /// null (or empty) when the user hasn't logged those dimensions.
  final RealWellnessScores? wellness;

  bool get hasCycleHistory => cycleLengths.length >= 2;
  bool get hasPeriodHistory => periodDurations.length >= 2;
  bool get hasTemperature => monthlyTemps.isNotEmpty;

  bool get hasCycleTemperature =>
      (cycleTemperature?.points.length ?? 0) >= 6;

  static const AnalyticsHistory empty = AnalyticsHistory(
    cycleLengths: [],
    periodDurations: [],
    monthlyTemps: [],
  );
}
