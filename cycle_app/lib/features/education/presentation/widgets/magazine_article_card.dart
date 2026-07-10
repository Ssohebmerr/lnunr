import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/education_content.dart';
import '../article_screen.dart';
import 'magazine_article_helpers.dart';

/// Flo-style magazine card — compact list row or full-width hero.
class MagazineArticleCard extends StatelessWidget {
  const MagazineArticleCard({
    super.key,
    required this.article,
    required this.lang,
    this.hero = false,
  });

  final Article article;
  final String lang;
  final bool hero;

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArticleScreen(article: article)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return hero ? _buildHero(context) : _buildCompact(context);
  }

  Widget _buildHero(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categoryColor = articleCategoryColor(article.category);
    final categoryLabel = articleCategoryLabel(article.category, l10n);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppGlassCard(
        blur: false,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => _open(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  child: SizedBox(
                    height: 180,
                    child: _CoverImage(
                      article: article,
                      categoryColor: categoryColor,
                      large: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.magazineFeatured,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CategoryChip(
                            label: categoryLabel,
                            color: categoryColor,
                          ),
                          const Spacer(),
                          _MinutesLabel(minutes: article.minutes),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        article.title(lang),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.excerpt(lang),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.magazineReadMore,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final categoryColor = articleCategoryColor(article.category);
    final categoryLabel = articleCategoryLabel(article.category, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        blur: false,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => _open(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.xl),
                  ),
                  child: SizedBox(
                    width: 96,
                    height: 96,
                    child: _CoverImage(
                      article: article,
                      categoryColor: categoryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CategoryChip(
                              label: categoryLabel,
                              color: categoryColor,
                            ),
                            const Spacer(),
                            _MinutesLabel(minutes: article.minutes),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.title(lang),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          article.excerpt(lang),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.article,
    required this.categoryColor,
    this.large = false,
  });

  final Article article;
  final Color categoryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    if (article.hasCover) {
      return Image.network(
        article.coverImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _Fallback(
          icon: article.icon,
          categoryColor: categoryColor,
          large: large,
        ),
      );
    }
    return _Fallback(
      icon: article.icon,
      categoryColor: categoryColor,
      large: large,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({
    required this.icon,
    required this.categoryColor,
    this.large = false,
  });

  final IconData icon;
  final Color categoryColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            categoryColor.withValues(alpha: 0.55),
            categoryColor.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: large ? 48 : 32,
          color: Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MinutesLabel extends StatelessWidget {
  const _MinutesLabel({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 12, color: theme.colorScheme.outline),
        const SizedBox(width: 3),
        Text(
          l10n.educationMinutes(minutes),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
