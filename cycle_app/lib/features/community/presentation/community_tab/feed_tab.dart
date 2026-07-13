import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/theme/app_design_tokens.dart';
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
  final _searchController = TextEditingController();
  String _search = '';
  String _categoryFilter = 'all';

  /// Selected feed chip: newest / popular / discussed / following / mine /
  /// commented. Replaces the old sort enum + my-posts toggle pair.
  String _feedChip = 'newest';

  // Lazy streams — only created the first time their chip is selected so
  // regular feed browsing never runs the extra queries.
  Stream<Set<String>>? _followingUids;
  Stream<Set<String>>? _commentedPostIds;

  void _selectChip(String id) {
    final repo = context.read<CommunityRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    setState(() {
      _feedChip = id;
      if (uid != null) {
        if (id == 'following') {
          _followingUids ??= repo.watchFollowingUids(uid);
        } else if (id == 'commented') {
          _commentedPostIds ??= repo.watchMyCommentedPostIds(uid);
        }
      }
    });
  }

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

  int get _activeFilterCount =>
      (_categoryFilter != 'all' ? 1 : 0) + (_typeFilter != null ? 1 : 0);

  List<({String id, String label})> _categories(AppLocalizations l10n) => [
    (id: 'all', label: l10n.communityCatAll),
    (id: 'general', label: l10n.communityCatGeneral),
    (id: 'conception', label: l10n.communityCatConception),
    (id: 'contraception', label: l10n.communityCatContraception),
    (id: 'condition', label: l10n.communityCatCondition),
    (id: 'support', label: l10n.communityCatSupport),
    (id: 'culture', label: l10n.communityCatCulture),
    (id: 'age', label: l10n.communityCatAge),
  ];

  /// Category + post-type filters live in a bottom sheet so the feed header
  /// stays clean — one search row and one sort row.
  Future<void> _openFilterSheet(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    var category = _categoryFilter;
    var type = _typeFilter;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setModalState) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.communityFilters,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setModalState(() {
                          category = 'all';
                          type = null;
                        }),
                        child: Text(l10n.communityFilterReset),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.communityFilterCategory,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in _categories(l10n))
                        CommunityChoiceChip(
                          label: c.label,
                          selected: category == c.id,
                          onTap: () => setModalState(() => category = c.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.communityFilterPostType,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CommunityChoiceChip(
                        label: l10n.communityFilterAll,
                        selected: type == null,
                        onTap: () => setModalState(() => type = null),
                      ),
                      for (final t in PostType.values)
                        CommunityChoiceChip(
                          label: _typeLabel(t, l10n),
                          selected: type == t,
                          onTap: () => setModalState(() => type = t),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.communityFilterApply),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (mounted && (category != _categoryFilter || type != _typeFilter)) {
      setState(() {
        _categoryFilter = category;
        _typeFilter = type;
      });
    }
  }

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
      stream: uid != null ? repo.watchBlockedUids(uid) : Stream.value(const {}),
      builder: (context, blockedSnap) {
        final blocked = blockedSnap.data ?? const <String>{};
        return StreamBuilder<Set<String>>(
          stream: _followingUids ?? Stream.value(const {}),
          builder: (context, followingSnap) {
            final followed = followingSnap.data ?? const <String>{};
            return StreamBuilder<Set<String>>(
              stream: _commentedPostIds ?? Stream.value(const {}),
              builder: (context, commentedSnap) {
                final commented = commentedSnap.data ?? const <String>{};
                return _buildFeed(
                  context,
                  l10n,
                  repo,
                  blocked: blocked,
                  followed: followed,
                  commented: commented,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFeed(
    BuildContext context,
    AppLocalizations l10n,
    CommunityRepository repo, {
    required Set<String> blocked,
    required Set<String> followed,
    required Set<String> commented,
  }) {
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
              sort: _feedChip == 'discussed'
                  ? CommunityFeedSort.discussed
                  : CommunityFeedSort.newest,
              authorUidFilter: _feedChip == 'mine' ? currentUid : null,
            );
            switch (_feedChip) {
              case 'popular':
                posts = sortByPopularity(posts);
              case 'following':
                posts = posts
                    .where((p) => followed.contains(p.authorUid))
                    .toList();
              case 'commented':
                posts = posts.where((p) => commented.contains(p.id)).toList();
            }

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
                      child: Material(
                        color: Theme.of(context).colorScheme.surface.withValues(
                          alpha: Theme.of(context).brightness == Brightness.dark
                              ? 0.22
                              : 0.55,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.08),
                          ),
                        ),
                        child: InkWell(
                          onTap: widget.onJoinPrompt,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.explore_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.communityFeedBrowseTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      Text(
                                        l10n.communityFeedBrowseSubtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              height: 1.25,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Search + filters in a single row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: CommunitySearchField(
                              controller: _searchController,
                              hint: l10n.communitySearchPosts,
                              onChanged: (v) => setState(() => _search = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _FilterButton(
                            activeCount: _activeFilterCount,
                            tooltip: l10n.communityFilters,
                            onTap: () => _openFilterSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Feed chips: sort modes + personal filters, always visible.
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CommunityFilterChips(
                        items: [
                          (
                            id: 'newest',
                            label: l10n.communitySortNewest,
                            icon: Icons.schedule_rounded,
                          ),
                          (
                            id: 'popular',
                            label: l10n.communityFeedPopular,
                            icon: Icons.local_fire_department_outlined,
                          ),
                          (
                            id: 'following',
                            label: l10n.communityFollowingTitle,
                            icon: Icons.favorite_outline_rounded,
                          ),
                          (
                            id: 'discussed',
                            label: l10n.communitySortDiscussed,
                            icon: Icons.forum_outlined,
                          ),
                          (
                            id: 'mine',
                            label: l10n.communityFilterMyPosts,
                            icon: Icons.person_outline_rounded,
                          ),
                          (
                            id: 'commented',
                            label: l10n.communityFeedMyComments,
                            icon: Icons.chat_bubble_outline_rounded,
                          ),
                        ],
                        selected: _feedChip,
                        onSelected: _selectChip,
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
                      padding: EdgeInsets.fromLTRB(
                        16,
                        12,
                        16,
                        MediaQuery.paddingOf(context).bottom + 24,
                      ),
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
  }
}

/// Compact filter button with an active-filter count badge.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.activeCount,
    required this.tooltip,
    required this.onTap,
  });

  final int activeCount;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = activeCount > 0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? theme.colorScheme.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.85)),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: active
                    ? Colors.transparent
                    : (isDark ? Colors.white : theme.colorScheme.outline)
                          .withValues(alpha: isDark ? 0.08 : 0.1),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (active)
                  PositionedDirectional(
                    top: 6,
                    end: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AuraColors.rose.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$activeCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AuraColors.roseDeep,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
