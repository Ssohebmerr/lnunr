import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cycle_aura/core/privacy/consent_manager.dart';

void main() {
  group('ConsentManager', () {
    setUp(() {
      // Reset SharedPreferences mock before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Privacy Policy', () {
      test('hasAcceptedPrivacyPolicy returns false by default', () async {
        final result = await ConsentManager.hasAcceptedPrivacyPolicy();
        expect(result, isFalse);
      });

      test('acceptPrivacyPolicy sets the flag', () async {
        await ConsentManager.acceptPrivacyPolicy();
        final result = await ConsentManager.hasAcceptedPrivacyPolicy();
        expect(result, isTrue);
      });

      test('acceptPrivacyPolicy does not enable AI consent', () async {
        await ConsentManager.acceptPrivacyPolicy();
        expect(await ConsentManager.hasAiConsent(), isFalse);
      });
    });

    group('Cloud Sync Consent', () {
      test('hasCloudSyncConsent returns false by default', () async {
        final result = await ConsentManager.hasCloudSyncConsent();
        expect(result, isFalse);
      });

      test('setCloudSyncConsent(true) enables consent', () async {
        await ConsentManager.setCloudSyncConsent(true);
        final result = await ConsentManager.hasCloudSyncConsent();
        expect(result, isTrue);
      });

      test('setCloudSyncConsent(false) disables consent', () async {
        await ConsentManager.setCloudSyncConsent(true);
        await ConsentManager.setCloudSyncConsent(false);
        final result = await ConsentManager.hasCloudSyncConsent();
        expect(result, isFalse);
      });
    });

    group('AI Consent', () {
      test('hasAiConsent returns false by default', () async {
        final result = await ConsentManager.hasAiConsent();
        expect(result, isFalse);
      });

      test('setAiConsent(true) enables consent', () async {
        await ConsentManager.setAiConsent(true);
        final result = await ConsentManager.hasAiConsent();
        expect(result, isTrue);
      });

      test('setAiConsent(false) disables consent', () async {
        await ConsentManager.setAiConsent(true);
        await ConsentManager.setAiConsent(false);
        final result = await ConsentManager.hasAiConsent();
        expect(result, isFalse);
      });
    });

    group('Communities Consent', () {
      test('hasCommunitiesConsent returns false by default', () async {
        final result = await ConsentManager.hasCommunitiesConsent();
        expect(result, isFalse);
      });

      test('setCommunitiesConsent(true) enables consent', () async {
        await ConsentManager.setCommunitiesConsent(true);
        final result = await ConsentManager.hasCommunitiesConsent();
        expect(result, isTrue);
      });

      test('setCommunitiesConsent(false) disables consent', () async {
        await ConsentManager.setCommunitiesConsent(true);
        await ConsentManager.setCommunitiesConsent(false);
        final result = await ConsentManager.hasCommunitiesConsent();
        expect(result, isFalse);
      });
    });

    group('Consent independence', () {
      test('enabling one consent does not affect others', () async {
        await ConsentManager.setAiConsent(true);

        expect(await ConsentManager.hasCloudSyncConsent(), isFalse);
        expect(await ConsentManager.hasCommunitiesConsent(), isFalse);
        expect(await ConsentManager.hasAcceptedPrivacyPolicy(), isFalse);
      });
    });
  });
}
