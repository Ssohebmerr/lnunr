import 'package:flutter/material.dart';

/// Designed gradient covers for text posts — the Flo-style "big visual with
/// the question on top" look, without any downloaded imagery: covers are
/// pure gradients + a subtle watermark icon, so they cost nothing to ship,
/// work offline, and can never need moderation.
///
/// Ids are stored on the post document (`coverStyle`) and validated against
/// this same list server-side — keep the ids in sync with
/// firebase/functions/endpoints/community.js `COVER_STYLES`.
class PostCoverStyle {
  const PostCoverStyle({
    required this.id,
    required this.colors,
    required this.icon,
  });

  final String id;
  final List<Color> colors;

  /// Faint oversized watermark drawn behind the text.
  final IconData icon;

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: colors,
  );
}

class PostCoverStyles {
  PostCoverStyles._();

  static const List<PostCoverStyle> all = [
    PostCoverStyle(
      id: 'berry',
      colors: [Color(0xFFC02E6A), Color(0xFF7B2A5B)],
      icon: Icons.favorite_rounded,
    ),
    PostCoverStyle(
      id: 'lavender',
      colors: [Color(0xFF8A79E8), Color(0xFF5C4DB1)],
      icon: Icons.nightlight_round,
    ),
    PostCoverStyle(
      id: 'sunset',
      colors: [Color(0xFFE8834A), Color(0xFFC2465C)],
      icon: Icons.wb_twilight_rounded,
    ),
    PostCoverStyle(
      id: 'ocean',
      colors: [Color(0xFF3D8FB8), Color(0xFF2A5B8A)],
      icon: Icons.water_rounded,
    ),
    PostCoverStyle(
      id: 'forest',
      colors: [Color(0xFF3D9A78), Color(0xFF23634C)],
      icon: Icons.spa_rounded,
    ),
    PostCoverStyle(
      id: 'blush',
      colors: [Color(0xFFE28BAE), Color(0xFFB05684)],
      icon: Icons.local_florist_rounded,
    ),
  ];

  static PostCoverStyle? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final style in all) {
      if (style.id == id) return style;
    }
    return null;
  }
}
