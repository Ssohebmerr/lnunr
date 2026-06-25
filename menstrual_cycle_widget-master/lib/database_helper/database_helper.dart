import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../menstrual_cycle_widget.dart';

class MenstrualCycleDbHelper {
  static const _databaseName = "MenstrualCycleAppDatabase.db";
  static const _databaseVersion = 4;

  /// Common Columns
  static const String columnID = "id";
  static const String columnCreatedDateTime = "createdAt";
  static const String columnCustomerId = "customerId";

  /// New merged table (replaces 3 old tables)
  static const String tableDailyLogs = "tblDailyLogs";

  // --- Old table names kept for migration ---
  static const String oldSymptomsTable = "tblDailyUserSymptomsLogs";
  static const String oldPeriodsTable = "tblUserPeriodsLogs";
  static const String oldConfigTable = "tblCurrentUserDetails";

  /// Log date (YYYY-MM-DD) or '__CONFIG__' for user config row
  static const String columnLogDate = "logDate";
  static const String columnCycleDay = "cycleDay";

  // Period (was in tblUserPeriodsLogs)
  static const String columnIsPeriodDay = "isPeriodDay";

  // Symptoms data (was in tblDailyUserSymptomsLogs)
  static const String columnUserEncryptData = "symptomData";
  static const String columnMeditationTime = "meditationTime";
  static const String columnSleepTime = "sleepTime";
  static const String columnBodyTemperatureUnit = "bodyTemperatureUnit";
  static const String columnWaterUnit = "waterUnit";
  static const String columnWeightUnit = "weightUnit";
  static const String columnWater = "waterValue";
  static const String columnNotes = "notes";
  static const String columnWeight = "weight";
  static const String columnIsCustomLog = "isCustomLog";
  static const String columnBodyTemperature = "bodyTemperature";

  // User config (was in tblCurrentUserDetails)
  static const String columnCycleLength = "cycleLength";
  static const String columnPeriodDuration = "periodDuration";

  /// Backward-compatible aliases for old code that references old table names
  static const String tableDailyUserSymptomsLogsData = tableDailyLogs;
  static const String tableUserPeriodsLogsData = tableDailyLogs;

  /// Special logDate value for the user config row
  static const String _configRowDate = "__CONFIG__";

  static const String createTableDailyLogs = """
    CREATE TABLE $tableDailyLogs (
      $columnID INTEGER PRIMARY KEY,
      $columnCustomerId TEXT DEFAULT '0',
      $columnLogDate TEXT,
      $columnCycleDay INTEGER,
      $columnIsPeriodDay INTEGER DEFAULT 0,
      $columnUserEncryptData TEXT,
      $columnMeditationTime TEXT,
      $columnSleepTime TEXT,
      $columnBodyTemperatureUnit TEXT,
      $columnWaterUnit TEXT,
      $columnWeightUnit TEXT,
      $columnWater TEXT,
      $columnNotes TEXT,
      $columnWeight TEXT,
      $columnBodyTemperature TEXT,
      $columnIsCustomLog TEXT DEFAULT '0',
      $columnCycleLength INTEGER,
      $columnPeriodDuration INTEGER,
      $columnCreatedDateTime TEXT,
      UNIQUE($columnCustomerId, $columnLogDate)
    )
  """;

  MenstrualCycleDbHelper._privateConstructor();

