import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/models/community_profile.dart';

void main() {
  group('CommunityProfile.fromMap', () {
    test('returns empty alias profile for null data', () {
      const profile = CommunityProfile(alias: '');
      expect(profile.alias, '');
      expect(profile.birthYear, isNull);
      expect(profile.setupComplete, isFalse);
    });

    test('parses all fields from map', () {
      final profile = CommunityProfile.fromMap({
        'communityAlias': 'Luna',
        'communityGoal': 'general',
        'communityBirthYear': 1995,
        'communitySetupComplete': true,
        'communityAvatarIndex': 3,
        'communityPhotoUrl': 'https://example.com/photo.jpg',
      });

      expect(profile.alias, 'Luna');
      expect(profile.goal, 'general');
      expect(profile.birthYear, 1995);
      expect(profile.setupComplete, isTrue);
      expect(profile.avatarIndex, 3);
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
    });

    test('defaults missing fields', () {
      final profile = CommunityProfile.fromMap({});
      expect(profile.alias, '');
      expect(profile.goal, isNull);
      expect(profile.birthYear, isNull);
      expect(profile.setupComplete, isFalse);
      expect(profile.avatarIndex, 0);
      expect(profile.photoUrl, isNull);
    });
  });

  group('CommunityProfile.toMap', () {
    test('includes all set fields', () {
      const profile = CommunityProfile(
        alias: 'Luna',
        birthYear: 1995,
        setupComplete: true,
        avatarIndex: 2,
      );
      final map = profile.toMap();
      expect(map['communityAlias'], 'Luna');
      expect(map['communityBirthYear'], 1995);
      expect(map['communitySetupComplete'], isTrue);
      expect(map['communityAvatarIndex'], 2);
    });

    test('omits null optional fields', () {
      const profile = CommunityProfile(alias: 'Luna');
      final map = profile.toMap();
      expect(map.containsKey('communityGoal'), isFalse);
      expect(map.containsKey('communityBirthYear'), isFalse);
      expect(map.containsKey('communityPhotoUrl'), isFalse);
    });
  });

  group('CommunityProfile.isMinor', () {
    test('null birth year is minor', () {
      const profile = CommunityProfile(alias: 'Luna');
      expect(profile.isMinor, isTrue);
    });

    test('17 years old is minor', () {
      final year = DateTime.now().year - 17;
      final profile = CommunityProfile(alias: 'Luna', birthYear: year);
      expect(profile.isMinor, isTrue);
    });

    test('18 years old is adult', () {
      final year = DateTime.now().year - 18;
      final profile = CommunityProfile(alias: 'Luna', birthYear: year);
      expect(profile.isMinor, isFalse);
    });

    test('25 years old is adult', () {
      final year = DateTime.now().year - 25;
      final profile = CommunityProfile(alias: 'Luna', birthYear: year);
      expect(profile.isMinor, isFalse);
    });
  });

  group('CommunityProfile.isReady', () {
    test('not ready without birth year', () {
      const profile = CommunityProfile(alias: 'Luna');
      expect(profile.isReady, isFalse);
    });

    test('not ready with short alias', () {
      final year = DateTime.now().year - 25;
      final profile = CommunityProfile(alias: 'L', birthYear: year);
      expect(profile.isReady, isFalse);
    });

    test('not ready if minor', () {
      final year = DateTime.now().year - 16;
      final profile = CommunityProfile(alias: 'Luna', birthYear: year);
      expect(profile.isReady, isFalse);
    });

    test('not ready without setupComplete', () {
      final year = DateTime.now().year - 25;
      final profile = CommunityProfile(alias: 'Luna', birthYear: year);
      expect(profile.isReady, isFalse);
    });

    test('ready with valid alias, adult birth year, and setupComplete', () {
      final year = DateTime.now().year - 25;
      final profile = CommunityProfile(
        alias: 'Luna',
        birthYear: year,
        setupComplete: true,
      );
      expect(profile.isReady, isTrue);
    });
  });

  group('CommunityProfile.needsBirthYearOnly', () {
    test('true when alias is set but birth year is null', () {
      const profile = CommunityProfile(alias: 'Luna');
      expect(profile.needsBirthYearOnly, isTrue);
    });

    test('false when birth year is set', () {
      final profile = CommunityProfile(
        alias: 'Luna',
        birthYear: DateTime.now().year - 25,
      );
      expect(profile.needsBirthYearOnly, isFalse);
    });

    test('false when alias is too short', () {
      const profile = CommunityProfile(alias: 'L');
      expect(profile.needsBirthYearOnly, isFalse);
    });
  });
}
