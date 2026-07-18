import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/media/media_upload_service.dart';
import '../../../core/security/community_text_sanitize.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/community_repository.dart';
import '../data/models/community.dart';
import '../data/models/community_post.dart';
import '../data/models/community_profile.dart';
import '../data/models/post_type.dart';
import '../data/moderation_result.dart';
import '../data/post_cover_styles.dart';
import 'widgets/community_ui.dart';
import 'widgets/moderation_rejected_dialog.dart';

/// Create or edit a community post, with optional image media.
class ComposePostScreen extends StatefulWidget {
  const ComposePostScreen({
    super.key,
    required this.community,
    required this.alias,
    required this.profile,
    this.existingPost,
    this.initialText,
    this.initialType,
  });

  final Community community;
  final String alias;
  final CommunityProfile profile;
  final CommunityPost? existingPost;

  /// Pre-filled text for prompt-driven posts (e.g. question of the week).
  final String? initialText;
  final PostType? initialType;

  bool get isEditing => existingPost != null;

  @override
  State<ComposePostScreen> createState() => _ComposePostScreenState();
}

class _ComposePostScreenState extends State<ComposePostScreen> {
  late final TextEditingController _controller;
  late PostType _type;
  bool _sending = false;
  bool _isAnonymous = false;

  /// Selected gradient cover id for text posts (null = plain text).
  String? _coverStyle;

  // Poll options (2 required, up to 4)
  static const _maxPollOptions = 4;
  final List<TextEditingController> _pollControllers = [];

