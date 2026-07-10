import 'package:flutter/material.dart';

import '../../../core/privacy/privacy_constants.dart';
import '../../../l10n/app_localizations.dart';
import 'trust_document_id.dart';

class TrustSection {
  const TrustSection({required this.title, required this.body, this.isFaq = false});

  final String title;
  final String body;
  final bool isFaq;
}

class TrustDocumentMeta {
  const TrustDocumentMeta({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.url,
    required this.sections,
  });

  final TrustDocumentId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String url;
  final List<TrustSection> sections;
}

class TrustHubItem {
  const TrustHubItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final TrustDocumentId id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class TrustDocumentRegistry {
  TrustDocumentRegistry._();

  static List<TrustHubItem> hubItems(AppLocalizations l10n) => [
        TrustHubItem(
          id: TrustDocumentId.security,
          title: l10n.trustLinkSecurity,
          subtitle: l10n.trustLinkSecuritySub,
          icon: Icons.shield_outlined,
        ),
        TrustHubItem(
          id: TrustDocumentId.yourBodyYourData,
          title: l10n.trustLinkBodyData,
          subtitle: l10n.trustLinkBodyDataSub,
          icon: Icons.favorite_outline,
        ),
        TrustHubItem(
          id: TrustDocumentId.yourDataEnds,
          title: l10n.trustLinkDataEnds,
          subtitle: l10n.trustLinkDataEndsSub,
          icon: Icons.auto_delete_outlined,
        ),
        TrustHubItem(
          id: TrustDocumentId.privacyFaq,
          title: l10n.trustLinkFaq,
          subtitle: l10n.trustLinkFaqSub,
          icon: Icons.help_outline_rounded,
        ),
        TrustHubItem(
          id: TrustDocumentId.cookies,
          title: l10n.trustLinkCookies,
          subtitle: l10n.trustLinkCookiesSub,
          icon: Icons.cookie_outlined,
        ),
        TrustHubItem(
          id: TrustDocumentId.ipAddress,
          title: l10n.trustLinkIp,
          subtitle: l10n.trustLinkIpSub,
          icon: Icons.language_outlined,
        ),
        TrustHubItem(
          id: TrustDocumentId.accessibility,
          title: l10n.trustLinkAccessibility,
          subtitle: l10n.trustLinkAccessibilitySub,
          icon: Icons.accessibility_new_outlined,
        ),
      ];

  static TrustDocumentMeta document(
    TrustDocumentId id,
    AppLocalizations l10n,
  ) {
    return TrustDocumentMeta(
      id: id,
      title: _title(id, l10n),
      subtitle: _subtitle(id, l10n),
      icon: _icon(id),
      url: _url(id),
      sections: _sections(id, l10n),
    );
  }

  static String _title(TrustDocumentId id, AppLocalizations l10n) => switch (id) {
        TrustDocumentId.security => l10n.trustSecurityTitle,
        TrustDocumentId.cookies => l10n.trustCookiesTitle,
        TrustDocumentId.ipAddress => l10n.trustIpTitle,
        TrustDocumentId.privacyFaq => l10n.trustFaqTitle,
        TrustDocumentId.yourBodyYourData => l10n.trustBodyDataTitle,
        TrustDocumentId.yourDataEnds => l10n.trustDataEndsTitle,
        TrustDocumentId.accessibility => l10n.trustA11yTitle,
      };

  static String _subtitle(TrustDocumentId id, AppLocalizations l10n) =>
      switch (id) {
        TrustDocumentId.security => l10n.trustSecurityIntro,
        TrustDocumentId.cookies => l10n.trustCookiesIntro,
        TrustDocumentId.ipAddress => l10n.trustIpIntro,
        TrustDocumentId.privacyFaq => l10n.trustFaqIntro,
        TrustDocumentId.yourBodyYourData => l10n.trustBodyDataIntro,
        TrustDocumentId.yourDataEnds => l10n.trustDataEndsIntro,
        TrustDocumentId.accessibility => l10n.trustA11yIntro,
      };

  static IconData _icon(TrustDocumentId id) => switch (id) {
        TrustDocumentId.security => Icons.shield_outlined,
        TrustDocumentId.cookies => Icons.cookie_outlined,
        TrustDocumentId.ipAddress => Icons.language_outlined,
        TrustDocumentId.privacyFaq => Icons.help_outline_rounded,
        TrustDocumentId.yourBodyYourData => Icons.favorite_outline,
        TrustDocumentId.yourDataEnds => Icons.auto_delete_outlined,
        TrustDocumentId.accessibility => Icons.accessibility_new_outlined,
      };

  static String _url(TrustDocumentId id) => switch (id) {
        TrustDocumentId.security => PrivacyConstants.securityUrl,
        TrustDocumentId.cookies => PrivacyConstants.cookiesUrl,
        TrustDocumentId.ipAddress => PrivacyConstants.ipAddressUrl,
        TrustDocumentId.privacyFaq => PrivacyConstants.privacyFaqUrl,
        TrustDocumentId.yourBodyYourData => PrivacyConstants.yourBodyYourDataUrl,
        TrustDocumentId.yourDataEnds => PrivacyConstants.yourDataEndsUrl,
        TrustDocumentId.accessibility => PrivacyConstants.accessibilityUrl,
      };

  static List<TrustSection> _sections(
    TrustDocumentId id,
    AppLocalizations l10n,
  ) =>
      switch (id) {
        TrustDocumentId.security => [
            TrustSection(title: l10n.trustSecurityS1Title, body: l10n.trustSecurityS1Body),
            TrustSection(title: l10n.trustSecurityS2Title, body: l10n.trustSecurityS2Body),
            TrustSection(title: l10n.trustSecurityS3Title, body: l10n.trustSecurityS3Body),
            TrustSection(title: l10n.trustSecurityS4Title, body: l10n.trustSecurityS4Body),
            TrustSection(title: l10n.trustSecurityS5Title, body: l10n.trustSecurityS5Body),
            TrustSection(title: l10n.trustSecurityS6Title, body: l10n.trustSecurityS6Body),
            TrustSection(title: l10n.trustSecurityS7Title, body: l10n.trustSecurityS7Body),
            TrustSection(title: l10n.trustSecurityS8Title, body: l10n.trustSecurityS8Body),
            TrustSection(title: l10n.trustSecurityS9Title, body: l10n.trustSecurityS9Body),
            TrustSection(title: l10n.trustSecurityS10Title, body: l10n.trustSecurityS10Body),
          ],
        TrustDocumentId.cookies => [
            TrustSection(title: l10n.trustCookiesS1Title, body: l10n.trustCookiesS1Body),
            TrustSection(title: l10n.trustCookiesS2Title, body: l10n.trustCookiesS2Body),
            TrustSection(title: l10n.trustCookiesS3Title, body: l10n.trustCookiesS3Body),
            TrustSection(title: l10n.trustCookiesS4Title, body: l10n.trustCookiesS4Body),
            TrustSection(title: l10n.trustCookiesS5Title, body: l10n.trustCookiesS5Body),
            TrustSection(title: l10n.trustCookiesS6Title, body: l10n.trustCookiesS6Body),
            TrustSection(title: l10n.trustCookiesS7Title, body: l10n.trustCookiesS7Body),
            TrustSection(title: l10n.trustCookiesS8Title, body: l10n.trustCookiesS8Body),
          ],
        TrustDocumentId.ipAddress => [
            TrustSection(title: l10n.trustIpS1Title, body: l10n.trustIpS1Body),
            TrustSection(title: l10n.trustIpS2Title, body: l10n.trustIpS2Body),
            TrustSection(title: l10n.trustIpS3Title, body: l10n.trustIpS3Body),
            TrustSection(title: l10n.trustIpS4Title, body: l10n.trustIpS4Body),
            TrustSection(title: l10n.trustIpS5Title, body: l10n.trustIpS5Body),
            TrustSection(title: l10n.trustIpS6Title, body: l10n.trustIpS6Body),
            TrustSection(title: l10n.trustIpS7Title, body: l10n.trustIpS7Body),
            TrustSection(title: l10n.trustIpS8Title, body: l10n.trustIpS8Body),
          ],
        TrustDocumentId.privacyFaq => [
            TrustSection(title: l10n.trustFaqQ1, body: l10n.trustFaqA1, isFaq: true),
            TrustSection(title: l10n.trustFaqQ2, body: l10n.trustFaqA2, isFaq: true),
            TrustSection(title: l10n.trustFaqQ3, body: l10n.trustFaqA3, isFaq: true),
            TrustSection(title: l10n.trustFaqQ4, body: l10n.trustFaqA4, isFaq: true),
            TrustSection(title: l10n.trustFaqQ5, body: l10n.trustFaqA5, isFaq: true),
            TrustSection(title: l10n.trustFaqQ6, body: l10n.trustFaqA6, isFaq: true),
            TrustSection(title: l10n.trustFaqQ7, body: l10n.trustFaqA7, isFaq: true),
            TrustSection(title: l10n.trustFaqQ8, body: l10n.trustFaqA8, isFaq: true),
            TrustSection(title: l10n.trustFaqQ9, body: l10n.trustFaqA9, isFaq: true),
            TrustSection(title: l10n.trustFaqQ10, body: l10n.trustFaqA10, isFaq: true),
            TrustSection(title: l10n.trustFaqQ11, body: l10n.trustFaqA11, isFaq: true),
            TrustSection(title: l10n.trustFaqQ12, body: l10n.trustFaqA12, isFaq: true),
            TrustSection(title: l10n.trustFaqQ13, body: l10n.trustFaqA13, isFaq: true),
            TrustSection(title: l10n.trustFaqQ14, body: l10n.trustFaqA14, isFaq: true),
            TrustSection(title: l10n.trustFaqQ15, body: l10n.trustFaqA15, isFaq: true),
            TrustSection(title: l10n.trustFaqQ16, body: l10n.trustFaqA16, isFaq: true),
            TrustSection(title: l10n.trustFaqQ17, body: l10n.trustFaqA17, isFaq: true),
            TrustSection(title: l10n.trustFaqQ18, body: l10n.trustFaqA18, isFaq: true),
            TrustSection(title: l10n.trustFaqQ19, body: l10n.trustFaqA19, isFaq: true),
            TrustSection(title: l10n.trustFaqQ20, body: l10n.trustFaqA20, isFaq: true),
            TrustSection(title: l10n.trustFaqQ21, body: l10n.trustFaqA21, isFaq: true),
          ],
        TrustDocumentId.yourBodyYourData => [
            TrustSection(title: l10n.trustBodyDataS1Title, body: l10n.trustBodyDataS1Body),
            TrustSection(title: l10n.trustBodyDataS2Title, body: l10n.trustBodyDataS2Body),
            TrustSection(title: l10n.trustBodyDataS3Title, body: l10n.trustBodyDataS3Body),
            TrustSection(title: l10n.trustBodyDataS4Title, body: l10n.trustBodyDataS4Body),
            TrustSection(title: l10n.trustBodyDataS5Title, body: l10n.trustBodyDataS5Body),
            TrustSection(title: l10n.trustBodyDataS6Title, body: l10n.trustBodyDataS6Body),
            TrustSection(title: l10n.trustBodyDataS7Title, body: l10n.trustBodyDataS7Body),
            TrustSection(title: l10n.trustBodyDataS8Title, body: l10n.trustBodyDataS8Body),
          ],
        TrustDocumentId.yourDataEnds => [
            TrustSection(title: l10n.trustDataEndsS1Title, body: l10n.trustDataEndsS1Body),
            TrustSection(title: l10n.trustDataEndsS2Title, body: l10n.trustDataEndsS2Body),
            TrustSection(title: l10n.trustDataEndsS3Title, body: l10n.trustDataEndsS3Body),
            TrustSection(title: l10n.trustDataEndsS4Title, body: l10n.trustDataEndsS4Body),
            TrustSection(title: l10n.trustDataEndsS5Title, body: l10n.trustDataEndsS5Body),
            TrustSection(title: l10n.trustDataEndsS6Title, body: l10n.trustDataEndsS6Body),
            TrustSection(title: l10n.trustDataEndsS7Title, body: l10n.trustDataEndsS7Body),
            TrustSection(title: l10n.trustDataEndsS8Title, body: l10n.trustDataEndsS8Body),
          ],
        TrustDocumentId.accessibility => [
            TrustSection(title: l10n.trustA11yS1Title, body: l10n.trustA11yS1Body),
            TrustSection(title: l10n.trustA11yS2Title, body: l10n.trustA11yS2Body),
            TrustSection(title: l10n.trustA11yS3Title, body: l10n.trustA11yS3Body),
            TrustSection(title: l10n.trustA11yS4Title, body: l10n.trustA11yS4Body),
            TrustSection(title: l10n.trustA11yS5Title, body: l10n.trustA11yS5Body),
            TrustSection(title: l10n.trustA11yS6Title, body: l10n.trustA11yS6Body),
            TrustSection(title: l10n.trustA11yS7Title, body: l10n.trustA11yS7Body),
          ],
      };
}
