import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AppBanner {
  const AppBanner({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    this.actionUrl,
    this.accentHex = '#E8A0BF',
    this.order = 0,
    this.published = true,
  });

  factory AppBanner.fromMap(String id, Map<String, dynamic> data) {
    return AppBanner(
      id: id,
      titleAr: data['titleAr'] as String? ?? '',
      titleEn: data['titleEn'] as String? ?? '',
      bodyAr: data['bodyAr'] as String? ?? '',
      bodyEn: data['bodyEn'] as String? ?? '',
      actionUrl: data['actionUrl'] as String?,
      accentHex: data['accentHex'] as String? ?? '#E8A0BF',
      order: (data['order'] as num?)?.toInt() ?? 0,
      published: data['published'] as bool? ?? true,
    );
  }

  final String id;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String? actionUrl;
  final String accentHex;
  final int order;
  final bool published;

  String title(String lang) => lang == 'ar' ? titleAr : titleEn;
  String body(String lang) => lang == 'ar' ? bodyAr : bodyEn;

  Color get accent {
    final hex = accentHex.replaceAll('#', '');
    if (hex.length != 6) return const Color(0xFFE8A0BF);
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return const Color(0xFFE8A0BF);
    return Color(0xFF000000 | value);
  }
}

class AppBannersRepository {
  AppBannersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const collection = 'appBanners';

  Future<List<AppBanner>> fetchPublished() async {
    try {
      final snap = await _firestore
          .collection(collection)
          .where('published', isEqualTo: true)
          .orderBy('order')
          .get();
      return snap.docs
          .map((d) => AppBanner.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
