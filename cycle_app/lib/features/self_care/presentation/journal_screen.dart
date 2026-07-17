import 'package:flutter/material.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/privacy/consent_dialogs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/journal_service.dart';
import '../data/self_care_content.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _controller = TextEditingController();
  int _promptIndex = 0;
  bool _loading = true;
  bool _saving = false;
  List<JournalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entries = await JournalService.all();
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final lang = Localizations.localeOf(context).languageCode;
    await JournalService.add(
      text: text,
      prompt: SelfCareContent.journalPrompts[_promptIndex].forLocale(lang),
    );
    if (!mounted) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    await _load();
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.selfCareJournalSaved)),
      );
    }
  }

  Future<void> _delete(JournalEntry entry) async {
    await JournalService.delete(entry.id);
    await _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final prompt = SelfCareContent.journalPrompts[_promptIndex].forLocale(lang);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.selfCareJournal),
      ),
      body: AppMeshBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            32,
          ),
          children: [
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.selfCareJournalPrompt,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: () => setState(() {
                          _promptIndex = (_promptIndex + 1) %
                              SelfCareContent.journalPrompts.length;
                        }),
                      ),
                    ],
                  ),
                  Text(prompt, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: l10n.selfCareJournalHint,
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppGradientButton(
                    label: l10n.selfCareJournalSave,
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_entries.isNotEmpty) ...[
              AppSectionHeader(title: l10n.selfCareJournalHistory),
              const SizedBox(height: 4),
              for (final entry in _entries)
                _JournalEntryCard(
                  entry: entry,
                  lang: lang,
                  onDelete: () => _delete(entry),
                  onReflect: () => _reflect(entry),
                ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.menu_book_rounded,
                        size: 48,
                        color: theme.colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      l10n.selfCareJournalEmpty,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _reflect(JournalEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final access = await PremiumGate.checkAiChat();
    if (!mounted) return;
    if (access == PremiumAiAccess.needsAdult) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.aiAdultsOnly)));
      return;
    }
    if (access == PremiumAiAccess.needsPremium ||
        access == PremiumAiAccess.limitReached) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.premiumRequiredAi)));
      return;
    }
    if (access == PremiumAiAccess.needsConsent) {
      final accepted = await showAiConsentDialog(context);
      if (!accepted || !mounted) return;
    }
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReflectionSheet(entryText: entry.text),
    );
  }
}

class _JournalEntryCard extends StatefulWidget {
  const _JournalEntryCard({
    required this.entry,
    required this.lang,
    required this.onDelete,
    required this.onReflect,
  });

  final JournalEntry entry;
  final String lang;
  final VoidCallback onDelete;
  final VoidCallback onReflect;

  @override
  State<_JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<_JournalEntryCard> {
  bool _expanded = false;

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)} · ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entry = widget.entry;
    final long = entry.text.length > 140;

    return AppGlassCard(
      blur: false,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _formatDate(entry.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
                onSelected: (v) {
                  if (v == 'delete') widget.onDelete();
                  if (v == 'reflect') widget.onReflect();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reflect',
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(l10n.selfCareJournalReflect),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.selfCareJournalDelete),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (entry.prompt != null && entry.prompt!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                entry.prompt!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          Text(
            _expanded || !long
                ? entry.text
                : '${entry.text.substring(0, 140)}…',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (long)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? l10n.showLess : l10n.showMore),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom sheet that runs Lune's gentle mood reflection on a journal entry.
class _ReflectionSheet extends StatefulWidget {
  const _ReflectionSheet({required this.entryText});

  final String entryText;

  @override
  State<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<_ReflectionSheet> {
  String? _reflection;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final ctx = await AiContextEngine().buildAnonymizedContext();
      final reply = await AiGateway().request(
        message: widget.entryText,
        context: ctx,
        mode: 'mood',
      );
      if (mounted) {
        setState(() {
          _reflection = reply?.trim();
          _loading = false;
          _failed = reply == null || reply.trim().isEmpty;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 18, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.selfCareJournalReflect,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 14),
                  Text(l10n.selfCareJournalReflecting),
                ],
              ),
            )
          else if (_failed)
            Text(l10n.aiUnavailable)
          else
            Text(
              _reflection!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
