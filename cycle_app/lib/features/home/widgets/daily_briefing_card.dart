import 'package:flutter/material.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/ai_gateway.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// A card that shows a personalized daily AI greeting based on cycle phase.
/// Loads once per session and caches the result.
class DailyBriefingCard extends StatefulWidget {
  const DailyBriefingCard({super.key});

  @override
  State<DailyBriefingCard> createState() => _DailyBriefingCardState();
}

class _DailyBriefingCardState extends State<DailyBriefingCard> {
  String? _briefing;
  bool _loading = true;
  bool _failed = false;

  // Session-level cache so we don't re-fetch on every rebuild.
  static String? _cachedBriefing;
  static DateTime? _cacheDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use cache if it's from today.
    final now = DateTime.now();
    if (_cachedBriefing != null &&
        _cacheDate != null &&
        _cacheDate!.year == now.year &&
        _cacheDate!.month == now.month &&
        _cacheDate!.day == now.day) {
      if (mounted) {
        setState(() {
          _briefing = _cachedBriefing;
          _loading = false;
        });
      }
      return;
    }

    try {
      final engine = AiContextEngine();
      final context = await engine.buildAnonymizedContext();

      final gateway = AiGateway();
      final reply = await gateway.request(
        message: 'Give me my daily briefing for today.',
        context: context,
        mode: 'briefing',
      );

      if (mounted) {
        setState(() {
          _briefing = reply;
          _loading = false;
          _failed = reply == null || reply.isEmpty;
        });
        if (reply != null && reply.isNotEmpty) {
          _cachedBriefing = reply;
          _cacheDate = now;
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AuraDecorations.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.dailyBriefingTitle,
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
                ),
            ],
          ),
          if (_briefing != null) ...[
            const SizedBox(height: 12),
            Text(
              _briefing!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.55,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ] else if (_loading) ...[
            const SizedBox(height: 12),
            Text(
              l10n.dailyBriefingLoading,
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
