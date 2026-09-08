import 'package:cycle_aura/core/cycle/bbt_tracking_status.dart';
import 'package:cycle_aura/core/notifications/notification_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  BbtTrackingStatus statusWith({
    int readings = 0,
    bool confirmed = false,
    int signals = 0,
  }) => BbtTrackingStatus(
    readingsThisCycle: readings,
    ovulationConfirmed: confirmed,
    measuredLutealSignals: signals,
  );

  group('readiness for detection', () {
    test('needs six baseline plus three confirming readings', () {
      expect(BbtTrackingStatus.minReadingsForDetection, 9);
    });

    test('counts down honestly toward the first possible confirmation', () {
      expect(statusWith(readings: 0).readingsUntilReady, 9);
      expect(statusWith(readings: 4).readingsUntilReady, 5);
      expect(statusWith(readings: 9).readingsUntilReady, 0);
    });

    test('never reports a negative countdown once past the threshold', () {
      expect(statusWith(readings: 20).readingsUntilReady, 0);
      expect(statusWith(readings: 20).isReady, isTrue);
    });

    test('progress fills toward the threshold and stops at full', () {
      expect(statusWith(readings: 0).progress, 0);
      expect(statusWith(readings: 9).progress, 1);
      expect(statusWith(readings: 30).progress, 1);
    });

    test('a confirmed shift is full progress regardless of reading count', () {
      expect(statusWith(readings: 3, confirmed: true).progress, 1);
    });
  });

  group('calibration', () {
    test('two measured signals personalize the luteal phase', () {
      expect(statusWith(signals: 1).isCalibrated, isFalse);
      expect(statusWith(signals: 2).isCalibrated, isTrue);
    });

    test('an untouched status offers nothing and claims nothing', () {
      const s = BbtTrackingStatus.empty;
      expect(s.hasStarted, isFalse);
      expect(s.isReady, isFalse);
      expect(s.isCalibrated, isFalse);
      expect(s.ovulationConfirmed, isFalse);
    });
  });

  group('reminder preferences', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('the morning reminder is off until the user opts in', () async {
      expect(await NotificationPrefs.temperatureEnabled(), isFalse);
    });

    test('defaults to 07:00 and round-trips a chosen time', () async {
      expect(await NotificationPrefs.temperatureTime(), (7, 0));
      await NotificationPrefs.setTemperatureTime(6, 30);
      expect(await NotificationPrefs.temperatureTime(), (6, 30));
    });

    test('an out-of-range time is clamped rather than stored broken', () async {
      await NotificationPrefs.setTemperatureTime(99, 99);
      expect(await NotificationPrefs.temperatureTime(), (23, 59));
    });

    test('the master switch overrides the temperature reminder', () async {
      SharedPreferences.setMockInitialValues({
        NotificationPrefs.temperatureKey: true,
        NotificationPrefs.masterKey: false,
      });
      expect(await NotificationPrefs.temperatureEnabled(), isFalse);
    });
  });
}
