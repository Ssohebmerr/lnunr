import 'package:cycle_aura/features/health_connect/data/health_connect_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HealthConnectStatus', () {
    test('parses availability and per-group permission progress', () {
      final status = HealthConnectStatus.fromMap(const {
        'availability': 'available',
        'cycleGranted': true,
        'wellnessGranted': false,
        'historyGranted': true,
        'cycleGrantedCount': 12,
        'cyclePermissionCount': 12,
        'wellnessGrantedCount': 4,
        'wellnessPermissionCount': 11,
      });

      expect(status.available, isTrue);
      expect(status.installRequired, isFalse);
      expect(status.grantedFor(HealthConnectGroup.cycle), isTrue);
      expect(status.grantedFor(HealthConnectGroup.wellness), isFalse);
      expect(status.historyGranted, isTrue);
      expect(status.cycleGrantedCount, 12);
      expect(status.wellnessPermissionCount, 11);
    });

    test('uses privacy-safe disabled defaults for missing fields', () {
      final status = HealthConnectStatus.fromMap(const {});

      expect(status.available, isFalse);
      expect(status.installRequired, isFalse);
      expect(status.cycleGranted, isFalse);
      expect(status.wellnessGranted, isFalse);
      expect(status.historyGranted, isFalse);
      expect(status.cyclePermissionCount, 0);
      expect(status.wellnessPermissionCount, 0);
    });

    test('recognizes provider installation requirement', () {
      final status = HealthConnectStatus.fromMap(const {
        'availability': 'installRequired',
      });

      expect(status.installRequired, isTrue);
      expect(status.available, isFalse);
    });
  });
}
