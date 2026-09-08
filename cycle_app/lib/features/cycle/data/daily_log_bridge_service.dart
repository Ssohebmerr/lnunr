import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../menstrudel/database/repositories/logs_repository.dart';
import '../../../menstrudel/models/period_logs/log_day.dart';
import '../../../menstrudel/models/period_logs/symptom.dart';
import '../../../menstrudel/models/period_logs/symptom_type_enum.dart';

/// Folds Menstrudel daily-log **symptoms** into the main (widget-package)
/// store, so there is one daily log instead of two.
///
/// [PeriodBridgeService] already mirrors bleeding days between the two stores,
/// but by design it stops there — symptoms and pain levels logged in the old
/// Wellness Hub daily log never reached the main store. That meant analytics,
/// symptom patterns, the doctor report, and the AI context all silently
/// ignored anything logged through that second door. Closing the second door
/// without moving its data would strand it, so this runs once on upgrade.
///
/// Writes go straight to `tblDailyLogs` with **only** the symptom blob, because
/// `insertDailyLog` merges by (logDate, customerId) and leaves untouched
/// columns alone. Going through `saveSymptomsLogs` instead would rewrite every
/// column from its defaults and wipe `cycleDay`, weight, water, temperature,
/// and sleep on any day the user had already logged here — `cycleDay` in
/// particular is what symptom-pattern analysis groups on.
class DailyLogBridgeService {
  DailyLogBridgeService._();

  /// Bumped only if the mapping below changes in a way that needs a re-run.
  static const _migrationKey = 'menstrudel_symptom_merge_v1';

  /// Menstrudel symptom → the widget catalogue id for the same thing.
  ///
  /// Ids come from `defaultSymptomsData` and are stable. Types with no
  /// counterpart (insomnia, and the sleep/water pseudo-symptoms that are
  /// vitals here, plus free-text customs) are carried over as notes instead.
  static const _idByType = <SymptomType, int>{
    SymptomType.moodSwings: 21005, // Mood swings
    SymptomType.depressed: 21017, // Depressed
    SymptomType.cramps: 21048, // Cramps
    SymptomType.tenderBreasts: 21049, // Tender breasts
    SymptomType.headache: 21050, // Headache
    SymptomType.acne: 21051, // Acne
    SymptomType.backPain: 21052, // Backache
    SymptomType.fatigue: 21054, // Fatigue
    SymptomType.bloating: 21075, // Bloating
    SymptomType.nausea: 21077, // Nauseous
  };

  /// "Period cramps" in the Pain category — the closest home for Menstrudel's
  /// 0-10 pain level, which has no numeric equivalent in the main store.
  static const _painSymptomId = 21056;

  /// Pain levels below this are not strong enough to be worth asserting a
  /// pain symptom the user never explicitly ticked.
  static const _painThreshold = 4;

  /// Exposed so a test can assert every hardcoded id still resolves in the
  /// widget catalogue — a stale id would silently drop that symptom.
  @visibleForTesting
  static Map<SymptomType, int> get symptomIdMapping => _idByType;

  @visibleForTesting
  static int get painSymptomId => _painSymptomId;

  @visibleForTesting
  static SymptomsData? catalogueEntry(int id) => _catalogueEntry(id);

  /// Runs the merge at most once per install. Safe to call on every launch.
  static Future<void> migrateOnce(SharedPreferences prefs) async {
    if (prefs.getBool(_migrationKey) == true) return;
    final merged = await mergeMenstrudelSymptoms();
    // A negative result means the stores were not ready — leave the flag unset
    // so the next launch tries again instead of silently skipping forever.
    if (merged < 0) return;
    await prefs.setBool(_migrationKey, true);
    if (merged > 0) {
      debugPrint('DailyLogBridge: merged symptoms for $merged day(s)');
    }
  }

  /// Merges every Menstrudel log that carries symptoms or a pain level.
  ///
  /// Returns the number of days actually written, or -1 when the merge could
  /// not run at all. Idempotent: a day whose symptoms are already present in
  /// the main store is skipped, so re-running writes nothing.
  static Future<int> mergeMenstrudelSymptoms() async {
    final api = MenstrualCycleWidget.instance;
    if (api == null) return -1;

    try {
      final logs = await LogsRepository().readAllLogs();
      if (logs.isEmpty) return 0;

      final db = await MenstrualCycleDbHelper.instance.database;
      if (db == null) return -1;

      final customerId = api.getCustomerId();
      final encryption = Encryption.instance;
      var written = 0;

      for (final log in logs) {
        final mapped = _mapSymptoms(log);
        if (mapped.ids.isEmpty && mapped.unmapped.isEmpty) continue;

        final logDate = defaultDateFormat.format(DateUtils.dateOnly(log.date));
        final existing = await db.query(
          MenstrualCycleDbHelper.tableDailyLogs,
          where: '${MenstrualCycleDbHelper.columnLogDate} = ? '
              'AND ${MenstrualCycleDbHelper.columnCustomerId} = ?',
          whereArgs: [logDate, customerId],
        );
        final row = existing.isEmpty ? null : existing.first;

        final current = _decodeSymptoms(
          encryption,
          row?[MenstrualCycleDbHelper.columnUserEncryptData] as String?,
        );
        final currentIds =
            current.map((s) => s.symptomId).whereType<int>().toSet();

        final newIds = mapped.ids.difference(currentIds);
        final currentNotes = encryption
            .decrypt(row?[MenstrualCycleDbHelper.columnNotes] as String?);
        final noteAddition = _noteAddition(mapped.unmapped, currentNotes);

        if (newIds.isEmpty && noteAddition == null) continue;

        final merged = [...current];
        for (final id in newIds) {
          final catalogue = _catalogueEntry(id);
          if (catalogue != null) merged.add(catalogue);
        }

        final data = <String, dynamic>{
          MenstrualCycleDbHelper.columnCustomerId: customerId,
          MenstrualCycleDbHelper.columnLogDate: logDate,
          MenstrualCycleDbHelper.columnUserEncryptData: encryption
              .encrypt(json.encode(merged.map((s) => s.toJson()).toList())),
        };
        if (noteAddition != null) {
          data[MenstrualCycleDbHelper.columnNotes] =
              encryption.encrypt(noteAddition);
        }
        if (row == null) {
          // Brand-new row: fill the columns the log form would have written so
          // reads that decrypt them unconditionally do not hit a null.
          data.addAll(_defaultsFor(encryption));
          data[MenstrualCycleDbHelper.columnCycleDay] =
              await _cycleDayFor(logDate);
        }

        await MenstrualCycleDbHelper.instance
            .insertDailyLog(data, logDate, customerId);
        written++;
      }

      return written;
    } catch (e, st) {
      debugPrint('DailyLogBridge: symptom merge failed: $e\n$st');
      return -1;
    }
  }

