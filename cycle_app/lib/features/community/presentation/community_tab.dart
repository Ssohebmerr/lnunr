import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_navigation.dart';
import '../data/community_repository.dart';
import '../data/community_seed.dart';
import '../data/models/community.dart';
import '../data/models/community_post.dart';
import '../data/models/community_profile.dart';
import '../data/models/post_type.dart';
import 'community_activity_screen.dart';
import 'community_detail_screen.dart';
import 'community_feed_utils.dart';
import 'community_profile_setup_sheet.dart';
import 'widgets/community_card.dart';
import 'widgets/community_ui.dart';
import 'widgets/post_card.dart';
import 'widgets/stories_row.dart';
import 'widgets/story_composer.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Community> _communities = [];
  bool _loading = false;
  bool _communityConsent = false;
  CommunityProfile? _profile;
  String? _alias;
  String _search = '';
  String _category = 'all';
  final _searchController = TextEditingController();
  StreamSubscription<User?>? _authSub;
  bool _loadInProgress = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) _load();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loadInProgress) return;
    _loadInProgress = true;

    if (mounted) setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final repo = context.read<CommunityRepository>();
      final consent = await ConsentManager.hasCommunitiesConsent();
      if (!consent) {
        if (mounted) setState(() => _communityConsent = false);
        return;
      }

      final profile = await repo.resolveProfile(user.uid);
      final canReadMemberCounts = profile.isReady && !profile.isMinor;
      final communities = await repo.fetchCommunitiesWithCounts(
        fetchCounts: canReadMemberCounts,
      );

      if (mounted) {
        setState(() {
          _communityConsent = true;
          _profile = profile;
          _alias = profile.alias;
          _communities = communities.isEmpty
              ? CommunitySeed.defaults
              : communities;
        });
      }
    } catch (e, st) {
      debugPrint('CommunityTab._load failed: $e\n$st');
      if (mounted) {
        setState(() {
          _communityConsent = true;
          _communities = CommunitySeed.defaults;
        });
      }
    } finally {
      _loadInProgress = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLogin() async {
    final signedIn = await openLoginScreen(context);
    if (signedIn == true && mounted) await _load();
  }

  Future<void> _showProfileSetup({
    bool birthYearOnly = false,
    VoidCallback? onSavedDone,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    var saved = false;

    final profile = _profile;
    final onlyYear = birthYearOnly ||
        (profile != null && profile.needsBirthYearOnly);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: onlyYear,
      enableDrag: onlyYear,
      builder: (ctx) => CommunityProfileSetupSheet(
        birthYearOnly: onlyYear,
        initialAlias: _alias,
        initialBirthYear: _profile?.birthYear,
        initialAvatarIndex: _profile?.avatarIndex ?? 0,
        initialPhotoUrl: _profile?.photoUrl,
        onSaved: (alias, birthYear, avatarIndex, photoUrl) async {
          final profile = CommunityProfile(
            alias: alias,
            birthYear: birthYear,
            goal: _profile?.goal,
            setupComplete: true,
            avatarIndex: avatarIndex,
            photoUrl: photoUrl,
          );
          try {
            await context.read<CommunityRepository>().saveProfile(user.uid, profile);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.errorGeneric),
                ),
              );
            }
            rethrow;
          }
          if (mounted) {
            setState(() {
              _alias = alias;
              _profile = profile;
            });
            saved = true;
            await _load();
          }
        },
      ),
    );
    if (saved && mounted) {
      onSavedDone?.call();
    }
  }

  List<Community> get _filtered {
    var list = CommunitySeed.search(
        _search, Localizations.localeOf(context).languageCode);
    if (_category != 'all') {
      list = list.where((c) => c.topic == _category).toList();
    }
    return list.map((c) {
      final match = _communities.where((x) => x.id == c.id);
      return match.isEmpty ? c : match.first;
    }).toList();
  }

  void _openCommunity(Community c, bool joined) {
    final profile = _profile;
    if (profile == null || !profile.isReady) {
      _showProfileSetup(
        birthYearOnly: profile?.needsBirthYearOnly ?? false,
        onSavedDone: () => _openCommunity(c, joined),
      );
      return;
    }
    if (profile.isMinor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.communityAdultsOnly)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          community: c,
          alias: _alias ?? 'User',
          isJoined: joined,
        ),
      ),
    );
  }

  void _openPost(BuildContext context, CommunityPost post) {
    final profile = _profile;
    if (profile == null || !profile.isReady || profile.isMinor) return;
    final community = CommunitySeed.byId(post.communityId);
    if (community == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          community: community,
          alias: _alias ?? 'User',
          isJoined: true,
          initialPostId: post.id,
        ),
      ),
    );
  }

  Future<void> _showGuidelines() async {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final rules = lang.startsWith('ar')
        ? CommunitySeed.defaultRulesAr
        : CommunitySeed.defaultRulesEn;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityGuidelinesTitle),
        content: SingleChildScrollView(child: Text(rules)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.continueBtn),
          ),
        ],
      ),
    );
  }

  void _openActivity() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CommunityActivityScreen()),
    );
  }

  void _openStoryComposer(BuildContext context, List<String> joinedIds) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _profile == null) return;
    if (joinedIds.isEmpty) return;

    final communityId = joinedIds.first;
    final community = CommunitySeed.byId(communityId);
    if (community == null) return;

    showStoryComposer(
      context: context,
      communityId: communityId,
      alias: _alias ?? 'User',
      profile: _profile!,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        return _buildContent(context, user);
      },
    );
  }

  Widget _buildContent(BuildContext context, User? user) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    if (user == null) {
      return _LoginPrompt(l10n: l10n, theme: theme, onSignIn: _openLogin);
    }

    if (_loading && _profile == null && _communities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_communityConsent) {
      return _ConsentPrompt(
        l10n: l10n,
        theme: theme,
        onAccept: () async {
          final ok = await showCommunitiesConsentDialog(context);
          if (ok && mounted) {
            setState(() {
              _loading = true;
              _communityConsent = true;
            });
            await _load();
          }
        },
      );
    }

    final profile = _profile;
    if (profile == null || !profile.isReady) {
      if (profile != null && profile.needsBirthYearOnly) {
        return _BirthYearOnlyPrompt(
          l10n: l10n,
          alias: profile.alias,
          onSetup: () => _showProfileSetup(birthYearOnly: true),
        );
      }
      return _ProfileSetupPrompt(
        l10n: l10n,
        onSetup: _showProfileSetup,
      );
    }

    if (profile.isMinor) {
      return _AdultsOnlyGate(l10n: l10n, theme: theme);
    }

    return StreamBuilder<List<String>>(
      stream: context
          .read<CommunityRepository>()
          .watchJoinedCommunityIds(user.uid),
      builder: (context, membershipSnap) {
        if (membershipSnap.hasError) {
          debugPrint(
            'CommunityTab membership stream: ${membershipSnap.error}',
          );
        }

        final joinedIds = membershipSnap.data ?? [];
        final repo = context.read<CommunityRepository>();

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Compact hero header — scrolls away
            SliverToBoxAdapter(
              child: StreamBuilder<int>(
                stream: repo.watchUnreadInboxCount(user.uid),
                builder: (context, unreadSnap) {
                  return CommunityHeroHeader(
                    l10n: l10n,
                    joinedCount: joinedIds.length,
                    alias: _alias,
                    avatarIndex: _profile?.avatarIndex ?? 0,
                    photoUrl: _profile?.photoUrl,
                    uidSeed: user.uid,
                    onEditProfile: _showProfileSetup,
                    unreadCount: unreadSnap.data ?? 0,
                    onActivityTap: _openActivity,
                    onGuidelinesTap: _showGuidelines,
                  );
                },
              ),
            ),
            // Pinned tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                controller: _tabs,
                tabs: [
                  (icon: Icons.dynamic_feed_rounded,
                      label: l10n.communityTabFeed),
                  (icon: Icons.explore_rounded,
                      label: l10n.communityTabDiscover),
                  (icon: Icons.favorite_rounded,
                      label: l10n.communityTabMine),
                  (icon: Icons.bookmark_rounded,
                      label: l10n.communityTabSaved),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _FeedTab(
                joinedIds: joinedIds,
                alias: _alias,
                avatarIndex: _profile?.avatarIndex ?? 0,
                onPostTap: (p) => _openPost(context, p),
                onJoinPrompt: () => _tabs.animateTo(1),
                onRefresh: _load,
                onCreateStory: () => _openStoryComposer(context, joinedIds),
              ),
              _DiscoverTab(
                l10n: l10n,
                lang: lang,
                joinedIds: joinedIds,
                searchController: _searchController,
                category: _category,
                onSearchChanged: (v) => setState(() => _search = v),
                onCategoryChanged: (v) => setState(() => _category = v),
                communities: _filtered,
                onRefresh: _load,
                onOpen: _openCommunity,
              ),
              _MyGroupsTab(
                l10n: l10n,
                lang: lang,
                joinedIds: joinedIds,
                communities: _communities,
                onOpen: _openCommunity,
                onRefresh: _load,
              ),
              _SavedTab(
                alias: _alias,
                onPostTap: (p) => _openPost(context, p),
                onRefresh: _load,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Persistent tab bar delegate for NestedScrollView
// ---------------------------------------------------------------------------
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate({required this.controller, required this.tabs});

  final TabController controller;
  final List<({IconData icon, String label})> tabs;

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return CommunityHubTabBar(controller: controller, tabs: tabs);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      controller != oldDelegate.controller;
}

// ---------------------------------------------------------------------------
// Login prompt
// ---------------------------------------------------------------------------
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({
    required this.l10n,
    required this.theme,
    required this.onSignIn,
  });
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.groups_rounded,
      title: l10n.communityTitle,
      subtitle: l10n.communityRequiresAccount,
      actionLabel: l10n.signInOptionalTitle,
      onAction: onSignIn,
    );
  }
}

