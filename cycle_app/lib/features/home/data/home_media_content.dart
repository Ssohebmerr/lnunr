import 'package:flutter/material.dart';

import '../../education/data/education_articles_repository.dart';
import '../../education/data/education_content.dart';

/// Curated articles and educational videos shown on the home feed.
class HomeMediaItem {
  const HomeMediaItem._({
    this.article,
    required this.titleEn,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleAr,
    this.url,
    required this.icon,
    this.accent,
  });

  factory HomeMediaItem.article(Article article) {
    return HomeMediaItem._(
      article: article,
      titleEn: article.titleEn,
      titleAr: article.titleAr,
      subtitleEn: '${article.minutes} min read',
      subtitleAr: '${article.minutes} د قراءة',
      icon: article.icon,
    );
  }

  const HomeMediaItem.video({
    required String titleEn,
    required String titleAr,
    required String subtitleEn,
    required String subtitleAr,
    required String url,
    required IconData icon,
    required Color accent,
  }) : this._(
          titleEn: titleEn,
          titleAr: titleAr,
          subtitleEn: subtitleEn,
          subtitleAr: subtitleAr,
          url: url,
          icon: icon,
          accent: accent,
        );

  final Article? article;
  final String titleEn;
  final String titleAr;
  final String subtitleEn;
  final String subtitleAr;
  final String? url;
  final IconData icon;
  final Color? accent;

  bool get isVideo => url != null;

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String subtitle(String lang) => lang == 'ar' ? subtitleAr : subtitleEn;
}

class HomeMediaContent {
  HomeMediaContent._();

  static Future<List<HomeMediaItem>> feed({
    required String phase,
    required int cycleDay,
    bool includeAdult = true,
    EducationArticlesRepository? repository,
  }) async {
    final repo = repository ?? EducationArticlesRepository();
    final articles = await repo.fetchPublished(includeAdult: includeAdult);
    if (articles.isEmpty) return [];

    final phaseKey = phase.toLowerCase();
    ArticleCategory preferred = ArticleCategory.basics;
    if (phaseKey.contains('menstrual') ||
        phaseKey.contains('period') ||
        phaseKey.contains('حيض')) {
      preferred = ArticleCategory.health;
    } else if (phaseKey.contains('follicular') || phaseKey.contains('جريبي')) {
      preferred = ArticleCategory.nutrition;
    } else if (phaseKey.contains('ovulation') || phaseKey.contains('إباض')) {
      preferred = ArticleCategory.basics;
    } else if (phaseKey.contains('luteal') || phaseKey.contains('أصفار')) {
      preferred = ArticleCategory.mind;
    }

    final preferredArticles = EducationContent.filterByCategory(
      articles,
      preferred,
      includeAdult: includeAdult,
    );
    final pool = preferredArticles.isNotEmpty ? preferredArticles : articles;
    final start = cycleDay % pool.length;
    final picked = <Article>[
      pool[start % pool.length],
      pool[(start + 1) % pool.length],
    ];

    return picked.map(HomeMediaItem.article).toList();
  }
}
