import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../data/community_catalog_repository.dart';
import '../../data/community_list_resolver.dart';
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
      (
        'condition',
        l10n.communityCatCondition,
        Icons.medical_information_rounded,
      ),
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
      // Recommendations are a curated preview. Every community remains
      // available in the complete lists below without repeating the entire
      // catalog in the horizontal rail.
      limit: 6,
    );
    final unjoined = communities
        .where((c) => !joinedIds.contains(c.id))
        .toList();
    final joinedInBrowse = communities
        .where((c) => joinedIds.contains(c.id))
        .toList();
    final selectedCategory = categories.firstWhere(
      (item) => item.$1 == category,
      orElse: () => categories.first,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: CommunitySearchField(
                  controller: searchController,
                  hint: l10n.communitySearchHint,
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 10),
              _CategoryFilterButton(
                label: selectedCategory.$2,
                active: category != 'all',
                onTap: () => _pickCategory(context, categories),
              ),
            ],
          ),
          if (category != 'all') ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: InputChip(
                avatar: Icon(selectedCategory.$3, size: 15),
                label: Text(selectedCategory.$2),
                onDeleted: () => onCategoryChanged('all'),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                side: BorderSide.none,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.45),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (category == 'all' && searchController.text.trim().isEmpty)
            CommunityRecommendedRow(
              communities: recommended,
              languageCode: lang,
              joinedIds: joinedIds,
              onOpen: onOpen,
            ),
          if (unjoined.isNotEmpty) ...[
            _SectionHeading(
              title: l10n.communityDiscoverNew,
              count: unjoined.length,
              emphasized: true,
            ),
            const SizedBox(height: 10),
            ...unjoined.map(
              (c) => CommunityCard(
                community: c,
                languageCode: lang,
                isJoined: false,
                isJoinable: CommunityListResolver.isJoinable(c.id, catalog),
                onTap: () => onOpen(c, false),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (joinedInBrowse.isNotEmpty) ...[
            _SectionHeading(
              title: l10n.communityDiscoverJoined,
              count: joinedInBrowse.length,
            ),
            const SizedBox(height: 10),
            ...joinedInBrowse.map(
              (c) => CommunityCard(
                community: c,
                languageCode: lang,
                isJoined: true,
                isJoinable: true,
                onTap: () => onOpen(c, true),
              ),
            ),
          ],
          if (unjoined.isEmpty && joinedInBrowse.isEmpty)
            CommunityEmptyState(
              icon: Icons.search_off_rounded,
              title: l10n.communityBrowse,
              subtitle: l10n.communityDiscoverNoResults,
            ),
        ],
      ),
    );
  }

  Future<void> _pickCategory(
    BuildContext context,
    List<(String, String, IconData)> categories,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in categories)
              ListTile(
                leading: Icon(item.$3),
                title: Text(item.$2),
                trailing: item.$1 == category
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetContext).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(sheetContext, item.$1),
              ),
          ],
        ),
      ),
    );
    if (selected != null && selected != category) onCategoryChanged(selected);
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.count,
    this.emphasized = false,
  });

  final String title;
  final int count;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasized
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryFilterButton extends StatelessWidget {
  const _CategoryFilterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.9)),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
