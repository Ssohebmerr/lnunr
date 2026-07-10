import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:menstrual_cycle_widget/menstrual_cycle_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ai/models/ai_insight.dart';
import '../../../core/ai/widgets/ai_insight_card.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../l10n/app_localizations.dart';
import '../../cycle/data/cycle_bridge_service.dart';
import '../../education/presentation/article_screen.dart';
import '../../self_care/data/self_care_content.dart';
import '../data/home_media_content.dart';

class HomeTodayBanner extends StatelessWidget {
  const HomeTodayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final pattern = lang == 'ar' ? 'EEEE، d MMMM yyyy' : 'EEEE, MMMM d, yyyy';
    final formatted = DateFormat(pattern, lang).format(DateTime.now());

    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AuraDecorations.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              formatted,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeKeyDatesCard extends StatelessWidget {
  const HomeKeyDatesCard({super.key, required this.data});

  final CycleDashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AppGlassCard(
      blur: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeKeyDates,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _DateRow(
            icon: Icons.water_drop_outlined,
            color: theme.colorScheme.primary,
            label: l10n.nextPeriod,
            value: data.nextPeriod,
          ),
          const SizedBox(height: 10),
          _DateRow(
            icon: Icons.favorite_outline,
            color: theme.colorScheme.secondary,
            label: l10n.homeOvulation,
            value: data.ovulation,
          ),
          if (data.expectedDueDate.isNotEmpty &&
              data.expectedDueDate != '—' &&
              data.expectedDueDate != '-') ...[
            const SizedBox(height: 10),
            _DateRow(
              icon: Icons.child_care_outlined,
              color: theme.colorScheme.tertiary,
              label: l10n.homeDueDate,
              value: data.expectedDueDate,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l10n.homeCycleProgress,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: data.avgCycleLength > 0
                  ? (data.cycleDay / data.avgCycleLength).clamp(0.0, 1.0)
                  : null,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${data.cycleDay} / ${data.avgCycleLength} ${l10n.homeDayShort}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class HomeWeeklyCalendarCard extends StatelessWidget {
  const HomeWeeklyCalendarCard({super.key, required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppGlassCard(
      blur: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              l10n.homeWeeklyCalendar,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(
            height: 200,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RepaintBoundary(
                    child: IgnorePointer(
                      child: MenstrualCycleCalenderView(
                        themeColor: AuraColors.roseDeep,
                        daySelectedColor: AuraColors.lavenderSoft,
                        hideInfoView: true,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class HomeTipsSection extends StatelessWidget {
  const HomeTipsSection({super.key, required this.phase});

  final String phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final tip = SelfCareContent.tipForPhase(phase, lang);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.homeTipsSection),
        const AiInsightCard(type: AiInsightType.dailyTip, blur: false),
        const SizedBox(height: 10),
        const AiInsightCard(type: AiInsightType.moodInsight, blur: false),
        const SizedBox(height: 10),
        AppGlassCard(
          blur: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selfCareTodayTip,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.forLocale(lang),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const AiInsightCard(type: AiInsightType.cycleHealth, blur: false),
      ],
    );
  }
}

class HomeLearnWatchRail extends StatefulWidget {
  const HomeLearnWatchRail({
    super.key,
    required this.phase,
    required this.cycleDay,
  });

  final String phase;
  final int cycleDay;

  @override
  State<HomeLearnWatchRail> createState() => _HomeLearnWatchRailState();
}

class _HomeLearnWatchRailState extends State<HomeLearnWatchRail> {
  late Future<List<HomeMediaItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void didUpdateWidget(covariant HomeLearnWatchRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.cycleDay != widget.cycleDay) {
      _loadItems();
    }
  }

  void _loadItems() {
    _itemsFuture = HomeMediaContent.feed(
      phase: widget.phase,
      cycleDay: widget.cycleDay,
    );
  }

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(title: l10n.magazineFromLune),
        SizedBox(
          height: 168,
          child: FutureBuilder<List<HomeMediaItem>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return const SizedBox.shrink();

              return ListView.separated(
                primary: false,
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final accent = item.accent ?? theme.colorScheme.primary;

                  return SizedBox(
                    width: 220,
                    child: AppGlassCard(
                      blur: false,
                      padding: EdgeInsets.zero,
                      onTap: () {
                        if (item.isVideo && item.url != null) {
                          _openVideo(context, item.url!);
                          return;
                        }
                        if (item.article != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ArticleScreen(article: item.article!),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppRadius.lg),
                              ),
                              child: item.hasCover
                                  ? Image.network(
                                      item.coverImageUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) =>
                                          _mediaGradientHeader(
                                        accent: accent,
                                        item: item,
                                        l10n: l10n,
                                        theme: theme,
                                      ),
                                    )
                                  : _mediaGradientHeader(
                                      accent: accent,
                                      item: item,
                                      l10n: l10n,
                                      theme: theme,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title(lang),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle(lang),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Widget _mediaGradientHeader({
  required Color accent,
  required HomeMediaItem item,
  required AppLocalizations l10n,
  required ThemeData theme,
}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accent.withValues(alpha: 0.45),
          accent.withValues(alpha: 0.15),
        ],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          item.isVideo ? Icons.play_circle_filled : item.icon,
          size: 44,
          color: Colors.white.withValues(alpha: 0.95),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              item.isVideo ? l10n.homeVideoLabel : l10n.homeArticleLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
