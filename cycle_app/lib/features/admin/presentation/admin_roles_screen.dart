import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';

/// Owner-only screen to grant/revoke admin + moderator roles. The server
/// (adminApi `setAdminRole` / `removeAdmin`) enforces owner-only; this UI
/// hides the controls for non-owners as a courtesy, not as the security gate.
class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  final _emailCtrl = TextEditingController();
  String _newRole = 'moderator';
  bool _busy = false;
  bool _loading = true;
  String? _myRole;
  List<AdminMember> _admins = const [];

  bool get _isOwner => _myRole == 'owner';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final role = await widget.repo.myAdminRole();
    final admins = await widget.repo.listAdmins();
    if (mounted) {
      setState(() {
        _myRole = role;
        _admins = admins;
        _loading = false;
      });
    }
  }

  Future<void> _grant() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _busy = true);
    // Resolve the email to a uid via the existing admin user search.
    final matches = await widget.repo.searchUsers(email);
    final match = matches.where(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
    );
    final user = match.isNotEmpty ? match.first : null;
    if (user == null) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminRolesUserNotFound)),
        );
      }
      return;
    }
    final error = await widget.repo.setAdminRole(user.uid, _newRole);
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? l10n.adminRolesGranted)),
    );
    if (error == null) {
      _emailCtrl.clear();
      await _reload();
    }
  }

  Future<void> _remove(AdminMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminRolesRemove),
        content: Text(member.email.isEmpty ? member.uid : member.email),
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
    HapticFeedback.mediumImpact();
    final error = await widget.repo.removeAdmin(member.uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? l10n.adminRolesRemoved)),
    );
    await _reload();
  }

  String _roleLabel(String role, AppLocalizations l10n) => switch (role) {
        'owner' => l10n.adminRolesRoleOwner,
        'admin' => l10n.adminRolesRoleAdmin,
        _ => l10n.adminRolesRoleModerator,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminRolesTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (_isOwner) ...[
                AppGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.adminRolesAddHeader,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.adminRolesEmailHint,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'moderator',
                            label: Text(l10n.adminRolesRoleModerator),
                          ),
                          ButtonSegment(
                            value: 'admin',
                            label: Text(l10n.adminRolesRoleAdmin),
                          ),
                        ],
                        selected: {_newRole == 'admin' ? 'admin' : 'moderator'},
                        onSelectionChanged: (s) =>
                            setState(() => _newRole = s.first),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _busy ? null : _grant,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(l10n.adminRolesGrant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    l10n.adminRolesOwnerOnly,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              AppSectionHeader(title: l10n.adminRolesCurrentHeader),
              const SizedBox(height: 8),
              if (_admins.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    l10n.adminRolesEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              else
                ..._admins.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppGlassCard(
                      blur: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                theme.colorScheme.primaryContainer,
                            child: Text(
                              (m.email.isNotEmpty ? m.email[0] : '?')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.email.isEmpty ? m.uid : m.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _roleLabel(m.role, l10n),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isOwner && m.role != 'owner')
                            IconButton(
                              onPressed: () => _remove(m),
                              icon: const Icon(Icons.person_remove_outlined,
                                  color: Colors.red),
                              tooltip: l10n.adminRolesRemove,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
