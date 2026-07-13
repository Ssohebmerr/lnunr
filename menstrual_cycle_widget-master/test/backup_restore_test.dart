import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// End-to-end round trip of the encrypted backup/restore pipeline against a
/// real SQLite store (sqflite FFI). Guards the bugs that made every backup
/// action in the app report failure:
///  * export crashed on period-only rows (json.decode of "")
///  * export crashed assigning INTEGER cycleDay to a String field
///  * restore double-encrypted the customer id (data became invisible)
///  * restore always returned false even on success
///  * a plaintext config row could blank the in-memory customer id
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('mcw_backup_test');

    // Route path_provider's documents dir to the temp dir.
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);

    // Run sqflite on the FFI factory so the real DB code runs on the host.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    MenstrualCycleWidget.init(
      secretKey: 'test-secret-key-0123456789abcdef',
      ivKey: 'test-iv-key-0123',
    );
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('encrypted export → wipe → restore round-trips all data', () async {
    final api = MenstrualCycleWidget.instance!;
    await api.updateConfiguration(
      cycleLength: 28,
      periodDuration: 5,
      customerId: 'local_user',
      lastPeriodDate: DateTime(2026, 7, 1),
    );

    var saved = false;
    await api.saveSymptomsLogs(
      userSymptomsData: [
        SymptomsData(symptomId: 1, symptomName: 'Cramps', isSelected: true),
      ],
      symptomsLogDate: DateTime(2026, 7, 2),
      customNotes: 'round-trip-note',
      waterValue: '2',
      weight: '60',
      cycleDay: 2,
      onSuccess: (_) => saved = true,
      onError: () => fail('saveSymptomsLogs reported an error'),
    );
    expect(saved, isTrue);

    final dbHelper = MenstrualCycleDbHelper.instance;
    final periodsBefore = await dbHelper.getPastPeriodDates();
    expect(periodsBefore, hasLength(5),
        reason: 'configuration should have logged 5 period days');

    // Export — used to throw on the period-only rows / int cycleDay.
    final backup = await api.getBackupOfMenstrualCycleData(isEncryptData: true);
    expect(backup['encryptedData'], isA<String>());
    expect((backup['encryptedData'] as String), isNotEmpty);

    // Wipe the whole store (same device keys, fresh data) and reset memory.
    final db = await dbHelper.database;
    await db!.delete(MenstrualCycleDbHelper.tableDailyLogs);
    await api.calculateLastPeriodDate();
    expect(await dbHelper.getPastPeriodDates(), isEmpty);

    // Restore — used to always return false and hide restored rows.
    final restored = await api.restoreBackupOfMenstrualCycleData(
      backupData: backup,
      customerId: api.getCustomerId(),
    );
    expect(restored, isTrue, reason: 'successful restore must return true');

    // Period dates round-tripped.
    final periodsAfter = await dbHelper.getPastPeriodDates();
    expect(periodsAfter, periodsBefore);

    // Symptom logs are visible again under the store id (no double
    // encryption of the customer id).
    final logs = await api.getAllSymptomsData();
    expect(logs, hasLength(1));
    expect(logs.single.notes, 'round-trip-note');
    expect(logs.single.waterValue, '2');
    expect(logs.single.weight, '60');

    // In-memory state refreshed: an export right after restore still
    // contains everything (no app relaunch needed).
    final backup2 =
        await api.getBackupOfMenstrualCycleData(isEncryptData: false);
    final tableData = backup2['allTableData'] as Map<String, dynamic>;
    expect(tableData['periods_logs'], hasLength(5));
    expect(tableData['symptoms_logs'], hasLength(1));
    expect(backup2['cycleLength'], 28);
    expect(backup2['periodDuration'], 5);
  });

  test('setCurrentUserData ignores corrupt plaintext config rows', () {
    final api = MenstrualCycleWidget.instance!;
    final before = api.getCustomerId();

    // A plaintext id (as written by the old cloud-restore path) fails to
    // decrypt; it must not blank the active customer id.
    api.setCurrentUserData('local_user', 30, 6);

    expect(api.getCustomerId(), before);
  });
}
