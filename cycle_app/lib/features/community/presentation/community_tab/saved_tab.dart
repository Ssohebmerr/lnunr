import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/community_repository.dart';
import '../../data/models/community_post.dart';
import '../widgets/community_ui.dart';
import '../widgets/post_card.dart';

class CommunitySavedTab extends StatelessWidget {
  const CommunitySavedTab({
    super.key,
    required this.alias,
    required this.onPostTap,
    required this.onRefresh,
  });

  final String? alias;
  final void Function(CommunityPost) onPostTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(child: Text(l10n.communityLoginRequired));
    }

    final repo = context.read<CommunityRepository>();
    // Listen to the blocked-users stream first so we can pass the current
    // block list into watchSavedPosts — otherwise posts from authors the
    // user blocked would resurface through the saved tab.
    return StreamBuilder<Set<String>>(
      stream: repo.watchBlockedUids(uid),
      initialData: const <String>{},
      builder: (context, blockedSnap) {
        final blocked = blockedSnap.data ?? const <String>{};
        return StreamBuilder<List<CommunityPost>>(
          stream: repo
              .watchSavedPosts(uid)
              .map(
                (posts) =>
                    posts.where((p) => !blocked.contains(p.authorUid)).toList(),
              ),
          builder: (context, snap) {
            final posts = snap.data ?? [];
            if (posts.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: CommunityEmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: l10n.communityTabSaved,
                        subtitle: l10n.communitySavedEmpty,
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.paddingOf(context).bottom + 24,
                ),
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(
                  post: posts[i],
                  showCommunity: true,
                  onTap: () => onPostTap(posts[i]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
