import 'package:shared_preferences/shared_preferences.dart';

import '../storage/user_prefs.dart';
import 'avatar_catalog.dart';

/// Local-only profile — no email required. Used for privacy-first guest mode.
class LocalProfile {
  LocalProfile._();

  static const localChatUid = 'local_guest';
  static const _customPhotoKey = 'profile_custom_photo_path';
  static const _customPhotoUrlKey = 'profile_custom_photo_url';

  static int get avatarCount => AvatarCatalog.count;

  static Future<String> displayName() async {
    final name = await UserPrefs.getProfileName();
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return 'Guest';
  }

  static Future<int> avatarIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(UserPrefs.avatarIndexKey) ?? 0;
  }

  static Future<void> saveAvatarIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      UserPrefs.avatarIndexKey,
      index.clamp(0, AvatarCatalog.count - 1),
    );
  }

  static Future<String?> customPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customPhotoKey);
  }

  static Future<String?> customPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customPhotoUrlKey);
  }

  static Future<void> saveCustomPhotoPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null || path.isEmpty) {
      await prefs.remove(_customPhotoKey);
    } else {
      await prefs.setString(_customPhotoKey, path);
    }
  }

  static Future<void> saveCustomPhotoUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(_customPhotoUrlKey);
    } else {
      await prefs.setString(_customPhotoUrlKey, url);
    }
  }

  static Future<void> clearCustomPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_customPhotoKey);
    await prefs.remove(_customPhotoUrlKey);
  }

  static Future<void> saveDisplayName(String name) async {
    final trimmed = name.trim();
    final goal = await UserPrefs.getProfileGoal();
    await UserPrefs.setProfile(
      name: trimmed.isEmpty ? 'Guest' : trimmed,
      goal: goal ?? 'general',
    );
  }

  /// Valid handle: 3–20 chars of lowercase letters, digits, dot, underscore.
  static final usernamePattern = RegExp(r'^[a-z0-9._]{3,20}$');

  static String normalizeUsername(String raw) =>
      raw.trim().toLowerCase().replaceAll('@', '');

  static bool isValidUsername(String raw) =>
      usernamePattern.hasMatch(normalizeUsername(raw));

  static Future<String?> username() => UserPrefs.getProfileUsername();

  static Future<void> saveUsername(String username) =>
      UserPrefs.setProfileUsername(normalizeUsername(username));

  /// Returns the stored handle, generating a stable default from the display
  /// name + uid suffix on first use (e.g. `sara_4f2a` / `lune_4f2a`).
  static Future<String> ensureUsername({String? uid}) async {
    final existing = await UserPrefs.getProfileUsername();
    if (existing != null && existing.isNotEmpty) return existing;

    final name = await displayName();
    var base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._]'), '')
        .replaceAll(RegExp(r'^[._]+|[._]+$'), '');
    if (base.length > 12) base = base.substring(0, 12);
    if (base.length < 3) base = 'lune';

    final suffixSource = (uid == null || uid.isEmpty)
        ? DateTime.now().millisecondsSinceEpoch.toRadixString(36)
        : uid.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final suffix = suffixSource.length >= 4
        ? suffixSource.substring(0, 4)
        : suffixSource.padRight(4, '0');

    final generated = '${base}_$suffix';
    await UserPrefs.setProfileUsername(generated);
    return generated;
  }
}
