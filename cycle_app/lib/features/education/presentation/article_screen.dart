import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../data/education_content.dart';
import 'widgets/magazine_article_helpers.dart';
import 'widgets/magazine_ui.dart';

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final categoryColor = articleCategoryColor(article.category);
    final categoryLabel = articleCategoryLabel(article.category, l10n);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: AppMeshBackground(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              stretch: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: theme.colorScheme.surface.withValues(
                alpha: 0.12,
              ),
              surfaceTintColor: Colors.transparent,
              leadingWidth: 64,
              leading: Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: Center(
                  child: _GlassBackButton(
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    MagazineArticleCover(
                      article: article,
                      color: categoryColor,
                      overlay: true,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppRadius.xl),
                      ),
                    ),
                    PositionedDirectional(
                      start: 18,
                      end: 18,
                      bottom: 34,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MagazineBrandBadge(
                            label: l10n.magazineTitle,
                            onDark: true,
                          ),
                          const Spacer(),
                          MagazineCategoryBadge(
                            label: categoryLabel,
                            color: categoryColor,
                            onDark: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppGlassCard(
                        radius: AppRadius.xl,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MagazineCategoryBadge(
                                  label: categoryLabel,
                                  color: categoryColor,
                                ),
                                const Spacer(),
                                MagazineReadingTime(minutes: article.minutes),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              article.title(lang),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.28,
                                letterSpacing: -0.35,
                              ),
                            ),
                            if (article.excerpt(lang).trim().isNotEmpty) ...[
                              const SizedBox(height: 11),
                              Text(
                                article.excerpt(lang),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.6,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppGlassCard(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        child: _ArticleBody(
                          body: article.body(lang),
                          accent: categoryColor,
                        ),
                      ),
                      if (article.sourceUrls.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _ArticleSources(
                          urls: article.sourceUrls,
                          isArabic: lang == 'ar',
                        ),
                      ],
                      const SizedBox(height: 14),
                      AppGlassCard(
                        blur: false,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.10,
                                ),
                              ),
                              child: Icon(
                                Icons.health_and_safety_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                l10n.educationDisclaimer,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 42),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleSources extends StatelessWidget {
  const _ArticleSources({required this.urls, required this.isArabic});

  final List<String> urls;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppGlassCard(
      blur: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_outlined,
                size: 19,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isArabic ? 'مصادر موثوقة' : 'Trusted sources',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          for (final rawUrl in urls)
            Builder(
              builder: (context) {
                final uri = Uri.tryParse(rawUrl);
                if (uri == null || uri.scheme != 'https') {
                  return const SizedBox.shrink();
                }
                return TextButton.icon(
                  onPressed: () =>
                      launchUrl(uri, mode: LaunchMode.externalApplication),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(
                    uri.host.replaceFirst('www.', ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.70),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const IconTheme(
            data: IconThemeData(color: AuraColors.ink),
            child: BackButtonIcon(),
          ),
        ),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody({required this.body, required this.accent});

  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final paragraphs = body
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          _ReaderParagraph(text: paragraphs[i], accent: accent),
          if (i != paragraphs.length - 1) const SizedBox(height: 19),
        ],
      ],
    );
  }
}

class _ReaderParagraph extends StatelessWidget {
  const _ReaderParagraph({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSectionHeading = text.startsWith('## ');
    final bulletLines = text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final numbered = RegExp(
      r'^(\d+)[\.)]\s*(.+)$',
      dotAll: true,
    ).firstMatch(text);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.90),
      height: 1.85,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );

    if (isSectionHeading) {
      return Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            text.substring(3).trim(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.38,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
      );
    }

    if (bulletLines.isNotEmpty &&
        bulletLines.every((line) => line.trimLeft().startsWith('• '))) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final line in bulletLines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsetsDirectional.only(top: 11, end: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 7,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      line.trimLeft().substring(2).trim(),
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    if (numbered == null) {
      return SelectableText(text, style: textStyle);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          margin: const EdgeInsets.only(top: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Text(
            numbered.group(1)!,
            style: theme.textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: SelectableText(numbered.group(2)!, style: textStyle)),
      ],
    );
  }
}
