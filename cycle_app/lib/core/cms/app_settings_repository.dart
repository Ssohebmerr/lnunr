import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_settings.dart';

class AppSettingsRepository {
  AppSettingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const docPath = 'appSettings/main';

  AppSettings? _cache;

  Future<AppSettings> fetch() async {
    if (_cache != null) return _cache!;
    try {
      final snap = await _firestore.doc(docPath).get();
      _cache = AppSettings.fromMap(snap.data());
      return _cache!;
    } catch (_) {
      return const AppSettings();
    }
  }

  void clearCache() => _cache = null;
}
