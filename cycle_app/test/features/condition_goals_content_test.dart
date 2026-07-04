import 'package:cycle_aura/features/menopause/data/menopause_content.dart';
import 'package:cycle_aura/features/pcos/data/pcos_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MenopauseContent', () {
    test('tracking focus is non-empty and bilingual', () {
      expect(MenopauseContent.trackingFocus, isNotEmpty);
      for (final t in MenopauseContent.trackingFocus) {
        expect(t.forLang('en'), isNotEmpty);
        expect(t.forLang('ar'), isNotEmpty);
      }
    });

    test('education cards carry both languages', () {
      expect(MenopauseContent.education, isNotEmpty);
      for (final e in MenopauseContent.education) {
        expect(e.titleFor('en'), isNotEmpty);
        expect(e.titleFor('ar'), isNotEmpty);
        expect(e.bodyFor('en'), isNotEmpty);
        expect(e.bodyFor('ar'), isNotEmpty);
      }
    });

    test('doctor note is bilingual', () {
      expect(MenopauseContent.doctorNote.forLang('en'), isNotEmpty);
      expect(MenopauseContent.doctorNote.forLang('ar'), isNotEmpty);
    });
  });

  group('PcosContent', () {
    test('tracking focus is non-empty and bilingual', () {
      expect(PcosContent.trackingFocus, isNotEmpty);
      for (final t in PcosContent.trackingFocus) {
        expect(t.forLang('en'), isNotEmpty);
        expect(t.forLang('ar'), isNotEmpty);
      }
    });

    test('education cards carry both languages', () {
      expect(PcosContent.education, isNotEmpty);
      for (final e in PcosContent.education) {
        expect(e.titleFor('ar'), isNotEmpty);
        expect(e.bodyFor('en'), isNotEmpty);
      }
    });

    test('doctor note is bilingual', () {
      expect(PcosContent.doctorNote.forLang('en'), isNotEmpty);
      expect(PcosContent.doctorNote.forLang('ar'), isNotEmpty);
    });
  });
}
