import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/app_home_refresh.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../data/pregnancy_log_models.dart';
import '../data/pregnancy_tracking_service.dart';

/// Weight, kick counter, and contraction timer — Flo-style pregnancy trackers.
class PregnancyTrackingSection extends StatefulWidget {
  const PregnancyTrackingSection({super.key, this.compact = false});

  /// When true, hides the section title (for embedding in reports).
  final bool compact;

  @override
  State<PregnancyTrackingSection> createState() => _PregnancyTrackingSectionState();
}

class _PregnancyTrackingSectionState extends State<PregnancyTrackingSection> {
  final _service = PregnancyTrackingService();
  final _weightController = TextEditingController();

  List<PregnancyWeightLog> _weights = [];
  PregnancyKickSession? _kickSession;
  List<PregnancyContraction> _contractions = [];
  PregnancyTrackingSummary? _summary;
  DateTime? _contractionStart;
  Timer? _uiTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_contractionStart != null || _kickSession?.endedAt == null) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final weights = await _service.recentWeights(limit: 14);
    final session = await _service.activeKickSession();
    final contractions = await _service.todayContractions();
    final summary = await _service.buildSummary();
    if (mounted) {
      setState(() {
        _weights = weights;
        _kickSession = session;
        _contractions = contractions;
        _summary = summary;
        _loading = false;
      });
    }
  }

  Future<void> _saveWeight() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = _weightController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null || value < 30 || value > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pregnancyWeightInvalid)),
      );
      return;
    }
    await _service.logWeight(value);
    _weightController.clear();
    await _load();
    HomeRefreshScope.notifier.value++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pregnancyWeightSaved)),
      );
    }
  }

  Future<void> _startKicks() async {
    final session = await _service.startKickSession();
    setState(() => _kickSession = session);
  }

  Future<void> _tapKick() async {
    var session = _kickSession;
    session ??= await _service.startKickSession();
    final updated = await _service.registerKick(session);
    setState(() => _kickSession = updated.endedAt != null ? null : updated);
    await _load();
    HomeRefreshScope.notifier.value++;
  }

  Future<void> _endKicks() async {
    final session = _kickSession;
    if (session == null) return;
    await _service.endKickSession(session);
    setState(() => _kickSession = null);
    await _load();
  }

  void _startContraction() {
    setState(() => _contractionStart = DateTime.now());
  }

  Future<void> _endContraction() async {
    final start = _contractionStart;
    if (start == null) return;
    final end = DateTime.now();
    if (end.difference(start).inSeconds < 5) {
      setState(() => _contractionStart = null);
      return;
    }
    await _service.recordContraction(startedAt: start, endedAt: end);
    setState(() => _contractionStart = null);
    await _load();
    HomeRefreshScope.notifier.value++;
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) ...[
          AppSectionHeader(title: l10n.pregnancyTrackingTitle),
          Text(
            l10n.pregnancyTrackingSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _WeightCard(
          l10n: l10n,
          theme: theme,
          weights: _weights,
          summary: _summary,
          controller: _weightController,
          onSave: _saveWeight,
        ),
        const SizedBox(height: 10),
        _KickCard(
          l10n: l10n,
          theme: theme,
          session: _kickSession,
          summary: _summary,
          formatDuration: _formatDuration,
          onStart: _startKicks,
          onKick: _tapKick,
          onEnd: _endKicks,
        ),
        const SizedBox(height: 10),
        _ContractionCard(
          l10n: l10n,
          theme: theme,
          contractions: _contractions,
          summary: _summary,
          contractionStart: _contractionStart,
          formatDuration: _formatDuration,
          onStart: _startContraction,
          onEnd: _endContraction,
        ),
      ],
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.l10n,
    required this.theme,
    required this.weights,
    required this.summary,
    required this.controller,
    required this.onSave,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<PregnancyWeightLog> weights;
  final PregnancyTrackingSummary? summary;
  final TextEditingController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final chartWeights = weights.take(8).toList().reversed.toList();

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(l10n.pregnancyWeightTitle, style: theme.textTheme.titleSmall),
            ],
          ),
          if (summary?.latestWeightKg != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.pregnancyWeightLatest(summary!.latestWeightKg!),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (chartWeights.length >= 2) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < chartWeights.length; i++)
                          FlSpot(i.toDouble(), chartWeights[i].weightKg),
                      ],
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.pregnancyWeightHint,
                    suffixText: l10n.pregnancyWeightUnit,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: onSave, child: Text(l10n.pregnancyWeightSave)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KickCard extends StatelessWidget {
  const _KickCard({
    required this.l10n,
    required this.theme,
    required this.session,
    required this.summary,
    required this.formatDuration,
    required this.onStart,
    required this.onKick,
    required this.onEnd,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final PregnancyKickSession? session;
  final PregnancyTrackingSummary? summary;
  final String Function(Duration) formatDuration;
  final VoidCallback onStart;
  final VoidCallback onKick;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final active = session != null && session!.endedAt == null;
    final count = session?.kickCount ?? 0;
    final goal = PregnancyTrackingService.kickGoal;

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.baby_changing_station, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.pregnancyKicksTitle, style: theme.textTheme.titleSmall),
              ),
              if (summary != null && summary!.todayKicks > 0)
                AppStatChip(
                  icon: Icons.today,
                  label: l10n.pregnancyKicksToday(summary!.todayKicks),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.pregnancyKicksHint,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 14),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: active ? count / goal : 0,
                    strokeWidth: 8,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '/ $goal',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (active) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                formatDuration(session!.elapsed),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!active)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.pregnancyKicksStart),
                  ),
                )
              else ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onKick,
                    icon: const Icon(Icons.touch_app),
                    label: Text(l10n.pregnancyKicksTap),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onEnd,
                  child: Text(l10n.pregnancyKicksEnd),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ContractionCard extends StatelessWidget {
  const _ContractionCard({
    required this.l10n,
    required this.theme,
    required this.contractions,
    required this.summary,
    required this.contractionStart,
    required this.formatDuration,
    required this.onStart,
    required this.onEnd,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<PregnancyContraction> contractions;
  final PregnancyTrackingSummary? summary;
  final DateTime? contractionStart;
  final String Function(Duration) formatDuration;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final timing = contractionStart != null;
    final elapsed = timing
        ? DateTime.now().difference(contractionStart!)
        : Duration.zero;

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(l10n.pregnancyContractionsTitle,
                  style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.pregnancyContractionsHint,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
          ),
          if (summary != null && summary!.todayContractions > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                AppStatChip(
                  icon: Icons.today,
                  label: l10n.pregnancyContractionsToday(summary!.todayContractions),
                ),
                if (summary!.avgContractionSeconds != null)
                  AppStatChip(
                    icon: Icons.av_timer,
                    label: l10n.pregnancyContractionAvg(
                      summary!.avgContractionSeconds!,
                    ),
                  ),
                if (summary!.lastContractionIntervalMinutes != null)
                  AppStatChip(
                    icon: Icons.linear_scale,
                    label: l10n.pregnancyContractionInterval(
                      summary!.lastContractionIntervalMinutes!,
                    ),
                  ),
              ],
            ),
          ],
          if (timing) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                formatDuration(elapsed),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: timing
                ? FilledButton.icon(
                    onPressed: onEnd,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                    ),
                    icon: const Icon(Icons.stop),
                    label: Text(l10n.pregnancyContractionEnd),
                  )
                : FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.pregnancyContractionStart),
                  ),
          ),
          if (contractions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(l10n.pregnancyContractionRecent,
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            ...contractions.take(5).map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          '${_timeLabel(c.startedAt)} · '
                          '${l10n.pregnancyContractionDuration(c.durationSeconds)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
