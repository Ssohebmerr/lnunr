import 'package:cycle_aura/features/cycle/data/daily_log_bridge_service.dart';
import 'package:cycle_aura/menstrudel/models/period_logs/symptom_type_enum.dart';
import 'package:flutter_test/flutter_test.dart';

/// The one-time Menstrudel→main symptom merge maps Menstrudel symptom types
/// onto hardcoded widget-catalogue ids. If one of those ids ever stops
/// resolving, the merge drops that symptom silently and the user's history
/// quietly loses data — so pin the mapping down here.
void main() {
  group('DailyLogBridgeService symptom mapping', () {
    test('every mapped id resolves to a catalogue symptom', () {
      for (final entry in DailyLogBridgeService.symptomIdMapping.entries) {
        final match = DailyLogBridgeService.catalogueEntry(entry.value);
        expect(
          match,
          isNotNull,
          reason: '${entry.key.name} maps to ${entry.value}, '
              'which is not in the widget catalogue',
        );
        expect(match!.symptomId, entry.value);
        expect(match.symptomName, isNotEmpty);
        expect(match.isSelected, isTrue);
      }
    });

    test('the pain-level fallback id resolves too', () {
      final match =
          DailyLogBridgeService.catalogueEntry(DailyLogBridgeService.painSymptomId);
      expect(match, isNotNull);
      expect(match!.symptomId, DailyLogBridgeService.painSymptomId);
    });

    test('no two symptom types share an id', () {
      final ids = DailyLogBridgeService.symptomIdMapping.values.toList();
      expect(ids.toSet().length, ids.length,
          reason: 'a duplicated id means one symptom overwrites another');
    });

    test('sleep and water are deliberately unmapped', () {
      // They are vitals in the main store, not symptoms — mapping them onto a
      // symptom id would invent data the user never logged as a symptom.
      expect(
        DailyLogBridgeService.symptomIdMapping.containsKey(SymptomType.sleep),
        isFalse,
      );
      expect(
        DailyLogBridgeService.symptomIdMapping.containsKey(SymptomType.water),
        isFalse,
      );
      expect(
        DailyLogBridgeService.symptomIdMapping.containsKey(SymptomType.custom),
        isFalse,
      );
    });
  });
}
