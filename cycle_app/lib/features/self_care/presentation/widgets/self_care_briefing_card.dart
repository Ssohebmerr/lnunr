import 'package:flutter/material.dart';

import '../../../../core/ai/ai_action_parser.dart';
import '../../../../core/ai/ai_context_engine.dart';
import '../../../../core/ai/ai_gateway.dart';
import '../../../../core/ai/ai_gateway_exception.dart';
import '../../../../core/ai/ai_response_cache.dart';
import '../../../../core/premium/premium_gate.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/self_care_content.dart';

/// AI-powered "whisper of the day" for the Self-care tab.
///
/// Mirrors the Home tab's daily briefing but with a tender, self-care voice
/// and awareness of today's logged mood. Gracefully falls back to a static,
/// phase-based tip when the user isn't premium or the AI is unavailable —
/// so the card is never empty.
class SelfCareBriefingCard extends StatefulWidget {
  const SelfCareBriefingCard({
    super.key,
    required this.fallbackTip,
    required this.phase,
    required this.cycleDay,
    required this.moodKey,
    this.phaseLabel,
  });

  /// Static, phase/goal-aware tip shown when AI isn't available.
  final String fallbackTip;
  final String phase;
  final int? cycleDay;
  final String? moodKey;

  /// Optional human-readable phase/week label for the subtitle.
  final String? phaseLabel;

  @override
  State<SelfCareBriefingCard> createState() => _SelfCareBriefingCardState();
}

class _SelfCareBriefingCardState extends State<SelfCareBriefingCard> {
  String? _whisper;
  bool _loading = true;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SelfCareBriefingCard old) {
    super.didUpdateWidget(old);
    // Re-fetch when the mood or phase changes so the whisper stays relevant.
    if (old.moodKey != widget.moodKey || old.phase != widget.phase) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _locked = false;
      });
    }
    try {
      if (!await PremiumGate.hasPremium()) {
        if (mounted) {
          setState(() {
            _loading = false;
            _locked = true;
            _whisper = null;
          });
        }
        return;
      }
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).languageCode;

      final ctx = await AiContextEngine().buildAnonymizedContext();
      if (widget.moodKey != null) {
        ctx['todayMood'] = widget.moodKey;
      }
      if (!mounted) return;

      final cacheKey = AiResponseCache.makeKey(
        mode: 'selfcare',
        cycleDay: widget.cycleDay,
        phase: widget.phase,
        locale: locale,
        extra: 'mood=${widget.moodKey ?? '-'}',
      );

      final cached = await AiResponseCache.get(cacheKey, ttl: const Duration(hours: 12));
      if (cached != null && cached.isNotEmpty && !_looksLikeError(cached)) {
        if (mounted) {
          setState(() {
            _whisper = AiActionParser.sanitizeForDisplay(cached);
            _loading = false;
          });
        }
        return;
      }

      String? reply;
      try {
        reply = await AiGateway().request(
          message: l10n.selfCareWhisperPrompt,
          context: ctx,
          mode: 'selfcare',
        );
      } on AiGatewayException catch (e) {
        if (e.isPremiumRequired && mounted) {
          setState(() {
            _loading = false;
            _locked = true;
          });
          return;
        }
      }

      final ok = reply != null && reply.isNotEmpty && !_looksLikeError(reply);
      if (mounted) {
        setState(() {
          _whisper = ok ? AiActionParser.sanitizeForDisplay(reply!) : null;
          _loading = false;
        });
      }
      if (ok) AiResponseCache.set(cacheKey, reply);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _whisper = null;
        });
      }
    }
  }

  bool _looksLikeError(String text) {
    final lower = text.toLowerCase();
    return RegExp(r'^\[.*error\]').hasMatch(text.trim()) ||
        lower.startsWith('ai diagnostic') ||
        lower.contains('api_key_service_blocked') ||
        lower.contains('unauthenticated') ||
        lower.contains('"error"') ||
        lower.contains('expected oauth');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mood = SelfCareContent.moodByKey(widget.moodKey);

    // The body: AI whisper when we have it, otherwise the static tip.
    final body = _whisper ?? widget.fallbackTip;

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppShadows.softRose(opacity: 0.3),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selfCareWhisperTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.phaseLabel != null && widget.phaseLabel!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          mood != null
                              ? '${widget.phaseLabel} · ${mood.emoji} ${mood.label(Localizations.localeOf(context).languageCode)}'
                              : widget.phaseLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              if (_loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (_locked) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.lock_open_rounded,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.selfCareWhisperLocked,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
