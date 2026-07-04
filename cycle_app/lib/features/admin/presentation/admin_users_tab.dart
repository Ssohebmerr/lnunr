part of 'admin_screen.dart';

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

  Future<void> _confirmAndTogglePremium(AdminUser u) async {
    final l10n = widget.l10n;
    final granting = !u.isPremium;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          granting ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 32,
        ),
        title: Text(
          granting ? l10n.adminGrantPremium : l10n.adminRevokePremium,
        ),
        content: Text(u.email.isEmpty ? u.uid : u.email),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.adminConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    HapticFeedback.mediumImpact();
    final success = await widget.repo.setUserPremium(u.uid, granting);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.adminPremiumUpdated : l10n.errorGeneric,
        ),
      ),
    );
    if (success) _search();
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
                            onTogglePremium: () => _confirmAndTogglePremium(u),
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
    required this.onTogglePremium,
  });

  final AdminUser user;
  final AppLocalizations l10n;
  final VoidCallback onBan;
  final VoidCallback onTogglePremium;

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
          // Premium toggle — server-audited via adminApi `setUserPremium`.
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTogglePremium,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  user.isPremium
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
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

