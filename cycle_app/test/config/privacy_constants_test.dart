import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/core/privacy/privacy_constants.dart';

void main() {
  group('PrivacyConstants', () {
    test('privacy policy URL is a valid HTTPS URL', () {
      final uri = Uri.parse(PrivacyConstants.privacyPolicyUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
    });

    test('terms of service URL is a valid HTTPS URL', () {
      final uri = Uri.parse(PrivacyConstants.termsOfServiceUrl);
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
    });

    test('support email contains @', () {
      expect(PrivacyConstants.supportEmail, contains('@'));
    });

    test('support mailto URI is valid', () {
      final uri = PrivacyConstants.supportMailto;
      expect(uri.scheme, 'mailto');
      expect(uri.path, PrivacyConstants.supportEmail);
      expect(uri.queryParameters['subject'], isNotEmpty);
    });

    test('app name is Lune', () {
      expect(PrivacyConstants.appName, 'Lune');
    });

    test('effective date is set', () {
      expect(PrivacyConstants.effectiveDate, isNotEmpty);
    });
  });
}
