import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_aura/core/auth/apple_auth_helper.dart';
import 'package:cycle_aura/features/community/data/community_constants.dart';
import 'package:cycle_aura/core/age/age_gate.dart';
import 'package:cycle_aura/features/community/data/models/community_profile.dart';

void main() {
  group('AppleAuthHelper', () {
    test('sha256ofString is deterministic', () {
      expect(
        AppleAuthHelper.sha256ofString('test-nonce'),
        AppleAuthHelper.sha256ofString('test-nonce'),
      );
    });

    test('generateNonce returns requested length', () {
      expect(AppleAuthHelper.generateNonce(16).length, 16);
    });
  });

  group('CommunityProfile.isMinor', () {
    test('unknown birth year is treated as minor', () {
      const profile = CommunityProfile(alias: 'luna', setupComplete: true);
      expect(profile.isMinor, isTrue);
    });

    test('user born 20 years ago is adult', () {
      final adultYear = DateTime.now().year - 20;
      final profile = CommunityProfile(
        alias: 'luna',
        birthYear: adultYear,
        setupComplete: true,
      );
      expect(profile.isMinor, isFalse);
    });

    test('user born 16 years ago is minor', () {
      final minorYear = DateTime.now().year - 16;
      final profile = CommunityProfile(
        alias: 'luna',
        birthYear: minorYear,
        setupComplete: true,
      );
      expect(profile.isMinor, isTrue);
    });
  });

  group('community birth year gate', () {
    test('allowed years match 18+ and Firestore max', () {
      final years = communityAllowedBirthYears();
      expect(years, isNotEmpty);
      for (final y in years) {
        expect(isCommunityAdultBirthYear(y), isTrue);
        expect(y, lessThanOrEqualTo(kCommunityMaxBirthYearFirestore));
      }
      expect(years.first, communityMaxAdultBirthYear());
    });

    test('profile without birth year is not ready for community', () {
      const profile = CommunityProfile(
        alias: 'luna_user',
        setupComplete: true,
      );
      expect(profile.isReady, isFalse);
      expect(profile.isMinor, isTrue);
    });

    test('adult profile without setupComplete is not ready', () {
      final adultYear = DateTime.now().year - 25;
      final profile = CommunityProfile(
        alias: 'luna_user',
        birthYear: adultYear,
        setupComplete: false,
      );
      expect(profile.isReady, isFalse);
      expect(profile.isMinor, isFalse);
    });

    test('adult profile with setupComplete is ready', () {
      final adultYear = DateTime.now().year - 25;
      final profile = CommunityProfile(
        alias: 'luna_user',
        birthYear: adultYear,
        setupComplete: true,
      );
      expect(profile.isReady, isTrue);
    });
  });

  group('age gate community blocks', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('teen blocks community via age gate', () async {
      await saveAgeGroup(AgeGroup.teen);
      expect(await blocksCommunityByAgeGate(), isTrue);
    });

    test('under13 blocks app completion', () async {
      await saveAgeGroup(AgeGroup.under13);
      expect(await blocksAppByAgeGate(), isTrue);
      expect(await blocksCommunityByAgeGate(), isTrue);
    });

    test('adult does not block community via age gate', () async {
      await saveAgeGroup(AgeGroup.adult);
      expect(await blocksCommunityByAgeGate(), isFalse);
      expect(await blocksAppByAgeGate(), isFalse);
    });
  });
}
