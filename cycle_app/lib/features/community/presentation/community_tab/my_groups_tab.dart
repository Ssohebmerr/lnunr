import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/community_catalog_repository.dart';
import '../../data/community_list_resolver.dart';
import '../../data/community_sort.dart';
import '../../data/models/community.dart';
import '../../data/models/community_membership.dart';
import '../widgets/community_card.dart';
import '../widgets/community_ui.dart';

class CommunityMyGroupsTab extends StatelessWidget {
  const CommunityMyGroupsTab({
    super.key,
    required this.l10n,
    required this.lang,
    required this.memberships,
    required this.communities,
    required this.catalog,
    required this.onOpen,
    required this.onRefresh,
    this.onBrowse,
  });

  final AppLocalizations l10n;
  final String lang;
  final List<CommunityMembership> memberships;
  final List<Community> communities;
  final Map<String, CommunityCatalogEntry> catalog;
  final void Function(Community, bool) onOpen;
  final Future<void> Function() onRefresh;
  final VoidCallback? onBrowse;

  @override
  Widget build(BuildContext context) {
    final lookup = {
      for (final c in CommunityListResolver.browseAll(catalog: catalog)) c.id: c,
      for (final c in communities) c.id: c,
    };
    final mine = sortJoinedCommunities(
      communities: lookup.values.toList(),
      memberships: memberships,
    );

    if (mine.isEmpty) {
      return CommunityEmptyState(
        icon: Icons.favorite_outline,
        title: l10n.communityTabMine,
        subtitle: l10n.communityMineEmpty,
        actionLabel: l10n.communityTabDiscover,
        onAction: onBrowse,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mine.length,
        itemBuilder: (_, i) => CommunityCard(
          community: mine[i],
          languageCode: lang,
          isJoined: true,
          onTap: () => onOpen(mine[i], true),
        ),
      ),
    );
  }
}
