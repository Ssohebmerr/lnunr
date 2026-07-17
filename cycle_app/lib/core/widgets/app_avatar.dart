import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_design_tokens.dart';
import '../profile/avatar_catalog.dart';
import '../premium/premium_badge.dart';
import 'lune_avatar_artwork.dart';

/// App-wide avatar: stylized character, custom photo, or network image.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.avatarIndex,
    this.photoPath,
    this.networkUrl,
    this.uidSeed,
    this.radius = 20,
    this.onTap,
    this.isPremium = false,
  });

  final int? avatarIndex;
  final String? photoPath;
  final String? networkUrl;
  final String? uidSeed;
  final double radius;
  final VoidCallback? onTap;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    Widget child;

    if (photoPath != null &&
        photoPath!.isNotEmpty &&
        File(photoPath!).existsSync()) {
      child = ClipOval(
        child: Image.file(
          File(photoPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: networkUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _loading(size),
          errorWidget: (_, _, _) => _fallback(context, size),
        ),
      );
    } else {
      final index =
          avatarIndex ??
          (uidSeed != null ? AvatarCatalog.indexFromSeed(uidSeed!) : 0);
      child = ClipOval(
        child: LuneAvatarArtwork(avatarIndex: index, size: size),
      );
    }

    child = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isPremium
              ? AuraColors.peachGold.withValues(alpha: 0.85)
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: isPremium ? 2 : 1.5,
        ),
      ),
      child: child,
    );

    if (isPremium) {
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          PremiumBadge.avatarOverlay(size: radius * 0.55 + 8),
        ],
      );
    }

    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }

    return child;
  }

  Widget _loading(double size) => SizedBox(
    width: size,
    height: size,
    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );

  Widget _fallback(BuildContext context, double size) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(Icons.person, color: theme.colorScheme.primary, size: radius),
    );
  }
}
