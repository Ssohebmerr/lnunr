import 'package:cycle_aura/features/cycle/data/cycle_bridge_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';

void main() {
  group('CycleBridgeService static helpers', () {
    test('supportedLanguageCodes includes en and ar', () {
      expect(CycleBridgeService.supportedLanguageCodes, contains('en'));
      expect(CycleBridgeService.supportedLanguageCodes, contains('ar'));
    });

    test('languageLabel returns friendly names', () {
      expect(CycleBridgeService.languageLabel('en'), 'English');
      expect(CycleBridgeService.languageLabel('ar'), 'العربية');
      expect(CycleBridgeService.languageLabel('xx'), 'xx');
    });
  });

  group('CycleBridgeService.tryLoadDashboard', () {
    test('returns null when MenstrualCycleWidget is not initialized', () async {
      // Other test files may initialize the widget; this only asserts the
      // soft-fail contract when the native store is unavailable.
      if (MenstrualCycleWidget.instance == null) {
        expect(await CycleBridgeService().tryLoadDashboard(), isNull);
      }
    });
  });

  group('CycleReportData models', () {
    test('PredictedSymptom stores display fields', () {
      const s = PredictedSymptom(name: 'cramps', occurrences: 3, accuracy: 0.8);
      expect(s.name, 'cramps');
      expect(s.occurrences, 3);
      expect(s.accuracy, 0.8);
    });

    test('GraphAvailability exposes all graph toggles', () {
      const g = GraphAvailability(
        trends: true,
        periods: false,
        history: true,
        temperature: false,
        weight: false,
        sleep: true,
        water: true,
        meditation: false,
      );
      expect(g.trends, isTrue);
      expect(g.periods, isFalse);
      expect(g.meditation, isFalse);
    });
  });
}
