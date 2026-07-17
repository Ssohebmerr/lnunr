import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/widgets/aura_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../education/data/education_content.dart';
import '../../../education/presentation/article_screen.dart';
import '../../../education/presentation/widgets/magazine_article_helpers.dart';
import '../../../education/presentation/widgets/magazine_ui.dart';

class CommunityMagazineFeedCard extends StatelessWidget {
  const CommunityMagazineFeedCard({
    super.key,
    required this.article,
    this.onDiscuss,
  });

  final Article article;
  final VoidCallback? onDiscuss;

  void _openArticle(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ArticleScreen(article: article)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final categoryColor = articleCategoryColor(article.category);
    final categoryLabel = articleCategoryLabel(article.category, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppGlassCard(
        blur: false,
        padding: EdgeInsets.zero,
        radius: AppRadius.xl,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => _openArticle(context),
                child: SizedBox(
                  height: 164,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MagazineArticleCover(
                        article: article,
                        color: categoryColor,
                        overlay: true,
                      ),
                      PositionedDirectional(
                        top: 13,
                        start: 13,
                        child: MagazineBrandBadge(
                          label: l10n.magazineFromLune,
                          onDark: true,
                          compact: true,
                        ),
                      ),
                      PositionedDirectional(
                        end: 14,
                        bottom: 13,
                        child: MagazineReadingTime(
                          minutes: article.minutes,
                          onDark: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MagazineCategoryBadge(
                      label: categoryLabel,
                      color: categoryColor,
                    ),
                    const SizedBox(height: 9),
                    InkWell(
                      onTap: () => _openArticle(context),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title(lang),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.28,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            article.excerpt(lang),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outline.withValues(alpha: 0.10),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _openArticle(context),
                          icon: const Icon(
                            Icons.auto_stories_rounded,
                            size: 18,
                          ),
                          label: Text(l10n.magazineReadMore),
                        ),
                        const Spacer(),
                        if (onDiscuss != null)
                          OutlinedButton.icon(
                            onPressed: onDiscuss,
                            icon: const Icon(Icons.forum_outlined, size: 17),
                            label: Text(l10n.communityNewPost),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: theme.colorScheme.primary,
                              side: BorderSide(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
