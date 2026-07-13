part of 'admin_screen.dart';

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
  late Future<Map<String, dynamic>> _aiCost;

  @override
  void initState() {
    super.initState();
    _userCount = widget.repo.approximateUserCount();
    _reportsCount = widget.repo.pendingReportsCount();
    _aiCost = widget.repo.fetchAiCostStats(days: 30);
  }

  Future<void> _refresh() async {
    setState(() {
      _userCount = widget.repo.approximateUserCount();
      _reportsCount = widget.repo.pendingReportsCount();
      _aiCost = widget.repo.fetchAiCostStats(days: 30);
    });
    await Future.wait([_userCount, _reportsCount, _aiCost]);
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
          const SizedBox(height: 12),
          // AI budget monitor — 30-day token usage + estimated USD cost from
          // the aiUsageDaily aggregates (admin action `aiCostStats`).
          FutureBuilder<Map<String, dynamic>>(
            future: _aiCost,
            builder: (context, snap) {
              final totals =
                  (snap.data?['totals'] as Map<String, dynamic>?) ?? const {};
              final cost = (totals['estimatedCostUsd'] as num?) ?? 0;
              final tokens = ((totals['promptTokens'] as num?) ?? 0) +
                  ((totals['completionTokens'] as num?) ?? 0);
              final requests = (totals['requests'] as num?) ?? 0;
              return AppGlassCard(
                blur: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D9A78).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF3D9A78),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.adminAiCost30d,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            snap.connectionState == ConnectionState.waiting
                                ? '…'
                                : '\$${cost.toStringAsFixed(2)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          l10n.adminAiTokensCount(_fmt(tokens.toInt())),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.adminAiRequestsCount(_fmt(requests.toInt())),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
                  color: gradient.first.withValues(alpha: 0.18),
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
                        fontWeight: FontWeight.w800,
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

