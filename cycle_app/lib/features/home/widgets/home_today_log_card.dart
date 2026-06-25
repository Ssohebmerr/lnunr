import 'package:flutter/material.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/navigation/home_shell_actions.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../cycle/data/today_log_service.dart';

/// Shows today's saved mood/symptoms/water on the home screen.
class HomeTodayLogCard extends StatefulWidget {
  const HomeTodayLogCard({super.key});

  @override
  State<HomeTodayLogCard> createState() => _HomeTodayLogCardState();
}

class _HomeTodayLogCardState extends State<HomeTodayLogCard> {
  final _service = TodayLogService();
  TodayLogSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    HomeRefreshScope.notifier.addListener(_onHomeRefresh);
    _load();
  }

  @override
  void dispose() {
    HomeRefreshScope.notifier.removeListener(_onHomeRefresh);
    super.dispose();
  }

  void _onHomeRefresh() => _load();

  Future<void> _load() async {
    final summary = await _service.loadToday();
    if (mounted) {
      setState(() {
        _summary = summary;
        _loading = false;
      });
    }
  }

  void _openLog() => HomeShellActions.openLog?.call();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = _summary;

    if (_loading) {
      return const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (summary == null) return const SizedBox.shrink();

    return AppGlassCard(
      blur: false,
      onTap: _openLog,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.homeTodayLogTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!summary.hasEntry)
            Text(
              l10n.homeTodayLogEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            if (summary.symptoms.isNotEmpty) ...[
              Text(
                l10n.homeTodayLogSymptoms,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: summary.symptoms.take(6).map((name) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (summary.waterCups > 0) ...[
              if (summary.symptoms.isNotEmpty) const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.homeTodayLogWater(summary.waterCups),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              l10n.homeTodayLogStoredHint,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
