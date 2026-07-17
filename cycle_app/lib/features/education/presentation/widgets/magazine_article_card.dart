import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/education_content.dart';
import '../article_screen.dart';
import 'magazine_article_helpers.dart';
import 'magazine_ui.dart';

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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ArticleScreen(article: article)));
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      child: AppGlassCard(
        padding: EdgeInsets.zero,
        radius: AppRadius.xl,
        onTap: () => _open(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 218,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MagazineArticleCover(
                    article: article,
                    color: categoryColor,
                    overlay: true,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  PositionedDirectional(
                    top: 14,
                    start: 14,
                    child: MagazineBrandBadge(
                      label: l10n.magazineTitle,
                      onDark: true,
                      compact: true,
                    ),
                  ),
                  PositionedDirectional(
                    start: 16,
                    end: 16,
                    bottom: 15,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AuraColors.accentDeep,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            l10n.magazineFeatured,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        MagazineReadingTime(
                          minutes: article.minutes,
                          onDark: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MagazineCategoryBadge(
                    label: categoryLabel,
                    color: categoryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title(lang),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.excerpt(lang),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.magazineReadMore,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 13),
      child: AppGlassCard(
        blur: false,
        padding: EdgeInsets.zero,
        radius: AppRadius.lg,
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                height: 142,
                child: MagazineArticleCover(
                  article: article,
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MagazineCategoryBadge(
                              label: categoryLabel,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          MagazineReadingTime(minutes: article.minutes),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        article.title(lang),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.28,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        article.excerpt(lang),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Icon(
                        Directionality.of(context) == TextDirection.rtl
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