  /// Splits one Menstrudel log into catalogue ids and leftover free text.
  static ({Set<int> ids, List<String> unmapped}) _mapSymptoms(LogDay log) {
    final ids = <int>{};
    final unmapped = <String>[];

    for (final symptom in log.symptoms) {
      final id = _idByType[symptom.type];
      if (id != null) {
        ids.add(id);
      } else {
        final name = _readableName(symptom);
        if (name.isNotEmpty) unmapped.add(name);
      }
    }

    final pain = log.painLevel;
    if (pain != null && pain >= _painThreshold) ids.add(_painSymptomId);

    return (ids: ids, unmapped: unmapped);
  }

  static String _readableName(Symptom symptom) {
    if (symptom.type == SymptomType.custom) return symptom.customName.trim();
    // sleep / water are vitals here, not symptoms — nothing to carry over.
    if (symptom.type == SymptomType.sleep ||
        symptom.type == SymptomType.water) {
      return '';
    }
    return symptom.type.name;
  }

  /// Appends the names that have no catalogue entry to the day's notes,
  /// skipping anything already mentioned so re-runs stay a no-op.
  static String? _noteAddition(List<String> unmapped, String currentNotes) {
    if (unmapped.isEmpty) return null;
    final lower = currentNotes.toLowerCase();
    final missing = unmapped
        .where((n) => !lower.contains(n.toLowerCase()))
        .toSet()
        .toList();
    if (missing.isEmpty) return null;
    final addition = missing.join(', ');
    return currentNotes.trim().isEmpty
        ? addition
        : '${currentNotes.trim()}, $addition';
  }

  static List<SymptomsData> _decodeSymptoms(
    Encryption encryption,
    String? encrypted,
  ) {
    final raw = encryption.decrypt(encrypted).trim();
    if (raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => SymptomsData.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      // A corrupt blob must not cost the user the symptoms we are adding, but
      // it also must not be silently overwritten — skip the day instead.
      return [];
    }
  }

  /// Looks the id up in the widget's own catalogue so the stored name matches
  /// what the log form would have written, in the user's current language.
  static SymptomsData? _catalogueEntry(int id) {
    for (final category in defaultSymptomsData) {
      for (final symptom in category.symptomsData ?? const <SymptomsData>[]) {
        if (symptom.symptomId == id) {
          return SymptomsData(
            symptomId: symptom.symptomId,
            symptomName: symptom.symptomName,
            isSelected: true,
            phaseIds: symptom.phaseIds,
          );
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _defaultsFor(Encryption encryption) => {
        MenstrualCycleDbHelper.columnMeditationTime: encryption.encrypt('0'),
        MenstrualCycleDbHelper.columnSleepTime: encryption.encrypt('0'),
        MenstrualCycleDbHelper.columnWater: encryption.encrypt('0'),
        MenstrualCycleDbHelper.columnWaterUnit:
            encryption.encrypt(WaterUnits.liters.toString()),
        MenstrualCycleDbHelper.columnWeight: encryption.encrypt('0'),
        MenstrualCycleDbHelper.columnWeightUnit:
            encryption.encrypt(WeightUnits.kg.toString()),
        MenstrualCycleDbHelper.columnBodyTemperature: encryption.encrypt('0'),
        MenstrualCycleDbHelper.columnBodyTemperatureUnit:
            encryption.encrypt(BodyTemperatureUnits.celsius.toString()),
        MenstrualCycleDbHelper.columnCreatedDateTime:
            currentDateFormat.format(DateTime.now()),
        MenstrualCycleDbHelper.columnIsCustomLog: '1',
      };

  /// Same day-of-cycle the log form stores, so symptom-pattern analysis (which
  /// groups by cycle day) can see these entries.
  static Future<int> _cycleDayFor(String logDate) async {
    try {
      final dbHelper = MenstrualCycleDbHelper.instance;
      final lastPeriodDay =
          await dbHelper.getLastPeriodDateFromInputDate(logDate);
      if (lastPeriodDay.isEmpty) return 0;
      final difference =
          DateTime.parse(logDate).difference(DateTime.parse(lastPeriodDay)).inDays;
      return difference < 0 ? 0 : difference + 1;
    } catch (_) {
      return 0;
    }
  }
}
