/// Remote app configuration managed from the admin panel.
class AppSettings {
  const AppSettings({
    this.communityEnabled = true,
    this.aiEducationEnabled = true,
    this.announcementActive = false,
    this.announcementTitleAr = '',
    this.announcementTitleEn = '',
    this.announcementBodyAr = '',
    this.announcementBodyEn = '',
    this.supportUrl = '',
    this.privacyUrl = '',
  });

  factory AppSettings.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AppSettings();
    return AppSettings(
      communityEnabled: data['communityEnabled'] as bool? ?? true,
      aiEducationEnabled: data['aiEducationEnabled'] as bool? ?? true,
      announcementActive: data['announcementActive'] as bool? ?? false,
      announcementTitleAr: data['announcementTitleAr'] as String? ?? '',
      announcementTitleEn: data['announcementTitleEn'] as String? ?? '',
      announcementBodyAr: data['announcementBodyAr'] as String? ?? '',
      announcementBodyEn: data['announcementBodyEn'] as String? ?? '',
      supportUrl: data['supportUrl'] as String? ?? '',
      privacyUrl: data['privacyUrl'] as String? ?? '',
    );
  }

  final bool communityEnabled;
  final bool aiEducationEnabled;
  final bool announcementActive;
  final String announcementTitleAr;
  final String announcementTitleEn;
  final String announcementBodyAr;
  final String announcementBodyEn;
  final String supportUrl;
  final String privacyUrl;

  String announcementTitle(String lang) =>
      lang == 'ar' ? announcementTitleAr : announcementTitleEn;

  String announcementBody(String lang) =>
      lang == 'ar' ? announcementBodyAr : announcementBodyEn;

  bool get hasAnnouncement =>
      announcementActive &&
      announcementTitleAr.trim().isNotEmpty &&
      announcementTitleEn.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'communityEnabled': communityEnabled,
        'aiEducationEnabled': aiEducationEnabled,
        'announcementActive': announcementActive,
        'announcementTitleAr': announcementTitleAr,
        'announcementTitleEn': announcementTitleEn,
        'announcementBodyAr': announcementBodyAr,
        'announcementBodyEn': announcementBodyEn,
        'supportUrl': supportUrl,
        'privacyUrl': privacyUrl,
      };
}
