import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_aura/features/community/data/community_catalog_repository.dart';
import 'package:cycle_aura/features/community/data/community_list_resolver.dart';
import 'package:cycle_aura/features/community/data/community_seed.dart';

void main() {
  group('CommunityListResolver', () {
    test('browseAll keeps every seed even when catalog disables some', () {
      final catalog = {
        for (final c in CommunitySeed.defaults)
          c.id: CommunityCatalogEntry(id: c.id, enabled: false),
      };

      final browse = CommunityListResolver.browseAll(catalog: catalog);
      final active = CommunityListResolver.activeOnly(catalog: catalog);

      expect(browse.length, CommunitySeed.defaults.length);
      expect(active, isEmpty);
    });

    test('browseAll includes catalog-only custom communities', () {
      final catalog = {
        'custom-support': const CommunityCatalogEntry(
          id: 'custom-support',
          enabled: true,
          nameEn: 'Custom Support',
          nameAr: 'دعم مخصص',
          topic: 'support',
        ),
      };

      final browse = CommunityListResolver.browseAll(catalog: catalog);

      expect(browse.any((c) => c.id == 'custom-support'), isTrue);
      expect(browse.length, CommunitySeed.defaults.length + 1);
    });
  });
}
