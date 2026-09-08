import 'package:flutter/material.dart';

import '../../../core/ai/ai_context_engine.dart';
import '../../../core/ai/models/health_snapshot.dart';
import '../../../l10n/app_localizations.dart';
import '../data/insight_generator.dart';

/// Compact card placed at the top of the Home tab. Shows the current
/// cycle / pregnancy insight in plain language + a phase accent stripe.
class InsightCard extends StatefulWidget {
  const InsightCard({
    super.key,
    this.engine,
    InsightGenerator? generator,
    this.onTap,
  }) : _generator = generator;

  final AiContextEngine? engine;
  final InsightGenerator? _generator;
  final VoidCallback? onTap;

  @override
  State<InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<InsightCard> {
  late final Future<HealthSnapshot> _snapshotFuture;

  InsightGenerator get _gen => widget._generator ?? const InsightGenerator();

  @override
  void initState() {
    super.initState();
    _snapshotFuture = (widget.engine ?? AiContextEngine()).buildSnapshot();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: FutureBuilder<HealthSnapshot>(
        future: _snapshotFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const _InsightSkeleton();
          }
          final l10n = AppLocalizations.of(context)!;
          final insight = _gen.forSnapshot(snap.data!, l10n);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: insight.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: insight.accent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: insight.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(insight.icon, color: insight.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            insight.headline,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: insight.accent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            insight.body,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.8),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InsightSkeleton extends StatelessWidget {
  const _InsightSkeleton();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
