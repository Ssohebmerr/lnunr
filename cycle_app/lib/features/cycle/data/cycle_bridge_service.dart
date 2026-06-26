import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:menstrual_cycle_widget/ui/model/symptoms_patterns.dart';

import '../../../core/security/cycle_encryption_keys.dart';

/// Bridges Cycle Aura app with menstrual_cycle_widget package APIs.
class CycleBridgeService {
  MenstrualCycleWidget get _api {
    final api = MenstrualCycleWidget.instance;
    if (api == null) {
      throw StateError('MenstrualCycleWidget is not initialized');
    }
    return api;
  }

  /// Link Firebase UID to widget customerId for encrypted local storage.
  Future<void> linkAuthenticatedUser(User? user) async {
    final customerId = user != null
        ? CycleEncryptionKeys.customerIdFromUid(user.uid)
        : 'local_user';
    await _api.updateConfiguration(
      cycleLength: _api.getCycleLength(),
      periodDuration: _api.getPeriodDuration(),
      customerId: customerId,
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
      customerId: customerId ?? 'local_user',
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

  static const supportedLanguageCodes = [
    'en', 'ar',
  ];

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

  Future<CycleDashboardData> loadDashboard() async {
    return CycleDashboardData(
      phase: await _api.getCurrentPhaseName(),
      nextPeriod: await _api.getNextPredictedPeriodDate(),
      ovulation: await _api.getNextOvulationDate(),
      cycleDay: await _api.getCurrentCycleDay(),
      periodDay: await _api.getCurrentPeriodDay(),
      cycleRegularity: await _api.getCycleRegularityScore(),
      cycleRegularityStatus: await _api.getCycleRegularityScoreStatus(),
      periodRegularity: await _api.getPeriodRegularityScore(),
      periodRegularityStatus: await _api.getPeriodRegularityScoreStatus(),
      avgCycleLength: await _api.getAvgCycleLength(),
      avgPeriodDuration: await _api.getAvgPeriodDuration(),
      totalCycles: await _api.getTotalNumberOfCycle(),
      pregnancyChances: await _api.getPregnancyChances(),
      expectedDueDate: await _api.getExpectedDueDate(),
      pregnancyWeek: await _api.getCurrentPregnancyWeek(),
      trimester: await _api.getCurrentTrimester(),
      isPeriodStarted: await _api.isPeriodStarted(),
      isOvulationDay: await _api.isOvulationDay(),
      expectedPregnancyTestDate: await _api.getExpectedPregnancyTestDate(),
    );
  }

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
      _api.hasCycleTrendsGraphData(),
      _api.hasPeriodGraphData(),
      _api.hasCycleHistoryGraphData(),
      _api.hasBodyTemperatureGraphData(),
      _api.hasWeightGraphData(),
      _api.hasSleepGraphData(),
      _api.hasWaterGraphData(),
      _api.hasMeditationGraphData(),
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
    final keyMatrix =
        Map<String, dynamic>.from(raw['key_matrix'] as Map? ?? {});
    final predictionMatrix =
        Map<String, dynamic>.from(raw['prediction_matrix'] as Map? ?? {});
    final cycleRaw = raw['cycle_summary'] as List? ?? [];
    final cycles = <PeriodsDateRange>[];
    for (final item in cycleRaw) {
      if (item is! Map) continue;
      try {
        cycles.add(
          PeriodsDateRange.fromJson(Map<String, dynamic>.from(item)),
        );
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
}

class CycleDashboardData {
  const CycleDashboardData({
    required this.phase,
    required this.nextPeriod,
    required this.ovulation,
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
  });

  final String phase;
  final String nextPeriod;
  final String ovulation;
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
