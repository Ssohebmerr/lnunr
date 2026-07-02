import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
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
    required this.onOpen,
    required this.onRefresh,
  });

  final AppLocalizations l10n;
  final String lang;
  final List<CommunityMembership> memberships;
  final List<Community> communities;
  final void Function(Community, bool) onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final mine = sortJoinedCommunities(
      communities: communities,
      memberships: memberships,
    );

    if (mine.isEmpty) {
      return CommunityEmptyState(
        icon: Icons.favorite_outline,
        title: l10n.communityTabMine,
        subtitle: l10n.communityMineEmpty,
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
