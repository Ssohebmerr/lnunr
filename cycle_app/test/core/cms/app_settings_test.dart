import 'package:cycle_aura/core/cms/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings.fromMap', () {
    test('null map returns safe defaults', () {
      const s = AppSettings();
      expect(AppSettings.fromMap(null).communityEnabled, s.communityEnabled);
      expect(AppSettings.fromMap(null).aiEducationEnabled, s.aiEducationEnabled);
      expect(AppSettings.fromMap(null).announcementActive, isFalse);
    });

    test('parses CMS toggles', () {
      final s = AppSettings.fromMap({
        'communityEnabled': false,
        'aiEducationEnabled': false,
        'announcementActive': true,
        'announcementTitleAr': 'عنوان',
        'announcementTitleEn': 'Title',
        'announcementBodyAr': 'نص',
        'announcementBodyEn': 'Body',
        'supportUrl': 'https://example.com/support',
      });
      expect(s.communityEnabled, isFalse);
      expect(s.aiEducationEnabled, isFalse);
      expect(s.hasAnnouncement, isTrue);
      expect(s.announcementTitle('ar'), 'عنوان');
      expect(s.announcementTitle('en'), 'Title');
    });

    test('hasAnnouncement false when titles missing', () {
      final s = AppSettings.fromMap({
        'announcementActive': true,
        'announcementTitleAr': '',
        'announcementTitleEn': 'Only EN',
      });
      expect(s.hasAnnouncement, isFalse);
    });
  });

  group('AppSettings.toMap', () {
    test('round-trips core fields', () {
      const original = AppSettings(
        communityEnabled: false,
        aiEducationEnabled: true,
        supportUrl: 'https://lune.app/help',
      );
      final restored = AppSettings.fromMap(original.toMap());
      expect(restored.communityEnabled, isFalse);
      expect(restored.aiEducationEnabled, isTrue);
      expect(restored.supportUrl, 'https://lune.app/help');
    });
  });
}
