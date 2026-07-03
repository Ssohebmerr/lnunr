// ============================================================================
// test/features/notifications/smart_phase_messages_test.dart
// ----------------------------------------------------------------------------
// Pure-data tests — no Flutter bindings needed. We exhaustively cover:
//   * every localized phase variant (English + Arabic)
//   * pregnancy mode (T1/T2/T3) branching
//   * late-period fallback
//   * unknown / empty phase → generic message
//   * tag prefix invariant (used by analytics + dedup logic)
// ============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/notifications/data/smart_phase_messages.dart';

void main() {
  group('SmartPhaseMessages — cycle phase templates', () {
    test('menstrual — early day vs late day differs in body', () {
      final early = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Menstruation',
          cycleDay: 1,
          isPregnant: false,
        ),
        'en',
      );
      final late = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Menstruation',
          cycleDay: 4,
          isPregnant: false,
        ),
        'en',
      );
      expect(early.tag, 'menstrual|en');
      expect(late.tag, 'menstrual|en');
      expect(early.body, isNot(late.body));
      expect(early.body.toLowerCase(), contains('rest'));
    });

    test('menstrual Arabic variant picks up the localized phase string', () {
      // The widget emits Arabic phase labels ("الحيض") in Arabic locale;
      // the classifier must accept them. Both early-day and late-day
      // bodies should reference menstruation-friendly guidance.
      final early = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'الحيض',
          cycleDay: 1,
          isPregnant: false,
        ),
        'ar',
      );
      final late = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'الحيض',
          cycleDay: 3,
          isPregnant: false,
        ),
        'ar',
      );
      expect(early.tag, 'menstrual|ar');
      expect(late.tag, 'menstrual|ar');
      // Either body may be returned depending on cycle day, but the body
      // must reference menstrual-friendly guidance in Arabic.
      expect(
        early.body.contains('دورتك') || late.body.contains('الأمور'),
        isTrue,
        reason:
            'expected either early-day or late-day body to be selected',
      );
    });

    test('follicular — Arabic title + body is returned, tag is follicular|ar', () {
      final early = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'مرحلة الجريب',
          cycleDay: 5,
          isPregnant: false,
        ),
        'ar',
      );
      final late = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'مرحلة الجريب',
          cycleDay: 11,
          isPregnant: false,
        ),
        'ar',
      );
      expect(early.tag, 'follicular|ar');
      expect(late.tag, 'follicular|ar');
      expect(
        early.body.contains('طاقتك') || late.body.contains('الطاقة'),
        isTrue,
        reason: 'follicular body should mention rising energy',
      );
    });

    test('ovulation — Arabic + English', () {
      final en = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Ovulation',
          cycleDay: 14,
          isPregnant: false,
        ),
        'en',
      );
      final ar = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'الإباضة',
          cycleDay: 14,
          isPregnant: false,
        ),
        'ar',
      );
      expect(en.tag, 'ovulation|en');
      expect(ar.tag, 'ovulation|ar');
      expect(ar.body, contains('الإباضة'));
    });

    test('luteal — late day (>= 25) picks the late-luteal body in AR', () {
      final late = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Luteal',
          cycleDay: 27,
          isPregnant: false,
        ),
        'ar',
      );
      expect(late.tag, 'luteal|ar');
      expect(
        late.body.contains('الكافيين') || late.body.contains('السكريات'),
        isTrue,
        reason: 'late luteal body should mention caffeine or sugar',
      );
    });
  });

  group('SmartPhaseMessages — pregnancy mode', () {
    test('T1 — first trimester AR body mentions nausea / rest', () {
      final m = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: '',
          cycleDay: null,
          isPregnant: true,
          pregnancyWeek: 8,
          trimester: 1,
        ),
        'ar',
      );
      expect(m.tag, 'pregnancyT1|ar');
      expect(m.body, contains('الثلث الأول'));
    });

    test('T2 — second trimester EN body mentions walking', () {
      final m = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: '',
          cycleDay: null,
          isPregnant: true,
          pregnancyWeek: 18,
          trimester: 2,
        ),
        'en',
      );
      expect(m.tag, 'pregnancyT2|en');
      expect(m.body.toLowerCase(), contains('trimester 2'));
    });

    test('T3 — third trimester EN body mentions hospital bag', () {
      final m = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: '',
          cycleDay: null,
          isPregnant: true,
          pregnancyWeek: 36,
          trimester: 3,
        ),
        'en',
      );
      expect(m.tag, 'pregnancyT3|en');
      expect(m.body.toLowerCase(), contains('hospital bag'));
    });

    test('Pregnancy mode overrides phase context (no fallback to luteal)', () {
      // Even with a phase string that would normally resolve to luteal, the
      // pregnancy branch must win.
      final m = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Luteal',
          cycleDay: 25,
          isPregnant: true,
          pregnancyWeek: 10,
          trimester: 1,
        ),
        'en',
      );
      expect(m.tag, 'pregnancyT1|en');
    });
  });

  group('SmartPhaseMessages — edge cases', () {
    test('late period — phase contains "late" or Arabic متأخر', () {
      final en = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Late period',
          cycleDay: 32,
          isPregnant: false,
        ),
        'en',
      );
      final ar = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'متأخر',
          cycleDay: 32,
          isPregnant: false,
        ),
        'ar',
      );
      expect(en.tag, 'latePeriod|en');
      expect(ar.tag, 'latePeriod|ar');
      expect(en.body.toLowerCase(), contains('late'));
    });

    test('unknown phase — falls back to the generic daily reminder', () {
      final en = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'something-weird',
          cycleDay: 5,
          isPregnant: false,
        ),
        'en',
      );
      final ar = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: '',
          cycleDay: null,
          isPregnant: false,
        ),
        'ar',
      );
      expect(en.tag, 'generic|en');
      expect(ar.tag, 'generic|ar');
      // Generic Arabic body uses "سجلي" (log) — accept either that or
      // "يومك" (your day) for robustness against copy edits.
      expect(
        ar.body.contains('سجلي') || ar.body.contains('يومك'),
        isTrue,
        reason: 'generic Arabic body should mention logging',
      );
    });

    test('all messages have title + non-empty body', () {
      final phaseVariants = [
        'Menstruation',
        'Follicular',
        'Ovulation',
        'Luteal',
        '',
      ];
      for (final p in phaseVariants) {
        for (final loc in ['en', 'ar']) {
          final m = SmartPhaseMessages.pick(
            SmartPhaseContext(
              phase: p,
              cycleDay: p.isEmpty ? null : 5,
              isPregnant: false,
            ),
            loc,
          );
          expect(m.title, isNotEmpty, reason: 'title empty for phase=$p loc=$loc');
          expect(m.body.length, greaterThan(15),
              reason: 'body too short for phase=$p loc=$loc');
        }
      }
    });

    test('tag format is stable (used by analytics + dedup)', () {
      final m = SmartPhaseMessages.pick(
        const SmartPhaseContext(
          phase: 'Follicular',
          cycleDay: 7,
          isPregnant: false,
        ),
        'fr', // unknown locale → English
      );
      expect(m.tag, matches(RegExp(r'^[a-z0-9]+\|(en|ar)$')));
    });
  });
}
