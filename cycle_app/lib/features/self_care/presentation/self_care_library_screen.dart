import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/app_surface.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/self_care_library_content.dart';

/// A phase-by-phase self-care library (nutrition, movement, rest, mind).
/// The phase matching the user's current cycle phase is expanded by default.
class SelfCareLibraryScreen extends StatefulWidget {
  const SelfCareLibraryScreen({super.key, this.currentPhase});

  final String? currentPhase;

  @override
  State<SelfCareLibraryScreen> createState() => _SelfCareLibraryScreenState();
}

class _SelfCareLibraryScreenState extends State<SelfCareLibraryScreen> {
  late int _expanded = SelfCareLibraryContent.indexForPhase(widget.currentPhase);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final phases = SelfCareLibraryContent.all;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.selfCareLibraryTitle),
      ),
      body: AppMeshBackground(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + kToolbarHeight + 8,
            16,
            32,
          ),
          children: [
            Text(
              l10n.selfCareLibrarySubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < phases.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PhaseCard(
                  phase: phases[i],
                  lang: lang,
                  expanded: _expanded == i,
                  isCurrent: i == SelfCareLibraryContent.indexForPhase(widget.currentPhase),
                  currentLabel: l10n.selfCareLibraryCurrent,
                  onTap: () => setState(() => _expanded = _expanded == i ? -1 : i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.lang,
    required this.expanded,
    required this.isCurrent,
    required this.currentLabel,
    required this.onTap,
  });

  final LibraryPhase phase;
  final String lang;
  final bool expanded;
  final bool isCurrent;
  final String currentLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppGlassCard(
      blur: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          phase.color.withValues(alpha: 0.32),
                          phase.color.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(phase.icon, color: phase.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                phase.name(lang),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: phase.color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  currentLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: phase.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phase.summary(lang),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  for (final topic in phase.topics)
                    _TopicTile(topic: topic, lang: lang, accent: phase.color),
                ],
              ),
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.topic,
    required this.lang,
    required this.accent,
  });

  final LibraryTopic topic;
  final String lang;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(topic.icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                topic.title(lang),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            topic.body(lang),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
