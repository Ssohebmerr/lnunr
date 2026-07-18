import 'package:cycle_aura/core/storage/user_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserPrefs.setSessionUnlocked(false);
    UserPrefs.resetStealthCacheForTest();
  });

  group('UserPrefs onboarding', () {
    test('starts incomplete then can be marked done', () async {
      expect(await UserPrefs.isOnboardingDone(), isFalse);
      await UserPrefs.setOnboardingDone();
      expect(await UserPrefs.isOnboardingDone(), isTrue);
      await UserPrefs.clearOnboardingDone();
      expect(await UserPrefs.isOnboardingDone(), isFalse);
    });
  });

  group('UserPrefs profile', () {
    test('stores name and goal', () async {
      await UserPrefs.setProfile(name: 'Sara', goal: 'conceive');
      expect(await UserPrefs.getProfileName(), 'Sara');
      expect(await UserPrefs.getProfileGoal(), 'conceive');
    });
  });

  group('UserPrefs premium', () {
    test('defaults to false', () async {
      expect(await UserPrefs.isPremium(), isFalse);
      await UserPrefs.setPremium(true);
      expect(await UserPrefs.isPremium(), isTrue);
    });
  });

  group('UserPrefs stealth', () {
    test('pin hash persists and matches buffer suffix', () async {
      await UserPrefs.setStealthModeEnabled(true);
      await UserPrefs.setStealthModePin('1234');
      expect(await UserPrefs.isStealthModeEnabled(), isTrue);
      expect(await UserPrefs.hasStealthPin(), isTrue);
      expect(await UserPrefs.stealthPinMatchesBuffer('991234'), isTrue);
      expect(await UserPrefs.stealthPinMatchesBuffer('991235'), isFalse);
    });

    test('six-digit pin matches even with operator characters mixed in',
        () async {
      await UserPrefs.setStealthModePin('123456');
      expect(await UserPrefs.stealthPinMatchesBuffer('123456'), isTrue);
      expect(await UserPrefs.stealthPinMatchesBuffer('99+123456'), isTrue);
      expect(await UserPrefs.stealthPinMatchesBuffer('123+456'), isTrue);
      expect(await UserPrefs.stealthPinMatchesBuffer('12345'), isFalse);
      expect(await UserPrefs.stealthPinMatchesBuffer('654321'), isFalse);
    });
  });
}
