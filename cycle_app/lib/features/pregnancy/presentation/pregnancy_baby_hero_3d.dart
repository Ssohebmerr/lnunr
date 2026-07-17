import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import 'pregnancy_baby_realistic_visual.dart';

/// Realistic pregnancy hero: soft aura background and a gently animated fetal
/// stage image. The previous drawn-ring engine has been removed.
///
/// Visual layering (back to front):
///   1. Soft pinkish radial aura that breathes.
///   2. A floating, pulsing fetal-stage image.
///   3. A gentle vignette overlay.
class PregnancyBabyHero3DCard extends StatefulWidget {
  const PregnancyBabyHero3DCard({
    super.key,
    required this.week,
    required this.lang,
    this.gestationalDay = 7,
    this.size = 260,
  });

  final int week;
  final String lang;
  final int gestationalDay;
  final double size;

  @override
  State<PregnancyBabyHero3DCard> createState() =>
      _PregnancyBabyHero3DCardState();
}

class _PregnancyBabyHero3DCardState extends State<PregnancyBabyHero3DCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 — soft radial aura
            const _AuraBackground(),

            // Layer 2 — softly floating, medically staged illustration.
            AnimatedBuilder(
              animation: Listenable.merge([_pulse, _float]),
              builder: (_, _) {
                final pulse = Curves.easeInOut.transform(_pulse.value);
                final floatY = Curves.easeInOutSine.transform(_float.value);
                // The fetal artwork now owns the visible movement and gradual
                // weekly growth. Keep this outer motion restrained so the
                // layered perspective remains calm instead of feeling shaky.
                final scale = 0.998 + pulse * 0.004;
                return Center(
                  child: Transform.translate(
                    offset: Offset(0, -0.8 * floatY),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.09 + 0.04 * pulse,
                              ),
                              blurRadius: 20 + 8 * pulse,
                              spreadRadius: 1 + pulse,
                            ),
                          ],
                        ),
                        child: PregnancyBabyRealisticVisual(
                          week: widget.week,
                          gestationalDay: widget.gestationalDay,
                          lang: widget.lang,
                          size: widget.size,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Layer 3 — gentle vignette so the illustration pops
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layer 1 — soft pinkish-rose radial aura that breathes.
class _AuraBackground extends StatefulWidget {
  const _AuraBackground();

  @override
  State<_AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<_AuraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = Curves.easeInOutSine.transform(_ctrl.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.05),
              radius: 0.95 + 0.06 * t,
              colors: [
                Color.lerp(
                  const Color(0xFFFDE2EA),
                  const Color(0xFFFAB6CB),
                  t,
                )!,
                Color.lerp(
                  const Color(0xFFFFE5EE),
                  const Color(0xFFFFD0DF),
                  1 - t,
                )!,
                const Color(0xFFFFF6F9),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }
}
