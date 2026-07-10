/// Host this policy at a public HTTPS URL before publishing on Google Play.
class PrivacyConstants {
  PrivacyConstants._();

  /// Replace with your live privacy policy URL in Play Console + here.
  static const privacyPolicyUrl =
      'https://lune-7d956.web.app/privacy-policy.html';

  static const termsOfServiceUrl =
      'https://lune-7d956.web.app/terms-of-service.html';

  static const trustHubUrl = 'https://lune-7d956.web.app/trust-hub.html';
  static const securityUrl = 'https://lune-7d956.web.app/security.html';
  static const cookiesUrl = 'https://lune-7d956.web.app/cookies.html';
  static const ipAddressUrl = 'https://lune-7d956.web.app/ip-address.html';
  static const privacyFaqUrl = 'https://lune-7d956.web.app/privacy-faq.html';
  static const yourBodyYourDataUrl =
      'https://lune-7d956.web.app/your-body-your-data.html';
  static const yourDataEndsUrl =
      'https://lune-7d956.web.app/your-data-ends.html';
  static const accessibilityUrl =
      'https://lune-7d956.web.app/accessibility.html';

  static const aboutUrl = 'https://lune-7d956.web.app/about.html';
  static const contactUrl = 'https://lune-7d956.web.app/contact.html';
  static const partnerUrl = 'https://lune-7d956.web.app/partner.html';

  static const supportEmail = 'merrsoheb@gmail.com';

  static Uri get supportMailto => Uri(
        scheme: 'mailto',
        path: supportEmail,
        query: 'subject=${Uri.encodeComponent('Lune Support')}',
      );

  static const appName = 'Lune';
  static const dataController = 'Lune';
  static const effectiveDate = 'July 7, 2026';
}