// ---------------------------------------------------------------------------
// Feed tab — stories + search + filters + posts (all in one scrollable list)
// ---------------------------------------------------------------------------
class _FeedTab extends StatefulWidget {
  const _FeedTab({
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
  State<_FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<_FeedTab> {
  PostType? _typeFilter;
  CommunityFeedSort _sort = CommunityFeedSort.newest;
  bool _myPostsOnly = false;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get joinedIds => widget.joinedIds;
  void Function(CommunityPost) get onPostTap => widget.onPostTap;
  VoidCallback get onJoinPrompt => widget.onJoinPrompt;
  Future<void> Function() get onRefresh => widget.onRefresh;

  String _typeLabel(PostType type, AppLocalizations l10n) => switch (type) {
        PostType.support => l10n.postTypeSupport,
        PostType.question => l10n.postTypeQuestion,
        PostType.tip => l10n.postTypeTip,
        PostType.vent => l10n.postTypeVent,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (joinedIds.isEmpty) {
      return CommunityEmptyState(
        icon: Icons.dynamic_feed_rounded,
        title: l10n.communityTabFeed,
        subtitle: l10n.communityFeedEmpty,
        actionLabel: l10n.communityTabDiscover,
        onAction: onJoinPrompt,
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
          stream: repo.watchJoinedFeed(joinedIds),
          builder: (context, snap) {
            final all = (snap.data ?? [])
                .where((p) => !blocked.contains(p.authorUid))
                .toList();
            final currentUid = FirebaseAuth.instance.currentUser?.uid;
            var posts = _typeFilter == null
                ? all
                : all.where((p) => p.postType == _typeFilter).toList();
            posts = filterAndSortCommunityPosts(
              posts: posts,
              query: _search,
              sort: _sort,
              authorUidFilter: _myPostsOnly ? currentUid : null,
            );

            // Everything in ONE scrollable list for smooth scrolling
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: CustomScrollView(
                slivers: [
                  // Stories
                  SliverToBoxAdapter(
                    child: StoriesRow(
                      joinedIds: joinedIds,
                      alias: widget.alias,
                      avatarIndex: widget.avatarIndex,
                      onCreateStory: widget.onCreateStory,
                    ),
                  ),
                  // Search field
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
                  // Type filter chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: CommunityFilterChips(
                        items: [
                          (id: 'all', label: l10n.communityFilterAll),
                          ...PostType.values.map(
                            (t) =>
                                (id: t.value, label: _typeLabel(t, l10n)),
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
                  // Sort filter chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: CommunityFilterChips(
                        items: [
                          (id: 'newest', label: l10n.communitySortNewest),
                          (id: 'discussed',
                              label: l10n.communitySortDiscussed),
                          (id: 'mine', label: l10n.communityFilterMyPosts),
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
                  // Posts
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
                            onTap: () => onPostTap(posts[i]),
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

// ---------------------------------------------------------------------------
// Discover tab
// ---------------------------------------------------------------------------
class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab({
    required this.l10n,
    required this.lang,
    required this.joinedIds,
    required this.searchController,
    required this.category,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.communities,
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
  final Future<void> Function() onRefresh;
  final void Function(Community, bool) onOpen;

  @override
  Widget build(BuildContext context) {
    final categories = [
      ('all', l10n.communityCatAll),
      ('general', l10n.communityCatGeneral),
      ('conception', l10n.communityCatConception),
      ('contraception', l10n.communityCatContraception),
      ('condition', l10n.communityCatCondition),
      ('support', l10n.communityCatSupport),
      ('culture', l10n.communityCatCulture),
      ('age', l10n.communityCatAge),
    ];

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
            items: categories.map((c) => (id: c.$1, label: c.$2)).toList(),
            selected: category,
            onSelected: onCategoryChanged,
          ),
          const SizedBox(height: 16),
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

// ---------------------------------------------------------------------------
// My groups tab
// ---------------------------------------------------------------------------
class _MyGroupsTab extends StatelessWidget {
  const _MyGroupsTab({
    required this.l10n,
    required this.lang,
    required this.joinedIds,
    required this.communities,
    required this.onOpen,
    required this.onRefresh,
  });

  final AppLocalizations l10n;
  final String lang;
  final List<String> joinedIds;
  final List<Community> communities;
  final void Function(Community, bool) onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final mine =
        communities.where((c) => joinedIds.contains(c.id)).toList();

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

// ---------------------------------------------------------------------------
// Saved tab
// ---------------------------------------------------------------------------
class _SavedTab extends StatelessWidget {
  const _SavedTab({
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
    return StreamBuilder<List<CommunityPost>>(
      stream: repo.watchSavedPosts(uid),
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
            padding: const EdgeInsets.all(16),
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
  }
}

// ---------------------------------------------------------------------------
// Birth year only (alias already from app profile)
// ---------------------------------------------------------------------------
class _BirthYearOnlyPrompt extends StatelessWidget {
  const _BirthYearOnlyPrompt({
    required this.l10n,
    required this.alias,
    required this.onSetup,
  });

  final AppLocalizations l10n;
  final String alias;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.cake_outlined,
      title: l10n.communityBirthYearLabel,
      subtitle: '${l10n.communityBirthYearWhy}\n\n${l10n.communityAliasLabel}: $alias',
      actionLabel: l10n.continueBtn,
      onAction: onSetup,
    );
  }
}

// ---------------------------------------------------------------------------
// Profile setup gate (birth year + nickname required before communities)
// ---------------------------------------------------------------------------
class _ProfileSetupPrompt extends StatelessWidget {
  const _ProfileSetupPrompt({
    required this.l10n,
    required this.onSetup,
  });

  final AppLocalizations l10n;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.badge_outlined,
      title: l10n.communitySetupTitle,
      subtitle: l10n.communitySetupSubtitle,
      actionLabel: l10n.communitySetupTitle,
      onAction: onSetup,
    );
  }
}

// ---------------------------------------------------------------------------
// Consent prompt
// ---------------------------------------------------------------------------
class _ConsentPrompt extends StatelessWidget {
  const _ConsentPrompt({
    required this.l10n,
    required this.theme,
    required this.onAccept,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CommunityEmptyState(
            icon: Icons.shield_outlined,
            title: l10n.consentCommunityTitle,
            subtitle: l10n.consentCommunityBody,
            actionLabel: l10n.consentAccept,
            onAction: onAccept,
          ),
        ),
        TextButton(
          onPressed: openPrivacyPolicy,
          child: Text(l10n.privacyPolicyLink),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Adults-only gate
// ---------------------------------------------------------------------------
class _AdultsOnlyGate extends StatelessWidget {
  const _AdultsOnlyGate({required this.l10n, required this.theme});

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return CommunityEmptyState(
      icon: Icons.lock_outline_rounded,
      title: l10n.communityAdultsOnlyTitle,
      subtitle: l10n.communityAdultsOnly,
    );
  }
}
