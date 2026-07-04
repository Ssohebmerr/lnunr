part of 'admin_screen.dart';

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
