import 'package:cycle_aura/features/community/presentation/community_magazine_feed.dart';
import 'package:cycle_aura/features/education/data/education_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Article article(String id, ArticleCategory category) => Article(
  id: id,
  category: category,
  icon: Icons.article_outlined,
  titleEn: id,
  titleAr: id,
  bodyEn: 'Body',
  bodyAr: 'المحتوى',
  minutes: 3,
);

void main() {
  final articles = <Article>[
    article('basics-1', ArticleCategory.basics),
    article('basics-2', ArticleCategory.basics),
    article('health-1', ArticleCategory.health),
    article('health-2', ArticleCategory.health),
    article('mind-1', ArticleCategory.mind),
    article('nutrition-1', ArticleCategory.nutrition),
  ];

  group('buildCommunityMagazineFeed', () {
    test('does not interrupt a short feed', () {
      final entries = buildCommunityMagazineFeed<String>(
        posts: List.filled(5, 'general-cycle'),
        articles: articles,
        communityIdOf: (id) => id,
        rotationSeed: 10,
      );

      expect(entries, hasLength(5));
      expect(entries.whereType<CommunityMagazineFeedEntry<String>>(), isEmpty);
    });

    test('places the first magazine card after six real posts', () {
      final entries = buildCommunityMagazineFeed<String>(
        posts: List.filled(6, 'general-cycle'),
        articles: articles,
        communityIdOf: (id) => id,
        rotationSeed: 10,
      );

      expect(entries, hasLength(7));
      expect(
        entries.take(6),
        everyElement(isA<CommunityPostFeedEntry<String>>()),
      );
      final magazine = entries.last as CommunityMagazineFeedEntry<String>;
      expect(magazine.afterPostCount, 6);
      expect(magazine.communityId, 'general-cycle');
    });

    test('adds at most two cards after post 6 and post 17', () {
      final entries = buildCommunityMagazineFeed<String>(
        posts: List.filled(30, 'pcos'),
        articles: articles,
        communityIdOf: (id) => id,
        rotationSeed: 4,
      );
      final magazines = entries
          .whereType<CommunityMagazineFeedEntry<String>>()
          .toList();

      expect(
        entries.whereType<CommunityPostFeedEntry<String>>(),
        hasLength(30),
      );
      expect(magazines, hasLength(2));
      expect(magazines.map((entry) => entry.afterPostCount), [6, 17]);
      expect(magazines.map((entry) => entry.article.id).toSet(), hasLength(2));
    });

    test('prefers an article relevant to the surrounding community', () {
      final entries = buildCommunityMagazineFeed<String>(
        posts: List.filled(6, 'mental-wellness'),
        articles: articles,
        communityIdOf: (id) => id,
        rotationSeed: 0,
      );
      final magazine = entries
          .whereType<CommunityMagazineFeedEntry<String>>()
          .single;

      expect(magazine.article.category, ArticleCategory.mind);
    });

    test('keeps the order stable for the same daily seed', () {
      List<String> selected(int seed) =>
          buildCommunityMagazineFeed<String>(
                posts: List.filled(20, 'pcos'),
                articles: articles,
                communityIdOf: (id) => id,
                rotationSeed: seed,
              )
              .whereType<CommunityMagazineFeedEntry<String>>()
              .map((entry) => entry.article.id)
              .toList();

      expect(selected(42), selected(42));
      expect(selected(42), isNot(selected(43)));
    });
  });

  group('preferredMagazineCategory', () {
    test('maps specific communities to editorial categories', () {
      expect(
        preferredMagazineCategory('lifestyle-wellness'),
        ArticleCategory.nutrition,
      );
      expect(
        preferredMagazineCategory('trying-to-conceive'),
        ArticleCategory.health,
      );
      expect(
        preferredMagazineCategory('mental-wellness'),
        ArticleCategory.mind,
      );
      expect(
        preferredMagazineCategory('general-cycle'),
        ArticleCategory.basics,
      );
    });
  });
}
