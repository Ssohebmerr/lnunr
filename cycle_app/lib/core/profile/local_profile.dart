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
}
