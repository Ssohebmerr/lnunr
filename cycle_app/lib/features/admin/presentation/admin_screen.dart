import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/cms/app_settings.dart';
import '../../../core/cms/app_settings_repository.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
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
    _tabs = TabController(length: 6, vsync: this);
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AuraDecorations.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.adminTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: StreamBuilder<List<AdminReport>>(
            stream: _repo.watchReports(),
            builder: (context, snap) {
              final pending =
                  (snap.data ?? []).where((r) => r.isPending).length;
              return TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  _AdminTab(
                      icon: Icons.dashboard_rounded,
                      label: l10n.adminDashboard),
                  _AdminTab(
                    icon: Icons.flag_rounded,
                    label: l10n.adminReports,
                    badge: pending,
                  ),
                  _AdminTab(
                      icon: Icons.tune_rounded, label: l10n.adminSettings),
                  _AdminTab(
                      icon: Icons.people_alt_rounded,
                      label: l10n.adminTabUsers),
                  _AdminTab(
                      icon: Icons.question_answer_rounded,
                      label: l10n.adminTabQA),
                  _AdminTab(
                      icon: Icons.campaign_rounded,
                      label: l10n.adminTabBroadcast),
                ],
              );
            },
          ),
        ),
      ),
      body: AppMeshBackground(
        child: TabBarView(
          controller: _tabs,
          children: [
            _DashboardTab(
              repo: _repo,
              l10n: l10n,
              theme: theme,
              onJumpToTab: (i) => _tabs.animateTo(i),
            ),
            _ReportsTab(repo: _repo, l10n: l10n, theme: theme),
            _SettingsTab(
              repo: _repo,
              settingsRepo: _settingsRepo,
              l10n: l10n,
              theme: theme,
            ),
            _UsersTab(repo: _repo, l10n: l10n),
            const _QATab(),
            _BroadcastTab(repo: _repo, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

/// Tab label with optional pending-count badge.
class _AdminTab extends StatelessWidget {
  const _AdminTab({
    required this.icon,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 18),
              if (badge > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 14),
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab({
    required this.repo,
    required this.l10n,
    required this.theme,
    required this.onJumpToTab,
  });
  final AdminRepository repo;
  final AppLocalizations l10n;
  final ThemeData theme;
  final ValueChanged<int> onJumpToTab;

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  late Future<int> _userCount;
  late Future<int> _reportsCount;

  @override
  void initState() {
    super.initState();
    _userCount = widget.repo.approximateUserCount();
    _reportsCount = widget.repo.pendingReportsCount();
  }

  Future<void> _refresh() async {
    setState(() {
      _userCount = widget.repo.approximateUserCount();
      _reportsCount = widget.repo.pendingReportsCount();
    });
    await Future.wait([_userCount, _reportsCount]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = widget.theme;
    final repo = widget.repo;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: [
              FutureBuilder<int>(
                future: _userCount,
                builder: (context, snap) => _StatCard(
                  icon: Icons.people_alt_rounded,
                  label: l10n.adminTotalUsers,
                  value: _fmt(snap.data),
                  gradient: const [Color(0xFF6B7FE8), Color(0xFF8FA8F5)],
                  loading: snap.connectionState == ConnectionState.waiting,
                ),
              ),
              FutureBuilder<int>(
                future: _reportsCount,
                builder: (context, snap) {
                  final n = snap.data ?? 0;
                  return _StatCard(
                    icon: Icons.flag_rounded,
                    label: l10n.adminPendingReports,
                    value: _fmt(snap.data),
                    gradient: n > 0
                        ? const [Color(0xFFE85D5D), Color(0xFFF58B8B)]
                        : const [Color(0xFF3D9A78), Color(0xFF5CC4A0)],
                    loading: snap.connectionState == ConnectionState.waiting,
                  );
                },
              ),
              _DailyCountCard(
                icon: Icons.forum_rounded,
                label: l10n.adminPostsToday,
                gradient: const [Color(0xFFE89B4F), Color(0xFFF4C26E)],
                stream: _todayCount('community_activity', 'posts_created'),
              ),
              _DailyCountCard(
                icon: Icons.auto_awesome_rounded,
                label: l10n.adminAiToday,
                gradient: const [Color(0xFFB07CD8), Color(0xFFD09BE5)],
                stream: _todayCount('ai_activity', 'requests'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.adminQuickActions,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.flag_rounded,
                  label: l10n.adminQuickViewReports,
                  color: const Color(0xFFE85D5D),
                  onTap: () => widget.onJumpToTab(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.campaign_rounded,
                  label: l10n.adminQuickSendBroadcast,
                  color: const Color(0xFFE89B4F),
                  onTap: () => widget.onJumpToTab(5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.tune_rounded,
                  label: l10n.adminQuickEditSettings,
                  color: const Color(0xFF6B7FE8),
                  onTap: () => widget.onJumpToTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.adminRecentActivity,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AdminActivity>>(
            stream: repo.watchActivityLog(),
            builder: (context, snap) {
              final activities = snap.data ?? [];
              if (activities.isEmpty) {
                return AppGlassCard(
                  blur: false,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.timeline_rounded,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.adminNoActivity,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return AppGlassCard(
                blur: false,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: activities.take(10).toList().asMap().entries.map((e) {
                    final i = e.key;
                    final a = e.value;
                    final isLast = i == activities.take(10).length - 1;
                    return _ActivityRow(
                      activity: a,
                      isLast: isLast,
                      l10n: l10n,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _fmt(int? n) {
    if (n == null) return '—';
    if (n < 1000) return '$n';
    if (n < 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '${(n / 1000).round()}k';
  }

  /// Counts documents in the given top-level collection created today.
  /// Falls back to `null` (renders as "—") if the collection doesn't exist.
  Stream<int?> _todayCount(String collection, String action) {
    final start = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    return FirebaseFirestore.instance
        .collection(collection)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(start))
        .snapshots()
        .map<int?>((s) => s.size)
        .handleError((_) => null);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              loading
                  ? Container(
                      width: 50,
                      height: 22,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    )
                  : Text(
                      value,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: gradient.first,
                      ),
                    ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyCountCard extends StatelessWidget {
  const _DailyCountCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.stream,
  });
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final Stream<int?> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: stream,
      builder: (context, snap) => _StatCard(
        icon: icon,
        label: label,
        value: snap.data == null ? '—' : '${snap.data}',
        gradient: gradient,
        loading: snap.connectionState == ConnectionState.waiting,
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.activity,
    required this.isLast,
    required this.l10n,
  });

  final AdminActivity activity;
  final bool isLast;
  final AppLocalizations l10n;

  static const Map<String, (IconData, Color)> _meta = {
    'resolve_report': (Icons.check_circle_outline_rounded, Color(0xFF3D9A78)),
    'hide_post': (Icons.visibility_off_rounded, Color(0xFFE89B4F)),
    'ban_user': (Icons.block_rounded, Color(0xFFE85D5D)),
    'unban_user': (Icons.person_outline_rounded, Color(0xFF6B7FE8)),
    'update_settings': (Icons.tune_rounded, Color(0xFF6B7FE8)),
    'approve_post': (Icons.check_rounded, Color(0xFF3D9A78)),
    'reject_post': (Icons.cancel_outlined, Color(0xFFE85D5D)),
    'broadcast': (Icons.campaign_rounded, Color(0xFFE89B4F)),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = _meta[activity.action] ??
        (Icons.circle_outlined, theme.colorScheme.outline);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: meta.$2.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.$1, size: 16, color: meta.$2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              activity.details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _ago(activity.createdAt, l10n),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _ago(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.adminTimeNow;
  if (diff.inMinutes < 60) return l10n.adminTimeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.adminTimeHours(diff.inHours);
  return l10n.adminTimeDays(diff.inDays);
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
          SnackBar(content: Text(widget.l10n.adminFailedSave)),
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
          title: Text(l10n.adminActive),
          value: _announcementActive,
          onChanged: (v) => setState(() => _announcementActive = v),
        ),
        TextField(
          controller: _titleEn,
          decoration: InputDecoration(labelText: l10n.adminTitleEnglish),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleAr,
          decoration: InputDecoration(labelText: l10n.adminTitleArabic),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyEn,
          decoration: InputDecoration(labelText: l10n.adminBodyEnglish),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyAr,
          decoration: InputDecoration(labelText: l10n.adminBodyArabic),
          maxLines: 3,
        ),
        const Divider(height: 32),
        TextField(
          controller: _supportUrl,
          decoration: InputDecoration(labelText: l10n.adminSupportUrl),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _privacyUrl,
          decoration: InputDecoration(labelText: l10n.adminPrivacyUrl),
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

// ---------------------------------------------------------------------------
// Users Tab — search users, ban/unban
// ---------------------------------------------------------------------------
class _UsersTab extends StatefulWidget {
  const _UsersTab({required this.repo, required this.l10n});
  final AdminRepository repo;
  final AppLocalizations l10n;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _searchCtrl = TextEditingController();
  List<AdminUser>? _results;
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() { _searching = true; _results = null; });
    final results = await widget.repo.searchUsers(query);
    if (mounted) setState(() { _results = results; _searching = false; });
  }

  Future<void> _confirmAndBan(AdminUser u) async {
    final l10n = widget.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.block_rounded, color: Colors.red, size: 32),
        title: Text(l10n.adminConfirmBan),
        content: Text(l10n.adminConfirmBanMsg),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.heavyImpact();
    await widget.repo.banUser(u.uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.adminUserBanned)),
    );
    _search();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.adminSearchHint,
                border: InputBorder.none,
                isDense: true,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                ),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        onPressed: _search,
                      ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
        ),
        Expanded(
          child: _results == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 64,
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminSearchUsers,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : _results!.isEmpty
                  ? Center(
                      child: Text(
                        l10n.adminNoUsers,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: _results!.length,
                      itemBuilder: (context, i) {
                        final u = _results![i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _UserTile(
                            user: u,
                            l10n: l10n,
                            onBan: () => _confirmAndBan(u),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({
    required this.user,
    required this.l10n,
    required this.onBan,
  });

  final AdminUser user;
  final AppLocalizations l10n;
  final VoidCallback onBan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = user.email.isEmpty ? l10n.adminNoEmail : user.email;
    final initial = user.email.isNotEmpty
        ? user.email[0].toUpperCase()
        : '?';
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.fingerprint_rounded,
                      size: 12,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${user.uid.substring(0, 10)}…',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    if (user.isPremium) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 14, color: Colors.amber),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (user.isBanned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.block_rounded,
                      size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    l10n.adminBannedBadge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBan,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.block_rounded,
                          size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        l10n.adminBanUser,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Q&A Tab — Anonymous health questions from users
// ---------------------------------------------------------------------------
class _QATab extends StatefulWidget {
  const _QATab();

  @override
  State<_QATab> createState() => _QATabState();
}

class _QATabState extends State<_QATab> {
  String _filter = 'pending'; // pending | answered | all

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final filters = <(String, String, IconData)>[
      ('pending', l10n.adminFilterPending, Icons.hourglass_top_rounded),
      ('answered', l10n.adminFilterAnswered, Icons.check_circle_rounded),
      ('all', l10n.adminFilterAll, Icons.list_alt_rounded),
    ];
    final selectedLabel =
        filters.firstWhere((f) => f.$1 == _filter, orElse: () => filters[0]).$2;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: filters.map((f) {
              final selected = f.$1 == _filter;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _filter = f.$1);
                      },
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? AuraDecorations.primaryGradient
                              : null,
                          color: selected
                              ? null
                              : theme.colorScheme.surface.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected
                                ? Colors.transparent
                                : theme.colorScheme.outline
                                    .withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              f.$3,
                              size: 14,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                f.$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? Colors.white
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _queryStream(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('${l10n.adminError} ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.question_answer_outlined,
                          size: 56, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        l10n.adminQuestionsEmpty(selectedLabel.toLowerCase()),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _QuestionCard(
                      docId: docs[i].id,
                      data: data,
                      theme: theme,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _queryStream() {
    final ref = FirebaseFirestore.instance.collection('anonymousQuestions');
    if (_filter == 'all') {
      return ref.orderBy('createdAt', descending: true).snapshots();
    }
    return ref
        .where('status', isEqualTo: _filter)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({
    required this.docId,
    required this.data,
    required this.theme,
  });

  final String docId;
  final Map<String, dynamic> data;
  final ThemeData theme;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  final _answerController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _answer() async {
    final l10n = AppLocalizations.of(context)!;
    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('anonymousQuestions')
          .doc(widget.docId)
          .update({
        'status': 'answered',
        'answer': answer,
        'answeredBy': 'admin',
        'answeredAt': FieldValue.serverTimestamp(),
      });
      _answerController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.adminError} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await FirebaseFirestore.instance
          .collection('anonymousQuestions')
          .doc(widget.docId)
          .update({'status': 'rejected'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminQuestionRejected)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.adminError} $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = widget.data;
    final theme = widget.theme;
    final question = data['question'] ?? '';
    final category = data['category'] ?? 'general';
    final status = data['status'] ?? 'pending';
    final answer = data['answer'];
    final createdAt = data['createdAt'] as Timestamp?;

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.toString().toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  _ago(createdAt.toDate(), l10n),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                status == 'answered'
                    ? Icons.check_circle
                    : status == 'rejected'
                        ? Icons.cancel
                        : Icons.hourglass_top,
                size: 18,
                color: status == 'answered'
                    ? Colors.green
                    : status == 'rejected'
                        ? Colors.red
                        : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Question
          Text(
            question,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          // Existing answer
          if (answer != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(l10n.adminQAExpertAnswer,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          )),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(answer, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],

          // Answer input (only for pending)
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.adminExpertAnswerHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _answer,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(l10n.adminPublishAnswer),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _reject,
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  tooltip: l10n.adminReject,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Broadcast Tab — send push notification to all users
// ---------------------------------------------------------------------------
class _BroadcastTab extends StatefulWidget {
  const _BroadcastTab({required this.repo, required this.l10n});
  final AdminRepository repo;
  final AppLocalizations l10n;

  @override
  State<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends State<_BroadcastTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;
  bool _isError = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_refresh);
    _bodyCtrl.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_refresh);
    _bodyCtrl.removeListener(_refresh);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = widget.l10n;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.campaign_rounded, size: 32, color: Colors.deepOrange),
        title: Text(l10n.adminConfirmBroadcast),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminConfirmBroadcastMsg),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(ctx)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(ctx).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: Text(l10n.adminSendBroadcast),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _sending = true;
      _result = null;
    });

    final res = await widget.repo.sendBroadcast(title: title, body: body);

    if (mounted) {
      setState(() {
        _sending = false;
        if (res.containsKey('error')) {
          _isError = true;
          _result = '${l10n.adminError} ${res['error']}';
        } else {
          _isError = false;
          _titleCtrl.clear();
          _bodyCtrl.clear();
          _result = l10n.adminBroadcastSent(
            '${res['sent'] ?? 0}',
            '${res['failed'] ?? 0}',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final canSend = !_sending &&
        _titleCtrl.text.trim().isNotEmpty &&
        _bodyCtrl.text.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppGlassCard(
          blur: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleCtrl,
                maxLength: 60,
                decoration: InputDecoration(
                  labelText: l10n.adminNotifTitle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyCtrl,
                maxLines: 3,
                maxLength: 240,
                decoration: InputDecoration(
                  labelText: l10n.adminNotifBody,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_titleCtrl.text.trim().isNotEmpty ||
            _bodyCtrl.text.trim().isNotEmpty) ...[
          Text(
            l10n.adminNotifPreview,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _NotifPreview(
            title: _titleCtrl.text.trim().isEmpty
                ? l10n.adminNotifTitle
                : _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim().isEmpty
                ? l10n.adminNotifBody
                : _bodyCtrl.text.trim(),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            onPressed: canSend ? _send : null,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? l10n.adminSending : l10n.adminSendBroadcast),
          ),
        ),
        if (_result != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isError
                  ? Colors.red.withValues(alpha: 0.1)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: (_isError ? Colors.red : Colors.green)
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: _isError ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _result!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isError ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Mock Android-style notification card for the broadcast preview.
class _NotifPreview extends StatelessWidget {
  const _NotifPreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lune',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '· now',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
