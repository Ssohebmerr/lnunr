import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/media/media_upload_service.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/avatar_picker_row.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_constants.dart';

class CommunityProfileSetupSheet extends StatefulWidget {
  const CommunityProfileSetupSheet({
    super.key,
    this.birthYearOnly = false,
    this.initialAlias,
    this.initialBirthYear,
    this.initialAvatarIndex = 0,
    this.initialPhotoUrl,
    required this.onSaved,
  });

  final bool birthYearOnly;
  final String? initialAlias;
  final int? initialBirthYear;
  final int initialAvatarIndex;
  final String? initialPhotoUrl;
  final Future<void> Function(
    String alias,
    int birthYear,
    int avatarIndex,
    String? photoUrl,
  )
  onSaved;

  @override
  State<CommunityProfileSetupSheet> createState() =>
      _CommunityProfileSetupSheetState();
}

class _CommunityProfileSetupSheetState
    extends State<CommunityProfileSetupSheet> {
  late final TextEditingController _aliasController;
  final _media = MediaUploadService();
  int? _birthYear;
  int _avatarIndex = 0;
  String? _photoUrl;
  String? _error;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.initialAlias);
    _birthYear = widget.initialBirthYear;
    _avatarIndex = widget.initialAvatarIndex;
    _photoUrl = widget.initialPhotoUrl;
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final file = await _media.pickImage();
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await _media.uploadProfilePhoto(uid: user.uid, file: file);
      if (mounted) setState(() => _photoUrl = url);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  bool _saving = false;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final alias = widget.birthYearOnly
        ? (widget.initialAlias?.trim() ?? '')
        : _aliasController.text.trim();
    if (!widget.birthYearOnly) {
      if (alias.length < 2) {
        setState(() => _error = l10n.communityAliasTooShort);
        return;
      }
      if (alias.contains('@') || alias.contains(' ')) {
        setState(() => _error = l10n.communityAliasInvalid);
        return;
      }
    } else if (alias.length < 2) {
      setState(() => _error = l10n.communityAliasTooShort);
      return;
    }
    if (_birthYear == null) {
      setState(() => _error = l10n.communityBirthYearRequired);
      return;
    }
    if (!isCommunityAdultBirthYear(_birthYear!)) {
      setState(() => _error = l10n.communityBirthYearTooYoung);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSaved(alias, _birthYear!, _avatarIndex, _photoUrl);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    final years = communityAllowedBirthYears();
    final onlyYear = widget.birthYearOnly;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            onlyYear ? l10n.communityBirthYearLabel : l10n.communitySetupTitle,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            onlyYear ? l10n.communityBirthYearWhy : l10n.communitySetupSubtitle,
            style: theme.textTheme.bodyMedium,
          ),
          if (onlyYear) ...[
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: Text(l10n.communityAliasLabel),
              subtitle: Text(widget.initialAlias ?? ''),
            ),
          ],
          if (!onlyYear) ...[
            const SizedBox(height: 16),
            Center(
              child: AppAvatar(
                radius: 40,
                avatarIndex: _avatarIndex,
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
              controller: _aliasController,
              decoration: InputDecoration(
                labelText: l10n.communityAliasLabel,
                hintText: l10n.communityAliasHint,
                errorText: _error,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              textInputAction: TextInputAction.done,
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _birthYear,
            decoration: InputDecoration(
              labelText: l10n.communityBirthYearLabel,
              prefixIcon: const Icon(Icons.cake_outlined),
            ),
            items: years
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (y) => setState(() => _birthYear = y),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.communityBirthYearWhy,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.continueBtn),
          ),
        ],
      ),
    );
  }
}
