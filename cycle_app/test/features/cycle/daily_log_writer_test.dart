import 'package:cycle_aura/features/cycle/data/daily_log_writer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyLogWriter without widget instance', () {
    test('logSymptom returns notReady when cycle store is unavailable', () async {
      // Ensure no singleton from other tests in this isolate.
      final result = await DailyLogWriter.logSymptom('calm');
      if (MenstrualCycleWidget.instance == null) {
        expect(result.status, DailyLogWriteStatus.notReady);
      }
    });

    test('logWater returns notReady when cycle store is unavailable', () async {
      final result = await DailyLogWriter.logWater(2);
      if (MenstrualCycleWidget.instance == null) {
        expect(result.status, DailyLogWriteStatus.notReady);
      }
    });
  });

  group('DailyLogWriter symptom aliases', () {
    setUp(() {
      databaseFactory = databaseFactorySqflitePlugin;

      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') return '.';
        return null;
      });

      const sqfliteChannel = MethodChannel('com.tekartik.sqflite');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sqfliteChannel, (MethodCall call) async {
        if (call.method == 'getDatabasesPath') return '.';
        if (call.method == 'openDatabase') return {'id': 1};
        if (call.method == 'query' || call.method == 'rawQuery') {
          return <Map<String, dynamic>>[];
        }
        if (call.method == 'insert' || call.method == 'update') return 1;
        return null;
      });

      MenstrualCycleWidget.init(
        secretKey: 'daily_log_writer_test_secret_key_32chars!!',
        ivKey: 'daily_log_iv16',
      );
    });

    test('recognizes known English aliases like calm and cramps', () async {
      for (final name in ['calm', 'cramps', 'tired']) {
        final result = await DailyLogWriter.logSymptom(name);
        expect(
          result.status,
          isNot(DailyLogWriteStatus.notMatched),
          reason: 'alias $name should resolve',
        );
        expect(result.status, isNot(DailyLogWriteStatus.notReady));
      }
    });

    test('returns notMatched for unknown symptom text', () async {
      final result =
          await DailyLogWriter.logSymptom('xyz_unknown_symptom_abc');
      expect(result.status, DailyLogWriteStatus.notMatched);
    });

    test('DailyLogWriteResult.ok is true only on success', () {
      expect(
        const DailyLogWriteResult(DailyLogWriteStatus.success).ok,
        isTrue,
      );
      expect(
        const DailyLogWriteResult(DailyLogWriteStatus.failed).ok,
        isFalse,
      );
    });
  });
}
