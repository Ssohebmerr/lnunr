import 'package:flutter/material.dart';

import '../../../core/cms/app_settings.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/ai_chat_page.dart';
import '../../community/presentation/community_tab.dart';
import '../../education/presentation/education_hub_page.dart';
import '../../partner/presentation/partner_page.dart';
import '../../self_care/presentation/self_care_tab.dart';
import '../cycle_calendar_page.dart';
import '../insights_tab.dart';
import '../sub_feature_page.dart';

/// Compact shortcuts — same destinations as account menu, less home clutter.
class HomeExploreRail extends StatelessWidget {
  const HomeExploreRail({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final items = <_ExploreItem>[
      _ExploreItem(
        icon: Icons.auto_awesome_rounded,
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
        icon: Icons.spa_outlined,
        label: l10n.navSelfCare,
        color: const Color(0xFFE8917A),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SubFeaturePage(
              title: l10n.navSelfCare,
              child: const SelfCareTab(),
            ),
          ),
        ),
      ),
      _ExploreItem(
        icon: Icons.calendar_month_rounded,
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
        icon: Icons.insights_rounded,
        label: l10n.accountMenuInsights,
        color: AppColors.accent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SubFeaturePage(
              title: l10n.navInsights,
              child: const InsightsTab(),
            ),
          ),
        ),
      ),
      if (settings.communityEnabled)
        _ExploreItem(
          icon: Icons.groups_rounded,
          label: l10n.accountMenuCommunity,
          color: const Color(0xFF7E57C2),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SubFeaturePage(
                title: l10n.navCommunity,
                child: const CommunityTab(),
              ),
            ),
          ),
        ),
      if (settings.aiEducationEnabled)
        _ExploreItem(
          icon: Icons.menu_book_rounded,
          label: l10n.accountMenuEducation,
          color: const Color(0xFF26A69A),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const EducationHubPage(),
            ),
          ),
        ),
      _ExploreItem(
        icon: Icons.favorite_outline,
        label: l10n.partnerTitle,
        color: theme.colorScheme.tertiary,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PartnerPage()),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.homeExplore),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 52) / 3,
                  child: AppQuickTile(
                    icon: item.icon,
                    label: item.label,
                    color: item.color,
                    onTap: item.onTap,
                  ),
                ),
              )
              .toList(),
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

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
