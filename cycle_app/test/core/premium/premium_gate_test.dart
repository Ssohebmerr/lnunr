import 'package:cycle_aura/core/age/age_gate.dart';
import 'package:cycle_aura/core/premium/premium_gate.dart';
import 'package:cycle_aura/core/privacy/consent_manager.dart';
import 'package:cycle_aura/core/storage/user_prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ConsentManager.setAiConsent(true);
    await UserPrefs.setPremium(false);
  });

  group('PremiumGate.checkAiChat', () {
    test('requires premium for AI chat', () async {
      expect(
        await PremiumGate.checkAiChat(),
        PremiumAiAccess.needsPremium,
      );
    });

    test('needs consent when premium but AI consent is missing', () async {
      await UserPrefs.setPremium(true);
      await ConsentManager.setAiConsent(false);
      expect(
        await PremiumGate.checkAiChat(),
        PremiumAiAccess.needsConsent,
      );
    });

    test('allows premium users with AI consent', () async {
      await UserPrefs.setPremium(true);
      await ConsentManager.setAiConsent(true);
      expect(await PremiumGate.checkAiChat(), PremiumAiAccess.allowed);
    });

    test('blocks teens from AI chat', () async {
      await UserPrefs.setPremium(true);
      await ConsentManager.setAiConsent(true);
      await saveAgeGroup(AgeGroup.teen);
      expect(await PremiumGate.checkAiChat(), PremiumAiAccess.needsAdult);
    });
  });

  group('PremiumGate doctor reports', () {
    test('free users get one report then need premium', () async {
      expect(await PremiumGate.canGenerateDoctorReport(), isTrue);
      expect(await PremiumGate.remainingFreeReports(), 1);
      await PremiumGate.recordDoctorReport();
      expect(await PremiumGate.canGenerateDoctorReport(), isFalse);
      expect(await PremiumGate.remainingFreeReports(), 0);
    });
  });
}
