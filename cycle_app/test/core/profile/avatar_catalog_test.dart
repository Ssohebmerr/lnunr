import 'package:cycle_aura/core/profile/avatar_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local avatar catalog keeps all 16 stable profile choices', () {
    expect(AvatarCatalog.count, 16);
    expect(AvatarCatalog.presets.map((preset) => preset.assetPath).toSet(), {
      'assets/avatars/lune_avatar_illustrated_sheet_01.png',
      'assets/avatars/lune_avatar_illustrated_sheet_02.png',
      'assets/avatars/lune_avatar_illustrated_sheet_03.png',
      'assets/avatars/lune_avatar_illustrated_sheet_04.png',
    });

    for (var sheet = 0; sheet < 4; sheet++) {
      expect(
        AvatarCatalog.presets
            .skip(sheet * 4)
            .take(4)
            .map((preset) => preset.tile),
        [0, 1, 2, 3],
      );
    }
  });

  test('seed mapping remains deterministic and within bounds', () {
    final first = AvatarCatalog.indexFromSeed('same-user');
    expect(AvatarCatalog.indexFromSeed('same-user'), first);
    expect(first, inInclusiveRange(0, AvatarCatalog.count - 1));
  });
}
