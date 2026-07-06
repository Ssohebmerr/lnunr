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
                  // Single sort row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: CommunityFilterChips(
                        items: [
                          (
                            id: 'newest',
                            label: l10n.communitySortNewest,
                            icon: Icons.schedule_rounded
                          ),
                          (
                            id: 'discussed',
                            label: l10n.communitySortDiscussed,
                            icon: Icons.forum_outlined
                          ),
                          (
                            id: 'mine',
                            label: l10n.communityFilterMyPosts,
                            icon: Icons.person_outline_rounded
                          ),
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
              gradient: active ? AuraDecorations.primaryGradient : null,
              color: active
                  ? null
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
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AuraColors.rose.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
