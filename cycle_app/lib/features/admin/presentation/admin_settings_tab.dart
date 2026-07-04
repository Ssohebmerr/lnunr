part of 'admin_screen.dart';

class _SettingsTab extends StatefulWidget {
  const _SettingsTab({
    required this.repo,
    required this.settingsRepo,
    required this.l10n,
    required this.theme,
  });
  final AdminRepository repo;
  final AppSettingsRepository settingsRepo;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late TextEditingController _titleEn;
  late TextEditingController _titleAr;
  late TextEditingController _bodyEn;
  late TextEditingController _bodyAr;
  late TextEditingController _supportUrl;
  late TextEditingController _privacyUrl;
  bool _communityEnabled = true;
  bool _aiEducation = true;
  bool _announcementActive = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleEn = TextEditingController();
    _titleAr = TextEditingController();
    _bodyEn = TextEditingController();
    _bodyAr = TextEditingController();
    _supportUrl = TextEditingController();
    _privacyUrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _titleEn.dispose();
    _titleAr.dispose();
    _bodyEn.dispose();
    _bodyAr.dispose();
    _supportUrl.dispose();
    _privacyUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await widget.settingsRepo.fetch();
    if (mounted) {
      setState(() {
        _communityEnabled = settings.communityEnabled;
        _aiEducation = settings.aiEducationEnabled;
        _announcementActive = settings.announcementActive;
        _titleEn.text = settings.announcementTitleEn;
        _titleAr.text = settings.announcementTitleAr;
        _bodyEn.text = settings.announcementBodyEn;
        _bodyAr.text = settings.announcementBodyAr;
        _supportUrl.text = settings.supportUrl;
        _privacyUrl.text = settings.privacyUrl;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repo.updateAppSettings(AppSettings(
        communityEnabled: _communityEnabled,
        aiEducationEnabled: _aiEducation,
        announcementActive: _announcementActive,
        announcementTitleEn: _titleEn.text.trim(),
        announcementTitleAr: _titleAr.text.trim(),
        announcementBodyEn: _bodyEn.text.trim(),
        announcementBodyAr: _bodyAr.text.trim(),
        supportUrl: _supportUrl.text.trim(),
        privacyUrl: _privacyUrl.text.trim(),
      ));
      widget.settingsRepo.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.adminSettingsSaved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.l10n.adminFailedSave)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: Text(l10n.adminCommunityEnabled),
          value: _communityEnabled,
          onChanged: (v) => setState(() => _communityEnabled = v),
        ),
        SwitchListTile(
          title: Text(l10n.adminAiEducation),
          value: _aiEducation,
          onChanged: (v) => setState(() => _aiEducation = v),
        ),
        const Divider(height: 32),
        Text(l10n.adminAnnouncement,
            style: widget.theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SwitchListTile(
          title: Text(l10n.adminActive),
          value: _announcementActive,
          onChanged: (v) => setState(() => _announcementActive = v),
        ),
        TextField(
          controller: _titleEn,
          decoration: InputDecoration(labelText: l10n.adminTitleEnglish),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleAr,
          decoration: InputDecoration(labelText: l10n.adminTitleArabic),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyEn,
          decoration: InputDecoration(labelText: l10n.adminBodyEnglish),
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bodyAr,
          decoration: InputDecoration(labelText: l10n.adminBodyArabic),
          maxLines: 3,
        ),
        const Divider(height: 32),
        TextField(
          controller: _supportUrl,
          decoration: InputDecoration(labelText: l10n.adminSupportUrl),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _privacyUrl,
          decoration: InputDecoration(labelText: l10n.adminPrivacyUrl),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_rounded),
          label: Text(l10n.adminSave),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

