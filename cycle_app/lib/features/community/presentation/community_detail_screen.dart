import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/premium/premium_badge.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_avatar.dart';
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
import 'widgets/comment_like_button.dart';
import 'widgets/comment_thread_sheet.dart';
import 'widgets/community_guidelines_dialog.dart';
import 'widgets/community_safety_actions.dart';
import 'widgets/community_time.dart';
import 'widgets/community_ui.dart';
import 'widgets/moderation_rejected_dialog.dart';
import 'widgets/post_card.dart';
import 'widgets/weekly_question_card.dart';

part 'community_detail_tabs.dart';
part 'community_post_detail.dart';

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
  int _memberCount = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _joined = widget.isJoined;
    _memberCount = widget.community.memberCount;
    _refreshMemberCount();
    if (widget.initialPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openPostById(widget.initialPostId!),
      );
    }
  }

  Future<void> _refreshMemberCount() async {
    final count = await context.read<CommunityRepository>().fetchMemberCount(
      widget.community.id,
    );
    if (mounted) setState(() => _memberCount = count);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityPostNotFound)));
      }
    } on TimeoutException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } catch (e, st) {
      debugPrint('CommunityDetailScreen._openPostById failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
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
          HapticFeedback.lightImpact();
          setState(() => _joined = false);
          unawaited(_refreshMemberCount());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.communityLeft)));
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
          HapticFeedback.mediumImpact();
          setState(() => _joined = true);
          unawaited(_refreshMemberCount());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.communityJoined)));
        }
      }
    } on MinorRestrictedException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityMinorRestricted)));
      }
    } on CommunityBannedException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityBannedMessage)));
      }
    } on CommunityFullException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityFull)));
      }
    } catch (e, st) {
      debugPrint('CommunityDetailScreen._toggleJoin failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPost({String? initialText, PostType? initialType}) async {
    if (!_joined) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await context.read<CommunityRepository>().resolveProfile(
      user.uid,
    );
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ComposePostScreen(
          community: widget.community,
          alias: widget.alias,
          profile: profile,
          initialText: initialText,
          initialType: initialType,
        ),
      ),
    );
    // Success feedback is shown inside ComposePostScreen.
  }

  /// Weekly question → composer pre-filled with the quoted prompt.
  void _answerWeeklyQuestion(String question) {
    _createPost(initialText: '«$question»\n\n');
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
    final headerColors = CommunityTopicPalette.gradient(widget.community.topic);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppTheme.gradientBackground(context),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 204,
              pinned: true,
              stretch: true,
              backgroundColor: headerColors.first,
              surfaceTintColor: Colors.transparent,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              title: innerBoxIsScrolled
                  ? Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    )
                  : null,
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
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
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
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: headerColors,
                        ),
                      ),
                    ),
                    // Community name — fixed at top so it never overlaps chips/tabs
                    PositionedDirectional(
                      start: 16,
                      end: 88,
                      top: kToolbarHeight + 12,
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.4,
                          shadows: const [
                            Shadow(
                              color: Color(0x33000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
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
                      bottom: 14,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.people_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_memberCount/${widget.community.maxMembers}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_joined)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_rounded,
                                    size: 12,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: ColoredBox(
                  color: theme.colorScheme.surface,
                  child: TabBar(
                    controller: _tabs,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
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
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _PostsList(
                communityId: widget.community.id,
                topic: widget.community.topic,
                joined: _joined,
                busy: _busy,
                alias: widget.alias,
                onJoin: _toggleJoin,
                onPostTap: _openPostDetail,
                onAnswerPrompt: _answerWeeklyQuestion,
                onCompose: () => _createPost(),
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
      ),
      floatingActionButton: _joined
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton.extended(
                onPressed: _busy ? null : _createPost,
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.communityNewPost),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
