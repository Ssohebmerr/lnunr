import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../data/community_catalog_repository.dart';
import '../../data/community_sort.dart';
import '../../data/models/community.dart';
import '../widgets/community_card.dart';
import '../widgets/community_recommended_row.dart';
import '../widgets/community_ui.dart';

class CommunityDiscoverTab extends StatelessWidget {
  const CommunityDiscoverTab({
    super.key,
    required this.l10n,
    required this.lang,
    required this.joinedIds,
    required this.searchController,
    required this.category,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.communities,
    required this.catalog,
    required this.userGoal,
    required this.onRefresh,
    required this.onOpen,
  });

  final AppLocalizations l10n;
  final String lang;
  final List<String> joinedIds;
  final TextEditingController searchController;
  final String category;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onCategoryChanged;
  final List<Community> communities;
  final Map<String, CommunityCatalogEntry> catalog;
  final UserGoalTypes? userGoal;
  final Future<void> Function() onRefresh;
  final void Function(Community, bool) onOpen;

  @override
  Widget build(BuildContext context) {
    final categories = <(String, String, IconData)>[
      ('all', l10n.communityCatAll, Icons.apps_rounded),
      ('general', l10n.communityCatGeneral, Icons.spa_rounded),
      ('conception', l10n.communityCatConception, Icons.favorite_rounded),
      ('contraception', l10n.communityCatContraception, Icons.shield_rounded),
      ('condition', l10n.communityCatCondition,
          Icons.medical_information_rounded),
      ('support', l10n.communityCatSupport, Icons.volunteer_activism_rounded),
      ('culture', l10n.communityCatCulture, Icons.public_rounded),
      ('age', l10n.communityCatAge, Icons.cake_rounded),
    ];

    final recommended = recommendedCommunities(
      communities: communities,
      catalog: catalog,
      languageCode: lang,
      goal: userGoal,
      joinedIds: joinedIds,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          CommunitySearchField(
            controller: searchController,
            hint: l10n.communitySearchHint,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          CommunityFilterChips(
            items: categories
                .map((c) => (id: c.$1, label: c.$2, icon: null))
                .toList(),
            selected: category,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: 16),
          if (category == 'all' && searchController.text.trim().isEmpty)
            CommunityRecommendedRow(
              communities: recommended,
              languageCode: lang,
              joinedIds: joinedIds,
              onOpen: onOpen,
            ),
          Row(
            children: [
              Text(
                l10n.communityBrowse,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${communities.length}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...communities.map(
            (c) => CommunityCard(
              community: c,
              languageCode: lang,
              isJoined: joinedIds.contains(c.id),
              onTap: () => onOpen(c, joinedIds.contains(c.id)),
            ),
          ),
        ],
      ),
    );
  }
}
