import 'package:cloud_firestore/cloud_firestore.dart';

import 'education_content.dart';

/// Loads education articles from Firestore, with bundled fallback when empty.
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
        return EducationContent.visible(includeAdult: includeAdult);
      }
      final articles =
          snap.docs.map((doc) => Article.fromMap(doc.id, doc.data())).toList();
      return articles.where((a) => includeAdult || !a.adultsOnly).toList();
    } catch (_) {
      return EducationContent.visible(includeAdult: includeAdult);
    }
  }
}
