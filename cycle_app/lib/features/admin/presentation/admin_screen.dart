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
import 'admin_promo_codes_screen.dart';
import 'admin_roles_screen.dart';

part 'admin_dashboard_tab.dart';
part 'admin_reports_tab.dart';
part 'admin_settings_tab.dart';
part 'admin_users_tab.dart';
part 'admin_qa_tab.dart';
part 'admin_broadcast_tab.dart';

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
              final communityPending =
                  (snap.data ?? []).where((r) => r.isPending).length;
              return StreamBuilder<List<AdminAiReport>>(
                stream: _repo.watchAiReports(),
                builder: (context, aiSnap) {
                  final aiPending =
                      (aiSnap.data ?? []).where((r) => r.isPending).length;
                  final pending = communityPending + aiPending;
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

