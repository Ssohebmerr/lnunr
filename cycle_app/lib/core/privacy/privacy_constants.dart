/// Host this policy at a public HTTPS URL before publishing on Google Play.
class PrivacyConstants {
  PrivacyConstants._();

  /// Replace with your live privacy policy URL in Play Console + here.
  static const privacyPolicyUrl =
      'https://lune-7d956.web.app/privacy-policy.html';

  static const termsOfServiceUrl =
      'https://lune-7d956.web.app/terms-of-service.html';

  static const supportEmail = 'merrsoheb@gmail.com';

  static Uri get supportMailto => Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: 'subject=${Uri.encodeComponent('Lune Support')}',
      );

  static const appName = 'Lune';
  static const dataController = 'Lune';
  static const effectiveDate = 'June 21, 2026';
}
