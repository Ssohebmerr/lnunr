import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firestore overrides for curated communities (managed from admin).
class CommunityCatalogEntry {
  const CommunityCatalogEntry({
    required this.id,
    this.enabled = true,
    this.nameEn,
    this.nameAr,
    this.descriptionEn,
    this.descriptionAr,
    this.rulesEn,
    this.rulesAr,
    this.topic,
    this.iconName,
    this.maxMembers,
    this.order,
  });

  factory CommunityCatalogEntry.fromMap(String id, Map<String, dynamic> data) {
    return CommunityCatalogEntry(
      id: id,
      enabled: data['enabled'] as bool? ?? true,
      nameEn: data['nameEn'] as String?,
      nameAr: data['nameAr'] as String?,
      descriptionEn: data['descriptionEn'] as String?,
      descriptionAr: data['descriptionAr'] as String?,
      rulesEn: data['rulesEn'] as String?,
      rulesAr: data['rulesAr'] as String?,
      topic: data['topic'] as String?,
      iconName: data['iconName'] as String?,
      maxMembers: (data['maxMembers'] as num?)?.toInt(),
      order: (data['order'] as num?)?.toInt(),
    );
  }

  final String id;
  final bool enabled;
  final String? nameEn;
  final String? nameAr;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? rulesEn;
  final String? rulesAr;
  final String? topic;
  final String? iconName;
  final int? maxMembers;
  final int? order;
}

class CommunityCatalogRepository {
  CommunityCatalogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Map<String, CommunityCatalogEntry>? _memoryCache;
  DateTime? _memoryCacheAt;

  static const _memoryCacheTtl = Duration(minutes: 5);

  static const collection = 'communityCatalog';

  Future<Map<String, CommunityCatalogEntry>> fetchAll() async {
    final cached = _memoryCache;
    final cachedAt = _memoryCacheAt;
    if (cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _memoryCacheTtl) {
      return cached;
    }

    try {
      final snap = await _firestore.collection(collection).get();
      final resolved = <String, CommunityCatalogEntry>{
        for (final d in snap.docs)
          d.id: CommunityCatalogEntry.fromMap(d.id, d.data()),
      };
      _memoryCache = resolved;
      _memoryCacheAt = DateTime.now();
      return resolved;
    } catch (e, st) {
      debugPrint('CommunityCatalogRepository.fetchAll failed: $e\n$st');
      return cached ?? const {};
    }
  }
}
