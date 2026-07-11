import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_aura/core/cycle/ovulation_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OvulationLogService', () {
    late OvulationLogService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = OvulationLogService();
    });

    test('logs and reads entries by date', () async {
      final day = DateTime(2026, 6, 15);
      await service.logDate(day, OvulationLogType.lhPositive);
      expect(await service.hasLogOn(day), isTrue);
      expect(await service.entryCount(), 1);

      await service.logDate(day, OvulationLogType.ovulation);
      final entries = await service.loadEntries();
      expect(entries.length, 1);
      expect(entries.first.type, OvulationLogType.ovulation);
    });

    test('remove clears a day', () async {
      final day = DateTime(2026, 6, 20);
      await service.logDate(day, OvulationLogType.ovulation);
      await service.remove(day);
      expect(await service.hasLogOn(day), isFalse);
    });
  });
}
