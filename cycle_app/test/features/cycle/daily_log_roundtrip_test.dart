import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Real database round-trip for the daily log: save a symptom, then read it
/// back. Reproduces (or clears) the "won't save" report against actual SQLite
/// + the package's encryption + customerId, not a mocked channel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathChannel, (call) async => '.');
  });

  test('symptom log saves and reads back on the same customerId', () async {
    // 16-char key — exactly what CycleEncryptionKeys._randomKey(16) produces
    // on-device (AES-128), so this reproduces the real runtime encryption.
    MenstrualCycleWidget.init(
      secretKey: 'abcdefghijklmnop',
      ivKey: 'roundtrip_iv_key_value',
    );
    await MenstrualCycleWidget.instance!.updateConfiguration(
      cycleLength: 28,
      periodDuration: 5,
      customerId: 'local_user',
    );

    final today = DateTime.now();
    var saved = false;
    await MenstrualCycleWidget.instance!.saveSymptomsLogs(
      userSymptomsData: [
        SymptomsData(
          symptomName: 'Cramps',
          symptomId: 21048,
          isSelected: true,
        ),
      ],
      symptomsLogDate: today,
      waterValue: '3',
      onSuccess: (_) => saved = true,
      onError: () => saved = false,
    );

    expect(saved, isTrue, reason: 'saveSymptomsLogs must report success');

    final readBack =
        await MenstrualCycleWidget.instance!.getSymptomsData(today);
    final ids =
        (readBack.symptomData ?? []).map((s) => s.symptomId).toList();
    expect(
      ids,
      contains(21048),
      reason: 'the symptom saved for today must read back',
    );
    expect(readBack.waterValue, '3', reason: 'water value must persist');
  });
}
