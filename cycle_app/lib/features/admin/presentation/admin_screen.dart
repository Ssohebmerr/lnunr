import 'package:flutter/material.dart';

import '../../../core/cms/app_settings.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _repo = AdminRepository();
  final _settingsRepo = AppSettingsRepository();
  bool? _isAdmin;
  bool _gateLoading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _checkAdmin();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final ok = await _repo.isAdmin();
    if (mounted) {
      setState(() {
        _isAdmin = ok;
        _gateLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_gateLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isAdmin != true) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.adminTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 16),
                Text(l10n.adminAccessDenied, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminTitle),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(icon: const Icon(Icons.dashboard_rounded), text: l10n.adminDashboard),
            Tab(icon: const Icon(Icons.flag_rounded), text: l10n.adminReports),
            Tab(icon: const Icon(Icons.settings_rounded), text: l10n.adminSettings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DashboardTab(repo: _repo, l10n: l10n, theme: theme),
          _ReportsTab(repo: _repo, l10n: l10n, theme: theme),
          _SettingsTab(repo: _repo, settingsRepo: _settingsRepo, l10n: l10n, theme: theme),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.repo,
    required this.l10n,
    required this.theme,
  });
  final AdminRepository repo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<int>(
          future: repo.approximateUserCount(),
          builder: (context, snap) => _StatCard(
            icon: Icons.people_rounded,
            label: l10n.adminTotalUsers,
            value: '${snap.data ?? 0}',
            theme: theme,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<int>(
          future: repo.pendingReportsCount(),
          builder: (context, snap) => _StatCard(
            icon: Icons.flag_rounded,
            label: l10n.adminPendingReports,
            value: '${snap.data ?? 0}',
            color: (snap.data ?? 0) > 0 ? Colors.deepOrange : null,
            theme: theme,
          ),
        ),
        const SizedBox(height: 20),
        Text(l10n.adminRecentActivity,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        StreamBuilder<List<AdminActivity>>(
          stream: repo.watchActivityLog(),
          builder: (context, snap) {
            final activities = snap.data ?? [];
            if (activities.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(l10n.adminNoActivity,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ),
              );
            }
            return Column(
              children: activities.take(10).map((a) {
                final when = _timeAgo(a.createdAt);
                return ListTile(
                  dense: true,
                  leading: Icon(_actionIcon(a.action), size: 20),
                  title: Text(a.details, style: theme.textTheme.bodySmall),
                  trailing: Text(when,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _actionIcon(String action) => switch (action) {
        'resolve_report' => Icons.check_circle_outline,
        'hide_post' => Icons.visibility_off,
        'ban_user' => Icons.block,
        'unban_user' => Icons.person_outline,
        'update_settings' => Icons.settings,
        _ => Icons.circle,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? theme.colorScheme.primary;
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: c, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, color: c)),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                if (pendingPosts.isEmpty &&
                    pendingComments.isEmpty &&
                    reports.isEmpty) {
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
                onPressed: () => repo.approvePost(post.communityId, post.postId),
              ),
              ActionChip(
                label: Text(l10n.adminRejectPost),
                onPressed: () => repo.rejectPendingPost(post.communityId, post.postId),
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
                onPressed: () => repo.approveComment(
                  comment.communityId,
                  comment.postId,
                  comment.commentId,
                ),
              ),
              ActionChip(
                label: Text(l10n.adminRejectComment),
                onPressed: () => repo.rejectPendingComment(
                  comment.communityId,
                  comment.postId,
                  comment.commentId,
                ),
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
            '${_statusLabel()} · ${_ago(report.createdAt)}',
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
                      label: Text('Ban reporter'),
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

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({
    required this.repo,
    required this.settingsRepo,
    required this.l10n,
    required this.theme,
  });
  final AdminRepository repo;
  final AppSettingsRepository settingsRepo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _titleEn;
  late TextEditingController _titleAr;
  late TextEditingController _bodyEn;
  late TextEditingController _bodyAr;
  late TextEditingController _supportUrl;
  late TextEditingController _privacyUrl;
  bool _communityEnabled = true;
  bool _aiEducation = true;
  bool _announcementActive = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleEn = TextEditingController();
    _titleAr = TextEditingController();
    _bodyEn = TextEditingController();
    _bodyAr = TextEditingController();
    _supportUrl = TextEditingController();
    _privacyUrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleAr.dispose();
    _bodyEn.dispose();
    _bodyAr.dispose();
    _supportUrl.dispose();
    _privacyUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await widget.settingsRepo.fetch();
    if (mounted) {
      setState(() {
        _communityEnabled = settings.communityEnabled;
        _aiEducation = settings.aiEducationEnabled;
        _announcementActive = settings.announcementActive;
        _titleEn.text = settings.announcementTitleEn;
        _titleAr.text = settings.announcementTitleAr;
        _bodyEn.text = settings.announcementBodyEn;
        _bodyAr.text = settings.announcementBodyAr;
        _supportUrl.text = settings.supportUrl;
        _privacyUrl.text = settings.privacyUrl;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateAppSettings(AppSettings(
        communityEnabled: _communityEnabled,
        aiEducationEnabled: _aiEducation,
        announcementActive: _announcementActive,
        announcementTitleEn: _titleEn.text.trim(),
        announcementTitleAr: _titleAr.text.trim(),
        announcementBodyEn: _bodyEn.text.trim(),
        announcementBodyAr: _bodyAr.text.trim(),
        supportUrl: _supportUrl.text.trim(),
        privacyUrl: _privacyUrl.text.trim(),
      ));
      widget.settingsRepo.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.adminSettingsSaved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: Text(l10n.adminCommunityEnabled),
          value: _communityEnabled,
          onChanged: (v) => setState(() => _communityEnabled = v),
        ),
        SwitchListTile(
          title: Text(l10n.adminAiEducation),
          value: _aiEducation,
          onChanged: (v) => setState(() => _aiEducation = v),
        ),
        const Divider(height: 32),
        Text(l10n.adminAnnouncement,
            style: widget.theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Active'),
          value: _announcementActive,
          onChanged: (v) => setState(() => _announcementActive = v),
        ),
        TextField(
          controller: _titleEn,
          decoration: const InputDecoration(labelText: 'Title (English)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleAr,
          decoration: const InputDecoration(labelText: 'Title (Arabic)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyEn,
          decoration: const InputDecoration(labelText: 'Body (English)'),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyAr,
          decoration: const InputDecoration(labelText: 'Body (Arabic)'),
          maxLines: 3,
        ),
        const Divider(height: 32),
        TextField(
          controller: _supportUrl,
          decoration: const InputDecoration(labelText: 'Support URL'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _privacyUrl,
          decoration: const InputDecoration(labelText: 'Privacy URL'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
          label: Text(l10n.adminSave),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
