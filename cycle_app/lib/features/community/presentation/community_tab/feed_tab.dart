import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_repository.dart';
import '../../data/community_seed.dart';
import '../../data/models/community_post.dart';
import '../../data/models/post_type.dart';
import '../community_feed_utils.dart';
import '../widgets/community_ui.dart';
import '../widgets/post_card.dart';
import '../widgets/stories_row.dart';

class CommunityFeedTab extends StatefulWidget {
  const CommunityFeedTab({
    super.key,
    required this.joinedIds,
    required this.alias,
    required this.avatarIndex,
    required this.onPostTap,
    required this.onJoinPrompt,
    required this.onRefresh,
    required this.onCreateStory,
  });

  final List<String> joinedIds;
  final String? alias;
  final int avatarIndex;
  final void Function(CommunityPost) onPostTap;
  final VoidCallback onJoinPrompt;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreateStory;

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab> {
  PostType? _typeFilter;
  CommunityFeedSort _sort = CommunityFeedSort.newest;
  bool _myPostsOnly = false;
  final _searchController = TextEditingController();
  String _search = '';
  String _categoryFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _typeLabel(PostType type, AppLocalizations l10n) => switch (type) {
        PostType.support => l10n.postTypeSupport,
        PostType.question => l10n.postTypeQuestion,
        PostType.tip => l10n.postTypeTip,
        PostType.vent => l10n.postTypeVent,
        PostType.milestone => l10n.postTypeMilestone,
        PostType.poll => l10n.postTypePoll,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.joinedIds.isEmpty) {
      return CommunityEmptyState(
        icon: Icons.dynamic_feed_rounded,
        title: l10n.communityTabFeed,
        subtitle: l10n.communityFeedEmpty,
        actionLabel: l10n.communityTabDiscover,
        onAction: widget.onJoinPrompt,
      );
    }

    final repo = context.read<CommunityRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<Set<String>>(
      stream:
          uid != null ? repo.watchBlockedUids(uid) : Stream.value(const {}),
      builder: (context, blockedSnap) {
        final blocked = blockedSnap.data ?? const <String>{};
        return StreamBuilder<List<CommunityPost>>(
          stream: repo.watchJoinedFeed(widget.joinedIds),
          builder: (context, snap) {
            final all = (snap.data ?? [])
                .where((p) => !blocked.contains(p.authorUid))
                .toList();
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            var posts = _typeFilter == null
                ? all
                : all.where((p) => p.postType == _typeFilter).toList();
            if (_categoryFilter != 'all') {
              posts = posts.where((p) {
                final c = CommunitySeed.byId(p.communityId);
                return c?.topic == _categoryFilter;
              }).toList();
            }
            posts = filterAndSortCommunityPosts(
              posts: posts,
              query: _search,
              sort: _sort,
              authorUidFilter: _myPostsOnly ? currentUid : null,
            );

            return RefreshIndicator(
              onRefresh: widget.onRefresh,
              child: CustomScrollView(
                slivers: [
                  if (FeatureFlags.isEnabledSync(FeatureFlags.luneStories))
                    SliverToBoxAdapter(
                      child: StoriesRow(
                        joinedIds: widget.joinedIds,
                        alias: widget.alias,
                        avatarIndex: widget.avatarIndex,
                        onCreateStory: widget.onCreateStory,
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: CommunitySearchField(
                        controller: _searchController,
                        hint: l10n.communitySearchPosts,
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CommunityFilterChips(
                        items: [
                          (id: 'all', label: l10n.communityCatAll, icon: null),
                          (id: 'general', label: l10n.communityCatGeneral, icon: null),
                          (id: 'conception', label: l10n.communityCatConception, icon: null),
                          (id: 'contraception', label: l10n.communityCatContraception, icon: null),
                          (id: 'condition', label: l10n.communityCatCondition, icon: null),
                          (id: 'support', label: l10n.communityCatSupport, icon: null),
                          (id: 'culture', label: l10n.communityCatCulture, icon: null),
                          (id: 'age', label: l10n.communityCatAge, icon: null),
                        ],
                        selected: _categoryFilter,
                        onSelected: (id) => setState(() => _categoryFilter = id),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CommunityFilterChips(
                        items: [
                          (id: 'all', label: l10n.communityFilterAll, icon: null),
                          ...PostType.values.map(
                            (t) => (
                              id: t.value,
                              label: _typeLabel(t, l10n),
                              icon: null,
                            ),
                          ),
                        ],
                        selected: _typeFilter?.value ?? 'all',
                        onSelected: (id) => setState(() {
                          if (id == 'all') {
                            _typeFilter = null;
                          } else {
                            _typeFilter = PostType.fromValue(id);
                          }
                        }),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CommunityFilterChips(
                        items: [
                          (id: 'newest', label: l10n.communitySortNewest, icon: null),
                          (id: 'discussed', label: l10n.communitySortDiscussed, icon: null),
                          (id: 'mine', label: l10n.communityFilterMyPosts, icon: null),
                        ],
                        selected: _myPostsOnly
                            ? 'mine'
                            : (_sort == CommunityFeedSort.discussed
                                ? 'discussed'
                                : 'newest'),
                        onSelected: (id) => setState(() {
                          if (id == 'mine') {
                            _myPostsOnly = true;
                            _sort = CommunityFeedSort.newest;
                          } else {
                            _myPostsOnly = false;
                            _sort = id == 'discussed'
                                ? CommunityFeedSort.discussed
                                : CommunityFeedSort.newest;
                          }
                        }),
                      ),
                    ),
                  ),
                  if (posts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: CommunityEmptyState(
                        icon: Icons.article_outlined,
                        title: l10n.communityNoPosts,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => PostCard(
                            post: posts[i],
                            showCommunity: true,
                            onTap: () => widget.onPostTap(posts[i]),
                          ),
                          childCount: posts.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
