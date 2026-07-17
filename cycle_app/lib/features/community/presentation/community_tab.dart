import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/presentation/auth_navigation.dart';
import '../../cycle/data/cycle_sync_service.dart';
import '../../../core/age/age_gate.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/privacy/consent_manager.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import '../../education/data/education_content.dart';
import '../data/community_catalog_repository.dart';
import '../data/community_list_resolver.dart';
import '../data/community_repository.dart';
import '../data/community_seed.dart';
import '../data/models/community.dart';
import '../data/models/community_membership.dart';
import '../data/models/community_post.dart';
import '../data/models/community_profile.dart';
import '../data/models/post_type.dart';
import 'community_activity_screen.dart';
import 'compose_post_screen.dart';
import 'community_detail_screen.dart';
import 'community_profile_setup_sheet.dart';
import 'community_tab/community_prompts.dart';
import 'community_tab/discover_tab.dart';
import 'community_tab/feed_tab.dart';
import 'community_tab/my_groups_tab.dart';
import 'community_tab/saved_tab.dart';
import 'community_tab/tab_bar_delegate.dart';
import 'widgets/community_ui.dart';
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
  Map<String, CommunityCatalogEntry> _catalog = {};
  UserGoalTypes? _userGoal;
  bool _loading = false;
  bool _communityConsent = false;
  CommunityProfile? _profile;
  String? _alias;
  String _search = '';
  String _category = 'all';
  final _searchController = TextEditingController();
  StreamSubscription<User?>? _authSub;
  bool _loadInProgress = false;
  int _loadGeneration = 0;
  bool _initialTabPicked = false;
  bool _ageGateBlocksCommunity = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && mounted) _load();
    });
  }

  /// New users with no joined communities land on Discover (index 1) instead
  /// of the empty Feed (index 0). Only runs once per session.
  void _maybePickInitialTab(List<String> joinedIds) {
    if (_initialTabPicked) return;
    _initialTabPicked = true;
    if (joinedIds.isEmpty && _tabs.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabs.animateTo(1);
      });
    }
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
    final generation = ++_loadGeneration;

    if (mounted) setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final lang = Localizations.localeOf(context).languageCode;
      final repo = context.read<CommunityRepository>();
      final consent = await ConsentManager.hasCommunitiesConsent();
      if (!consent) {
        if (mounted) setState(() => _communityConsent = false);
        return;
      }

      if (await blocksCommunityByAgeGate()) {
        if (mounted) {
          setState(() {
            _communityConsent = true;
            _ageGateBlocksCommunity = true;
          });
        }
        return;
      }

      // Start independent reads together. The previous sequential chain made
      // the first community paint wait for every network round trip.
      final profileFuture = repo.resolveProfile(user.uid);
      final goalFuture = CycleSyncService().getUserGoal();
      final catalogFuture = repo.fetchCommunityCatalog();
      final joinedIdsFuture = repo
          .watchJoinedCommunityIds(user.uid)
          .first
          .timeout(const Duration(seconds: 5), onTimeout: () => const []);

      final profile = await profileFuture;
      final canReadMemberCounts = profile.isReady && !profile.isMinor;

      // Paint the safe local catalog as soon as identity/age is known. Goal,
      // catalog overrides and counts enrich the page afterward without
      // keeping the user on a full-screen spinner.
      if (mounted && generation == _loadGeneration) {
        setState(() {
          _communityConsent = true;
          _ageGateBlocksCommunity = false;
          _profile = profile;
          _alias = profile.alias;
          if (_communities.isEmpty) {
            _communities = CommunitySeed.defaults;
          }
        });
      }

      final goal = await goalFuture;
      final catalog = await catalogFuture;
      final joinedIds = await joinedIdsFuture;
      final communities = await repo.fetchCommunitiesWithCounts(
        fetchCounts: false,
        languageCode: lang,
        goal: goal,
        joinedIds: joinedIds,
      );

      if (mounted && generation == _loadGeneration) {
        setState(() {
          _communityConsent = true;
          _ageGateBlocksCommunity = false;
          _profile = profile;
          _alias = profile.alias;
          _userGoal = goal;
          _catalog = catalog;
          _communities = communities.isEmpty
              ? CommunitySeed.defaults
              : communities;
        });
      }

      if (canReadMemberCounts && generation == _loadGeneration) {
        unawaited(
          _hydrateMemberCounts(
            repo: repo,
            languageCode: lang,
            goal: goal,
            joinedIds: joinedIds,
            generation: generation,
          ),
        );
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

  Future<void> _hydrateMemberCounts({
    required CommunityRepository repo,
    required String languageCode,
    required UserGoalTypes? goal,
    required List<String> joinedIds,
    required int generation,
  }) async {
    final counted = await repo.fetchCommunitiesWithCounts(
      languageCode: languageCode,
      goal: goal,
      joinedIds: joinedIds,
    );
    if (!mounted || generation != _loadGeneration || counted.isEmpty) return;
    setState(() => _communities = counted);
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
    final onlyYear =
        birthYearOnly || (profile != null && profile.needsBirthYearOnly);

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
            await context.read<CommunityRepository>().saveProfile(
              user.uid,
              profile,
            );
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
    final lang = Localizations.localeOf(context).languageCode;
    final browse = CommunityListResolver.browseAll(catalog: _catalog);
    final merged = browse.map((c) {
      final match = _communities.where((x) => x.id == c.id);
      return match.isEmpty ? c : match.first;
    }).toList();
    return CommunityListResolver.filterBrowseList(
      communities: merged,
      search: _search,
      category: _category,
      languageCode: lang,
      catalog: _catalog,
      goal: _userGoal,
      joinedIds: _joinedIdsCache,
    );
  }

  List<String> _joinedIdsCache = const [];

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
          content: Text(AppLocalizations.of(context)!.communityAdultsOnly),
        ),
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

  Future<void> _discussMagazineArticle(
    BuildContext context,
    Article article,
    String communityId,
  ) async {
    final profile = _profile;
    final community = CommunitySeed.byId(communityId);
    if (profile == null ||
        !profile.isReady ||
        profile.isMinor ||
        community == null) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComposePostScreen(
          community: community,
          alias: _alias ?? 'User',
          profile: profile,
          initialText: '${l10n.magazineFromLune}: «${article.title(lang)}»\n\n',
          initialType: PostType.question,
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CommunityActivityScreen()));
  }

  Future<void> _openStoryComposer(
    BuildContext context,
    List<CommunityMembership> memberships,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _profile == null) return;
    if (memberships.isEmpty) return;

    // With multiple joined communities, let the user pick where the story
    // goes instead of silently posting to the most recently joined one.
    String? communityId = memberships.first.communityId;
    if (memberships.length > 1) {
      communityId = await _pickStoryCommunity(context, memberships);
      if (communityId == null || !context.mounted) return;
    }

    showStoryComposer(
      context: context,
      communityId: communityId,
      alias: _alias ?? 'User',
      profile: _profile!,
    );
  }

  Future<String?> _pickStoryCommunity(
    BuildContext context,
    List<CommunityMembership> memberships,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.storyChooseCommunity,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final m in memberships)
                    if (CommunitySeed.byId(m.communityId) case final c?)
                      ListTile(
                        leading: Icon(
                          c.icon,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                        title: Text(c.nameForLocale(lang)),
                        onTap: () => Navigator.pop(ctx, m.communityId),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
      return CommunityLoginPrompt(
        l10n: l10n,
        theme: theme,
        onSignIn: _openLogin,
      );
    }

    if (_loading && _profile == null && _communities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_communityConsent) {
      return CommunityConsentPrompt(
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

    if (_ageGateBlocksCommunity) {
      return CommunityAdultsOnlyGate(l10n: l10n, theme: theme);
    }

    final profile = _profile;
    if (profile == null || !profile.isReady) {
      if (profile != null && profile.needsBirthYearOnly) {
        return CommunityBirthYearOnlyPrompt(
          l10n: l10n,
          alias: profile.alias,
          onSetup: () => _showProfileSetup(birthYearOnly: true),
        );
      }
      return CommunityProfileSetupPrompt(
        l10n: l10n,
        onSetup: _showProfileSetup,
      );
    }

    if (profile.isMinor) {
      return CommunityAdultsOnlyGate(l10n: l10n, theme: theme);
    }

    return StreamBuilder<List<CommunityMembership>>(
      stream: context.read<CommunityRepository>().watchJoinedMemberships(
        user.uid,
      ),
      builder: (context, membershipSnap) {
        if (membershipSnap.hasError) {
          debugPrint('CommunityTab membership stream: ${membershipSnap.error}');
        }

        final memberships = membershipSnap.data ?? [];
        final joinedIds = memberships.map((m) => m.communityId).toList();
        _joinedIdsCache = joinedIds;
        _maybePickInitialTab(joinedIds);
        final repo = context.read<CommunityRepository>();

        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
            SliverPersistentHeader(
              pinned: true,
              delegate: CommunityTabBarDelegate(
                controller: _tabs,
                tabs: [
                  (
                    icon: Icons.dynamic_feed_rounded,
                    label: l10n.communityTabFeed,
                  ),
                  (
                    icon: Icons.explore_rounded,
                    label: l10n.communityTabDiscover,
                  ),
                  (icon: Icons.favorite_rounded, label: l10n.communityTabMine),
                  (icon: Icons.bookmark_rounded, label: l10n.communityTabSaved),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              CommunityFeedTab(
                joinedIds: joinedIds,
                alias: _alias,
                avatarIndex: _profile?.avatarIndex ?? 0,
                onPostTap: (p) => _openPost(context, p),
                onJoinPrompt: () => _tabs.animateTo(1),
                onRefresh: _load,
                onCreateStory: () => _openStoryComposer(context, memberships),
                onDiscussArticle: (article, communityId) =>
                    _discussMagazineArticle(context, article, communityId),
              ),
              CommunityDiscoverTab(
                l10n: l10n,
                lang: lang,
                joinedIds: joinedIds,
                searchController: _searchController,
                category: _category,
                onSearchChanged: (v) => setState(() => _search = v),
                onCategoryChanged: (v) => setState(() => _category = v),
                communities: _filtered,
                catalog: _catalog,
                userGoal: _userGoal,
                onRefresh: _load,
                onOpen: _openCommunity,
              ),
              CommunityMyGroupsTab(
                l10n: l10n,
                lang: lang,
                memberships: memberships,
                communities: _communities,
                catalog: _catalog,
                onOpen: _openCommunity,
                onRefresh: _load,
                onBrowse: () => _tabs.animateTo(1),
              ),
              CommunitySavedTab(
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
