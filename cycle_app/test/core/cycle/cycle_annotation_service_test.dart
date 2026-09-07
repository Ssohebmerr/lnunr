import 'package:cycle_aura/core/cycle/cycle_annotation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late CycleAnnotationService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = CycleAnnotationService();
  });

  group('storing causes', () {
    test('round-trips a set of causes for one cycle', () async {
      final start = DateTime(2026, 3, 1);
      await service.setCauses(start, {CycleCause.illness, CycleCause.travel});

      expect(await service.causesFor(start), {
        CycleCause.illness,
        CycleCause.travel,
      });
      expect(await service.hasAnnotation(start), isTrue);
    });

    test('ignores the time part of the cycle start', () async {
      await service.setCauses(DateTime(2026, 3, 1), {CycleCause.stress});
      expect(
        await service.causesFor(DateTime(2026, 3, 1, 22, 45)),
        {CycleCause.stress},
      );
    });

    test('an empty set clears the annotation so the cycle counts again', () async {
      final start = DateTime(2026, 3, 1);
      await service.setCauses(start, {CycleCause.stress});
      await service.setCauses(start, {});

      expect(await service.hasAnnotation(start), isFalse);
      expect(await service.loadAll(), isEmpty);
    });

    test('re-annotating replaces rather than accumulating', () async {
      final start = DateTime(2026, 3, 1);
      await service.setCauses(start, {CycleCause.illness});
      await service.setCauses(start, {CycleCause.travel});

      expect(await service.causesFor(start), {CycleCause.travel});
      expect((await service.loadAll()).length, 1);
    });

    test('survives corrupted storage without throwing', () async {
      SharedPreferences.setMockInitialValues({
        'cycle_annotations_v1': 'not json at all',
      });
      expect(await CycleAnnotationService().loadAll(), isEmpty);
    });
  });

  group('explainedFlagsFor', () {
    // Four period starts → three completed cycle lengths.
    final starts = [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 29),
      DateTime(2026, 3, 4),
      DateTime(2026, 4, 1),
    ];

    test('flags the cycle that STARTED the annotated stretch', () async {
      // Illness during the cycle beginning Jan 29 is what stretched the
      // Jan 29 → Mar 4 length, so index 1 must be the flagged one.
      await service.setCauses(DateTime(2026, 1, 29), {CycleCause.illness});

      expect(await service.explainedFlagsFor(starts), [false, true, false]);
    });

    test('returns one flag per cycle length, not per period', () async {
      await service.setCauses(DateTime(2026, 1, 1), {CycleCause.travel});
      final flags = await service.explainedFlagsFor(starts);
      expect(flags.length, starts.length - 1);
    });

    test('is empty when nothing has been annotated', () async {
      expect(await service.explainedFlagsFor(starts), isEmpty);
    });

    test('is empty when there are too few cycles to have a length', () async {
      await service.setCauses(DateTime(2026, 1, 1), {CycleCause.travel});
      expect(await service.explainedFlagsFor([DateTime(2026, 1, 1)]), isEmpty);
    });
  });

  group('causeFrequencies', () {
    test('counts how often each cause is reported', () async {
      await service.setCauses(DateTime(2026, 1, 1), {
        CycleCause.travel,
        CycleCause.stress,
      });
      await service.setCauses(DateTime(2026, 2, 1), {CycleCause.travel});

      final counts = await service.causeFrequencies();
      expect(counts['travel'], 2);
      expect(counts['stress'], 1);
      expect(counts.containsKey('illness'), isFalse);
    });
  });
}
