import 'package:cloud_firestore/cloud_firestore.dart';

import 'education_content.dart';

/// Loads education / magazine articles from Firestore, with bundled fallback.
class EducationArticlesRepository {
  EducationArticlesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collection = 'educationArticles';

  Future<List<Article>> fetchPublished({required bool includeAdult}) async {
    try {
      final snap = await _firestore
          .collection(collection)
          .where('published', isEqualTo: true)
          .orderBy('order')
          .get();
      if (snap.docs.isEmpty) {
        return _sortArticles(
          EducationContent.visible(includeAdult: includeAdult),
        );
      }
      final articles = snap.docs
          .map((doc) => Article.fromMap(doc.id, doc.data()))
          .where((a) => includeAdult || !a.adultsOnly)
          .toList();
      return _sortArticles(articles);
    } catch (_) {
      return _sortArticles(
        EducationContent.visible(includeAdult: includeAdult),
      );
    }
  }

  Stream<List<Article>> watchPublished({required bool includeAdult}) {
    return _firestore
        .collection(collection)
        .where('published', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return _sortArticles(
          EducationContent.visible(includeAdult: includeAdult),
        );
      }
      final articles = snap.docs
          .map((doc) => Article.fromMap(doc.id, doc.data()))
          .where((a) => includeAdult || !a.adultsOnly)
          .toList();
      return _sortArticles(articles);
    });
  }

  Future<Article?> fetchFeatured({required bool includeAdult}) async {
    final articles = await fetchPublished(includeAdult: includeAdult);
    for (final a in articles) {
      if (a.featured) return a;
    }
    return articles.isNotEmpty ? articles.first : null;
  }

  static List<Article> _sortArticles(List<Article> articles) {
    final copy = [...articles];
    copy.sort((a, b) {
      if (a.featured != b.featured) return a.featured ? -1 : 1;
      final aDate = a.publishedAt;
      final bDate = b.publishedAt;
      if (aDate != null && bDate != null) {
        final byDate = bDate.compareTo(aDate);
        if (byDate != 0) return byDate;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return a.order.compareTo(b.order);
    });
    return copy;
  }
}
