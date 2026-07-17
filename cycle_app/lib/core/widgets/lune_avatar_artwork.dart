import 'package:flutter/material.dart';

import '../profile/avatar_catalog.dart';

/// Paints one quadrant from a local 2×2 avatar sheet.
///
/// Keeping four portraits per sheet gives all 16 avatars a consistent art
/// direction without 16 separate decodes or any dependency on a remote API.
class LuneAvatarArtwork extends StatelessWidget {
  const LuneAvatarArtwork({
    super.key,
    required this.avatarIndex,
    required this.size,
  });

  final int avatarIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final preset = AvatarCatalog.presetAt(avatarIndex);
    final sheetSize = size * 2;

    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: preset.cropAlignment,
          minWidth: sheetSize,
          maxWidth: sheetSize,
          minHeight: sheetSize,
          maxHeight: sheetSize,
          child: Image.asset(
            preset.assetPath,
            width: sheetSize,
            height: sheetSize,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, _, _) => ColoredBox(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: size * 0.52,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
