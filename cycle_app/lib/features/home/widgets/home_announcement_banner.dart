import 'package:flutter/material.dart';

import '../../../core/cms/app_settings.dart';
import '../../../core/widgets/app_surface.dart';

/// Admin-managed announcement shown at the top of the home feed.
class HomeAnnouncementBanner extends StatelessWidget {
  const HomeAnnouncementBanner({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    if (!settings.hasAnnouncement) return const SizedBox.shrink();

    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppGlassCard(
        blur: true,
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.campaign_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.announcementTitle(lang),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (settings.announcementBody(lang).trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      settings.announcementBody(lang),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
