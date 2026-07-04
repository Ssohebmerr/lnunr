part of 'admin_screen.dart';

class _ReportsTab extends StatefulWidget {
  const _ReportsTab({
    required this.repo,
    required this.l10n,
    required this.theme,
  });
  final AdminRepository repo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  int _refreshTick = 0;

  Future<void> _refresh() async {
    setState(() => _refreshTick++);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repo;
    final l10n = widget.l10n;
    final theme = widget.theme;

    return StreamBuilder<List<AdminPendingPost>>(
      key: ValueKey('pending-posts-$_refreshTick'),
      stream: repo.watchPendingPosts(),
      builder: (context, pendingSnap) {
        if (pendingSnap.hasError) {
          return _ReportsError(
            message: pendingSnap.error.toString(),
            onRetry: _refresh,
            l10n: l10n,
          );
        }
        final pendingPosts = pendingSnap.data ?? [];
        return StreamBuilder<List<AdminPendingComment>>(
          key: ValueKey('pending-comments-$_refreshTick'),
          stream: repo.watchPendingComments(),
          builder: (context, pendingCommentsSnap) {
            if (pendingCommentsSnap.hasError) {
              return _ReportsError(
                message: pendingCommentsSnap.error.toString(),
                onRetry: _refresh,
                l10n: l10n,
              );
            }
            final pendingComments = pendingCommentsSnap.data ?? [];
            return StreamBuilder<List<AdminReport>>(
              key: ValueKey('reports-$_refreshTick'),
              stream: repo.watchReports(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ReportsError(
                    message: snap.error.toString(),
                    onRetry: _refresh,
                    l10n: l10n,
                  );
                }
                final reports = snap.data ?? [];
                return StreamBuilder<List<AdminAiReport>>(
                  key: ValueKey('ai-reports-$_refreshTick'),
                  stream: repo.watchAiReports(),
                  builder: (context, aiSnap) {
                    if (aiSnap.hasError) {
                      return _ReportsError(
                        message: aiSnap.error.toString(),
                        onRetry: _refresh,
                        l10n: l10n,
                      );
                    }
                    final aiReports = aiSnap.data ?? [];
                if (pendingPosts.isEmpty &&
                    pendingComments.isEmpty &&
                    reports.isEmpty &&
                    aiReports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 56, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(l10n.adminNoReports,
                              style: theme.textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (aiReports.isNotEmpty) ...[
                        Text(
                          'بلاغات الذكاء الاصطناعي',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...aiReports.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AiReportCard(
                              report: r,
                              repo: repo,
                              theme: theme,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (pendingPosts.isNotEmpty) ...[
                        Text(
                          l10n.adminPendingModeration,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pendingPosts.map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PendingPostCard(
                              post: p,
                              repo: repo,
                              l10n: l10n,
                              theme: theme,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (pendingComments.isNotEmpty) ...[
                        Text(
                          l10n.adminPendingComments,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pendingComments.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PendingCommentCard(
                              comment: c,
                              repo: repo,
                              l10n: l10n,
                              theme: theme,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (reports.isNotEmpty) ...[
                        Text(
                          l10n.adminReports,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...reports.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ReportCard(
                              report: r,
                              repo: repo,
                              l10n: l10n,
                              theme: theme,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AiReportCard extends StatelessWidget {
  const _AiReportCard({
    required this.report,
    required this.repo,
    required this.theme,
  });

  final AdminAiReport report;
  final AdminRepository repo;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    report.reason,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  report.isPending ? 'معلق' : report.status,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: report.isPending
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              report.email.isNotEmpty
                  ? '${report.email} · ${report.uid}'
                  : report.uid,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              report.response,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            if (report.isPending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  TextButton(
                    onPressed: () => repo.resolveAiReport(report.id),
                    child: const Text('تم الحل'),
                  ),
                  TextButton(
                    onPressed: () =>
                        repo.resolveAiReport(report.id, status: 'dismissed'),
                    child: const Text('تجاهل'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({
    required this.message,
    required this.onRetry,
    required this.l10n,
  });

  final String message;
  final Future<void> Function() onRetry;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.deepOrange),
            const SizedBox(height: 12),
            Text(l10n.errorGeneric, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _PendingPostCard extends StatelessWidget {
  const _PendingPostCard({
    required this.post,
    required this.repo,
    required this.l10n,
    required this.theme,
  });

  final AdminPendingPost post;
  final AdminRepository repo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  post.authorAlias,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            post.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            post.communityId,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(l10n.adminApprovePost),
                onPressed: () async {
                  await repo.approvePost(post.communityId, post.postId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminApprovePost)),
                    );
                  }
                },
              ),
              ActionChip(
                label: Text(l10n.adminRejectPost),
                onPressed: () async {
                  await repo.rejectPendingPost(post.communityId, post.postId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminRejectPost)),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingCommentCard extends StatelessWidget {
  const _PendingCommentCard({
    required this.comment,
    required this.repo,
    required this.l10n,
    required this.theme,
  });

  final AdminPendingComment comment;
  final AdminRepository repo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.authorAlias,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${comment.communityId} · ${comment.postId}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: Text(l10n.adminApproveComment),
                onPressed: () async {
                  await repo.approveComment(
                    comment.communityId,
                    comment.postId,
                    comment.commentId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminApproveComment)),
                    );
                  }
                },
              ),
              ActionChip(
                label: Text(l10n.adminRejectComment),
                onPressed: () async {
                  await repo.rejectPendingComment(
                    comment.communityId,
                    comment.postId,
                    comment.commentId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.adminRejectComment)),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.repo,
    required this.l10n,
    required this.theme,
  });
  final AdminReport report;
  final AdminRepository repo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isPending = report.isPending;
    return AppGlassCard(
      blur: false,
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            isPending ? Icons.flag_rounded : Icons.check_circle_rounded,
            color: isPending ? Colors.deepOrange : Colors.green,
          ),
          title: Text(report.authorAlias,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${_statusLabel()} · ${_ago(report.createdAt, l10n)}',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant),
          ),
          children: [
            _detailRow(l10n.adminReportReason, report.reason),
            _detailRow('Post ID', report.postId),
            _detailRow('Community', report.communityId),
            if (report.commentId != null)
              _detailRow('Comment ID', report.commentId!),
            if (isPending) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: Text(l10n.adminReportDismiss),
                    onPressed: () => repo.resolveReport(report.id),
                  ),
                  ActionChip(
                    label: Text(l10n.adminHidePost),
                    onPressed: () => repo.hidePost(report.communityId, report.postId),
                  ),
                  ActionChip(
                    label: Text(l10n.adminBanUser),
                    onPressed: () => repo.banUser(report.authorUid),
                  ),
                  if (report.reporterUid != report.authorUid)
                    ActionChip(
                      label: Text(l10n.adminBanReporter),
                      onPressed: () => repo.banUser(report.reporterUid),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  String _statusLabel() =>
      report.isPending ? l10n.adminReportPending : l10n.adminReportResolved;
}

