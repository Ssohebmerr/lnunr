import 'models/community_membership.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import 'community_catalog_repository.dart';
import 'community_seed.dart';
import 'models/community.dart';

enum CommunitySortMode { discover, mine, defaultOrder }

/// Central sorting for community lists (Discover, Mine, repository fetch).
List<Community> sortCommunities({
  required List<Community> communities,
  Map<String, CommunityCatalogEntry> catalog = const {},
  required String languageCode,
  UserGoalTypes? goal,
  List<String> joinedIds = const [],
  CommunitySortMode mode = CommunitySortMode.discover,
}) {
  final seedIndex = {
    for (var i = 0; i < CommunitySeed.defaults.length; i++)
      CommunitySeed.defaults[i].id: i,
  };

  int score(Community c) {
    var s = (seedIndex[c.id] ?? 999) * 10;

    final entry = catalog[c.id];
    if (entry?.order != null) {
      s = entry!.order! * 1000;
    }

    s -= _goalBoost(c.id, goal);
    s -= _localeBoost(c, languageCode);

    if (mode == CommunitySortMode.discover && joinedIds.contains(c.id)) {
      s += 5000;
    }

    return s;
  }

  final sorted = [...communities]..sort((a, b) => score(a).compareTo(score(b)));
  return sorted;
}

/// Top N unjoined communities for the "Recommended" row.
List<Community> recommendedCommunities({
  required List<Community> communities,
  Map<String, CommunityCatalogEntry> catalog = const {},
  required String languageCode,
  UserGoalTypes? goal,
  required List<String> joinedIds,
  int limit = 3,
}) {
  final unjoined = communities
      .where((c) => !joinedIds.contains(c.id))
      .toList();
  return sortCommunities(
    communities: unjoined,
    catalog: catalog,
    languageCode: languageCode,
    goal: goal,
    joinedIds: joinedIds,
    mode: CommunitySortMode.discover,
  ).take(limit).toList();
}

/// Sort joined communities by membership date (newest first).
List<Community> sortJoinedCommunities({
  required List<Community> communities,
  required List<CommunityMembership> memberships,
}) {
  final order = {
    for (var i = 0; i < memberships.length; i++)
      memberships[i].communityId: i,
  };
  final joined = communities.where((c) => order.containsKey(c.id)).toList();
  joined.sort((a, b) {
    final ai = order[a.id] ?? 999;
    final bi = order[b.id] ?? 999;
    return ai.compareTo(bi);
  });
  return joined;
}

int _goalBoost(String id, UserGoalTypes? goal) {
  if (goal == null) return 0;
  final priority = switch (goal) {
    UserGoalTypes.conceive => const [
      'trying-to-conceive',
      'contraception',
      'general-cycle',
    ],
    UserGoalTypes.avoid => const [
      'contraception',
      'general-cycle',
    ],
    UserGoalTypes.pregnant => const [
      'postpartum',
      'general-cycle',
    ],
    UserGoalTypes.general ||
    UserGoalTypes.sexual => const [
      'general-cycle',
      'period-support',
      'mental-wellness',
    ],
    UserGoalTypes.menopause => const [
      'general-cycle',
      'mental-wellness',
      'period-support',
    ],
    UserGoalTypes.pcos => const [
      'general-cycle',
      'condition',
      'mental-wellness',
    ],
    UserGoalTypes.postpartum => const [
      'postpartum',
      'general-cycle',
      'mental-wellness',
    ],
  };
  final idx = priority.indexOf(id);
  if (idx < 0) return 0;
  return (priority.length - idx) * 200;
}

int _localeBoost(Community c, String languageCode) {
  if (!languageCode.startsWith('ar')) return 0;
  if (c.id == 'wellness-ar') return 800;
  if (c.topic == 'culture') return 300;
  return 0;
}
