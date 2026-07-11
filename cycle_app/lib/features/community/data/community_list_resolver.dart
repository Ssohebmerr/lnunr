import 'community_catalog_repository.dart';
import 'community_icon_registry.dart';
import 'community_seed.dart';
import 'community_sort.dart';
import '../../../menstrudel/models/app/user_goal_types_enum.dart';
import 'models/community.dart';

/// Builds the full community browse list (Discover tab) from in-app seeds
/// plus optional Firestore [communityCatalog] overrides.
///
/// Discover always lists every curated seed so groups do not "disappear" when
/// the user is only subscribed to a few. Catalog `enabled: false` still blocks
/// joining via [CommunityRepository.resolveCommunity].
class CommunityListResolver {
  CommunityListResolver._();

  static Community mergeSeed(Community seed, CommunityCatalogEntry? entry) {
    if (entry == null) return seed;
    return seed.copyWith(
      nameEn: entry.nameEn,
      nameAr: entry.nameAr,
      descriptionEn: entry.descriptionEn,
      descriptionAr: entry.descriptionAr,
      rulesEn: entry.rulesEn,
      rulesAr: entry.rulesAr,
      topic: entry.topic,
      icon: entry.iconName != null
          ? communityIconFromName(entry.iconName!)
          : null,
      maxMembers: entry.maxMembers,
    );
  }

  static Community? fromCatalogOnly(CommunityCatalogEntry entry) {
    final nameEn = entry.nameEn?.trim();
    final nameAr = entry.nameAr?.trim();
    if ((nameEn == null || nameEn.isEmpty) && (nameAr == null || nameAr.isEmpty)) {
      return null;
    }
    return Community(
      id: entry.id,
      nameEn: nameEn ?? nameAr ?? entry.id,
      nameAr: nameAr ?? nameEn ?? entry.id,
      descriptionEn: entry.descriptionEn ?? '',
      descriptionAr: entry.descriptionAr ?? '',
      topic: entry.topic ?? 'general',
      icon: communityIconFromName(entry.iconName ?? 'groups_outlined'),
      maxMembers: entry.maxMembers ?? 150,
      rulesEn: entry.rulesEn ?? '',
      rulesAr: entry.rulesAr ?? '',
    );
  }

  /// All browseable communities: seeds + catalog-only entries.
  /// Does not hide catalog-disabled groups — they stay visible in Discover.
  static List<Community> browseAll({
    Map<String, CommunityCatalogEntry> catalog = const {},
  }) {
    final results = <Community>[];
    final seen = <String>{};

    for (final seed in CommunitySeed.defaults) {
      results.add(mergeSeed(seed, catalog[seed.id]));
      seen.add(seed.id);
    }

    for (final entry in catalog.values) {
      if (seen.contains(entry.id)) continue;
      final custom = fromCatalogOnly(entry);
      if (custom != null) {
        results.add(custom);
        seen.add(entry.id);
      }
    }

    return results;
  }

  /// Active communities for server-backed flows (member counts, join checks).
  static List<Community> activeOnly({
    Map<String, CommunityCatalogEntry> catalog = const {},
  }) {
    final results = <Community>[];
    final seen = <String>{};

    for (final seed in CommunitySeed.defaults) {
      final entry = catalog[seed.id];
      if (entry != null && !entry.enabled) continue;
      results.add(mergeSeed(seed, entry));
      seen.add(seed.id);
    }

    for (final entry in catalog.values) {
      if (seen.contains(entry.id)) continue;
      if (!entry.enabled) continue;
      final custom = fromCatalogOnly(entry);
      if (custom != null) {
        results.add(custom);
        seen.add(entry.id);
      }
    }

    return results;
  }

  static List<Community> filterBrowseList({
    required List<Community> communities,
    required String search,
    required String category,
    required String languageCode,
    Map<String, CommunityCatalogEntry> catalog = const {},
    UserGoalTypes? goal,
    List<String> joinedIds = const [],
  }) {
    var list = communities;
    final q = search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        final name = c.nameForLocale(languageCode).toLowerCase();
        final desc = c.descriptionForLocale(languageCode).toLowerCase();
        return name.contains(q) || desc.contains(q) || c.topic.contains(q);
      }).toList();
    }
    if (category != 'all') {
      list = list.where((c) => c.topic == category).toList();
    }
    return sortCommunities(
      communities: list,
      catalog: catalog,
      languageCode: languageCode,
      goal: goal,
      joinedIds: joinedIds,
      mode: CommunitySortMode.discover,
    );
  }

  static bool isJoinable(
    String communityId,
    Map<String, CommunityCatalogEntry> catalog,
  ) {
    final entry = catalog[communityId];
    if (entry != null && !entry.enabled) return false;
    if (CommunitySeed.byId(communityId) != null) return true;
    if (entry != null) return fromCatalogOnly(entry) != null;
    return false;
  }
}
