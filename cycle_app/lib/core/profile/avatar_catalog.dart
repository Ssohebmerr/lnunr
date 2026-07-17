import 'package:flutter/material.dart';

/// A single portrait inside one of the local 2×2 Lune avatar sheets.
class AvatarPreset {
  const AvatarPreset(this.assetPath, this.tile);

  final String assetPath;
  final int tile;

  Alignment get cropAlignment => switch (tile) {
    0 => Alignment.topLeft,
    1 => Alignment.topRight,
    2 => Alignment.bottomLeft,
    _ => Alignment.bottomRight,
  };
}

class AvatarCatalog {
  AvatarCatalog._();

  /// 16 stable, app-owned portraits. Keep the order stable: avatar indices
  /// are already persisted locally and in community profiles.
  static const presets = [
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_01.png', 0),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_01.png', 1),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_01.png', 2),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_01.png', 3),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_02.png', 0),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_02.png', 1),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_02.png', 2),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_02.png', 3),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_03.png', 0),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_03.png', 1),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_03.png', 2),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_03.png', 3),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_04.png', 0),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_04.png', 1),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_04.png', 2),
    AvatarPreset('assets/avatars/lune_avatar_illustrated_sheet_04.png', 3),
  ];

  static int get count => presets.length;

  static AvatarPreset presetAt(int index) =>
      presets[index.clamp(0, presets.length - 1)];

  /// Stable avatar for a user id or alias when no index is stored.
  static int indexFromSeed(String seed) {
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = (hash + c) % presets.length;
    }
    return hash;
  }

  static String assetPathAt(int index) => presetAt(index).assetPath;

  static Alignment cropAlignmentAt(int index) => presetAt(index).cropAlignment;
}
