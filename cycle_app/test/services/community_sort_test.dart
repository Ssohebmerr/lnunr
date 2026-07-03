import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/community_catalog_repository.dart';
import 'package:cycle_aura/features/community/data/community_seed.dart';
import 'package:cycle_aura/features/community/data/community_sort.dart';
import 'package:cycle_aura/features/community/data/models/community.dart';
import 'package:cycle_aura/features/community/data/models/community_membership.dart';
import 'package:cycle_aura/menstrudel/models/app/user_goal_types_enum.dart';

Community _byId(String id) =>
    CommunitySeed.defaults.firstWhere((c) => c.id == id);

void main() {
  group('sortCommunities', () {
    test('orders by catalog.order when present', () {
      final communities = [
        _byId('general-cycle'),
        _byId('trying-to-conceive'),
        _byId('contraception'),
      ];
      final catalog = {
        'trying-to-conceive': CommunityCatalogEntry(
          id: 'trying-to-conceive',
          order: 1,
          enabled: true,
        ),
        'general-cycle': CommunityCatalogEntry(
          id: 'general-cycle',
          order: 3,
          enabled: true,
        ),
        'contraception': CommunityCatalogEntry(
          id: 'contraception',
          order: 2,
          enabled: true,
        ),
      };

      final sorted = sortCommunities(
        communities: communities,
        catalog: catalog,
        languageCode: 'en',
      );

      expect(sorted.map((c) => c.id).toList(), [
        'trying-to-conceive',
        'contraception',
        'general-cycle',
      ]);
    });

    test('boosts wellness-ar for Arabic locale', () {
      final communities = CommunitySeed.defaults;
      final sorted = sortCommunities(
        communities: communities,
        languageCode: 'ar',
      );

      expect(sorted.first.id, 'wellness-ar');
    });

    test('boosts trying-to-conceive for conceive goal', () {
      final communities = CommunitySeed.defaults;
      final sorted = sortCommunities(
        communities: communities,
        languageCode: 'en',
        goal: UserGoalTypes.conceive,
      );

      expect(sorted.first.id, 'trying-to-conceive');
    });

    test('discover mode pushes joined communities lower', () {
      final communities = [
        _byId('general-cycle'),
        _byId('trying-to-conceive'),
      ];
      final sorted = sortCommunities(
        communities: communities,
        languageCode: 'en',
        joinedIds: const ['general-cycle'],
        mode: CommunitySortMode.discover,
      );

      expect(sorted.first.id, 'trying-to-conceive');
      expect(sorted.last.id, 'general-cycle');
    });
  });

  group('sortJoinedCommunities', () {
    test('orders by joinedAt newest first', () {
      final communities = [
        _byId('general-cycle'),
        _byId('trying-to-conceive'),
        _byId('contraception'),
      ];
      final memberships = [
        CommunityMembership(
          communityId: 'general-cycle',
          joinedAt: DateTime(2025, 6, 1),
        ),
        CommunityMembership(
          communityId: 'contraception',
          joinedAt: DateTime(2025, 3, 1),
        ),
        CommunityMembership(
          communityId: 'trying-to-conceive',
          joinedAt: DateTime(2025, 1, 1),
        ),
      ];

      final sorted = sortJoinedCommunities(
        communities: communities,
        memberships: memberships,
      );

      expect(sorted.map((c) => c.id).toList(), [
        'general-cycle',
        'contraception',
        'trying-to-conceive',
      ]);
    });
  });

  group('recommendedCommunities', () {
    test('excludes joined and limits to 3', () {
      final recommended = recommendedCommunities(
        communities: CommunitySeed.defaults,
        languageCode: 'en',
        goal: UserGoalTypes.general,
        joinedIds: const ['general-cycle', 'trying-to-conceive'],
        limit: 3,
      );

      expect(recommended.length, lessThanOrEqualTo(3));
      expect(recommended.any((c) => c.id == 'general-cycle'), isFalse);
      expect(recommended.any((c) => c.id == 'trying-to-conceive'), isFalse);
    });
  });
}
