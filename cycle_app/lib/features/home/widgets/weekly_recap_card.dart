import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/ai/ai_response_cache.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// Weekly recap insight card — calls the `weekly_recap` AI mode and caches
/// the result for 7 days (key includes ISO week so it auto-refreshes Mondays).
class WeeklyRecapCard extends StatefulWidget {
  const WeeklyRecapCard({super.key});

  @override
  State<WeeklyRecapCard> createState() => _WeeklyRecapCardState();
}

class _WeeklyRecapCardState extends State<WeeklyRecapCard> {
  String? _text;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _weekKey(DateTime d) {
    // ISO week: Monday is first day. Yields "2026-W26" style.
    final dayOfYear = int.parse(
        '${d.difference(DateTime(d.year, 1, 1)).inDays + 1}');
    final week = ((dayOfYear - d.weekday + 10) / 7).floor();
    return '${d.year}-W$week';
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).languageCode;
      final engine = AiContextEngine();
      final ctx = await engine.buildAnonymizedContext();

      final cacheKey = AiResponseCache.makeKey(
        mode: 'weekly_recap',
        cycleDay: ctx['currentCycleDay'] as int?,
        phase: ctx['currentPhase']?.toString(),
        locale: locale,
        extra: _weekKey(DateTime.now()),
      );

      if (!force) {
        final cached = await AiResponseCache.get(
          cacheKey,
          ttl: const Duration(days: 7),
        );
        if (cached != null && cached.isNotEmpty) {
          if (mounted) {
            setState(() {
              _text = cached;
              _loading = false;
            });
          }
          return;
        }
      }

      final gateway = AiGateway();
      final reply = await gateway.request(
        message: l10n.weeklyRecapPrompt,
        context: ctx,
        mode: 'weekly_recap',
      );

      if (mounted) {
        setState(() {
          _text = reply;
          _loading = false;
          _failed = reply == null || reply.isEmpty;
        });
        if (reply != null && reply.isNotEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_failed) return const SizedBox.shrink();

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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB07CD8), Color(0xFFE89B4F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB07CD8).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.calendar_view_week_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.weeklyRecapTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                )
              else
                IconButton(
                  tooltip: l10n.weeklyRecapRefresh,
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _load(force: true);
                  },
                ),
            ],
          ),
          if (_text != null) ...[
            const SizedBox(height: 12),
            Text(
              _text!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.6,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ] else if (_loading) ...[
            const SizedBox(height: 12),
            Text(
              l10n.weeklyRecapLoading,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
