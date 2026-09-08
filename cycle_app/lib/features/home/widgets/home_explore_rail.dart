import 'package:flutter/material.dart';

import '../../../core/cms/app_settings.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/feminine_icon.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../../education/presentation/education_hub_page.dart';
import '../../partner/presentation/partner_page.dart';
import '../cycle_calendar_page.dart';
import '../insights_hub.dart';
import '../sub_feature_page.dart';

/// Compact shortcuts to destinations that have no other home on this screen.
///
/// Self-care and Community are deliberately absent: both are bottom-bar tabs
/// already, and a shortcut that lands on a tab the user can reach in one tap
/// is just a second door to the same room.
class HomeExploreRail extends StatelessWidget {
  const HomeExploreRail({
    super.key,
    required this.settings,
    this.showHeader = true,
  });

  final AppSettings settings;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final items = <_ExploreItem>[
      if (FeatureFlags.isEnabledSync(FeatureFlags.aiChatEnabled))
        _ExploreItem(
          icon: FeminineIcon.ai,
          label: l10n.accountMenuAi,
          color: theme.colorScheme.primary,
          onTap: () {
            if (HomeShellActions.openAiChat != null) {
              HomeShellActions.openAiChat!();
            } else {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AiChatPage()),
              );
            }
          },
        ),
      _ExploreItem(
        icon: FeminineIcon.calendar,
        label: l10n.accountMenuCalendar,
        color: theme.colorScheme.secondary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SubFeaturePage(
              title: l10n.homeCycleView,
              child: const CycleCalendarPage(),
            ),
          ),
        ),
      ),
      _ExploreItem(
        icon: FeminineIcon.insights,
        label: l10n.accountMenuInsights,
        color: AppColors.accent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SubFeaturePage(
              title: l10n.insightsHubTitle,
              child: const InsightsHub(),
            ),
          ),
        ),
      ),
      if (settings.aiEducationEnabled)
        _ExploreItem(
          icon: FeminineIcon.education,
          label: l10n.accountMenuEducation,
          color: const Color(0xFF26A69A),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const EducationHubPage()),
          ),
        ),
      if (FeatureFlags.isEnabledSync(FeatureFlags.partnerSync))
        _ExploreItem(
          icon: FeminineIcon.partner,
          label: l10n.partnerTitle,
          color: theme.colorScheme.tertiary,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const PartnerPage())),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader) AppSectionHeader(title: l10n.homeExplore),
        LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = (constraints.maxWidth - 20) / 3;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: tileWidth,
                      child: AppQuickTile(
                        femIcon: item.icon,
                        label: item.label,
                        color: item.color,
                        onTap: item.onTap,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ExploreItem {
  const _ExploreItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final FeminineIcon icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
