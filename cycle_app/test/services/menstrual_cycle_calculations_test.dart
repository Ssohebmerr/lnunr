import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Menstrual Cycle Calculations & Utilities Unit Tests', () {
    late MenstrualCycleWidget widgetInstance;

    setUp(() {
      // Set databaseFactory to the default sqflite factory implementation
      databaseFactory = databaseFactorySqflitePlugin;

      // Mock Path Provider Method Channel
      const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      });

      // Mock Sqflite Method Channel (using the correct channel name)
      const sqfliteChannel = MethodChannel('com.tekartik.sqflite');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sqfliteChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'getDatabasesPath') {
          return '.';
        }
        if (methodCall.method == 'openDatabase') {
          return {'id': 1};
        }
        if (methodCall.method == 'query' || methodCall.method == 'rawQuery') {
          return <Map<String, dynamic>>[];
        }
        if (methodCall.method == 'insert' || methodCall.method == 'update') {
          return 1;
        }
        return null;
      });

      // Initialize MenstrualCycleWidget with mock keys
      widgetInstance = MenstrualCycleWidget.init(
        secretKey: "my_secret_encryption_key_for_test",
        ivKey: "my_secret_iv_key",
      );
    });

    test('Cycle length and period duration settings', () {
      expect(widgetInstance.getCycleLength(), equals(defaultCycleLength)); // 28 days default
      expect(widgetInstance.getPeriodDuration(), equals(defaultPeriodDuration)); // 5 days default
    });

    test('Follicular Phase Day Counts calculation formula', () {
      // defaultCycleLength = 28, defaultPeriodDuration = 5
      // ovulationDay = 28 - 14 = 14
      // follicularDay = (14 - 5 - 4 ~/ 2) = 14 - 5 - 2 = 7
      // follicularDay - 1 = 6
      expect(widgetInstance.getFollicularDayCounts(), equals(6));
    });

    test('Unit Conversions: Celsius to Fahrenheit and vice versa', () {
      final f = celsiusToFahrenheit(37.0);
      expect(f, closeTo(98.6, 0.01));

      final c = fahrenheitToCelsius(98.6);
      expect(c, closeTo(37.0, 0.01));
    });

    test('Unit Conversions: Milliliters to other units', () {
      final liters = millilitersToLiters(1500.0);
      expect(liters, equals(1.5));

      final cups = millilitersToUSCups(236.588);
      expect(cups, closeTo(1.0, 0.01));

      final flOz = millilitersToUSFluidOunces(29.5735);
      expect(flOz, closeTo(1.0, 0.01));
    });

    test('Weight Conversions: Kg to Lb and vice versa', () {
      final lb = convertKgToLb(70.0);
      expect(lb, closeTo(154.323, 0.01));

      final kg = convertLbToKg(154.323);
      expect(kg, closeTo(70.0, 0.1));
    });

    test('Duration Conversions: Minutes to Hours & Minutes string', () {
      final formattedTime = convertMinutesToHours(135);
      expect(formattedTime, equals('2h 15m'));
    });
  });
}
