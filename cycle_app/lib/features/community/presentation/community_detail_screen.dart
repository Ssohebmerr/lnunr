import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/community_seed.dart';
import '../data/models/community.dart';
import '../data/models/community_comment.dart';
import '../data/models/community_post.dart';
import '../data/moderation_result.dart';
import '../data/models/post_type.dart';
import 'community_clipboard.dart';
import 'community_share.dart';
import 'community_feed_utils.dart';
import 'compose_post_screen.dart';
import 'widgets/comment_thread_sheet.dart';
import 'widgets/community_guidelines_dialog.dart';
import 'widgets/community_safety_actions.dart';
import 'widgets/community_ui.dart';
import 'widgets/moderation_rejected_dialog.dart';
import 'widgets/post_card.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.community,
    required this.alias,
    required this.isJoined,
    this.initialPostId,
  });

  final Community community;
  final String alias;
  final bool isJoined;
  final String? initialPostId;

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _joined = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _joined = widget.isJoined;
    if (widget.initialPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPostById(widget.initialPostId!));
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openPostById(String postId) async {
    final repo = context.read<CommunityRepository>();
    final l10n = AppLocalizations.of(context)!;
    try {
      final post = await repo
          .getPost(widget.community.id, postId)
          .timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (post != null) {
        _openPostDetail(post);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityPostNotFound)),
        );
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    } catch (e, st) {
      debugPrint('CommunityDetailScreen._openPostById failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    }
  }

  Future<void> _toggleJoin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    final repo = context.read<CommunityRepository>();
    final l10n = AppLocalizations.of(context)!;

    try {
      if (_joined) {
        await repo.leaveCommunity(user.uid, widget.community.id);
        if (mounted) {
          setState(() => _joined = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.communityLeft)));
        }
      } else {
        final uid = user.uid;
        final alreadyAccepted = await CommunityGuidelinesPrefs.hasAccepted(uid);
        if (!alreadyAccepted) {
          // ignore: use_build_context_synchronously
          final accepted = await showCommunityGuidelinesDialog(
            // ignore: use_build_context_synchronously
            context,
            community: widget.community,
          );
          if (!accepted || !mounted) return;
          await CommunityGuidelinesPrefs.accept(uid);
        }

        await repo.joinCommunity(
          uid: uid,
          communityId: widget.community.id,
          alias: widget.alias,
        );
        if (mounted) {
          setState(() => _joined = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.communityJoined)));
        }
      }
    } on MinorRestrictedException {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.communityMinorRestricted)));
      }
    } on CommunityBannedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityBannedMessage)),
        );
      }
    } on CommunityFullException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityFull)),
        );
      }
    } catch (e, st) {
      debugPrint('CommunityDetailScreen._toggleJoin failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPost() async {
    if (!_joined) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await context.read<CommunityRepository>().resolveProfile(user.uid);
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ComposePostScreen(
          community: widget.community,
          alias: widget.alias,
          profile: profile,
        ),
      ),
    );
    // Success feedback is shown inside ComposePostScreen.
  }

  void _openPostDetail(CommunityPost post) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PostDetailScreen(
          community: widget.community,
          post: post,
          alias: widget.alias,
          canComment: _joined,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final name = widget.community.nameForLocale(lang);
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            stretch: true,
            actions: [
              if (!_joined)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: InkWell(
                        onTap: _busy ? null : _toggleJoin,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          child: Text(
                            l10n.communityJoin,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'leave') _toggleJoin();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'leave',
                      child: Text(l10n.communityLeave),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 14),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: CommunityTopicPalette.gradient(widget.community.topic),
                      ),
                    ),
                  ),
                  // Decorative large icon
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      widget.community.icon,
                      size: 140,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  // Decorative circles
                  Positioned(
                    left: -40,
                    top: -40,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 60,
                    top: 20,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 40,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  // Info chips overlay
                  Positioned(
                    left: 16,
                    bottom: 52,
                    right: 16,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_alt_rounded,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${widget.community.memberCount}/${widget.community.maxMembers}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_joined)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CommunityTopicPalette.iconColor(
                                        widget.community.topic,
                                      ).withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: CommunityTopicPalette.iconColor(
                                        widget.community.topic,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.communityJoined,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: CommunityTopicPalette.iconColor(
                                          widget.community.topic,
                                        ),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            bottom: TabBar(
              controller: _tabs,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  icon: const Icon(Icons.article_outlined, size: 20),
                  text: l10n.communityPostsTab,
                ),
                Tab(
                  icon: const Icon(Icons.info_outline_rounded, size: 20),
                  text: l10n.communityAboutTab,
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _PostsList(
              communityId: widget.community.id,
              joined: _joined,
              busy: _busy,
              onJoin: _toggleJoin,
              onPostTap: _openPostDetail,
            ),
            _AboutTab(
              community: widget.community,
              lang: lang,
              joined: _joined,
              busy: _busy,
              onLeave: _toggleJoin,
            ),
          ],
        ),
      ),
      floatingActionButton: _joined
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.softRose(opacity: 0.35),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: InkWell(
                    onTap: _busy ? null : _createPost,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            l10n.communityNewPost,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _PostsList extends StatefulWidget {
  const _PostsList({
    required this.communityId,
    required this.joined,
    required this.busy,
    required this.onJoin,
    required this.onPostTap,
  });

  final String communityId;
  final bool joined;
  final bool busy;
  final VoidCallback onJoin;
  final void Function(CommunityPost) onPostTap;

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
          ),
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
            stream: uid != null ? repo.watchBlockedUids(uid) : Stream.value(const {}),
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
                  padding: const EdgeInsets.all(16),
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
    final rules = community.rulesForLocale(lang).isNotEmpty
        ? community.rulesForLocale(lang)
        : (lang.startsWith('ar') ? CommunitySeed.defaultRulesAr : CommunitySeed.defaultRulesEn);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppGlassCard(
          blur: false,
          radius: AppRadius.xl,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          community.descriptionForLocale(lang),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        Text(l10n.communityRules, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        AppGlassCard(
          blur: false,
          radius: AppRadius.lg,
          child: Text(rules, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45)),
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

class _PostDetailScreen extends StatefulWidget {
  const _PostDetailScreen({
    required this.community,
    required this.post,
    required this.alias,
    required this.canComment,
  });

  final Community community;
  final CommunityPost post;
  final String alias;
  final bool canComment;

  @override
  State<_PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<_PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _sending = false;
  String? _replyToCommentId;
  String? _replyToAlias;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startReply(CommunityComment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAlias = comment.authorAlias;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToAlias = null;
    });
  }

  Future<void> _sendComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _commentController.text.trim();
    if (user == null || text.isEmpty || !widget.canComment) return;

    setState(() => _sending = true);
    final repo = context.read<CommunityRepository>();

    try {
      final profile = await repo.resolveProfile(user.uid);
      final pending = await repo.createComment(
        communityId: widget.community.id,
        postId: widget.post.id,
        uid: user.uid,
        alias: widget.alias,
        text: text,
        authorAvatarIndex: profile.avatarIndex,
        parentCommentId: _replyToCommentId,
      );
      _commentController.clear();
      _cancelReply();
      if (pending && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.communityPendingReview)),
        );
      }
    } on ModerationRejectedException catch (e) {
      if (mounted) {
        await showModerationRejectedDialog(context, reason: e.reason);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editPost(CommunityPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await context.read<CommunityRepository>().resolveProfile(user.uid);
    if (!mounted) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ComposePostScreen(
          community: widget.community,
          alias: widget.alias,
          profile: profile,
          existingPost: post,
        ),
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.communityPostUpdated)),
      );
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityDeletePost),
        content: Text(l10n.communityDeletePostConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.communityDeletePost),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<CommunityRepository>().deletePost(
          communityId: widget.community.id,
          postId: post.id,
          uid: user.uid,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityPostDeleted)),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _deleteComment(CommunityComment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityDeleteComment),
        content: Text(l10n.communityDeleteCommentConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.communityDeleteComment),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<CommunityRepository>().deleteComment(
          communityId: widget.community.id,
          postId: widget.post.id,
          commentId: comment.id,
          uid: user.uid,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.communityCommentDeleted)),
      );
    }
  }

  Future<void> _markBestAnswer(CommunityComment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await context.read<CommunityRepository>().setBestAnswer(
          communityId: widget.community.id,
          postId: widget.post.id,
          commentId: comment.id,
          uid: user.uid,
        );
  }

  Future<void> _editComment(CommunityComment comment) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: comment.text);

    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityEditComment),
        content: TextField(
          controller: controller,
          maxLength: 300,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.communityCommentHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.continueBtn),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newText == null || newText.isEmpty || !mounted) return;

    final repo = context.read<CommunityRepository>();
    try {
      await repo.updateComment(
            communityId: widget.community.id,
            postId: widget.post.id,
            commentId: comment.id,
            uid: user.uid,
            text: newText,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityCommentUpdated)),
        );
      }
    } on ModerationRejectedException catch (e) {
      if (mounted) await showModerationRejectedDialog(context, reason: e.reason);
    } catch (e) {
      debugPrint('_editComment error: $e');
    }
  }

  void _showCommentActions(
    CommunityComment comment,
    CommunityPost post, {
    required bool isPostAuthor,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<CommunityRepository>();
    final isOwn = comment.authorUid == user.uid;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.canComment && !isOwn)
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: Text(l10n.communityReply),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _startReply(comment);
                },
              ),
            if (isPostAuthor &&
                post.postType == PostType.question &&
                post.bestAnswerCommentId != comment.id)
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: Text(l10n.communityMarkBestAnswer),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _markBestAnswer(comment);
                },
              ),
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.communityEditComment),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _editComment(comment);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.communityDeleteComment),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _deleteComment(comment);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: Text(l10n.communityCopy),
              onTap: () {
                Navigator.of(ctx).pop();
                copyCommunityText(context, comment.text);
              },
            ),
            if (!isOwn) ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.communityReportComment),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final reason = await showReportReasonSheet(context);
                  if (reason == null || !mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await repo.reportPost(
                    communityId: widget.community.id,
                    postId: widget.post.id,
                    commentId: comment.id,
                    reporterUid: user.uid,
                    reason: reason.code,
                    authorUid: comment.authorUid,
                    authorAlias: comment.authorAlias,
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.communityReported)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: Text(l10n.communityBlockUser),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final confirmed = await confirmBlockUser(
                    context,
                    authorAlias: comment.authorAlias,
                  );
                  if (!confirmed || !mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  await repo.blockUser(
                    uid: user.uid,
                    blockedUid: comment.authorUid,
                    authorAlias: comment.authorAlias,
                  );
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.communityBlocked)),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }


  List<Widget> _buildCommentTiles(
    List<CommunityComment> comments,
    CommunityPost post,
    String? bestAnswerId,
    bool isPostAuthor,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topLevel = comments.where((c) => c.parentCommentId == null).toList();
    final widgets = <Widget>[];

    for (final c in topLevel) {
      final isBest = bestAnswerId == c.id;
      final replyCount = threadReplyCount(c.id, comments);

      widgets.add(
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: AppAvatar(
            radius: 16,
            avatarIndex: c.authorAvatarIndex,
            uidSeed: c.authorUid,
          ),
          title: Row(
            children: [
              Expanded(child: Text(c.authorAlias)),
              if (isBest)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Icon(
                    Icons.star,
                    size: 16,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBest)
                Text(
                  l10n.communityBestAnswer,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (c.isEdited)
                Text(
                  l10n.communityEdited,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (c.isPendingReview)
                Text(
                  l10n.communityPendingReview,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(c.text),
              if (replyCount > 0) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => showCommentThreadSheet(
                    context: context,
                    root: c,
                    allComments: comments,
                    bestAnswerId: bestAnswerId,
                    onCommentTap: (comment) => _showCommentActions(
                      comment,
                      post,
                      isPostAuthor: isPostAuthor,
                    ),
                  ),
                  icon: const Icon(Icons.forum_outlined, size: 16),
                  label: Text(l10n.communityViewReplies(replyCount)),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
          onLongPress: () => _showCommentActions(c, post, isPostAuthor: isPostAuthor),
          onTap: widget.canComment
              ? () => _showCommentActions(c, post, isPostAuthor: isPostAuthor)
              : replyCount > 0
                  ? () => showCommentThreadSheet(
                        context: context,
                        root: c,
                        allComments: comments,
                        bestAnswerId: bestAnswerId,
                        onCommentTap: (comment) => _showCommentActions(
                          comment,
                          post,
                          isPostAuthor: isPostAuthor,
                        ),
                      )
                  : null,
        ),
      );
    }
    return widgets;
  }

  Future<void> _report(CommunityPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final reason = await showReportReasonSheet(context);
    if (reason == null || !mounted) return;
    await context.read<CommunityRepository>().reportPost(
          communityId: widget.community.id,
          postId: post.id,
          reporterUid: user.uid,
          reason: reason.code,
          authorUid: post.authorUid,
          authorAlias: post.authorAlias,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.communityReported)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final repo = context.read<CommunityRepository>();
    final user = FirebaseAuth.instance.currentUser;
    final lang = Localizations.localeOf(context).languageCode;

    return StreamBuilder<CommunityPost?>(
      stream: repo.watchPost(widget.community.id, widget.post.id),
      builder: (context, postSnap) {
        if (postSnap.connectionState == ConnectionState.waiting &&
            !postSnap.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.communityPostDetail)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (postSnap.hasData && postSnap.data == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.communityPostDetail)),
            body: Center(child: Text(l10n.communityPostNotFound)),
          );
        }

        final livePost = postSnap.data ?? widget.post;
        final isAuthor = user?.uid == livePost.authorUid;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.communityPostDetail),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => shareCommunityPost(
                  post: livePost,
                  communityName: widget.community.nameForLocale(lang),
                  shareLabel: l10n.communityShareVia,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_outlined),
                onPressed: () => copyCommunityText(context, livePost.text),
              ),
              if (isAuthor) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editPost(livePost),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deletePost(livePost),
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.flag_outlined),
                  onPressed: () => _report(livePost),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PostCard(post: livePost, onTap: () {}),
                    const Divider(height: 32),
                    Text(l10n.communityComments, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    StreamBuilder<Set<String>>(
                      stream: user != null
                          ? repo.watchBlockedUids(user.uid)
                          : Stream.value(const {}),
                      builder: (context, blockedSnap) {
                        final blocked = blockedSnap.data ?? const <String>{};
                        return StreamBuilder<List<CommunityComment>>(
                          stream: repo.watchComments(widget.community.id, livePost.id),
                          builder: (context, snap) {
                            final comments = (snap.data ?? [])
                                .where((c) => !blocked.contains(c.authorUid))
                                .toList();
                            if (comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Text(l10n.communityNoComments),
                              );
                            }
                            return Column(
                              children: _buildCommentTiles(
                                comments,
                                livePost,
                                livePost.bestAnswerCommentId,
                                isAuthor,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (widget.canComment)
                SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyToAlias != null)
                        Material(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: ListTile(
                            dense: true,
                            title: Text(
                              l10n.communityReplyingTo(_replyToAlias!),
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _cancelReply,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(
                                  hintText: l10n.communityCommentHint,
                                ),
                                maxLength: 300,
                              ),
                            ),
                            IconButton(
                              onPressed: _sending ? null : _sendComment,
                              icon: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
