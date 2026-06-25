import 'package:flutter/material.dart';

import '../../../core/cms/app_settings.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import 'home_announcement_banner.dart';
import 'home_promo_banners.dart';
import 'home_feed_sections.dart';

/// Collapsed by default — announcements & promos stay available without clutter.
class HomeUpdatesPanel extends StatelessWidget {
  const HomeUpdatesPanel({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      blur: false,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.campaign_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            l10n.homeUpdatesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            l10n.homeUpdatesSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: [
            const HomeTodayBanner(),
            const SizedBox(height: 10),
            HomeAnnouncementBanner(settings: settings),
            const HomePromoBanners(),
          ],
        ),
      ),
    );
  }
}
