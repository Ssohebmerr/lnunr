import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

import '../../menstrudel/models/birth_control/pills/pill_status_enum.dart';
import '../../menstrudel_integration/menstrudel_init.dart';

/// Aggregates anonymized data from every Wellness Hub module (مركز العناية)
/// into a single map for [HealthSnapshot.wellnessHub].
class WellnessHubCollector {
  WellnessHubCollector._();

  static Future<Map<String, dynamic>> collect() async {
    final parts = await Future.wait([
      _collectPills(),
      _collectSanitary(),
      _collectIntimacy(),
      _collectLarc(),
      _collectDailyVitals(),
    ]);

    final hub = <String, dynamic>{};
    for (final part in parts) {
      hub.addAll(part);
    }
    return hub;
  }

  static Future<Map<String, dynamic>> _collectPills() async {
    final repo = MenstrudelInit.pillsRepository;
    if (repo == null) return const {};

    try {
      final regimen = await repo.readActivePillRegimen();
      if (regimen == null) {
        return {
          'birthControlPills': {'active': false},
        };
      }

      final regimenId = regimen.id;
      if (regimenId == null) {
        return {
          'birthControlPills': {'active': false},
        };
      }

      final intakes = await repo.readIntakesForRegimen(regimenId);
      final since7 = DateTime.now().subtract(const Duration(days: 7));
      final recent =
          intakes.where((i) => !i.scheduledDate.isBefore(since7)).toList();

      final taken = recent
          .where((i) => i.status == PillIntakeStatus.taken)
          .length;
      final skipped = recent
          .where((i) => i.status == PillIntakeStatus.skipped)
          .length;
      final late =
          recent.where((i) => i.status == PillIntakeStatus.late).length;

      return {
        'birthControlPills': {
          'active': true,
          'regimenName': regimen.name,
          'cycleActivePills': regimen.activePills,
          'cyclePlaceboPills': regimen.placeboPills,
          'takenLast7Days': taken,
          'skippedLast7Days': skipped,
          'lateLast7Days': late,
          'scheduledLast7Days': recent.length,
        },
      };
    } catch (_) {
      return const {};
    }
  }

  static Future<Map<String, dynamic>> _collectSanitary() async {
    final repo = MenstrudelInit.sanitaryRepository;
    if (repo == null) return const {};

    try {
      final active = await repo.getActiveEntry();
      final all = await repo.getAllLogs();
      final since30 = DateTime.now().subtract(const Duration(days: 30));
      final recent = all.where((e) => !e.logTime.isBefore(since30)).toList();

      final typeCounts = <String, int>{};
      for (final entry in recent) {
        final key = entry.type.name;
        typeCounts[key] = (typeCounts[key] ?? 0) + 1;
      }

      return {
        'sanitaryProducts': {
          'hasActiveProduct': active != null,
          if (active != null) 'activeProductType': active.type.name,
          'logsLast30Days': recent.length,
          if (typeCounts.isNotEmpty) 'usageByTypeLast30Days': typeCounts,
        },
      };
    } catch (_) {
      return const {};
    }
  }

  /// Privacy: only aggregate counts — no dates or partner details.
  static Future<Map<String, dynamic>> _collectIntimacy() async {
    final repo = MenstrudelInit.sexRepository;
    if (repo == null) return const {};

    try {
      final all = await repo.getAllLogs();
      final since30 = DateTime.now().subtract(const Duration(days: 30));
      final count =
          all.where((e) => !e.dateTime.isBefore(since30)).length;

      if (count == 0) return const {};

      return {
        'intimacy': {
          'loggedEntriesLast30Days': count,
        },
      };
    } catch (_) {
      return const {};
    }
  }

  static Future<Map<String, dynamic>> _collectLarc() async {
    final repo = MenstrudelInit.larcRepository;
    if (repo == null) return const {};

    try {
      final all = await repo.getAllLogs();
      if (all.isEmpty) return const {};

      final since90 = DateTime.now().subtract(const Duration(days: 90));
      final recent90 = all.where((e) => !e.date.isBefore(since90)).toList();
      final latest = all.first;

      return {
        'reversibleContraceptive': {
          'totalLogs': all.length,
          'latestType': latest.type.name,
          'daysSinceLastLog': DateTime.now().difference(latest.date).inDays,
          'logsLast90Days': recent90.length,
        },
      };
    } catch (_) {
      return const {};
    }
  }

  static Future<Map<String, dynamic>> _collectDailyVitals() async {
    final widget = MenstrualCycleWidget.instance;
    if (widget == null) return const {};

    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final logs = await widget.getSymptomsLogReport(
        startDate: start,
        endDate: end,
      );

      if (logs.isEmpty) return const {};

      String? latestWeight;
      String? latestTemp;
      final waterValues = <double>[];
      var sleepLogDays = 0;
      var meditationDays = 0;
      var vitalsLogDays = 0;

      for (final day in logs) {
        var hasVital = false;

        final weight = day.weight?.trim();
        if (weight != null && weight.isNotEmpty) {
          latestWeight = '$weight ${day.weightUnit ?? ''}'.trim();
          hasVital = true;
        }

        final temp = day.bodyTemperature?.trim();
        if (temp != null && temp.isNotEmpty) {
          latestTemp =
              '$temp ${day.bodyTemperatureUnit ?? ''}'.trim();
          hasVital = true;
        }

        final water = day.waterValue?.trim();
        if (water != null && water.isNotEmpty) {
          final parsed = double.tryParse(water);
          if (parsed != null) waterValues.add(parsed);
          hasVital = true;
        }

        if (day.sleepTime != null && day.sleepTime!.trim().isNotEmpty) {
          sleepLogDays++;
          hasVital = true;
        }

        if (day.meditationTime != null &&
            day.meditationTime!.trim().isNotEmpty) {
          meditationDays++;
          hasVital = true;
        }

        if (hasVital) vitalsLogDays++;
      }

      if (vitalsLogDays == 0) return const {};

      final vitals = <String, dynamic>{
        'vitalsLogDaysLast30': vitalsLogDays,
        'sleepLoggedDaysLast30': sleepLogDays,
        'meditationLoggedDaysLast30': meditationDays,
      };

      if (latestWeight != null) vitals['latestWeight'] = latestWeight;
      if (latestTemp != null) vitals['latestBodyTemperature'] = latestTemp;
      if (waterValues.isNotEmpty) {
        final avg = waterValues.reduce((a, b) => a + b) / waterValues.length;
        vitals['avgWaterLast30Days'] =
            double.parse(avg.toStringAsFixed(1));
        vitals['waterUnit'] = logs
                .firstWhere(
                  (d) =>
                      d.waterValue != null && d.waterValue!.trim().isNotEmpty,
                  orElse: () => logs.first,
                )
                .waterUnit ??
            '';
      }

      return {'dailyVitals': vitals};
    } catch (_) {
      return const {};
    }
  }
}
