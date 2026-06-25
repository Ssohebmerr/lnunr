import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_notifications.dart';
import 'notification_prefs.dart';

class CommunityNotificationService {
  CommunityNotificationService._();

  static const _channelId = 'cycle_aura_community';
  static const _baseId = 2000;
  static int _seq = 0;

  static Future<bool> _enabled() => NotificationPrefs.communityEnabled();

  static Future<void> showFromInbox(Map<String, dynamic> data) async {
    if (!await _enabled()) return;

    final type = data['type'] as String? ?? '';
    final fromAlias = data['fromAlias'] as String? ?? '';
    final preview = data['preview'] as String? ?? '';
    final ar = await _isArabic();

    final String title;
    final String body;
    switch (type) {
      case 'like':
        title = ar ? 'إعجاب جديد في المجتمع' : 'New community like';
        body = ar
            ? '$fromAlias أعجبت بمنشورك'
            : '$fromAlias liked your post';
        break;
      case 'reply':
        title = ar ? 'رد جديد على تعليقك' : 'New reply to your comment';
        body = ar ? '$fromAlias: $preview' : '$fromAlias: $preview';
        break;
      case 'comment':
      default:
        title = ar ? 'تعليق جديد في المجتمع' : 'New community comment';
        body = ar
            ? '$fromAlias: $preview'
            : '$fromAlias: $preview';
    }

    final id = _baseId + (_seq++ % 900);
    await AppNotifications.plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Community',
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  static Future<bool> _isArabic() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('app_locale') ?? 'ar') == 'ar';
  }
}
