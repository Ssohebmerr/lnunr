part of 'community_detail_screen.dart';

class _PostsList extends StatefulWidget {
  const _PostsList({
    required this.communityId,
    required this.topic,
    required this.joined,
    required this.busy,
    required this.onJoin,
    required this.onPostTap,
    required this.onAnswerPrompt,
    required this.onCompose,
    required this.alias,
  });

  final String communityId;
  final String topic;
  final bool joined;
  final bool busy;
  final String alias;
  final VoidCallback onJoin;
  final void Function(CommunityPost) onPostTap;

  /// Opens the composer pre-filled with the weekly question.
  final void Function(String question) onAnswerPrompt;

  /// Opens the blank composer (inline "start a post" bar).
  final VoidCallback onCompose;

  @override
  State<_PostsList> createState() => _PostsListState();
}

class _PostsListState extends State<_PostsList> {
  final _searchController = TextEditingController();
  String _search = '';

  // Pagination state
  final List<CommunityPost> _posts = [];
  bool _loading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_loading &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    final repo = context.read<CommunityRepository>();
    setState(() => _loading = true);
    try {
      final posts = await repo.fetchPostsPage(widget.communityId);
      final lastDoc = await repo.fetchPostsPageRaw(widget.communityId);
      if (mounted) {
        setState(() {
          _posts
            ..clear()
            ..addAll(posts);
          _lastDoc = lastDoc;
          _hasMore = posts.length >= CommunityRepository.postsPerPage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_lastDoc == null || !_hasMore) return;
    final repo = context.read<CommunityRepository>();
    setState(() => _loading = true);
    try {
      final posts = await repo.fetchPostsPage(
        widget.communityId,
        lastDocument: _lastDoc,
      );
      final lastDoc = await repo.fetchPostsPageRaw(
        widget.communityId,
        lastDocument: _lastDoc,
      );
      if (mounted) {
        setState(() {
          _posts.addAll(posts);
          _lastDoc = lastDoc;
          _hasMore = posts.length >= CommunityRepository.postsPerPage;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    _lastDoc = null;
    _hasMore = true;
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<CommunityRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        if (!widget.joined)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: widget.busy ? null : widget.onJoin,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              icon: const Icon(Icons.group_add_rounded),
              label: Text(l10n.communityJoin),
            ),
          )
        else ...[
          _InlineComposer(
            alias: widget.alias,
            onTap: widget.busy ? null : widget.onCompose,
          ),
          WeeklyQuestionCard(
            topic: widget.topic,
            onAnswer: widget.onAnswerPrompt,
          ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: CommunitySearchField(
            controller: _searchController,
            hint: l10n.communitySearchPosts,
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: StreamBuilder<Set<String>>(
            stream: uid != null
                ? repo.watchBlockedUids(uid)
                : Stream.value(const {}),
            builder: (context, blockedSnap) {
              final blocked = blockedSnap.data ?? const <String>{};
              final posts = filterAndSortCommunityPosts(
                posts: _posts
                    .where((p) => !blocked.contains(p.authorUid))
                    .toList(),
                query: _search,
                sort: CommunityFeedSort.newest,
              );

              if (posts.isEmpty && _loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (posts.isEmpty) {
                return CommunityEmptyState(
                  icon: Icons.article_outlined,
                  title: l10n.communityNoPosts,
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                  controller: _scrollController,
                  // Extra bottom space so the centered "New post" pill never
                  // overlaps the last post.
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    widget.joined ? 132 : 16,
                  ),
                  itemCount: posts.length + (_hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i >= posts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return PostCard(
                      post: posts[i],
                      onTap: () => widget.onPostTap(posts[i]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A prominent "start a post" bar at the top of the feed — the familiar
/// professional-app pattern, so posting is one obvious tap instead of hunting
/// for the FAB. Opens the same composer as [_CommunityDetailScreenState._createPost].
class _InlineComposer extends StatelessWidget {
  const _InlineComposer({required this.alias, required this.onTap});

  final String alias;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final initial = alias.trim().isNotEmpty
        ? alias.trim()[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: AppFloatingGlassPanel(
        onTap: onTap,
        radius: AppRadius.md,
        tint: theme.colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(
                  alpha: isDark ? 0.2 : 0.12,
                ),
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.communityPostHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.community,
    required this.lang,
    required this.joined,
    required this.busy,
    required this.onLeave,
  });
  final Community community;
  final String lang;
  final bool joined;
  final bool busy;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rules = community.rulesForLocale(lang).isNotEmpty
        ? community.rulesForLocale(lang)
        : (lang.startsWith('ar')
              ? CommunitySeed.defaultRulesAr
              : CommunitySeed.defaultRulesEn);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, joined ? 132 : 16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AuraDecorations.softCard(isDark, radius: AppRadius.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: CommunityTopicPalette.gradient(community.topic),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(community.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          community.nameForLocale(lang),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.descriptionForLocale(lang),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.communityRules,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AuraDecorations.softCard(isDark, radius: AppRadius.md),
          child: Text(
            rules,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ),
        if (joined) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: busy ? null : onLeave,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.communityLeave),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.communityDisclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
