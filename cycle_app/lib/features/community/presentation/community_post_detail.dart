part of 'community_detail_screen.dart';

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
            isPremium: c.authorIsPremium,
          ),
          title: Row(
            children: [
              Expanded(child: Text(c.authorAlias)),
              if (c.authorIsPremium) const PremiumNameBadge(),
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
          return _themedScaffold(
            context,
            title: l10n.communityPostDetail,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (postSnap.hasData && postSnap.data == null) {
          return _themedScaffold(
            context,
            title: l10n.communityPostDetail,
            body: Center(child: Text(l10n.communityPostNotFound)),
          );
        }

        final livePost = postSnap.data ?? widget.post;
        final isAuthor = user?.uid == livePost.authorUid;

        return _themedScaffold(
          context,
          title: l10n.communityPostDetail,
          actions: [
            _GlassAppBarButton(
              icon: Icons.share_outlined,
              tooltip: l10n.communityShareVia,
              onTap: () => shareCommunityPost(
                post: livePost,
                communityName: widget.community.nameForLocale(lang),
                shareLabel: l10n.communityShareVia,
              ),
            ),
            const SizedBox(width: 8),
            _PostActionsMenu(
              isAuthor: isAuthor,
              onCopy: () => copyCommunityText(context, livePost.text),
              onEdit: () => _editPost(livePost),
              onDelete: () => _deletePost(livePost),
              onReport: () => _report(livePost),
            ),
            const SizedBox(width: 8),
          ],
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    PostCard(post: livePost, onTap: () {}),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 18,
                      ),
                      child: Row(
                        children: [
                          Text(
                            l10n.communityComments,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Divider(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    l10n.communityNoComments,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
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
              if (widget.canComment) _buildCommentComposer(context, l10n),
            ],
          ),
        );
      },
    );
  }

  /// Transparent scaffold with the app's gradient background and a glass
  /// back button — keeps the post detail consistent with the rest of the app.
  Widget _themedScaffold(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget> actions = const [],
  }) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: AppGlassCard(
            radius: AppRadius.pill,
            padding: const EdgeInsets.all(8),
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: actions,
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(context),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight,
          ),
          child: SafeArea(top: false, child: body),
        ),
      ),
    );
  }

  Widget _buildCommentComposer(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_replyToAlias != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.communityReplyingTo(_replyToAlias!),
                        style: theme.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _cancelReply,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AuraColors.darkCard.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.04),
                ),
                boxShadow: AppShadows.navFloat(isDark),
              ),
              padding: const EdgeInsets.only(left: 18, right: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: l10n.communityCommentHint,
                        border: InputBorder.none,
                        counterText: '',
                        isCollapsed: true,
                      ),
                      maxLength: 300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AuraDecorations.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _sending ? null : _sendComment,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  size: 18, color: Colors.white),
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
    );
  }
}

/// Glass circular icon button used in the post detail app bar.
class _GlassAppBarButton extends StatelessWidget {
  const _GlassAppBarButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = AppGlassCard(
      radius: AppRadius.pill,
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Overflow menu grouping the secondary post actions (copy / edit / delete /
/// report) so the app bar stays clean.
class _PostActionsMenu extends StatelessWidget {
  const _PostActionsMenu({
    required this.isAuthor,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  final bool isAuthor;
  final VoidCallback onCopy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<String>(
      tooltip: '',
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      onSelected: (value) {
        switch (value) {
          case 'copy':
            onCopy();
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
          case 'report':
            onReport();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'copy',
          child: _menuRow(theme, Icons.copy_rounded, l10n.communityCopy),
        ),
        if (isAuthor) ...[
          PopupMenuItem(
            value: 'edit',
            child: _menuRow(theme, Icons.edit_outlined, l10n.communityEditPost),
          ),
          PopupMenuItem(
            value: 'delete',
            child: _menuRow(
              theme,
              Icons.delete_outline_rounded,
              l10n.communityDeletePost,
              danger: true,
            ),
          ),
        ] else
          PopupMenuItem(
            value: 'report',
            child:
                _menuRow(theme, Icons.flag_outlined, l10n.communityReportPost),
          ),
      ],
      child: AppGlassCard(
        radius: AppRadius.pill,
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _menuRow(ThemeData theme, IconData icon, String label,
      {bool danger = false}) {
    final color = danger ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
