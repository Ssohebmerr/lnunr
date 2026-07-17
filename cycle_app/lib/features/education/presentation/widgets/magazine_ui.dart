import 'package:flutter/material.dart';

import '../../../../core/theme/app_design_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/education_content.dart';

/// Shared visual language for every place a Lune magazine story appears.
class MagazineBrandBadge extends StatelessWidget {
  const MagazineBrandBadge({
    super.key,
    required this.label,
    this.onDark = false,
    this.compact = false,
  });

  final String label;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? Colors.white : AuraColors.accentDeep;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: onDark
              ? Colors.white.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.78),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_stories_rounded,
            size: compact ? 14 : 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class MagazineCategoryBadge extends StatelessWidget {
  const MagazineCategoryBadge({
    super.key,
    required this.label,
    required this.color,
    this.onDark = false,
  });

  final String label;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.24)
            : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.24))
            : null,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: onDark ? Colors.white : color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class MagazineReadingTime extends StatelessWidget {
  const MagazineReadingTime({
    super.key,
    required this.minutes,
    this.onDark = false,
  });

  final int minutes;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = onDark
        ? Colors.white.withValues(alpha: 0.88)
        : theme.colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          AppLocalizations.of(context)!.educationMinutes(minutes),
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class MagazineArticleCover extends StatelessWidget {
  const MagazineArticleCover({
    super.key,
    required this.article,
    required this.color,
    this.borderRadius = BorderRadius.zero,
    this.overlay = false,
  });

  final Article article;
  final Color color;
  final BorderRadiusGeometry borderRadius;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final fallback = _MagazineCoverFallback(article: article, color: color);
    final image = article.hasCover
        ? Image.network(
            article.coverImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          image,
          if (overlay)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.64),
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
          PositionedDirectional(
            top: 12,
            end: 12,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.68),
                border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: AuraColors.accentDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MagazineCoverFallback extends StatelessWidget {
  const _MagazineCoverFallback({required this.article, required this.color});

  final Article article;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            color.withValues(alpha: 0.82),
            AuraColors.rose.withValues(alpha: 0.70),
            AuraColors.lavenderSoft.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PositionedDirectional(
            top: -42,
            start: -28,
            child: _CoverOrb(
              size: 128,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          PositionedDirectional(
            bottom: -52,
            end: -34,
            child: _CoverOrb(
              size: 150,
              color: AuraColors.peach.withValues(alpha: 0.24),
            ),
          ),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
              ),
              child: Icon(article.icon, size: 38, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverOrb extends StatelessWidget {
  const _CoverOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
