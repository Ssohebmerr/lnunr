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

enum _CommentSort { oldest, newest, top }

class _PostDetailScreenState extends State<_PostDetailScreen> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();
  bool _sending = false;
  String? _replyToCommentId;
  String? _replyToAlias;
  final List<CommunityComment> _optimisticComments = [];
  final Map<String, Timer> _optimisticCleanupTimers = {};

  _CommentSort _commentSort = _CommentSort.oldest;
  Future<Map<String, int>>? _likeCountsFuture;
  String _likeCountsKey = '';
  late final Stream<CommunityPost?> _postStream;
  late final Stream<List<CommunityComment>> _commentsStream;
  late final Stream<Set<String>> _blockedUidsStream;

  // Mention state: the @token being typed and aliases already picked from
  // the suggestion strip (alias → uid), resolved against the final text on
  // send so deleted mentions are dropped.
  String? _mentionQuery;
  int _mentionTokenStart = -1;
  final Map<String, String> _pickedMentions = {};
  List<CommunityComment> _latestComments = const [];

  @override
  void initState() {
    super.initState();
    final repo = context.read<CommunityRepository>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _postStream = repo.watchPost(widget.community.id, widget.post.id);
    _commentsStream = repo.watchComments(widget.community.id, widget.post.id);
    _blockedUidsStream = uid == null
        ? Stream.value(const <String>{})
        : repo.watchBlockedUids(uid);
    _commentController.addListener(_onComposerChanged);
    _commentFocus.addListener(_onCommentFocusChanged);
  }

  @override
  void dispose() {
    for (final timer in _optimisticCleanupTimers.values) {
      timer.cancel();
    }
    _commentFocus.removeListener(_onCommentFocusChanged);
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  bool _isOptimistic(CommunityComment comment) =>
      comment.id.startsWith('_local_');

  /// Keep a just-sent comment visible until the Firestore listener catches
  /// up, without duplicating it once the authoritative server copy arrives.
  List<CommunityComment> _withOptimisticComments(
    List<CommunityComment> serverComments,
  ) => mergeOptimisticComments(
    serverComments: serverComments,
    optimisticComments: _optimisticComments,
  );

  void _removeOptimisticComment(String id) {
    _optimisticCleanupTimers.remove(id)?.cancel();
    if (!mounted) return;
    setState(() => _optimisticComments.removeWhere((c) => c.id == id));
  }

  void _onComposerChanged() {
    final sel = _commentController.selection;
    final text = _commentController.text;
    if (!sel.isValid || !sel.isCollapsed) {
      _clearMentionQuery();
      return;
    }
    final upto = text.substring(0, sel.baseOffset);
    final at = upto.lastIndexOf('@');
    // Token must start the text or follow whitespace, and stay short and on
    // one line — otherwise every later '@' in a long comment would reopen
    // the suggestions.
    if (at < 0 || (at > 0 && !RegExp(r'\s').hasMatch(upto[at - 1]))) {
      _clearMentionQuery();
      return;
    }
    final query = upto.substring(at + 1);
    if (query.contains('\n') || query.length > 24) {
      _clearMentionQuery();
      return;
    }
    setState(() {
      _mentionQuery = query.toLowerCase();
      _mentionTokenStart = at;
    });
  }

  void _onCommentFocusChanged() {
    if (mounted) setState(() {});
  }

  void _clearMentionQuery() {
    if (_mentionQuery == null) return;
    setState(() {
      _mentionQuery = null;
      _mentionTokenStart = -1;
    });
  }

  void _insertMention(String alias, String uid) {
    final text = _commentController.text;
    final sel = _commentController.selection;
    final start = _mentionTokenStart;
    if (start < 0 || !sel.isValid || !sel.isCollapsed) return;
    final replaced =
        '${text.substring(0, start)}@$alias ${text.substring(sel.baseOffset)}';
    _pickedMentions[alias] = uid;
    _commentController.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: start + alias.length + 2),
    );
    _commentFocus.requestFocus();
  }

  /// Post author + commenters (never anonymous identities, never self),
  /// filtered by the @query being typed.
  List<({String uid, String alias, int avatarIndex})> _mentionCandidates() {
    final query = _mentionQuery;
    if (query == null) return const [];
    final me = FirebaseAuth.instance.currentUser?.uid;
    final byUid = <String, ({String uid, String alias, int avatarIndex})>{};

    final post = widget.post;
    if (!post.isAnonymous &&
        post.authorUid.isNotEmpty &&
        post.authorUid != me) {
      byUid[post.authorUid] = (
        uid: post.authorUid,
        alias: post.authorAlias,
        avatarIndex: post.authorAvatarIndex,
      );
    }
    for (final c in _latestComments) {
      if (c.authorUid.isEmpty || c.authorUid == me) continue;
      byUid[c.authorUid] = (
        uid: c.authorUid,
        alias: c.authorAlias,
        avatarIndex: c.authorAvatarIndex,
      );
    }

    return byUid.values
        .where((m) => m.alias.toLowerCase().contains(query))
        .take(6)
        .toList();
  }

  void _startReply(CommunityComment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToAlias = comment.authorAlias;
    });
    _commentFocus.requestFocus();
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

    final replyToCommentId = _replyToCommentId;
    final replyToAlias = _replyToAlias;
    final optimistic = CommunityComment(
      id: '_local_${DateTime.now().microsecondsSinceEpoch}',
      authorUid: user.uid,
      authorAlias: widget.alias,
      text: text,
      createdAt: DateTime.now(),
      parentCommentId: replyToCommentId,
      moderationStatus: 'pending_review',
    );

    setState(() {
      _sending = true;
      _optimisticComments.add(optimistic);
      _replyToCommentId = null;
      _replyToAlias = null;
    });
    // Clear immediately so sending feels instant. On failure, the draft is
    // restored if the user has not started typing a new comment.
    _commentController.clear();
    final repo = context.read<CommunityRepository>();

    // Only aliases still present in the final text count as mentions.
    final mentionUids = <String>{
      for (final e in _pickedMentions.entries)
        if (text.contains('@${e.key}')) e.value,
    };

    try {
      final pending = await repo.createComment(
        communityId: widget.community.id,
        postId: widget.post.id,
        uid: user.uid,
        text: text,
        parentCommentId: replyToCommentId,
        mentions: mentionUids.take(5).toList(),
      );
      _pickedMentions.clear();
      if (mounted) {
        _optimisticCleanupTimers[optimistic.id] = Timer(
          const Duration(seconds: 8),
          () => _removeOptimisticComment(optimistic.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pending
                  ? AppLocalizations.of(context)!.communityPendingReview
                  : AppLocalizations.of(context)!.communityPostPublished,
            ),
          ),
        );
      }
    } on ModerationRejectedException catch (e) {
      _restoreFailedComment(
        optimistic,
        replyToCommentId: replyToCommentId,
        replyToAlias: replyToAlias,
      );
      if (mounted) {
        await showModerationRejectedDialog(context, reason: e.reason);
      }
    } on CommunityBannedException {
      _restoreFailedComment(
        optimistic,
        replyToCommentId: replyToCommentId,
        replyToAlias: replyToAlias,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.communityBannedMessage),
          ),
        );
      }
    } on MinorRestrictedException {
      _restoreFailedComment(
        optimistic,
        replyToCommentId: replyToCommentId,
        replyToAlias: replyToAlias,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.communityMinorRestricted,
            ),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('_PostDetailScreen._sendComment failed: $e\n$st');
      _restoreFailedComment(
        optimistic,
        replyToCommentId: replyToCommentId,
        replyToAlias: replyToAlias,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              onPressed: () {
                _commentFocus.requestFocus();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _restoreFailedComment(
    CommunityComment optimistic, {
    required String? replyToCommentId,
    required String? replyToAlias,
  }) {
    _optimisticCleanupTimers.remove(optimistic.id)?.cancel();
    if (!mounted) return;
    final shouldRestoreDraft = _commentController.text.trim().isEmpty;
    setState(() {
      _optimisticComments.removeWhere((c) => c.id == optimistic.id);
      if (shouldRestoreDraft) {
        _replyToCommentId = replyToCommentId;
        _replyToAlias = replyToAlias;
      }
    });
    if (shouldRestoreDraft) {
      _commentController.value = TextEditingValue(
        text: optimistic.text,
        selection: TextSelection.collapsed(offset: optimistic.text.length),
      );
    }
    _commentFocus.requestFocus();
  }

  Future<void> _editPost(CommunityPost post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await context.read<CommunityRepository>().resolveProfile(
      user.uid,
    );
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
        SnackBar(
          content: Text(AppLocalizations.of(context)!.communityPostUpdated),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityPostDeleted)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityCommentDeleted)));
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityCommentUpdated)));
      }
    } on ModerationRejectedException catch (e) {
      if (mounted) {
        await showModerationRejectedDialog(context, reason: e.reason);
      }
    } catch (e) {
      debugPrint('_editComment error: $e');
    }
  }

  void _showCommentActions(
    CommunityComment comment,
    CommunityPost post, {
    required bool isPostAuthor,
    bool fromThreadSheet = false,
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
            if (widget.canComment)
              ListTile(
                leading: const Icon(Icons.reply_outlined),
                title: Text(l10n.communityReply),
                onTap: () {
                  Navigator.of(ctx).pop();
                  // The thread sheet would otherwise stay open and cover the
                  // composer, so the reply banner would never be seen.
                  if (fromThreadSheet) Navigator.of(context).pop();
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

  /// Aggregate like counts for the current top-level comments, cached until
  /// the comment set changes so rebuilds don't refetch.
  Future<Map<String, int>> _topLikeCounts(List<CommunityComment> comments) {
    final topLevel = comments
        .where((c) => c.parentCommentId == null && !_isOptimistic(c))
        .toList();
    final keyParts =
        topLevel.map((c) => '${c.id}:${c.likeCount ?? 'legacy'}').toList()
          ..sort();
    final key = keyParts.join(',');
    if (key != _likeCountsKey || _likeCountsFuture == null) {
      _likeCountsKey = key;
      final known = <String, int>{
        for (final comment in topLevel)
          if (comment.likeCount != null) comment.id: comment.likeCount!,
      };
      final legacyIds = topLevel
          .where((comment) => comment.likeCount == null)
          .map((comment) => comment.id)
          .toList();
      _likeCountsFuture = legacyIds.isEmpty
          ? Future.value(known)
          : context
                .read<CommunityRepository>()
                .fetchCommentLikeCounts(
                  widget.community.id,
                  widget.post.id,
                  legacyIds,
                )
                .then((legacy) => {...known, ...legacy});
    }
    return _likeCountsFuture!;
  }

  List<Widget> _buildCommentTiles(
    List<CommunityComment> comments,
    CommunityPost post,
    String? bestAnswerId,
    bool isPostAuthor, {
    Map<String, int> likeCounts = const {},
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final topLevel = comments.where((c) => c.parentCommentId == null).toList();
    switch (_commentSort) {
      case _CommentSort.oldest:
        break; // stream order is already createdAt ascending
      case _CommentSort.newest:
        topLevel.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _CommentSort.top:
        topLevel.sort((a, b) {
          final byLikes = (likeCounts[b.id] ?? 0).compareTo(
            likeCounts[a.id] ?? 0,
          );
          if (byLikes != 0) return byLikes;
          return a.createdAt.compareTo(b.createdAt);
        });
    }
    final widgets = <Widget>[];

    for (final c in topLevel) {
      final isBest = bestAnswerId == c.id;
      final replyCount = threadReplyCount(c.id, comments);
      final isOptimistic = _isOptimistic(c);

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: theme.brightness == Brightness.dark
                ? AuraColors.darkCard.withValues(alpha: 0.74)
                : Colors.white.withValues(alpha: 0.82),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.07),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              leading: AppAvatar(
                radius: 16,
                avatarIndex: c.authorAvatarIndex,
                uidSeed: c.authorUid,
                isPremium: c.authorIsPremium,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(c.authorAlias, overflow: TextOverflow.ellipsis),
                  ),
                  if (c.authorIsPremium) const PremiumNameBadge(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Text(
                      communityRelativeTime(context, c.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isOptimistic)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(start: 8),
                      child: SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 1.7),
                      ),
                    ),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (!isOptimistic)
                        CommentLikeButton(
                          communityId: widget.community.id,
                          postId: widget.post.id,
                          commentId: c.id,
                        ),
                      if (widget.canComment && !isOptimistic) ...[
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: () => _startReply(c),
                          icon: const Icon(Icons.reply_outlined, size: 16),
                          label: Text(l10n.communityReply),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                      if (replyCount > 0) ...[
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: () => showCommentThreadSheet(
                            context: context,
                            root: c,
                            allComments: comments,
                            bestAnswerId: bestAnswerId,
                            communityId: widget.community.id,
                            postId: widget.post.id,
                            onReply: widget.canComment ? _startReply : null,
                            onCommentTap: (comment) => _showCommentActions(
                              comment,
                              post,
                              isPostAuthor: isPostAuthor,
                              fromThreadSheet: true,
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
                ],
              ),
              onLongPress: isOptimistic
                  ? null
                  : () => _showCommentActions(
                      c,
                      post,
                      isPostAuthor: isPostAuthor,
                    ),
              onTap: isOptimistic
                  ? null
                  : widget.canComment
                  ? () =>
                        _showCommentActions(c, post, isPostAuthor: isPostAuthor)
                  : replyCount > 0
                  ? () => showCommentThreadSheet(
                      context: context,
                      root: c,
                      allComments: comments,
                      bestAnswerId: bestAnswerId,
                      communityId: widget.community.id,
                      postId: widget.post.id,
                      onCommentTap: (comment) => _showCommentActions(
                        comment,
                        post,
                        isPostAuthor: isPostAuthor,
                        fromThreadSheet: true,
                      ),
                    )
                  : null,
            ),
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityReported)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final lang = Localizations.localeOf(context).languageCode;

    return StreamBuilder<CommunityPost?>(
      stream: _postStream,
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
                            style: Theme.of(context).textTheme.titleSmall
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
                          _CommentSortMenu(
                            current: _commentSort,
                            onChanged: (sort) =>
                                setState(() => _commentSort = sort),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<Set<String>>(
                      stream: _blockedUidsStream,
                      builder: (context, blockedSnap) {
                        final blocked = blockedSnap.data ?? const <String>{};
                        return StreamBuilder<List<CommunityComment>>(
                          stream: _commentsStream,
                          builder: (context, snap) {
                            final serverComments = (snap.data ?? [])
                                .where((c) => !blocked.contains(c.authorUid))
                                .toList();
                            final comments = _withOptimisticComments(
                              serverComments,
                            );
                            _latestComments = comments;
                            if (comments.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.communityNoComments,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              );
                            }
                            if (_commentSort == _CommentSort.top) {
                              return FutureBuilder<Map<String, int>>(
                                future: _topLikeCounts(comments),
                                builder: (context, countsSnap) => Column(
                                  children: _buildCommentTiles(
                                    comments,
                                    livePost,
                                    livePost.bestAnswerCommentId,
                                    isAuthor,
                                    likeCounts: countsSnap.data ?? const {},
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

  /// Transparent scaffold with the app gradient and clean tonal actions.
  Widget _themedScaffold(
    BuildContext context, {
    required String title,
    required Widget body,
    List<Widget> actions = const [],
  }) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
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

  /// Horizontal strip of member chips shown while an @token is being typed.
  Widget _buildMentionStrip(BuildContext context, ThemeData theme) {
    final candidates = _mentionCandidates();
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: candidates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final m = candidates[i];
          return ActionChip(
            avatar: AppAvatar(
              radius: 11,
              avatarIndex: m.avatarIndex,
              uidSeed: m.uid,
            ),
            label: Text(m.alias, overflow: TextOverflow.ellipsis),
            labelStyle: theme.textTheme.labelMedium,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
            ),
            onPressed: () => _insertMention(m.alias, m.uid),
          );
        },
      ),
    );
  }

  Widget _buildCommentComposer(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mentionQuery != null) _buildMentionStrip(context, theme),
            if (_replyToAlias != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
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
            AppFloatingGlassPanel(
              radius: AppRadius.md,
              tint: theme.colorScheme.primary,
              highlighted: _commentFocus.hasFocus,
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocus,
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
                  IconButton.filled(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
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

/// Sort selector for the comments list (oldest / newest / most liked).
class _CommentSortMenu extends StatelessWidget {
  const _CommentSortMenu({required this.current, required this.onChanged});

  final _CommentSort current;
  final ValueChanged<_CommentSort> onChanged;

  String _label(_CommentSort sort, AppLocalizations l10n) => switch (sort) {
    _CommentSort.oldest => l10n.communityCommentSortOldest,
    _CommentSort.newest => l10n.communityCommentSortNewest,
    _CommentSort.top => l10n.communityCommentSortTop,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return PopupMenuButton<_CommentSort>(
      tooltip: '',
      initialValue: current,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      itemBuilder: (ctx) => [
        for (final sort in _CommentSort.values)
          PopupMenuItem(value: sort, child: Text(_label(sort, l10n))),
      ],
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 3),
            Text(
              _label(current, l10n),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
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
    final button = IconButton.filledTonal(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
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
      icon: const Icon(Icons.more_horiz_rounded, size: 20),
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
            child: _menuRow(
              theme,
              Icons.flag_outlined,
              l10n.communityReportPost,
            ),
          ),
      ],
    );
  }

  Widget _menuRow(
    ThemeData theme,
    IconData icon,
    String label, {
    bool danger = false,
  }) {
    final color = danger
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
