import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_design_tokens.dart';
import '../../widgets/aura_scaffold.dart';
import '../ai_insights_service.dart';
import '../models/ai_insight.dart';

/// Drop-in AI insight card for any screen.
///
/// Reads [AiInsightsService] from the provider tree, loads (or serves the
/// cached) insight for [type], and renders it in the Aura glass style.
/// Hides itself entirely when AI is unavailable (no consent / no key), so
/// screens can embed it unconditionally.
class AiInsightCard extends StatefulWidget {
  const AiInsightCard({
    super.key,
    required this.type,
    this.margin,
    this.blur = true,
    this.compact = false,
  });

  final AiInsightType type;
  final EdgeInsetsGeometry? margin;
  final bool blur;
  final bool compact;

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  AiInsight? _insight;
  bool _loading = true;
  bool _refreshing = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    if (!mounted) return;
    setState(() => force ? _refreshing = true : _loading = true);

    final service = context.read<AiInsightsService>();
    final lang = Localizations.localeOf(context).languageCode;
    final insight = await service
        .getInsight(widget.type, languageCode: lang, forceRefresh: force)
        .timeout(const Duration(seconds: 10), onTimeout: () => null);

    if (mounted) {
      setState(() {
        _insight = insight ?? _insight;
        _loading = false;
        _refreshing = false;
      });
    }
  }

  (IconData, String) _header(AppLocalizations l10n) => switch (widget.type) {
    AiInsightType.dailyTip => (Icons.auto_awesome, l10n.aiInsightDailyTitle),
    AiInsightType.moodInsight => (
      Icons.favorite_outline,
      l10n.aiInsightMoodTitle,
    ),
    AiInsightType.cycleHealth => (
      Icons.monitor_heart_outlined,
      l10n.aiInsightCycleTitle,
    ),
    AiInsightType.weeklySummary => (
      Icons.calendar_view_week_outlined,
      l10n.aiInsightWeeklyTitle,
    ),
    AiInsightType.prenatalTip => (
      Icons.pregnant_woman_rounded,
      l10n.aiInsightPrenatalTitle,
    ),
    AiInsightType.conceiveTip => (
      Icons.child_friendly,
      l10n.aiInsightConceiveTitle,
    ),
    AiInsightType.avoidTip => (Icons.shield_outlined, l10n.aiInsightAvoidTitle),
    AiInsightType.wellnessTip => (
      Icons.health_and_safety_outlined,
      l10n.aiInsightWellnessTitle,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // AI unavailable (no consent, no key, no data) → take no space at all.
    if (!_loading && _insight == null) return const SizedBox.shrink();

    final (icon, title) = _header(l10n);

    return Padding(
      padding: widget.margin ?? const EdgeInsets.only(top: 12),
      child: AppGlassCard(
        radius: AppRadius.lg,
        blur: widget.blur,
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
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                AppPhaseBadge(
                  icon: Icons.auto_awesome,
                  label: l10n.aiInsightBadge,
                  highlight: true,
                ),
                if (_insight != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l10n.aiInsightRefresh,
                    onPressed: _refreshing ? null : () => _load(force: true),
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.refresh,
                            size: 18,
                            color: theme.colorScheme.outline,
                          ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loading)
              const _InsightSkeleton()
            else ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: AlignmentDirectional.topStart,
                child: Text(
                  _insight!.text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                  maxLines: widget.compact && !_expanded ? 4 : null,
                  overflow: widget.compact && !_expanded
                      ? TextOverflow.ellipsis
                      : TextOverflow.visible,
                ),
              ),
              if (widget.compact && _insight!.text.length > 180)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? (_expanded ? 'عرض أقل' : 'قراءة المزيد')
                          : (_expanded ? 'Show less' : 'Read more'),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                l10n.aiInsightDisclaimer,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightSkeleton extends StatelessWidget {
  const _InsightSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double widthFactor) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(1), bar(0.9), bar(0.6)],
    );
  }
}
