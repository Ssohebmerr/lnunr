import '../../education/data/education_content.dart';
import '../data/community_seed.dart';

/// A typed entry in the mixed community feed.
sealed class CommunityFeedEntry<T> {
  const CommunityFeedEntry();
}

final class CommunityPostFeedEntry<T> extends CommunityFeedEntry<T> {
  const CommunityPostFeedEntry(this.post);

  final T post;
}

final class CommunityMagazineFeedEntry<T> extends CommunityFeedEntry<T> {
  const CommunityMagazineFeedEntry({
    required this.article,
    required this.communityId,
    required this.afterPostCount,
  });

  final Article article;
  final String communityId;
  final int afterPostCount;
}

/// Interleaves a small number of relevant Lune Magazine cards into a feed.
///
/// The first card appears after six real posts, then every eleven real posts.
/// Magazine cards never count as posts and never repeat within the same feed.
List<CommunityFeedEntry<T>> buildCommunityMagazineFeed<T>({
  required List<T> posts,
  required List<Article> articles,
  required String Function(T post) communityIdOf,
  required int rotationSeed,
  int firstAfter = 6,
  int interval = 11,
  int maxArticles = 2,
}) {
  if (posts.isEmpty ||
      articles.isEmpty ||
      firstAfter <= 0 ||
      interval <= 0 ||
      maxArticles <= 0) {
    return posts
        .map<CommunityFeedEntry<T>>(CommunityPostFeedEntry.new)
        .toList();
  }

  final entries = <CommunityFeedEntry<T>>[];
  final usedArticleIds = <String>{};
  var nextInsertion = firstAfter;
  var inserted = 0;

  for (var index = 0; index < posts.length; index++) {
    final post = posts[index];
    entries.add(CommunityPostFeedEntry(post));

    final postCount = index + 1;
    if (postCount != nextInsertion || inserted >= maxArticles) continue;

    final communityId = communityIdOf(post);
    final article = _pickArticle(
      articles: articles,
      communityId: communityId,
      usedArticleIds: usedArticleIds,
      rotationSeed: rotationSeed,
      slot: inserted,
    );
    if (article != null) {
      usedArticleIds.add(article.id);
      entries.add(
        CommunityMagazineFeedEntry<T>(
          article: article,
          communityId: communityId,
          afterPostCount: postCount,
        ),
      );
      inserted++;
    }
    nextInsertion += interval;
  }

  return entries;
}

Article? _pickArticle({
  required List<Article> articles,
  required String communityId,
  required Set<String> usedArticleIds,
  required int rotationSeed,
  required int slot,
}) {
  final available = articles
      .where((article) => !usedArticleIds.contains(article.id))
      .toList();
  if (available.isEmpty) return null;

  final category = preferredMagazineCategory(communityId);
  final relevant = available
      .where((article) => article.category == category)
      .toList();
  final pool = relevant.isNotEmpty ? relevant : available;

  // Daily rotation is deterministic: no cards jump around during a session,
  // while the same member does not keep seeing the first article forever.
  final offset =
      (rotationSeed + _stableStringValue(communityId) + slot) % pool.length;
  return pool[offset];
}

ArticleCategory preferredMagazineCategory(String communityId) {
  switch (communityId) {
    case 'mental-wellness':
    case 'pms-pmdd-support':
      return ArticleCategory.mind;
    case 'fitness-cycle':
    case 'lifestyle-wellness':
      return ArticleCategory.nutrition;
    case 'trying-to-conceive':
    case 'contraception':
    case 'pcos':
    case 'endometriosis':
    case 'period-support':
    case 'postpartum':
    case 'pregnancy-support':
    case 'menopause-support':
    case 'irregular-periods':
    case 'thyroid-hormones':
    case 'fibroids-support':
      return ArticleCategory.health;
  }

  final topic = CommunitySeed.byId(communityId)?.topic;
  return switch (topic) {
    'conception' || 'contraception' || 'condition' => ArticleCategory.health,
    'support' => ArticleCategory.mind,
    _ => ArticleCategory.basics,
  };
}

int _stableStringValue(String value) {
  var result = 0;
  for (final unit in value.codeUnits) {
    result = ((result * 31) + unit) & 0x7fffffff;
  }
  return result;
}
