import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import '../data/pregnancy_fetal_stage.dart';

class PregnancyBabyRealisticVisual extends StatefulWidget {
  const PregnancyBabyRealisticVisual({
    super.key,
    required this.week,
    required this.lang,
    this.gestationalDay = 7,
    this.size = 260,
  });

  final int week;
  final int gestationalDay;
  final String lang;
  final double size;

  @override
  State<PregnancyBabyRealisticVisual> createState() =>
      _PregnancyBabyRealisticVisualState();
}

class _PregnancyBabyRealisticVisualState
    extends State<PregnancyBabyRealisticVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7800),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion != reduceMotion) {
      _reduceMotion = reduceMotion;
      if (_reduceMotion) {
        _motion.stop();
      } else if (!_motion.isAnimating) {
        _motion.repeat();
      }
    }
    _precacheNearbyStages();
  }

  @override
  void didUpdateWidget(covariant PregnancyBabyRealisticVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldStage = fetalStageForGestationalAge(
      oldWidget.week,
      day: oldWidget.gestationalDay,
    );
    final newStage = fetalStageForGestationalAge(
      widget.week,
      day: widget.gestationalDay,
    );
    if (oldStage.kind != newStage.kind) _precacheNearbyStages();
  }

  void _precacheNearbyStages() {
    final stage = fetalStageForGestationalAge(
      widget.week,
      day: widget.gestationalDay,
    );
    final index = pregnancyFetalStages.indexOf(stage);
    for (final candidate in [index - 1, index, index + 1]) {
      if (candidate >= 0 && candidate < pregnancyFetalStages.length) {
        precacheImage(
          AssetImage(pregnancyFetalStages[candidate].assetPath),
          context,
        );
      }
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = fetalStageForGestationalAge(
      widget.week,
      day: widget.gestationalDay,
    );
    final growthZoom = fetalVisualGrowthZoom(
      widget.week,
      day: widget.gestationalDay,
    );

    return Semantics(
      image: true,
      label: stage.labelFor(widget.lang),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 680),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: child,
            ),
          ),
          child: ClipRRect(
            key: ValueKey(stage.kind),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _AnimatedStageImage(
                  stage: stage,
                  size: widget.size,
                  growthZoom: growthZoom,
                  motion: _reduceMotion
                      ? const AlwaysStoppedAnimation<double>(0.18)
                      : _motion,
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x12000000),
                          Color(0x52000000),
                        ],
                        stops: [0.48, 0.72, 1],
                      ),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 10,
                  end: 10,
                  bottom: 9,
                  child: Text(
                    stage.magnifiedNoteFor(widget.lang),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(color: Color(0x66000000), blurRadius: 5),
                      ],
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

class _AnimatedStageImage extends StatelessWidget {
  const _AnimatedStageImage({
    required this.stage,
    required this.size,
    required this.growthZoom,
    required this.motion,
  });

  final PregnancyFetalStage stage;
  final double size;
  final double growthZoom;
  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: growthZoom),
      duration: const Duration(milliseconds: 760),
      curve: Curves.easeOutCubic,
      child: Image.asset(
        stage.assetPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Center(
            child: Icon(
              Icons.child_care_outlined,
              size: 40,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
      builder: (context, animatedGrowth, image) => AnimatedBuilder(
        animation: motion,
        child: image,
        builder: (context, image) {
          final phase = motion.value * math.pi * 2;
          final driftX = math.sin(phase) * size * 0.009;
          final driftY = math.sin(phase * 0.74 + 0.8) * size * 0.012;
          final breathe = 1 + math.sin(phase * 1.08 + 0.35) * 0.008;
          final tiltY = math.sin(phase * 0.82) * 0.018;
          final tiltX = math.cos(phase * 0.67) * 0.011;
          final lightX = math.sin(phase * 0.55) * 0.24;
          final lightY = math.cos(phase * 0.48) * 0.16;

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.translate(
                offset: Offset(driftX, driftY),
                child: Transform.scale(
                  scale: animatedGrowth * breathe,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0008)
                      ..rotateX(tiltX)
                      ..rotateY(tiltY),
                    child: image,
                  ),
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(lightX, lightY - 0.34),
                      radius: 0.78,
                      colors: const [
                        Color(0x20FFFFFF),
                        Color(0x08FFFFFF),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.48, 1],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