  // Media
  XFile? _pickedFile;
  bool _uploadingMedia = false;
  final _mediaUpload = MediaUploadService();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingPost?.text ?? widget.initialText ?? '',
    );
    _type =
        widget.existingPost?.postType ?? widget.initialType ?? PostType.support;
    final existingOptions = widget.existingPost?.pollOptions ?? const [];
    for (final option in existingOptions) {
      _pollControllers.add(TextEditingController(text: option));
    }
    while (_pollControllers.length < 2) {
      _pollControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _pollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _pollOptions => _pollControllers
      .map((c) => c.text.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  // ──────────────────────────────────────────────────────────
  // Media picker
  // ──────────────────────────────────────────────────────────
  Future<void> _pickMedia(ImageSource source) async {
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
    final text = CommunityTextSanitize.post(_controller.text);
    if (user == null || text.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    if (_type == PostType.poll &&
        !widget.isEditing &&
        _pollOptions.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.communityPollNeedsOptions)));
      return;
    }

    setState(() => _sending = true);
    final lang = Localizations.localeOf(context).languageCode;
    final repo = context.read<CommunityRepository>();
    String? orphanedMediaUrl;

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
          orphanedMediaUrl = uploadedUrl;
        }

        final pending = await repo.createPost(
          communityId: widget.community.id,
          uid: user.uid,
          text: text,
          postType: _type,
          communityName: widget.community.nameForLocale(lang),
          authorAvatarIndex: widget.profile.avatarIndex,
          mediaUrl: uploadedUrl,
          mediaType: uploadedUrl != null ? 'image' : null,
          isAnonymous: _isAnonymous,
          pollOptions: _type == PostType.poll ? _pollOptions : null,
          coverStyle: (_type != PostType.poll && uploadedUrl == null)
              ? _coverStyle
              : null,
        );
        // The server has atomically attached and approved the upload.
        orphanedMediaUrl = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                pending
                    ? l10n.communityPendingReview
                    : l10n.communityPostPublished,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityBannedMessage)));
      }
    } on MediaReviewUnavailableException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } on MinorRestrictedException {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.communityMinorRestricted)));
      }
    } catch (e, st) {
      debugPrint('ComposePostScreen._submit failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (orphanedMediaUrl != null) {
        try {
          await _mediaUpload.deleteUploadedCommunityMedia(orphanedMediaUrl);
        } catch (error) {
          debugPrint('Could not clean up unpublished media: $error');
        }
      }
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Poll option fields — 2 required, "add option" up to 4.
  Widget _buildPollEditor(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AuraColors.darkCard.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.poll_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.postTypePoll,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < _pollControllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pollControllers[i],
                      maxLength: 60,
                      decoration: InputDecoration(
                        hintText: l10n.communityPollOptionHint(i + 1),
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: isDark ? 0.06 : 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  if (_pollControllers.length > 2)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.cancel,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: theme.colorScheme.outline,
                      ),
                      onPressed: () => setState(() {
                        _pollControllers.removeAt(i).dispose();
                      }),
                    ),
                ],
              ),
            ),
          if (_pollControllers.length < _maxPollOptions)
            TextButton.icon(
              onPressed: () => setState(() {
                _pollControllers.add(TextEditingController());
              }),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l10n.communityPollAddOption),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final communityName = widget.community.nameForLocale(lang);
    final isBusy = _sending || _uploadingMedia;
    final topInset = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton.filledTonal(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                  : Text(
                      widget.isEditing
                          ? l10n.continueBtn
                          : l10n.communityPublish,
                    ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: AppTheme.gradientBackground(context),
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AuraColors.darkCard.withValues(alpha: 0.82)
                              : Colors.white.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CommunityTopicPalette.iconColor(
                                  widget.community.topic,
                                ).withValues(alpha: isDark ? 0.18 : 0.11),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                widget.community.icon,
                                color: CommunityTopicPalette.iconColor(
                                  widget.community.topic,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    communityName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    l10n.communityPostHint,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
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
                              PostType.milestone => l10n.postTypeMilestone,
                              PostType.poll => l10n.postTypePoll,
                            };
                            final icon = switch (t) {
                              PostType.support => Icons.favorite_rounded,
                              PostType.question => Icons.help_outline_rounded,
                              PostType.tip => Icons.lightbulb_outline_rounded,
                              PostType.vent => Icons.whatshot_rounded,
                              PostType.milestone => Icons.emoji_events_rounded,
                              PostType.poll => Icons.poll_rounded,
                            };
                            return Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: CommunityChoiceChip(
                                label: label,
                                icon: icon,
                                selected: _type == t,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _type = t);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AuraColors.darkCard.withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.04),
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
                      // ── Cover style picker (text posts only) ──
                      if (!widget.isEditing &&
                          _type != PostType.poll &&
                          _pickedFile == null) ...[
                        const SizedBox(height: 16),
                        Text(
                          l10n.communityCoverTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _CoverSwatch(
                                selected: _coverStyle == null,
                                label: l10n.communityCoverNone,
                                onTap: () => setState(() => _coverStyle = null),
                              ),
                              for (final style in PostCoverStyles.all)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 8,
                                  ),
                                  child: _CoverSwatch(
                                    gradient: style.gradient,
                                    icon: style.icon,
                                    selected: _coverStyle == style.id,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _coverStyle = style.id);
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (_type == PostType.poll && !widget.isEditing) ...[
                        const SizedBox(height: 16),
                        _buildPollEditor(context, l10n, theme, isDark),
                      ],
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
                            PositionedDirectional(
                              top: 8,
                              end: 8,
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
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
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
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.isEditing) ...[
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: l10n.communityAddMedia,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  onPressed: isBusy
                                      ? null
                                      : _showMediaPickerSheet,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _isAnonymous = !_isAnonymous,
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isAnonymous
                                            ? theme.colorScheme.primaryContainer
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                        border: Border.all(
                                          color: _isAnonymous
                                              ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.3)
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
                                                ? theme
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              l10n.communityPostAnonymously,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                    color: _isAnonymous
                                                        ? theme
                                                              .colorScheme
                                                              .onPrimaryContainer
                                                        : theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round swatch for the cover-style picker: a gradient circle (or a "none"
/// outline) with a check overlay when selected.
class _CoverSwatch extends StatelessWidget {
  const _CoverSwatch({
    required this.selected,
    required this.onTap,
    this.gradient,
    this.icon,
    this.label,
  });

  final bool selected;
  final VoidCallback onTap;
  final Gradient? gradient;
  final IconData? icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: gradient == null
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : null,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: selected ? 2.4 : 1,
          ),
        ),
        child: Center(
          child: selected
              ? Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: gradient != null
                      ? Colors.white
                      : theme.colorScheme.primary,
                )
              : (gradient != null
                    ? Icon(
                        icon,
                        size: 18,
                        color: Colors.white.withValues(alpha: 0.85),
                      )
                    : Icon(
                        Icons.block_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
        ),
      ),
    );
  }
}
