import 'package:flutter/material.dart';

class Community {
  const Community({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.topic,
    required this.icon,
    required this.maxMembers,
    this.memberCount = 0,
    this.rulesEn = '',
    this.rulesAr = '',
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;
  final String topic;
  final IconData icon;
  final int maxMembers;
  final int memberCount;
  final String rulesEn;
  final String rulesAr;

  String nameForLocale(String languageCode) =>
      languageCode.startsWith('ar') ? nameAr : nameEn;

  String descriptionForLocale(String languageCode) =>
      languageCode.startsWith('ar') ? descriptionAr : descriptionEn;

  String rulesForLocale(String languageCode) =>
      languageCode.startsWith('ar') ? rulesAr : rulesEn;

  Community copyWith({
    int? memberCount,
    String? nameEn,
    String? nameAr,
    String? descriptionEn,
    String? descriptionAr,
    String? rulesEn,
    String? rulesAr,
    String? topic,
    IconData? icon,
    int? maxMembers,
  }) =>
      Community(
        id: id,
        nameEn: nameEn ?? this.nameEn,
        nameAr: nameAr ?? this.nameAr,
        descriptionEn: descriptionEn ?? this.descriptionEn,
        descriptionAr: descriptionAr ?? this.descriptionAr,
        topic: topic ?? this.topic,
        icon: icon ?? this.icon,
        maxMembers: maxMembers ?? this.maxMembers,
        memberCount: memberCount ?? this.memberCount,
        rulesEn: rulesEn ?? this.rulesEn,
        rulesAr: rulesAr ?? this.rulesAr,
      );
}
