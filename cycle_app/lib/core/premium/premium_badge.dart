import 'package:flutter/material.dart';

import '../theme/app_design_tokens.dart';

/// Golden crown / star badge for Premium members.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    this.size = 16,
    this.showLabel = false,
  });

  final double size;
  final bool showLabel;

  /// Small crown pinned on an avatar corner.
  static Widget avatarOverlay({double size = 18}) {
    return Positioned(
      top: -2,
      right: -2,
      child: PremiumBadge(size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = size * 0.62;

    final crown = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AuraDecorations.premiumGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AuraColors.peachGold.withValues(alpha: 0.45),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.08),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.workspace_premium_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );

    if (!showLabel) return crown;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        crown,
        const SizedBox(width: 4),
        Text(
          'Premium',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AuraColors.peachGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

/// Inline star chip shown beside a display name.
class PremiumNameBadge extends StatelessWidget {
  const PremiumNameBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AuraColors.peachGold.withValues(alpha: 0.25),
            AuraColors.rose.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AuraColors.peachGold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: 12,
            color: AuraColors.peachGold,
          ),
          const SizedBox(width: 2),
          Text(
            'Pro',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AuraColors.peachGold,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}