  static final MenstrualCycleDbHelper instance =
      MenstrualCycleDbHelper._privateConstructor();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(createTableDailyLogs);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 4) {
        // 1. Create new table
        await db.execute(createTableDailyLogs);

        // 2. Migrate symptoms data from old table
        final symptomsRows = await db.rawQuery(
            "SELECT * FROM $oldSymptomsTable");
        for (final row in symptomsRows) {
          await db.insert(tableDailyLogs, {
            columnCustomerId: row[columnCustomerId],
            columnLogDate: row[columnLogDate],
            columnCycleDay: row[columnCycleDay] ?? 0,
            columnIsPeriodDay: 0,
            columnUserEncryptData: row[columnUserEncryptData],
            columnMeditationTime: row[columnMeditationTime] ?? "",
            columnSleepTime: row[columnSleepTime] ?? "",
            columnBodyTemperatureUnit: row[columnBodyTemperatureUnit] ?? "",
            columnWaterUnit: row[columnWaterUnit] ?? "",
            columnWeightUnit: row[columnWeightUnit] ?? "",
            columnWater: row[columnWater] ?? "",
            columnNotes: row[columnNotes] ?? "",
            columnWeight: row[columnWeight] ?? "",
            columnBodyTemperature: row[columnBodyTemperature] ?? "",
            columnIsCustomLog: row[columnIsCustomLog] ?? "0",
            columnCycleLength: null,
            columnPeriodDuration: null,
            columnCreatedDateTime: row[columnCreatedDateTime],
          });
        }

        // 3. Migrate period data from old table
        final periodRows = await db.rawQuery(
            "SELECT * FROM $oldPeriodsTable");
        for (final row in periodRows) {
          String? customerId = row[columnCustomerId] as String?;
          String? periodEncrypted = row["periodDate"] as String?;
          if (customerId == null || periodEncrypted == null) continue;

          String decryptedDate = Encryption.instance.decrypt(periodEncrypted);
          await db.insert(tableDailyLogs, {
            columnCustomerId: customerId,
            columnLogDate: decryptedDate,
            columnCycleDay: null,
            columnIsPeriodDay: 1,
            columnUserEncryptData: null,
            columnMeditationTime: null,
            columnSleepTime: null,
            columnBodyTemperatureUnit: null,
            columnWaterUnit: null,
            columnWeightUnit: null,
            columnWater: null,
            columnNotes: null,
            columnWeight: null,
            columnBodyTemperature: null,
            columnIsCustomLog: "0",
            columnCycleLength: null,
            columnPeriodDuration: null,
            columnCreatedDateTime: null,
          });
        }

        // 4. Migrate user config from old table
        final configRows = await db.rawQuery(
            "SELECT * FROM $oldConfigTable");
        for (final row in configRows) {
          await db.insert(tableDailyLogs, {
            columnCustomerId: row[columnCustomerId],
            columnLogDate: _configRowDate,
            columnCycleDay: null,
            columnIsPeriodDay: 0,
            columnUserEncryptData: null,
            columnMeditationTime: null,
            columnSleepTime: null,
            columnBodyTemperatureUnit: null,
            columnWaterUnit: null,
            columnWeightUnit: null,
            columnWater: null,
            columnNotes: null,
            columnWeight: null,
            columnBodyTemperature: null,
            columnIsCustomLog: "0",
            columnCycleLength: row[columnCycleLength],
            columnPeriodDuration: row[columnPeriodDuration],
            columnCreatedDateTime: null,
          });
        }
      }
    } catch (_) {}
  }

  // ======================== DAILY LOGS ========================

  /// Insert or update daily log (symptoms + period). Merges logDate + customerId unique.
  Future<int> insertDailyLog(
      Map<String, dynamic> data, String logDate, String customerId) async {
    Database? db = await instance.database;

    return await db!.transaction((txn) async {
      // Check if a row already exists for this date + customer
      final List<Map<String, dynamic>> existing = await txn.rawQuery(
          "SELECT * FROM $tableDailyLogs WHERE $columnLogDate = ? AND $columnCustomerId = ?",
          [logDate, customerId]);

      if (existing.isNotEmpty) {
        // Merge: update existing row with new data (don't overwrite period flag)
        final existingRow = existing.first;

        // Keep existing period flag if the new data doesn't specify it
        int periodFlag = data[columnIsPeriodDay] ?? existingRow[columnIsPeriodDay] ?? 0;

        Map<String, dynamic> updateData = {};
        for (var key in data.keys) {
          if (key != columnID && key != columnCustomerId && key != columnLogDate) {
            updateData[key] = data[key];
          }
        }
        updateData[columnIsPeriodDay] = periodFlag;

        await txn.update(tableDailyLogs, updateData,
            where: "$columnLogDate = ? AND $columnCustomerId = ?",
            whereArgs: [logDate, customerId]);
        return existingRow[columnID] as int;
      } else {
        return await txn.insert(tableDailyLogs, data);
      }
    });
  }

  /// Mark specific dates as period days (creates or updates daily logs)
  Future<int> insertPeriodLog(List<DateTime> selectedPeriodsDate) async {
    final mInstance = MenstrualCycleWidget.instance!;
    String customerId = mInstance.getCustomerId();
    Database? db = await instance.database;

    for (final date in selectedPeriodsDate) {
      String dateStr = CalenderDateUtils.dateDayFormat(date);
      final List<Map<String, dynamic>> existing = await db!.rawQuery(
          "SELECT * FROM $tableDailyLogs WHERE $columnLogDate = ? AND $columnCustomerId = ?",
          [dateStr, customerId]);

      if (existing.isNotEmpty) {
        await db.update(tableDailyLogs, {columnIsPeriodDay: 1},
            where: "$columnLogDate = ? AND $columnCustomerId = ?",
            whereArgs: [dateStr, customerId]);
      } else {
        await db.insert(tableDailyLogs, {
          columnCustomerId: customerId,
          columnLogDate: dateStr,
          columnIsPeriodDay: 1,
          columnCycleDay: null,
          columnUserEncryptData: null,
          columnMeditationTime: null,
          columnSleepTime: null,
          columnBodyTemperatureUnit: null,
          columnWaterUnit: null,
          columnWeightUnit: null,
          columnWater: null,
          columnNotes: null,
          columnWeight: null,
          columnBodyTemperature: null,
          columnIsCustomLog: "0",
          columnCycleLength: null,
          columnPeriodDuration: null,
          columnCreatedDateTime: CalenderDateUtils.fullFormatWithTime.format(DateTime.now()),
        });
      }
    }
    return 0;
  }

  /// Insert or update period logs (for restore)
  Future<void> insertOrUpdatePeriodLog(List<dynamic> selectedPeriodsDate) async {
    final mInstance = MenstrualCycleWidget.instance!;
    String customerId = mInstance.getCustomerId();
    Database? db = await instance.database;

    for (final dateStr in selectedPeriodsDate) {
      String dateStrParsed = dateStr is DateTime
          ? CalenderDateUtils.dateDayFormat(dateStr)
          : dateStr.toString();

      final List<Map<String, dynamic>> existing = await db!.rawQuery(
          "SELECT * FROM $tableDailyLogs WHERE $columnLogDate = ? AND $columnCustomerId = ?",
          [dateStrParsed, customerId]);

      if (existing.isNotEmpty) {
        await db.update(tableDailyLogs, {columnIsPeriodDay: 1},
            where: "$columnLogDate = ? AND $columnCustomerId = ?",
            whereArgs: [dateStrParsed, customerId]);
      } else {
        await db.insert(tableDailyLogs, {
          columnCustomerId: customerId,
          columnLogDate: dateStrParsed,
          columnIsPeriodDay: 1,
        });
      }
    }
  }

  /// Check if a date is marked as period day
  Future<bool> isPeriodDateFound(DateTime periodDate) async {
    final mInstance = MenstrualCycleWidget.instance!;
    String customerId = mInstance.getCustomerId();
    String dateStr = CalenderDateUtils.dateDayFormat(periodDate);
    Database? db = await instance.database;

    final List<Map<String, dynamic>> result = await db!.rawQuery(
        "SELECT COUNT(*) as cnt FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnLogDate = ? AND $columnIsPeriodDay = 1",
        [customerId, dateStr]);

    int? count = Sqflite.firstIntValue(result);
    return (count ?? 0) > 0;
  }

  // ======================== PERIOD DATES ========================

  /// Return last period start date
  Future<String> getLastPeriodDateFromInputDate(String logDate) async {
    final mInstance = MenstrualCycleWidget.instance!;
    String customerId = mInstance.getCustomerId();
    String lastPeriodsDate = "";
    Database? db = await instance.database;

    final List<Map<String, dynamic>> queryResponse = await db!.rawQuery(
        "SELECT * FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 1 ORDER BY $columnLogDate ASC",
        [customerId]);

    List<DateTime> allPeriodDates = queryResponse
        .map((r) => DateTime.parse(r[columnLogDate] as String))
        .toList();

    if (allPeriodDates.isEmpty) return "";

    // Group consecutive dates into periods, find start dates
    List<DateTime> periodStartDates = [];
    periodStartDates.add(allPeriodDates[0]);
    for (int i = 1; i < allPeriodDates.length; i++) {
      int gap = allPeriodDates[i]
          .difference(allPeriodDates[i - 1])
          .inDays;
      if (gap > 2) {
        periodStartDates.add(allPeriodDates[i]);
      }
    }

    DateTime inputDate = DateTime.parse(logDate);
    for (final startDate in periodStartDates) {
      if (inputDate == startDate || inputDate.isAfter(startDate)) {
        lastPeriodsDate = CalenderDateUtils.dateDayFormat(startDate);
      }
    }

    return lastPeriodsDate;
  }

  /// Return most recent period start date
  Future<String> getLastPeriodDate() async {
    final mInstance = MenstrualCycleWidget.instance!;
    String customerId = mInstance.getCustomerId();
    String lastPeriodsDate = "";
    Database? db = await instance.database;

    final List<Map<String, dynamic>> queryResponse = await db!.rawQuery(
        "SELECT * FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 1 ORDER BY $columnLogDate DESC",
        [customerId]);

    List<DateTime> allPeriodDates = queryResponse
        .map((r) => DateTime.parse(r[columnLogDate] as String))
        .toList();

    if (allPeriodDates.isEmpty) return "";

    allPeriodDates.sort((a, b) => b.compareTo(a));

    if (allPeriodDates.length == 1) {
      return CalenderDateUtils.dateDayFormat(allPeriodDates[0]);
    }

    int oneDaysCount = 0;
    for (int index = 1; index < allPeriodDates.length; index++) {
      int inDays = allPeriodDates[index - 1]
          .difference(allPeriodDates[index])
          .inDays;
      if (inDays > 2) {
        lastPeriodsDate =
            CalenderDateUtils.dateDayFormat(allPeriodDates[index - 1]);
        break;
      } else if (inDays == 1) {
        oneDaysCount++;
      }
    }

    if (lastPeriodsDate.isEmpty &&
        oneDaysCount == allPeriodDates.length - 1) {
      lastPeriodsDate = CalenderDateUtils.dateDayFormat(
          allPeriodDates[allPeriodDates.length - 1]);
    }

    return lastPeriodsDate;
  }

  /// Return all period dates
  Future<List<String>> getPastPeriodDates() async {
    final mInstance = MenstrualCycleWidget.instance!;
    Database? db = await instance.database;
    String customerId = mInstance.getCustomerId();
    List<String> periodDays = [];

    final List<Map<String, dynamic>> queryResponse = await db!.rawQuery(
        "SELECT $columnLogDate FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 1 ORDER BY $columnLogDate ASC",
        [customerId]);

    for (final row in queryResponse) {
      periodDays.add(row[columnLogDate] as String);
    }

    return periodDays;
  }

  // ======================== USER CONFIG ========================

  /// Save or update user config (cycle length, period duration)
  Future<int> insertCurrentUserDetails({
    int? periodDuration,
    int? cycleLength,
    String? customerId,
  }) async {
    Database? db = await instance.database;

    // Delete existing config row for this customer
    await db!.rawDelete(
        "DELETE FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnLogDate = ?",
        [customerId, _configRowDate]);

    Map<String, dynamic> data = {
      columnCustomerId: customerId,
      columnLogDate: _configRowDate,
      columnCycleLength: cycleLength,
      columnPeriodDuration: periodDuration,
      columnIsPeriodDay: 0,
    };

    return await db.insert(tableDailyLogs, data);
  }

  /// Load user config from database into memory
  void setCurrentUserDetail() async {
    Database? db = await instance.database;

    final List<Map<String, dynamic>> queryResponse = await db!.rawQuery(
        "SELECT * FROM $tableDailyLogs WHERE $columnLogDate = ?",
        [_configRowDate]);

    if (queryResponse.isNotEmpty) {
      for (int i = 0; i < queryResponse.length; i++) {
        MenstrualCycleWidget.instance!.setCurrentUserData(
            queryResponse[i][columnCustomerId],
            queryResponse[i][columnCycleLength],
            queryResponse[i][columnPeriodDuration]);
      }
    }
  }

  // ======================== CLEAR DATA ========================

  /// Delete period flags for a customer
  Future<int> clearPeriodLog(String customerId) async {
    Database? db = await instance.database;

    // Set isPeriodDay = 0 for all period days (keep symptom data)
    int updated = await db!.rawUpdate(
        "UPDATE $tableDailyLogs SET $columnIsPeriodDay = 0 WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 1",
        [customerId]);

    // Delete rows that have no symptoms and no longer period days (cleanup)
    await db.rawDelete(
        "DELETE FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 0 AND ($columnUserEncryptData IS NULL OR $columnUserEncryptData = '')",
        [customerId]);

    return updated;
  }

  /// Delete period flags after a specific date
  Future<int> clearPeriodLogAfterSpecificDate(
      String customerId, String lastLogDate) async {
    Database? db = await instance.database;

    await db!.rawUpdate(
        "UPDATE $tableDailyLogs SET $columnIsPeriodDay = 0 WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 1 AND $columnLogDate > ?",
        [customerId, lastLogDate]);

    // Cleanup empty rows
    await db.rawDelete(
        "DELETE FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnIsPeriodDay = 0 AND ($columnUserEncryptData IS NULL OR $columnUserEncryptData = '') AND $columnLogDate != ?",
        [customerId, _configRowDate]);

    return 1;
  }

  /// Delete all symptoms data for a customer
  Future<int> clearSymptomsLog(String customerId) async {
    Database? db = await instance.database;

    // Reset symptoms fields but keep period + config data
    return await db!.rawUpdate(
      "UPDATE $tableDailyLogs SET $columnUserEncryptData = NULL, $columnMeditationTime = NULL, $columnSleepTime = NULL, $columnBodyTemperature = NULL, $columnWeight = NULL, $columnWater = NULL, $columnNotes = NULL, $columnIsCustomLog = '0' WHERE $columnCustomerId = ? AND $columnLogDate != ?",
      [customerId, _configRowDate],
    );
  }

  /// Get all rows for a customer (excluding config)
  Future<List<Map<String, dynamic>>> getAllDailyLogs(String customerId) async {
    Database? db = await instance.database;
    return await db!.rawQuery(
        "SELECT * FROM $tableDailyLogs WHERE $columnCustomerId = ? AND $columnLogDate != ? ORDER BY $columnLogDate DESC",
        [customerId, _configRowDate]);
  }
}
