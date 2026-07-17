import 'package:flutter/material.dart';

import 'article_icon_registry.dart';

enum ArticleCategory { basics, health, nutrition, mind, adult }

/// A server-backed magazine article.
///
/// Article copy and cover images are intentionally not bundled in the app.
/// Firestore supplies the text and the cover is loaded from its HTTPS URL.
class Article {
  const Article({
    required this.id,
    required this.category,
    required this.icon,
    required this.titleEn,
    required this.titleAr,
    required this.bodyEn,
    required this.bodyAr,
    required this.minutes,
    this.adultsOnly = false,
    this.order = 0,
    this.coverImageUrl,
    this.excerptAr = '',
    this.excerptEn = '',
    this.featured = false,
    this.slug,
    this.publishedAt,
    this.sourceUrls = const [],
  });

  factory Article.fromMap(String id, Map<String, dynamic> data) {
    final categoryName = data['category'] as String? ?? 'basics';
    final category = ArticleCategory.values.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => ArticleCategory.basics,
    );
    return Article(
      id: id,
      category: category,
      icon: articleIconFromName(data['iconName'] as String? ?? 'article_outlined'),
      titleEn: data['titleEn'] as String? ?? '',
      titleAr: data['titleAr'] as String? ?? '',
      bodyEn: data['bodyEn'] as String? ?? '',
      bodyAr: data['bodyAr'] as String? ?? '',
      minutes: (data['minutes'] as num?)?.toInt() ?? 3,
      adultsOnly: data['adultsOnly'] as bool? ?? false,
      order: (data['order'] as num?)?.toInt() ?? 0,
      coverImageUrl: data['coverImageUrl'] as String?,
      excerptAr: data['excerptAr'] as String? ?? '',
      excerptEn: data['excerptEn'] as String? ?? '',
      featured: data['featured'] as bool? ?? false,
      slug: data['slug'] as String?,
      publishedAt: _readDate(data['publishedAt']),
      sourceUrls: (data['sourceUrls'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .where((url) => url.trim().isNotEmpty)
          .toList(growable: false),
    );
  }

  final String id;
  final ArticleCategory category;
  final IconData icon;
  final String titleEn;
  final String titleAr;
  final String bodyEn;
  final String bodyAr;
  final int minutes;
  final int order;
  final String? coverImageUrl;
  final String excerptAr;
  final String excerptEn;
  final bool featured;
  final String? slug;
  final DateTime? publishedAt;
  final List<String> sourceUrls;

  /// Hidden for users known to be under 18.
  final bool adultsOnly;

  String get displaySlug => (slug != null && slug!.trim().isNotEmpty) ? slug! : id;

  bool get hasCover =>
      coverImageUrl != null && coverImageUrl!.trim().isNotEmpty;

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String body(String lang) => lang == 'ar' ? bodyAr : bodyEn;

  /// Card excerpt — explicit field or first ~120 chars of body.
  String excerpt(String lang) {
    final explicit = lang == 'ar'
        ? (excerptAr.trim().isNotEmpty ? excerptAr.trim() : null)
        : (excerptEn.trim().isNotEmpty ? excerptEn.trim() : null);
    if (explicit != null) return explicit;
    final text = body(lang).replaceAll('\n', ' ').trim();
    if (text.length <= 120) return text;
    return '${text.substring(0, 120)}…';
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }
}
