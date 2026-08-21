import 'package:cloud_firestore/cloud_firestore.dart';

import 'education_content.dart';

/// Loads education / magazine articles from Firestore.
///
/// Magazine content intentionally has no bundled fallback: editors can update
/// it without shipping a new app build, and article text/images never add to
/// the application binary size.
class EducationArticlesRepository {
  EducationArticlesRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collection = 'educationArticles';

  Future<List<Article>> fetchPublished({required bool includeAdult}) async {
    try {
      // List views do not need every body at once; paginate to keep the
      // education hub responsive with a large Firestore magazine library.
      final snap = await _firestore
          .collection(collection)
          .where('published', isEqualTo: true)
          .orderBy('order')
          .limit(120)
          .get();
      if (snap.docs.isEmpty) {
        return const [];
      }
      final articles = snap.docs
          .map((doc) => Article.fromMap(doc.id, doc.data()))
          .where((a) => includeAdult || !a.adultsOnly)
          .toList();
      return _sortArticles(articles);
    } catch (_) {
      return const [];
    }
  }

  Stream<List<Article>> watchPublished({required bool includeAdult}) async* {
    try {
      await for (final snap
          in _firestore
              .collection(collection)
              .where('published', isEqualTo: true)
              .orderBy('order')
              .limit(120)
              .snapshots()) {
        if (snap.docs.isEmpty) {
          yield const [];
          continue;
        }
        final articles = snap.docs
            .map((doc) => Article.fromMap(doc.id, doc.data()))
            .where((a) => includeAdult || !a.adultsOnly)
            .toList();
        yield _sortArticles(articles);
      }
    } catch (_) {
      yield const [];
    }
  }

  /// Loads one full article by id (used when opening a guide).
  Future<Article?> fetchById(String id) async {
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      return Article.fromMap(doc.id, doc.data()!);
    } catch (_) {
      return null;
    }
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
