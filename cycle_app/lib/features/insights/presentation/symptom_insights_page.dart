import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../data/insight_message_builder.dart';
import '../data/symptom_insight_analyzer.dart';
import 'symptom_insight_tile.dart';

/// The standalone "Symptom Insights" page — fed by the
/// [SymptomInsightAnalyzer]. Shows a header summary, then one
/// [SymptomInsightTile] per symptom that clears the minimum-samples
/// + minimum-confidence filters.
class SymptomInsightsPage extends StatefulWidget {
  const SymptomInsightsPage({
    super.key,
    this.analyzer = const SymptomInsightAnalyzer(),
    this.builder = const InsightMessageBuilder(),
  });

  final SymptomInsightAnalyzer analyzer;
  final InsightMessageBuilder builder;

  @override
  State<SymptomInsightsPage> createState() => _SymptomInsightsPageState();
}

class _SymptomInsightsPageState extends State<SymptomInsightsPage> {
  late Future<List<SymptomInsight>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.analyzer.analyze();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.analyzer.analyze();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'أنماط الأعراض' : 'Symptom patterns'),
        actions: [
          IconButton(
            tooltip: isArabic ? 'تحديث' : 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<SymptomInsight>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snap.hasError) {
            return _ErrorState(onRetry: _refresh);
          }
          final insights = snap.data ?? const <SymptomInsight>[];
          if (insights.isEmpty) {
            return _EmptyState(
              isArabic: isArabic,
              onRetry: _refresh,
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              itemCount: insights.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) return _Header(insights: insights, isArabic: isArabic);
                final insight = insights[i - 1];
                return SymptomInsightTile(
                  insight: insight,
                  isArabic: isArabic,
                  builder: widget.builder,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.insights, required this.isArabic});

  final List<SymptomInsight> insights;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSamples = insights.fold<int>(
        0, (sum, i) => sum + i.samples);
    final headline = isArabic
        ? 'اكتشفنا ${insights.length} ${_pluralAr(insights.length)} بناءً على $totalSamples دورة مسجلة'
        : 'Found ${insights.length} pattern${insights.length == 1 ? "" : "s"} '
            'across $totalSamples logged cycles';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_graph_rounded, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              headline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pluralAr(int n) => n == 1 ? 'نمط' : 'أنماط';
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isArabic, required this.onRetry});
  final bool isArabic;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timeline,
                size: 56, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'لا توجد أنماط بعد\nسجّل أعراضك لبضعة دورات لاكتشاف الأنماط'
                  : 'No patterns yet\nLog symptoms for a few cycles to start seeing patterns',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(isArabic ? 'إعادة فحص' : 'Re-scan'),
            ),
          ],
        ),
      ),
    );
  }
}