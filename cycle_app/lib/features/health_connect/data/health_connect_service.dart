import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cycle/luteal_calibration.dart';
import '../../../core/cycle/ovulation_log_service.dart';
import '../../cycle/data/period_bridge_service.dart';
import '../../../menstrudel/database/repositories/logs_repository.dart';
import '../../../menstrudel/models/flows/flow_enum.dart';
import '../../../menstrudel/models/period_logs/log_day.dart';

enum HealthConnectGroup { cycle, wellness }

class HealthConnectStatus {
  const HealthConnectStatus({
    required this.availability,
    this.cycleGranted = false,
    this.wellnessGranted = false,
    this.historyGranted = false,
    this.cycleGrantedCount = 0,
    this.cyclePermissionCount = 0,
    this.wellnessGrantedCount = 0,
    this.wellnessPermissionCount = 0,
  });

  factory HealthConnectStatus.fromMap(Map<String, dynamic> map) {
    return HealthConnectStatus(
      availability: map['availability']?.toString() ?? 'notSupported',
      cycleGranted: map['cycleGranted'] == true,
      wellnessGranted: map['wellnessGranted'] == true,
      historyGranted: map['historyGranted'] == true,
      cycleGrantedCount: (map['cycleGrantedCount'] as num?)?.toInt() ?? 0,
      cyclePermissionCount: (map['cyclePermissionCount'] as num?)?.toInt() ?? 0,
      wellnessGrantedCount: (map['wellnessGrantedCount'] as num?)?.toInt() ?? 0,
      wellnessPermissionCount:
          (map['wellnessPermissionCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String availability;
  final bool cycleGranted;
  final bool wellnessGranted;
  final bool historyGranted;
  final int cycleGrantedCount;
  final int cyclePermissionCount;
  final int wellnessGrantedCount;
  final int wellnessPermissionCount;

  bool get available => availability == 'available';
  bool get installRequired => availability == 'installRequired';

  bool grantedFor(HealthConnectGroup group) =>
      group == HealthConnectGroup.cycle ? cycleGranted : wellnessGranted;
}

class HealthConnectSyncResult {
  const HealthConnectSyncResult({
    required this.exported,
    required this.imported,
    required this.read,
    required this.errors,
    required this.completedAt,
  });

  final int exported;
  final int imported;
  final int read;
  final List<String> errors;
  final DateTime completedAt;

  bool get ok => errors.isEmpty;
}

/// Foreground-only, opt-in bridge between Lune's local stores and Android
/// Health Connect. This class deliberately has no Firebase, AI, analytics,
/// community, partner, or ad dependency.
class HealthConnectService {
  HealthConnectService({
    MethodChannel? channel,
    FlutterSecureStorage? secureStorage,
  }) : _channel = channel ?? const MethodChannel(_channelName),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _channelName = 'com.lune.app/health_connect';
  static const _cycleEnabledKey = 'health_connect_cycle_enabled_v1';
  static const _wellnessEnabledKey = 'health_connect_wellness_enabled_v1';
  static const _cycleLastSyncKey = 'health_connect_cycle_last_sync_v1';
  static const _wellnessLastSyncKey = 'health_connect_wellness_last_sync_v1';
  static const _cycleCacheKey = 'health_connect_cycle_cache_v1';
  static const _wellnessCacheKey = 'health_connect_wellness_cache_v1';
  static const _ownClientPrefix = 'lune_';

  final MethodChannel _channel;
  final FlutterSecureStorage _secureStorage;

  bool get supportedPlatform => !kIsWeb && Platform.isAndroid;

  Future<HealthConnectStatus> getStatus() async {
    if (!supportedPlatform) {
      return const HealthConnectStatus(availability: 'notSupported');
    }
    final raw = await _channel.invokeMapMethod<String, dynamic>('getStatus');
    return HealthConnectStatus.fromMap(raw ?? const {});
  }

  Future<bool> isEnabled(HealthConnectGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey(group)) ?? false;
  }

  Future<void> setEnabled(HealthConnectGroup group, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey(group), enabled);
  }

  Future<DateTime?> lastSync(HealthConnectGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey(group));
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<bool> requestPermissions(HealthConnectGroup group) async {
    if (!supportedPlatform) return false;
    await _channel.invokeMethod<List<dynamic>>('requestPermissions', {
      'group': group.name,
    });
    final status = await getStatus();
    final granted = status.grantedFor(group);
    await setEnabled(group, granted);
    return granted;
  }

  Future<void> revokeAllPermissions() async {
    if (supportedPlatform) {
      await _channel.invokeMethod<bool>('revokeAllPermissions');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cycleEnabledKey, false);
    await prefs.setBool(_wellnessEnabledKey, false);
  }

  Future<bool> openSettings() async {
    if (!supportedPlatform) return false;
    return await _channel.invokeMethod<bool>('openSettings') ?? false;
  }

  Future<bool> installProvider() async {
    if (!supportedPlatform) return false;
    return await _channel.invokeMethod<bool>('installProvider') ?? false;
  }

  Future<HealthConnectSyncResult> sync(HealthConnectGroup group) async {
    if (!await isEnabled(group)) {
      throw StateError('Health Connect group is paused');
    }
    final status = await getStatus();
    if (!status.grantedFor(group)) {
      throw StateError('Health Connect permissions are incomplete');
    }

    final now = DateTime.now();
    final start = group == HealthConnectGroup.cycle
        ? DateTime(now.year - 1, now.month, now.day)
        : now.subtract(const Duration(days: 30));
    final localRecords = group == HealthConnectGroup.cycle
        ? await _collectCycleExports(start, now)
        : await _collectWellnessExports(start, now);

    final writeRaw =
        await _channel.invokeMapMethod<String, dynamic>('writeData', {
          'records': localRecords,
        }) ??
        const {};
    final readRaw =
        await _channel.invokeMapMethod<String, dynamic>('readData', {
          'group': group.name,
          'start': start.toUtc().toIso8601String(),
          'end': now.add(const Duration(days: 1)).toUtc().toIso8601String(),
        }) ??
        const {};

    final records = (readRaw['records'] as List<dynamic>? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .toList();
    final readErrors = (readRaw['errors'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();
    final writeErrors = (writeRaw['errors'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();

    // Cache uses encrypted platform storage. It is not part of cloud backup,
    // AI context, reports, communities, or analytics.
    await _secureStorage.write(
      key: group == HealthConnectGroup.cycle
          ? _cycleCacheKey
          : _wellnessCacheKey,
      value: jsonEncode(records),
    );

    final external = records
        .where(
          (record) =>
              !(record['clientRecordId']?.toString().startsWith(
                    _ownClientPrefix,
                  ) ??
                  false),
        )
        .toList();
    final imported = group == HealthConnectGroup.cycle
        ? await _importCycle(external)
        : await _importWellness(external);

    final completedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey(group), completedAt.toIso8601String());

    return HealthConnectSyncResult(
      exported: (writeRaw['written'] as num?)?.toInt() ?? 0,
      imported: imported,
      read: records.length,
      errors: [...writeErrors, ...readErrors],
      completedAt: completedAt,
    );
  }

  Future<List<Map<String, dynamic>>> cachedRecords(
    HealthConnectGroup group,
  ) async {
    final raw = await _secureStorage.read(
      key: group == HealthConnectGroup.cycle
          ? _cycleCacheKey
          : _wellnessCacheKey,
    );
    if (raw == null || raw.isEmpty) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _collectCycleExports(
    DateTime start,
    DateTime end,
  ) async {
    final records = <Map<String, dynamic>>[];
    final api = MenstrualCycleWidget.instance;
    if (api == null) return records;

    final rawDays = await MenstrualCycleDbHelper.instance.getPastPeriodDates();
    final periodDays =
        rawDays
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .map(DateUtils.dateOnly)
            .where((day) => !day.isBefore(DateUtils.dateOnly(start)))
            .toList()
          ..sort();
    for (final range in _contiguousRanges(periodDays)) {
      records.add({
        'type': 'period',
        'clientRecordId':
            'lune_period_${_dayKey(range.$1)}_${_dayKey(range.$2)}',
        'start': _instant(range.$1).toIso8601String(),
        'end': _instant(
          range.$2.add(const Duration(days: 1)),
        ).toIso8601String(),
      });
    }

    try {
      final logs = await LogsRepository().readAllLogs();
      for (final log in logs) {
        final day = DateUtils.dateOnly(log.date);
        if (day.isBefore(DateUtils.dateOnly(start)) ||
            log.flow == FlowRate.none) {
          continue;
        }
        if (log.flow == FlowRate.spotting) {
          records.add({
            'type': 'intermenstrualBleeding',
            'clientRecordId': 'lune_spotting_${_dayKey(day)}',
            'time': _instant(day, hour: 12).toIso8601String(),
          });
        } else {
          records.add({
            'type': 'flow',
            'clientRecordId': 'lune_flow_${_dayKey(day)}',
            'time': _instant(day, hour: 12).toIso8601String(),
            'flow': switch (log.flow) {
              FlowRate.light => 1,
              FlowRate.medium => 2,
              FlowRate.heavy => 3,
              _ => 0,
            },
          });
        }
      }
    } catch (error) {
      debugPrint('HealthConnect flow export: $error');
    }

    for (final entry in await OvulationLogService().loadEntries()) {
      if (entry.date.isBefore(start)) continue;
      records.add({
        'type': 'ovulationTest',
        'clientRecordId':
            'lune_ovulation_${entry.type.storageKey}_${_dayKey(entry.date)}',
        'time': _instant(entry.date, hour: 8).toIso8601String(),
        'result': 1,
      });
    }

    final logs = await api.getSymptomsLogReport(startDate: start, endDate: end);
    for (final log in logs) {
      final day = log.logDate;
      if (day == null) continue;
      final temp = _positive(log.bodyTemperature);
      if (temp != null) {
        final celsius = (log.bodyTemperatureUnit ?? '').contains('fahrenheit')
            ? (temp - 32) * 5 / 9
            : temp;
        if (celsius >= 30 && celsius <= 45) {
          records.add({
            'type': 'basalBodyTemperature',
            'clientRecordId': 'lune_bbt_${_dayKey(day)}',
            'time': _instant(day, hour: 7).toIso8601String(),
            'celsius': celsius,
          });
        }
      }
    }
    return records;
  }

  Future<List<Map<String, dynamic>>> _collectWellnessExports(
    DateTime start,
    DateTime end,
  ) async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return const [];
    final records = <Map<String, dynamic>>[];
    final logs = await api.getSymptomsLogReport(startDate: start, endDate: end);
    for (final log in logs) {
      final day = log.logDate;
      if (day == null) continue;

      final weightValue = _positive(log.weight);
      if (weightValue != null) {
        final kilograms = (log.weightUnit ?? '').contains('lb')
            ? weightValue * 0.45359237
            : weightValue;
        if (kilograms <= 1000) {
          records.add({
            'type': 'weight',
            'clientRecordId': 'lune_weight_${_dayKey(day)}',
            'time': _instant(day, hour: 12).toIso8601String(),
            'kilograms': kilograms,
          });
        }
      }

      final waterValue = _positive(log.waterValue);
      if (waterValue != null) {
        final liters = _waterLiters(waterValue, log.waterUnit);
        if (liters > 0 && liters <= 100) {
          final at = _instant(day, hour: 12);
          records.add({
            'type': 'hydration',
            'clientRecordId': 'lune_hydration_${_dayKey(day)}',
            'start': at.toIso8601String(),
            'end': at.add(const Duration(minutes: 5)).toIso8601String(),
            'liters': liters,
          });
        }
      }

      final sleep = _parseSleep(day, log.sleepTime);
      if (sleep != null) {
        records.add({
          'type': 'sleep',
          'clientRecordId': 'lune_sleep_${_dayKey(day)}',
          'start': sleep.$1.toUtc().toIso8601String(),
          'end': sleep.$2.toUtc().toIso8601String(),
        });
      }
    }
    return records;
  }

  Future<int> _importCycle(List<Map<String, dynamic>> records) async {
    var imported = 0;
    final periodDays = <DateTime>[];
    final flowByDay = <DateTime, FlowRate>{};
    final daily = <DateTime, _DailyImport>{};

    for (final record in records) {
      switch (record['type']) {
        case 'period':
          final start = _localTime(record['start']);
          final end = _localTime(record['end']);
          if (start == null || end == null || !end.isAfter(start)) continue;
          for (
            var day = DateUtils.dateOnly(start);
            day.isBefore(DateUtils.dateOnly(end));
            day = day.add(const Duration(days: 1))
          ) {
            periodDays.add(day);
          }
          break;
        case 'flow':
          final time = _localTime(record['time']);
          if (time == null) continue;
          final flow = switch ((record['flow'] as num?)?.toInt()) {
            1 => FlowRate.light,
            2 => FlowRate.medium,
            3 => FlowRate.heavy,
            _ => FlowRate.none,
          };
          if (flow != FlowRate.none) flowByDay[DateUtils.dateOnly(time)] = flow;
          break;
        case 'intermenstrualBleeding':
          final time = _localTime(record['time']);
          if (time != null) {
            flowByDay[DateUtils.dateOnly(time)] = FlowRate.spotting;
          }
          break;
        case 'ovulationTest':
          final time = _localTime(record['time']);
          final value = (record['result'] as num?)?.toInt();
          if (time != null && (value == 1 || value == 2)) {
            final service = OvulationLogService();
            if (!await service.hasLogOn(time)) {
              await service.logDate(time, OvulationLogType.lhPositive);
              imported++;
            }
          }
          break;
        case 'basalBodyTemperature':
          final time = _localTime(record['time']);
          final value = (record['celsius'] as num?)?.toDouble();
          if (time != null && value != null && value >= 30 && value <= 45) {
            daily.update(
              DateUtils.dateOnly(time),
              (old) => old.copyWith(temperature: value),
              ifAbsent: () => _DailyImport(temperature: value),
            );
          }
          break;
      }
    }

    if (periodDays.isNotEmpty) {
      final unique = periodDays.toSet().toList()..sort();
      await MenstrualCycleDbHelper.instance.insertPeriodLog(unique);
      await MenstrualCycleWidget.instance?.calculateLastPeriodDate();
      await PeriodBridgeService.instance.syncWidgetToMenstrudel();
      imported += unique.length;
    }
    imported += await _mergeFlows(flowByDay);
    imported += await _mergeDaily(daily);
    return imported;
  }

  Future<int> _importWellness(List<Map<String, dynamic>> records) async {
    final daily = <DateTime, _DailyImport>{};
    final hydrationByDay = <DateTime, double>{};

    for (final record in records) {
      switch (record['type']) {
        case 'weight':
          final time = _localTime(record['time']);
          final kg = (record['kilograms'] as num?)?.toDouble();
          if (time != null && kg != null && kg > 0 && kg <= 1000) {
            final day = DateUtils.dateOnly(time);
            daily.update(
              day,
              (old) => old.copyWith(weight: kg),
              ifAbsent: () => _DailyImport(weight: kg),
            );
          }
          break;
        case 'hydration':
          final time = _localTime(record['start']);
          final liters = (record['liters'] as num?)?.toDouble();
          if (time != null && liters != null && liters > 0) {
            final day = DateUtils.dateOnly(time);
            hydrationByDay.update(
              day,
              (old) => old + liters,
              ifAbsent: () => liters,
            );
          }
          break;
        case 'sleep':
          final start = _localTime(record['start']);
          final end = _localTime(record['end']);
          if (start != null && end != null && end.isAfter(start)) {
            final day = DateUtils.dateOnly(end);
            daily.update(
              day,
              (old) => old.copyWith(sleepStart: start, sleepEnd: end),
              ifAbsent: () => _DailyImport(sleepStart: start, sleepEnd: end),
            );
          }
          break;
      }
    }

    for (final entry in hydrationByDay.entries) {
      daily.update(
        entry.key,
        (old) => old.copyWith(waterLiters: entry.value),
        ifAbsent: () => _DailyImport(waterLiters: entry.value),
      );
    }
    return _mergeDaily(daily);
  }

  Future<int> _mergeFlows(Map<DateTime, FlowRate> imported) async {
    if (imported.isEmpty) return 0;
    final repo = LogsRepository();
    final existing = await repo.readAllLogs();
    final byDay = {
      for (final log in existing) DateUtils.dateOnly(log.date): log,
    };
    var changed = 0;
    for (final entry in imported.entries) {
      final current = byDay[entry.key];
      if (current == null) {
        await repo.upsertLog(LogDay(date: entry.key, flow: entry.value));
        changed++;
      } else if (current.flow == FlowRate.none) {
        await repo.upsertLog(current.copyWith(flow: entry.value));
        changed++;
      }
    }
    if (changed > 0) {
      await PeriodBridgeService.instance.syncMenstrudelToWidget(
        await repo.readAllLogs(),
      );
    }
    return changed;
  }

  Future<int> _mergeDaily(Map<DateTime, _DailyImport> imported) async {
    final api = MenstrualCycleWidget.instance;
    if (api == null || imported.isEmpty) return 0;
    var changed = 0;
    for (final entry in imported.entries) {
      final existing = await api.getSymptomsData(entry.key);
      final update = entry.value;
      final existingTemp = _positive(existing.bodyTemperature);
      final existingWeight = _positive(existing.weight);
      final existingWater = _positive(existing.waterValue);
      final existingSleep = _parseTimeOfDayPair(existing.sleepTime);

      final useTemp = existingTemp == null && update.temperature != null;
      final useWeight = existingWeight == null && update.weight != null;
      final useWater = existingWater == null && update.waterLiters != null;
      final useSleep =
          existingSleep == null &&
          update.sleepStart != null &&
          update.sleepEnd != null;
      if (!useTemp && !useWeight && !useWater && !useSleep) continue;

      var ok = false;
      await api.saveSymptomsLogs(
        userSymptomsData: existing.symptomData,
        symptomsLogDate: entry.key,
        cycleDay: 0,
        meditationTime: existing.meditationTime ?? '0',
        customNotes: existing.notes ?? '',
        bodyTemperature: useTemp
            ? update.temperature!.toStringAsFixed(2)
            : (existing.bodyTemperature ?? '0'),
        bodyTemperatureUnit: useTemp
            ? BodyTemperatureUnits.celsius
            : _bodyTemperatureUnit(existing.bodyTemperatureUnit),
        weight: useWeight
            ? update.weight!.toStringAsFixed(2)
            : (existing.weight ?? '0'),
        weightUnit: useWeight
            ? WeightUnits.kg
            : _weightUnit(existing.weightUnit),
        waterValue: useWater
            ? update.waterLiters!.toStringAsFixed(2)
            : (existing.waterValue ?? '0'),
        waterUnit: useWater
            ? WaterUnits.liters
            : _waterUnit(existing.waterUnit),
        sleepBedTime: useSleep
            ? TimeOfDay.fromDateTime(update.sleepStart!)
            : existingSleep?.$1,
        sleepWakeUpTime: useSleep
            ? TimeOfDay.fromDateTime(update.sleepEnd!)
            : existingSleep?.$2,
        onSuccess: (_) => ok = true,
        onError: () => ok = false,
      );
      if (ok) changed++;
    }
    // Imported temperatures (thermometers, wearables) are the richest BBT
    // source there is — make them visible to ovulation detection right away.
    if (changed > 0) LutealCalibration.sharedBbtService.invalidate();
    return changed;
  }

  List<(DateTime, DateTime)> _contiguousRanges(List<DateTime> days) {
    if (days.isEmpty) return const [];
    final ranges = <(DateTime, DateTime)>[];
    var start = days.first;
    var end = days.first;
    for (final day in days.skip(1)) {
      if (day.difference(end).inDays == 1) {
        end = day;
      } else {
        ranges.add((start, end));
        start = day;
        end = day;
      }
    }
    ranges.add((start, end));
    return ranges;
  }

  DateTime _instant(DateTime day, {int hour = 0}) =>
      DateTime(day.year, day.month, day.day, hour).toUtc();

  DateTime? _localTime(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    return parsed?.toLocal();
  }

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  double? _positive(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    return value != null && value > 0 ? value : null;
  }

  double _waterLiters(double value, String? unit) {
    final normalized = unit?.toLowerCase() ?? '';
    if (normalized.contains('milliliter') || normalized.endsWith('.ml')) {
      return value / 1000;
    }
    if (normalized.contains('ounce') || normalized.contains('oz')) {
      return value * 0.0295735;
    }
    if (normalized.contains('cup') ||
        (normalized.contains('liter') && value > 5)) {
      return value * 0.24;
    }
    return value;
  }

  (DateTime, DateTime)? _parseSleep(DateTime day, String? raw) {
    final pair = _parseTimeOfDayPair(raw);
    if (pair == null) return null;
    var start = DateTime(
      day.year,
      day.month,
      day.day,
      pair.$1.hour,
      pair.$1.minute,
    );
    var end = DateTime(
      day.year,
      day.month,
      day.day,
      pair.$2.hour,
      pair.$2.minute,
    );
    if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    if (end.difference(start) > const Duration(hours: 24)) return null;
    return (start, end);
  }

  (TimeOfDay, TimeOfDay)? _parseTimeOfDayPair(String? raw) {
    if (raw == null || !raw.contains('T')) return null;
    try {
      final parts = raw.split('T');
      final bed = parts[0].split(':');
      final wake = parts[1].split(':');
      return (
        TimeOfDay(hour: int.parse(bed[0]), minute: int.parse(bed[1])),
        TimeOfDay(hour: int.parse(wake[0]), minute: int.parse(wake[1])),
      );
    } catch (_) {
      return null;
    }
  }

  WeightUnits _weightUnit(String? raw) => WeightUnits.values.firstWhere(
    (value) => raw?.endsWith(value.name) == true,
    orElse: () => WeightUnits.kg,
  );

  WaterUnits _waterUnit(String? raw) => WaterUnits.values.firstWhere(
    (value) => raw?.endsWith(value.name) == true,
    orElse: () => WaterUnits.liters,
  );

  BodyTemperatureUnits _bodyTemperatureUnit(String? raw) =>
      BodyTemperatureUnits.values.firstWhere(
        (value) => raw?.endsWith(value.name) == true,
        orElse: () => BodyTemperatureUnits.celsius,
      );

  String _enabledKey(HealthConnectGroup group) =>
      group == HealthConnectGroup.cycle
      ? _cycleEnabledKey
      : _wellnessEnabledKey;

  String _lastSyncKey(HealthConnectGroup group) =>
      group == HealthConnectGroup.cycle
      ? _cycleLastSyncKey
      : _wellnessLastSyncKey;
}

class _DailyImport {
  const _DailyImport({
    this.temperature,
    this.weight,
    this.waterLiters,
    this.sleepStart,
    this.sleepEnd,
  });

  final double? temperature;
  final double? weight;
  final double? waterLiters;
  final DateTime? sleepStart;
  final DateTime? sleepEnd;

  _DailyImport copyWith({
    double? temperature,
    double? weight,
    double? waterLiters,
    DateTime? sleepStart,
    DateTime? sleepEnd,
  }) {
    return _DailyImport(
      temperature: temperature ?? this.temperature,
      weight: weight ?? this.weight,
      waterLiters: waterLiters ?? this.waterLiters,
      sleepStart: sleepStart ?? this.sleepStart,
      sleepEnd: sleepEnd ?? this.sleepEnd,
    );
  }
}
