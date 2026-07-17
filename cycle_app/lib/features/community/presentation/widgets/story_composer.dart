import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/community_constants.dart';
import '../../data/community_story_repository.dart';
import '../../data/models/community_profile.dart';

/// Bottom sheet to create a new story (image from gallery or text-only).
Future<void> showStoryComposer({
  required BuildContext context,
  required String communityId,
  required String alias,
  required CommunityProfile profile,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Semantics(
        label: l10n.storyCreate,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                l10n.storyCreate,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (kCommunityMediaUploadsEnabled) ...[
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.storyPickImage),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final file = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1920,
                    imageQuality: 85,
                  );
                  if (file == null || !context.mounted) return;
                  await _uploadStory(
                    context: context,
                    communityId: communityId,
                    alias: alias,
                    profile: profile,
                    file: file,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.burst_mode_outlined),
                title: Text(l10n.storyPickMultiple),
                subtitle: Text(l10n.storyTextOnlyHint),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picker = ImagePicker();
                  final files = await picker.pickMultiImage(
                    maxWidth: 1920,
                    maxHeight: 1920,
                    imageQuality: 85,
                  );
                  if (files.isEmpty || !context.mounted) return;
                  await _uploadMultipleStories(
                    context: context,
                    communityId: communityId,
                    alias: alias,
                    profile: profile,
                    files: files,
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.text_fields_rounded),
              title: Text(l10n.storyTextOnly),
              subtitle: Text(l10n.storyTextOnlyHint),
              onTap: () {
                Navigator.pop(ctx);
                _showTextStoryEditor(
                  context: context,
                  communityId: communityId,
                  alias: alias,
                  profile: profile,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

Future<void> _uploadStory({
  required BuildContext context,
  required String communityId,
  required String alias,
  required CommunityProfile profile,
  required XFile file,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final repo = context.read<CommunityStoryRepository>();

  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(minutes: 1),
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(l10n.storyPublish),
        ],
      ),
    ),
  );

  try {
    await repo.createStory(
      communityId: communityId,
      uid: user.uid,
      alias: alias,
      file: file,
      authorAvatarIndex: profile.avatarIndex,
    );
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(l10n.storyPublished)));
    }
  } on MediaRequiresPremiumException {
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.storyPremiumRequired)),
      );
    }
  } on StoryMediaTooLargeException {
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(l10n.fileTooLarge)));
    }
  } catch (e) {
    debugPrint('Story upload failed for ${file.name}: $e');
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

Future<void> _uploadMultipleStories({
  required BuildContext context,
  required String communityId,
  required String alias,
  required CommunityProfile profile,
  required List<XFile> files,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || !context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final repo = context.read<CommunityStoryRepository>();

  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(minutes: 5),
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(l10n.storyPublish),
        ],
      ),
    ),
  );

  int successCount = 0;
  for (final file in files) {
    try {
      await repo.createStory(
        communityId: communityId,
        uid: user.uid,
        alias: alias,
        file: file,
        authorAvatarIndex: profile.avatarIndex,
      );
      successCount++;
    } on MediaRequiresPremiumException {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.storyPremiumRequired)),
        );
        return;
      }
    } on StoryMediaTooLargeException {
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text(l10n.fileTooLarge)));
        return;
      }
    } catch (e) {
      debugPrint('Multi-story upload failed for ${file.name}: $e');
    }
  }

  if (context.mounted && successCount > 0) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${l10n.storyPublished} ($successCount/${files.length})'),
      ),
    );
  } else if (context.mounted) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
  }
}

void _showTextStoryEditor({
  required BuildContext context,
  required String communityId,
  required String alias,
  required CommunityProfile profile,
}) {
  final l10n = AppLocalizations.of(context)!;
  final colors = [
    '0xFFE8A0BF',
    '0xFF7B6CF6',
    '0xFF3D9A78',
    '0xFFE88B4A',
    '0xFF5C6BC0',
    '0xFFD94F8A',
    '0xFF667EEA',
    '0xFFA18CD1',
  ];
  final random = Random();
  String selectedColor = colors[random.nextInt(colors.length)];
  final controller = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.storyTextOnly,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = Color(int.parse(colors[i]));
                    final isSelected = colors[i] == selectedColor;
                    return GestureDetector(
                      onTap: () =>
                          setModalState(() => selectedColor = colors[i]),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(int.parse(selectedColor)).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 200,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.storyTextHint,
                    border: InputBorder.none,
                    counterStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);

                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null || !context.mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final repo = context.read<CommunityStoryRepository>();

                  try {
                    await repo.createTextStory(
                      communityId: communityId,
                      uid: user.uid,
                      alias: alias,
                      text: text,
                      backgroundColor: selectedColor,
                      authorAvatarIndex: profile.avatarIndex,
                    );
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.storyPublished)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.errorGeneric)),
                      );
                    }
                  }
                },
                child: Text(l10n.storyPublish),
              ),
            ],
          ),
        ),
      );
    },
  );
}
