/// Premium illustrated avatars via DiceBear API.
///
/// Styles: lorelei (elegant portraits), notionists (modern illustration),
/// avataaars (rich cartoon characters).
class AvatarPreset {
  const AvatarPreset(this.style, this.seed);
  final String style;
  final String seed;
}

class AvatarCatalog {
  AvatarCatalog._();

  /// 16 premium avatar presets — elegant, diverse, modern.
  static const presets = [
    // Lorelei — elegant hand-drawn female portraits
    AvatarPreset('lorelei', 'luna'),
    AvatarPreset('lorelei', 'amira'),
    AvatarPreset('lorelei', 'sofia'),
    AvatarPreset('lorelei', 'yuki'),
    // Notionists — clean modern illustrations
    AvatarPreset('notionists', 'nora'),
    AvatarPreset('notionists', 'layla'),
    AvatarPreset('notionists', 'maya'),
    AvatarPreset('notionists', 'hana'),
    // Avataaars — rich cartoon characters
    AvatarPreset('avataaars', 'sara'),
    AvatarPreset('avataaars', 'leila'),
    AvatarPreset('avataaars', 'nada'),
    AvatarPreset('avataaars', 'rana'),
    // More lorelei variety
    AvatarPreset('lorelei', 'dina'),
    AvatarPreset('lorelei', 'farah'),
    // More notionists variety
    AvatarPreset('notionists', 'salma'),
    AvatarPreset('notionists', 'jana'),
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

  /// Returns a DiceBear image URL for the given avatar index.
  /// Uses API v9 (stable) with soft pastel backgrounds.
  static String imageUrl({
    required int index,
    int size = 256,
  }) {
    final p = presetAt(index);
    return 'https://api.dicebear.com/9.x/${p.style}/png'
        '?seed=${Uri.encodeComponent(p.seed)}'
        '&size=$size'
        '&backgroundColor=f5e6d3,e8d5c4,d4e6f1,e8daef,fdebd0,fadbd8,d5f5e3,fcf3cf'
        '&radius=50';
  }

  static String imageUrlForUid(String uid, {int size = 256}) =>
      imageUrl(index: indexFromSeed(uid), size: size);
}
