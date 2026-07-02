import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_design_tokens.dart';
import 'fetal_week_illustration.dart';

/// Flo-style 3D pregnancy hero: soft aura background, pulsing fetal
/// silhouette with a gentle float animation, and a decorative
/// "amniotic" gradient ring. Drops into the same slot the original
/// `PregnancyBabyHeroCard` used — the parent already passes a
/// `week` integer and a `lang` string.
///
/// Visual layering (back to front):
///   1. Soft pinkish radial aura that breathes.
///   2. Two concentric "amniotic" rings with subtle rotation.
///   3. A floating, pulsing illustration of the baby (fetal visual).
///   4. A faint heart-line pulse overlay.
class PregnancyBabyHero3DCard extends StatefulWidget {
  const PregnancyBabyHero3DCard({
    super.key,
    required this.week,
    this.size = 260,
  });

  final int week;
  final double size;

  @override
  State<PregnancyBabyHero3DCard> createState() =>
      _PregnancyBabyHero3DCardState();
}

class _PregnancyBabyHero3DCardState extends State<PregnancyBabyHero3DCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _float;
  late final AnimationController _rotate;

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
    _rotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _float.dispose();
    _rotate.dispose();
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

            // Layer 2 — amniotic rings (slow rotation)
            AnimatedBuilder(
              animation: _rotate,
              builder: (_, _) => CustomPaint(
                painter: _AmnioticRingsPainter(
                  rotation: _rotate.value,
                  color: Colors.white.withValues(alpha: 0.18),
                  colorStrong: Colors.white.withValues(alpha: 0.32),
                ),
              ),
            ),

            // Layer 3 — pulsing + floating illustration
            AnimatedBuilder(
              animation: Listenable.merge([_pulse, _float]),
              builder: (_, _) {
                final pulse = Curves.easeInOut.transform(_pulse.value);
                final floatY = Curves.easeInOutSine.transform(_float.value);
                final scale = 1.0 + pulse * 0.04;
                return Center(
                  child: Transform.translate(
                    offset: Offset(0, -4 * floatY),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.18 + 0.12 * pulse),
                              blurRadius: 32 + 18 * pulse,
                              spreadRadius: 2 + 4 * pulse,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.55),
                              blurRadius: 14,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: FetalWeekIllustration(
                          week: widget.week,
                          size: widget.size,
                          hero: true,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Layer 4 — gentle vignette so the illustration pops
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

/// Layer 2 — concentric amniotic rings, slowly rotating.
class _AmnioticRingsPainter extends CustomPainter {
  _AmnioticRingsPainter({
    required this.rotation,
    required this.color,
    required this.colorStrong,
  });

  final double rotation; // 0..1
  final Color color;
  final Color colorStrong;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = math.min(size.width, size.height) * 0.46;
    for (int i = 0; i < 3; i++) {
      final r = maxR * (0.55 + 0.18 * i);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 - 0.2 * i
        ..color = i == 0 ? colorStrong : color;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation * 2 * math.pi * (i.isEven ? 1 : -1));
      canvas.drawCircle(Offset.zero, r, paint);
      canvas.restore();
    }

    // Soft sparkle dots (3) — adds the "amniotic fluid" feel
    for (int i = 0; i < 3; i++) {
      final angle = rotation * 2 * math.pi + i * (2 * math.pi / 3);
      final r = maxR * 0.78;
      final dx = center.dx + math.cos(angle) * r;
      final dy = center.dy + math.sin(angle) * r;
      final paint = Paint()..color = colorStrong;
      canvas.drawCircle(Offset(dx, dy), 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmnioticRingsPainter old) =>
      old.rotation != rotation ||
      old.color != color ||
      old.colorStrong != colorStrong;
}
