import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/admin_repository.dart';

/// Admin screen to create + manage premium promo codes. The server
/// (adminApi `createPromoCode` / `revokePromoCode`) validates and audits every
/// action; this screen is the UI that was missing for that capability.
class AdminPromoCodesScreen extends StatefulWidget {
  const AdminPromoCodesScreen({super.key, required this.repo});

  final AdminRepository repo;

  @override
  State<AdminPromoCodesScreen> createState() => _AdminPromoCodesScreenState();
}

class _AdminPromoCodesScreenState extends State<AdminPromoCodesScreen> {
  final _codeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _days = 30;
  int _maxUses = 100;
  bool _busy = false;
  bool _loading = true;
  List<PromoCode> _codes = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final codes = await widget.repo.listPromoCodes();
    if (mounted) {
      setState(() {
        _codes = codes;
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.adminPromoCodeTooShort)),
      );
      return;
    }
    setState(() => _busy = true);
    final error = await widget.repo.createPromoCode(
      code: code,
      days: _days,
      maxUses: _maxUses,
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? l10n.adminPromoCreatedMsg)),
    );
    if (error == null) {
      _codeCtrl.clear();
      _noteCtrl.clear();
      await _reload();
    }
  }

  Future<void> _revoke(PromoCode code) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminPromoRevokeBtn),
        content: Text(code.code),
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
    final error = await widget.repo.revokePromoCode(code.code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? l10n.adminPromoRevokedMsg)),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPromoTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Create form ──────────────────────────────────────────────
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.adminPromoCreateHeader,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [
                      UpperCaseTextFormatter(),
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9_-]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.adminPromoCodeHint,
                      prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Stepper(
                    label: l10n.adminPromoDaysLabel,
                    value: _days,
                    min: 1,
                    max: 365,
                    step: 7,
                    onChanged: (v) => setState(() => _days = v),
                  ),
                  const SizedBox(height: 8),
                  _Stepper(
                    label: l10n.adminPromoMaxUsesLabel,
                    value: _maxUses,
                    min: 1,
                    max: 100000,
                    step: 10,
                    onChanged: (v) => setState(() => _maxUses = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.adminPromoNoteHint,
                      prefixIcon: const Icon(Icons.note_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppGradientButton(
                    label: l10n.adminPromoCreateBtn,
                    icon: Icons.add_rounded,
                    loading: _busy,
                    onPressed: _busy ? null : _create,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Existing codes ───────────────────────────────────────────
            AppSectionHeader(title: l10n.adminPromoExistingHeader),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_codes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.adminPromoEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ..._codes.map((c) => _PromoTile(code: c, onRevoke: _revoke)),
          ],
        ),
      ),
    );
  }
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.code, required this.onRevoke});

  final PromoCode code;
  final ValueChanged<PromoCode> onRevoke;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final inactive = !code.active || code.isExhausted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppGlassCard(
        blur: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        code.code,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: inactive
                              ? theme.colorScheme.surfaceContainerHighest
                              : Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          inactive
                              ? l10n.adminPromoRevokedLabel
                              : l10n.adminPromoActiveLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: inactive
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${code.days} ${l10n.premiumDaysShort} · '
                    '${l10n.adminPromoUsedLabel} ${code.usedCount}/${code.maxUses}'
                    '${code.note.isNotEmpty ? ' · ${code.note}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!inactive)
              TextButton(
                onPressed: () => onRevoke(code),
                child: Text(
                  l10n.adminPromoRevokeBtn,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        IconButton.filledTonal(
          onPressed: value - step >= min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.filledTonal(
          onPressed: value + step <= max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

/// Forces typed promo codes to uppercase as the user types.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
