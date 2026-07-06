import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/self_care_content.dart';

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key, this.phase});

  final String? phase;

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  static const _favKey = 'selfcare_fav_affirmations';

  late final List<SelfCareTip> _items =
      SelfCareContent.affirmationsForPhase(widget.phase);
  late final PageController _controller = PageController();
  int _index = 0;
  Set<String> _favorites = {};
  final Set<String> _aiTexts = {};
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _favorites = (prefs.getStringList(_favKey) ?? <String>[]).toSet());
    }
  }

  Future<void> _toggleFavorite(String text) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_favorites.contains(text)) {
        _favorites.remove(text);
      } else {
        _favorites.add(text);
        HapticFeedback.lightImpact();
      }
    });
    await prefs.setStringList(_favKey, _favorites.toList());
  }

  Future<void> _generate() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (!await PremiumGate.hasPremium()) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.premiumRequiredAi)));
      return;
    }
    if (!mounted) return;
    setState(() => _generating = true);

    try {
      final ctx = await AiContextEngine().buildAnonymizedContext();
      final reply = await AiGateway().request(
        message: l10n.selfCareAffirmationPrompt,
        context: ctx,
        mode: 'affirmation',
      );
      final raw = reply?.trim() ?? '';
      // Keep only the first line and strip any wrapping quotes the model adds.
      final clean = raw
          .split('\n')
          .first
          .replaceAll(RegExp(r'^["“”\s]+|["“”\s]+$'), '')
          .trim();

      if (clean.isNotEmpty && mounted) {
        setState(() {
          _items.insert(0, SelfCareTip(en: clean, ar: clean));
          _aiTexts.add(clean);
          _index = 0;
          _generating = false;
        });
        if (_controller.hasClients) {
          _controller.jumpToPage(0);
        }
        HapticFeedback.lightImpact();
      } else if (mounted) {
        setState(() => _generating = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.aiUnavailable)));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _generating = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.aiUnavailable)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final text = _items[_index].forLocale(lang);
    final isFav = _favorites.contains(text);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.selfCareAffirmations),
      ),
      body: AppMeshBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final isAi = _aiTexts.contains(_items[i].forLocale(lang));
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Container(
                          decoration: isAi
                              ? BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  gradient: AuraDecorations.primaryGradient,
                                )
                              : null,
                          padding: isAi ? const EdgeInsets.all(2) : null,
                          child: AppGlassCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isAi) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Lune 🌸',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ] else
                                  Icon(Icons.format_quote_rounded,
                                      size: 40,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.5)),
                                if (!isAi) const SizedBox(height: 16),
                                Text(
                                  _items[i].forLocale(lang),
                                  textAlign: TextAlign.center,
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? AuraColors.roseDeep : null,
                    onTap: () => _toggleFavorite(text),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.selfCareCopied)),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.share_rounded,
                    onTap: () => SharePlus.instance.share(ShareParams(text: text)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AppGradientButton(
                  label: l10n.selfCareAffirmationGenerate,
                  icon: Icons.auto_awesome_rounded,
                  loading: _generating,
                  onPressed: _generate,
                ),
              ),
              const SizedBox(height: 16),
              // Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap, this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface.withValues(alpha: 0.5),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 22),
        ),
      ),
    );
  }
}
