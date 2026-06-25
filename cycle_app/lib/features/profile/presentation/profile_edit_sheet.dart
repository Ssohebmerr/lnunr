import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/media/media_upload_service.dart';
import '../../../core/profile/local_profile.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/aura_scaffold.dart';
import '../../../core/widgets/avatar_picker_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../../menstrudel_integration/menstrudel_init.dart';

class ProfileEditSheet extends StatefulWidget {
  const ProfileEditSheet({super.key});

  @override
  State<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<ProfileEditSheet> {
  late final TextEditingController _nameController;
  final _media = MediaUploadService();
  int _avatarIndex = 0;
  String? _photoPath;
  String? _photoUrl;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final name = await LocalProfile.displayName();
    final avatar = await LocalProfile.avatarIndex();
    final path = await LocalProfile.customPhotoPath();
    final url = await LocalProfile.customPhotoUrl();
    if (mounted) {
      setState(() {
        _nameController.text = name == 'Guest' ? '' : name;
        _avatarIndex = avatar;
        _photoPath = path;
        _photoUrl = url;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await _media.pickImage();
    if (file == null) return;
    await LocalProfile.saveCustomPhotoPath(file.path);
    setState(() {
      _photoPath = file.path;
      _photoUrl = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _uploading = true);
    try {
      final url = await _media.uploadProfilePhoto(uid: user.uid, file: file);
      await LocalProfile.saveCustomPhotoUrl(url);
      if (mounted) setState(() => _photoUrl = url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    await LocalProfile.saveDisplayName(name);
    await LocalProfile.saveAvatarIndex(_avatarIndex);
    final userService = MenstrudelInit.userService;
    if (userService?.user != null) {
      await userService!.setName(name.isEmpty ? 'Guest' : name);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editProfileTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(l10n.editProfileSubtitle, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          Center(
            child: AppAvatar(
              radius: 40,
              avatarIndex: _avatarIndex,
              photoPath: _photoPath,
              networkUrl: _photoUrl,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.avatarPickTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          AvatarPickerRow(
            selectedIndex: _avatarIndex,
            onSelected: (i) => setState(() => _avatarIndex = i),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickPhoto,
            icon: _uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: Text(l10n.avatarUsePhoto),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.onboardingNameLabel,
              hintText: l10n.onboardingNameHint,
            ),
          ),
          const SizedBox(height: 16),
          AppGradientButton(label: l10n.editProfileSave, onPressed: _save),
        ],
      ),
    );
  }
}
