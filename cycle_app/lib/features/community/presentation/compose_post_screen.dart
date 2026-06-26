import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/media/media_upload_service.dart';
import '../../../core/premium/premium_upsell_dialog.dart';
import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/models/community.dart';
import '../data/models/community_post.dart';
import '../data/models/community_profile.dart';
import '../data/models/post_type.dart';
import '../data/moderation_result.dart';
import 'widgets/community_ui.dart';
import 'widgets/moderation_rejected_dialog.dart';

/// Create or edit a text-only (or media-enabled Premium) community post.
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({
    super.key,
    required this.community,
    required this.alias,
    required this.profile,
    this.existingPost,
  });

  final Community community;
  final String alias;
  final CommunityProfile profile;
  final CommunityPost? existingPost;

  bool get isEditing => existingPost != null;

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  late final TextEditingController _controller;
  late PostType _type;
  bool _sending = false;
  bool _isAnonymous = false;

  // Media (Premium only)
  XFile? _pickedFile;
  bool _uploadingMedia = false;
  final _mediaUpload = MediaUploadService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existingPost?.text ?? '');
    _type = widget.existingPost?.postType ?? PostType.support;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Media picker
  // ──────────────────────────────────────────────────────────
  Future<void> _pickMedia(ImageSource source) async {
    final isPremium = await UserPrefs.isPremium();
    if (!isPremium) {
      if (mounted) _showPremiumGate();
      return;
    }

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;

    // Basic size guard (≤15 MB)
    final bytes = await file.length();
    if (bytes > 15 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.fileTooLarge)),
        );
      }
      return;
    }

    setState(() {
      _pickedFile = file;
    });
  }

  Future<void> _showPremiumGate() {
    return showPremiumUpsellDialog(
      context,
      feature: PremiumUpsellFeature.communityMedia,
    );
  }

  void _showMediaPickerSheet() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.communityPickImage),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Upload helper
  // ──────────────────────────────────────────────────────────
  Future<String?> _uploadMedia(String uid) async {
    if (_pickedFile == null) return null;
    setState(() => _uploadingMedia = true);
    try {
      return await _mediaUpload.uploadCommunityPostMedia(
        uid: uid,
        communityId: widget.community.id,
        file: _pickedFile!,
        isVideo: false,
      );
    } finally {
      if (mounted) setState(() => _uploadingMedia = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Submit
  // ──────────────────────────────────────────────────────────
  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final repo = context.read<CommunityRepository>();

    try {
      if (widget.isEditing) {
        await repo.updatePost(
          communityId: widget.community.id,
          postId: widget.existingPost!.id,
          uid: user.uid,
          text: text,
          postType: _type,
        );
      } else {
        String? uploadedUrl;
        if (_pickedFile != null) {
          uploadedUrl = await _uploadMedia(user.uid);
        }

        final pending = await repo.createPost(
          communityId: widget.community.id,
          uid: user.uid,
          alias: widget.alias,
          text: text,
          postType: _type,
          communityName: widget.community.nameForLocale(lang),
          authorAvatarIndex: widget.profile.avatarIndex,
          mediaUrl: uploadedUrl,
          mediaType: uploadedUrl != null ? 'image' : null,
          isAnonymous: _isAnonymous,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pending ? l10n.communityPendingReview : l10n.communityPostPublished,
              ),
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } on ModerationRejectedException catch (e) {
      if (mounted) {
        await showModerationRejectedDialog(context, reason: e.reason);
      }
    } on CommunityBannedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityBannedMessage)),
        );
      }
    } on MediaRequiresPremiumException {
      if (mounted) _showPremiumGate();
    } on MinorRestrictedException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityMinorRestricted)),
        );
      }
    } catch (e, st) {
      debugPrint('ComposePostScreen._submit failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final communityName = widget.community.nameForLocale(lang);
    final isBusy = _sending || _uploadingMedia;
    final gradient = CommunityTopicPalette.gradient(widget.community.topic);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditing ? l10n.communityEditPost : l10n.communityNewPost,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              communityName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: FilledButton(
              onPressed: isBusy ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.isEditing ? l10n.continueBtn : l10n.communityPublish),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradient,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(widget.community.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              communityName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              l10n.communityPostHint,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.communityPostType,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: PostType.values.map((t) {
                      final label = switch (t) {
                        PostType.support => l10n.postTypeSupport,
                        PostType.question => l10n.postTypeQuestion,
                        PostType.tip => l10n.postTypeTip,
                        PostType.vent => l10n.postTypeVent,
                      };
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: CommunityChoiceChip(
                          label: label,
                          selected: _type == t,
                          onTap: () => setState(() => _type = t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 10,
                    minLines: 6,
                    maxLength: 500,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.communityPostHint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                if (_pickedFile != null) ...[
                  const SizedBox(height: 14),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Image.file(
                                File(_pickedFile!.path),
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => setState(() {
                              _pickedFile = null;
                            }),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Material(
            elevation: 8,
            shadowColor: Colors.black26,
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    if (!widget.isEditing)
                      IconButton.filledTonal(
                        tooltip: l10n.communityAddMedia,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        onPressed: isBusy ? null : _showMediaPickerSheet,
                      ),
                    if (!widget.isEditing) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isAnonymous = !_isAnonymous),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isAnonymous
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: _isAnonymous
                                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAnonymous
                                    ? Icons.visibility_off_rounded
                                    : Icons.person_outline_rounded,
                                size: 16,
                                color: _isAnonymous
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.communityPostAnonymously,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: _isAnonymous
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        l10n.communityTextOnlyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
