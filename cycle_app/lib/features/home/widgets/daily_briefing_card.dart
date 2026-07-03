import 'package:flutter/material.dart';

import '../../../core/ai/ai_action_parser.dart';
import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/ai/ai_gateway_exception.dart';
import '../../../core/premium/premium_gate.dart';
import '../../../core/ai/ai_response_cache.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// A card that shows a personalized daily AI greeting based on cycle phase.
/// Caches the result on disk for 18 hours so it doesn't re-fetch every visit.
class DailyBriefingCard extends StatefulWidget {
  const DailyBriefingCard({super.key});

  @override
  State<DailyBriefingCard> createState() => _DailyBriefingCardState();
}

class _DailyBriefingCardState extends State<DailyBriefingCard> {
  String? _briefing;
  String? _phase;
  int? _cycleDay;
  bool _loading = true;
  bool _failed = false;
  bool _needsPremium = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (!mounted) return;

      if (!await PremiumGate.hasPremium()) {
        setState(() {
          _loading = false;
          _needsPremium = true;
        });
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).languageCode;
      final engine = AiContextEngine();
      final ctx = await engine.buildAnonymizedContext();
      if (!mounted) return;

      final phase = ctx['currentPhase']?.toString();
      final cycleDay = ctx['currentCycleDay'] as int?;
      setState(() {
        _phase = phase;
        _cycleDay = cycleDay;
      });

      final cacheKey = AiResponseCache.makeKey(
        mode: 'briefing',
        cycleDay: cycleDay,
        phase: phase,
        locale: locale,
      );

      final cached = await AiResponseCache.get(cacheKey, ttl: const Duration(hours: 18));
      if (cached != null && cached.isNotEmpty && !_looksLikeError(cached)) {
        if (mounted) {
          setState(() {
            _briefing = AiActionParser.sanitizeForDisplay(cached);
            _loading = false;
          });
        }
        return;
      }

      final gateway = AiGateway();
      String? reply;
      try {
        reply = await gateway.request(
          message: l10n.dailyBriefingPrompt,
          context: ctx,
          mode: 'briefing',
        );
      } on AiGatewayException catch (e) {
        if (e.isPremiumRequired && mounted) {
          setState(() {
            _loading = false;
            _needsPremium = true;
          });
          return;
        }
      }

      final ok = reply != null && reply.isNotEmpty && !_looksLikeError(reply);
      if (mounted) {
        setState(() {
          _briefing = ok ? reply : null;
          _loading = false;
          _failed = !ok;
        });
        if (ok) {
          AiResponseCache.set(cacheKey, reply);
        }
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

  /// Detects raw error / diagnostic strings that must never be shown or cached.
  bool _looksLikeError(String text) {
    final lower = text.toLowerCase();
    return RegExp(r'^\[.*error\]').hasMatch(text.trim()) ||
        lower.startsWith('ai diagnostic') ||
        lower.contains('api_key_service_blocked') ||
        lower.contains('unauthenticated') ||
        lower.contains('"error"') ||
        lower.contains('expected oauth');
  }

  /// Picks an icon + accent based on the current cycle phase.
  ({IconData icon, Color accent}) _phaseVisual(ThemeData theme) {
    final phase = (_phase ?? '').toLowerCase();
    if (phase.contains('menstr') || phase.contains('حيض') || phase.contains('دور')) {
      return (icon: Icons.water_drop_rounded, accent: AuraColors.roseDeep);
    }
    if (phase.contains('follicular') || phase.contains('جريبي') || phase.contains('بصيلي')) {
      return (icon: Icons.spa_rounded, accent: const Color(0xFF84C9A0));
    }
    if (phase.contains('ovul') || phase.contains('إباض') || phase.contains('تبويض')) {
      return (icon: Icons.local_florist_rounded, accent: const Color(0xFFE89B4F));
    }
    if (phase.contains('luteal') || phase.contains('أصفر') || phase.contains('لوتي')) {
      return (icon: Icons.nightlight_round, accent: const Color(0xFF9F7BC8));
    }
    return (icon: Icons.wb_sunny_outlined, accent: theme.colorScheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_needsPremium) {
      return AppGlassCard(
        blur: false,
        child: Row(
          children: [
            Icon(Icons.auto_awesome_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.premiumRequiredAi,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_failed) return const SizedBox.shrink();

    final visual = _phaseVisual(theme);

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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      visual.accent,
                      visual.accent.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: visual.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(visual.icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dailyBriefingTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_cycleDay != null && _phase != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${l10n.homeCycleDay(_cycleDay!)} · $_phase',
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
                    color: visual.accent,
                  ),
                ),
            ],
          ),
          if (_briefing != null) ...[
            const SizedBox(height: 14),
            Text(
              _briefing!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ] else if (_loading) ...[
            const SizedBox(height: 14),
            const _BriefingSkeleton(),
          ],
        ],
      ),
    );
  }
}

/// Shimmer-like placeholder that hints at the upcoming text content.
class _BriefingSkeleton extends StatefulWidget {
  const _BriefingSkeleton();

  @override
  State<_BriefingSkeleton> createState() => _BriefingSkeletonState();
}

class _BriefingSkeletonState extends State<_BriefingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final alpha = 0.08 + (_ctrl.value * 0.07);
        final color = theme.colorScheme.onSurface.withValues(alpha: alpha);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line(color, widthFactor: 0.95),
            const SizedBox(height: 8),
            _line(color, widthFactor: 0.85),
            const SizedBox(height: 8),
            _line(color, widthFactor: 0.55),
          ],
        );
      },
    );
  }

  Widget _line(Color color, {required double widthFactor}) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
