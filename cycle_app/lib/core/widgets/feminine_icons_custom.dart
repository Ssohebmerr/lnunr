import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A curated set of hand-drawn feminine icons rendered with [CustomPainter].
///
/// Each icon is a single-color filled silhouette drawn from scratch using
/// bezier curves. They:
///   * use a 24×24 viewBox (same convention as Material Icons)
///   * tint to the current theme color (or a supplied color) at runtime
///   * gracefully support gradients via [_FeminineIconPaint]
///   * look soft, organic, and a little luxurious — never clinical
///
/// Drop-in API:
/// ```dart
/// FeminineIconView(FeminineIcon.cycle, size: 32, color: Colors.pink)
/// ```
enum FeminineIcon {
  // ---- Goals / mode icons ----
  cycle, // general / wellness
  pregnant, // pregnancy mode
  conceive, // trying to conceive
  avoid, // avoiding pregnancy
  menopause, // menopause / perimenopause
  pcos, // PCOS management
  postpartum, // postpartum recovery

  // ---- Feature / metric icons ----
  heart,
  heartPulse,
  mood,
  energy,
  sleep,
  droplet,
  weight,
  calendar,
  bell,
  sparkles,
  chart,
  doctor,
  shield,
  flame,
  leaf,
  baby,
  lotus,
}

class FeminineIconView extends StatelessWidget {
  const FeminineIconView(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.gradient,
  });

  final FeminineIcon icon;
  final double size;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? IconTheme.of(context).color ?? Colors.black87;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FeminineIconPaint(
          icon: icon,
          color: tint,
          gradient: gradient,
        ),
      ),
    );
  }
}

class _FeminineIconPaint extends CustomPainter {
  _FeminineIconPaint({
    required this.icon,
    required this.color,
    this.gradient,
  });

  final FeminineIcon icon;
  final Color color;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final s = math.min(w, h);
    // Scale all paths from a 24×24 reference grid to actual size.
    canvas.save();
    canvas.translate((w - s) / 2, (h - s) / 2);
    canvas.scale(s / 24.0);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    if (gradient != null) {
      paint.shader = gradient!.createShader(
        const Rect.fromLTWH(0, 0, 24, 24),
      );
    }

    final path = _pathFor(icon);
    canvas.drawPath(path, paint);

    canvas.restore();
  }

  Path _pathFor(FeminineIcon icon) {
    switch (icon) {
      case FeminineIcon.cycle:
        return _cycle();
      case FeminineIcon.pregnant:
        return _pregnant();
      case FeminineIcon.conceive:
        return _conceive();
      case FeminineIcon.avoid:
        return _avoid();
      case FeminineIcon.menopause:
        return _menopause();
      case FeminineIcon.pcos:
        return _pcos();
      case FeminineIcon.postpartum:
        return _postpartum();
      case FeminineIcon.heart:
        return _heart();
      case FeminineIcon.heartPulse:
        return _heartPulse();
      case FeminineIcon.mood:
        return _mood();
      case FeminineIcon.energy:
        return _energy();
      case FeminineIcon.sleep:
        return _sleep();
      case FeminineIcon.droplet:
        return _droplet();
      case FeminineIcon.weight:
        return _weight();
      case FeminineIcon.calendar:
        return _calendar();
      case FeminineIcon.bell:
        return _bell();
      case FeminineIcon.sparkles:
        return _sparkles();
      case FeminineIcon.chart:
        return _chart();
      case FeminineIcon.doctor:
        return _doctor();
      case FeminineIcon.shield:
        return _shield();
      case FeminineIcon.flame:
        return _flame();
      case FeminineIcon.leaf:
        return _leaf();
      case FeminineIcon.baby:
        return _baby();
      case FeminineIcon.lotus:
        return _lotus();
    }
  }

  // =========================================================================
  // GOAL ICONS
  // =========================================================================

  /// Cycle / General — soft crescent moon (a feminine "period" glyph).
  Path _cycle() {
    final p = Path();
    // Outer circle
    p.addOval(Rect.fromCircle(center: Offset(12, 12), radius: 9));
    // Inner mask (cuts a crescent — even-odd fill rule)
    p.addOval(
      Rect.fromCircle(center: Offset(15.5, 11), radius: 7.5),
    );
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Pregnant — silhouette of a person with a softly rounded belly.
  Path _pregnant() {
    final p = Path();
    // Head
    p.addOval(Rect.fromCircle(center: Offset(12, 5.5), radius: 2.6));
    // Body — gentle curve down, bulge for belly
    p.moveTo(12, 8.5);
    p.cubicTo(
      9, 9.2, 7.4, 11.5, 7.4, 14.5,
    );
    p.cubicTo(
      7.4, 17, 9, 19, 12, 19,
    );
    p.cubicTo(
      15, 19, 16.6, 17, 16.6, 14.5,
    );
    p.cubicTo(
      16.6, 11.5, 15, 9.2, 12, 8.5,
    );
    p.close();
    // Small heart on the belly
    p.moveTo(11, 14);
    p.cubicTo(
      10.2, 13, 9, 13.2, 9, 14.6,
    );
    p.cubicTo(
      9, 15.6, 10, 16.4, 11, 17,
    );
    p.cubicTo(
      12, 16.4, 13, 15.6, 13, 14.6,
    );
    p.cubicTo(
      13, 13.2, 11.8, 13, 11, 14,
    );
    p.close();
    p.fillType = PathFillType.nonZero;
    return p;
  }

  /// Conceive — heart with a small starburst (hope, trying).
  Path _conceive() {
    final p = Path();
    final double cx = 12, cy = 13.5;
    p.moveTo(cx, cy + 6.5);
    p.cubicTo(cx - 7, cy + 1, cx - 7, cy - 6, cx - 2, cy - 6);
    p.cubicTo(cx - 0.5, cy - 6, cx, cy - 4, cx, cy - 3);
    p.cubicTo(cx, cy - 4, cx + 0.5, cy - 6, cx + 2, cy - 6);
    p.cubicTo(cx + 7, cy - 6, cx + 7, cy + 1, cx, cy + 6.5);
    p.close();
    // Sparkle cut-out
    final sparkle = Path();
    sparkle.moveTo(13.5, 6);
    sparkle.lineTo(14.2, 8.2);
    sparkle.lineTo(16.4, 8.9);
    sparkle.lineTo(14.2, 9.6);
    sparkle.lineTo(13.5, 11.8);
    sparkle.lineTo(12.8, 9.6);
    sparkle.lineTo(10.6, 8.9);
    sparkle.lineTo(12.8, 8.2);
    sparkle.close();
    p.fillType = PathFillType.evenOdd;
    p.addPath(sparkle, Offset.zero);
    return p;
  }

  /// Avoid — shield with a soft heart inside (protection with care).
  Path _avoid() {
    final p = Path();
    // Shield silhouette
    p.moveTo(12, 2.5);
    p.cubicTo(8, 4, 5, 4.5, 5, 5);
    p.lineTo(5, 12);
    p.cubicTo(5, 17, 8.5, 20, 12, 21.5);
    p.cubicTo(15.5, 20, 19, 17, 19, 12);
    p.lineTo(19, 5);
    p.cubicTo(19, 4.5, 16, 4, 12, 2.5);
    p.close();
    // Inner heart (cut-out)
    final heart = Path();
    final double cx = 12, cy = 11;
    heart.moveTo(cx, cy + 4);
    heart.cubicTo(cx - 4.5, cy + 0.5, cx - 4.5, cy - 3.5, cx - 1.2, cy - 3.5);
    heart.cubicTo(cx - 0.3, cy - 3.5, cx, cy - 2.4, cx, cy - 1.6);
    heart.cubicTo(cx, cy - 2.4, cx + 0.3, cy - 3.5, cx + 1.2, cy - 3.5);
    heart.cubicTo(cx + 4.5, cy - 3.5, cx + 4.5, cy + 0.5, cx, cy + 4);
    heart.close();
    p.addPath(heart, Offset.zero);
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Menopause — hourglass with a soft rose in the middle.
  Path _menopause() {
    final p = Path();
    // Top cap
    p.moveTo(5, 2.5);
    p.lineTo(19, 2.5);
    p.lineTo(19, 4.5);
    p.lineTo(13.5, 12);
    p.lineTo(19, 19.5);
    p.lineTo(19, 21.5);
    p.lineTo(5, 21.5);
    p.lineTo(5, 19.5);
    p.lineTo(10.5, 12);
    p.lineTo(5, 4.5);
    p.close();
    // Cut a small heart in the middle (a "moment")
    final heart = Path();
    final double cx = 12, cy = 12;
    heart.moveTo(cx, cy + 2);
    heart.cubicTo(cx - 2.2, cy + 0.5, cx - 2.2, cy - 1.5, cx - 0.6, cy - 1.5);
    heart.cubicTo(cx - 0.15, cy - 1.5, cx, cy - 1, cx, cy - 0.6);
    heart.cubicTo(cx, cy - 1, cx + 0.15, cy - 1.5, cx + 0.6, cy - 1.5);
    heart.cubicTo(cx + 2.2, cy - 1.5, cx + 2.2, cy + 0.5, cx, cy + 2);
    heart.close();
    p.addPath(heart, Offset.zero);
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// PCOS — 6-petal lotus, symbol of hormonal balance.
  Path _pcos() {
    final p = Path();
    final cx = 12.0, cy = 12.0;
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi * 2 * i) / 6;
      final petal = Path();
      // Single petal pointing outward
      final tipX = cx + math.cos(angle) * 9;
      final tipY = cy + math.sin(angle) * 9;
      final leftAngle = angle - math.pi / 6;
      final rightAngle = angle + math.pi / 6;
      final leftX = cx + math.cos(leftAngle) * 2.5;
      final leftY = cy + math.sin(leftAngle) * 2.5;
      final rightX = cx + math.cos(rightAngle) * 2.5;
      final rightY = cy + math.sin(rightAngle) * 2.5;
      petal.moveTo(cx, cy);
      petal.cubicTo(leftX, leftY, tipX, tipY, tipX, tipY);
      petal.cubicTo(tipX, tipY, rightX, rightY, cx, cy);
      petal.close();
      p.addPath(petal, Offset.zero);
    }
    // Center dot
    p.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: 2.2));
    return p;
  }

  /// Postpartum — mother silhouette holding a baby (two connected circles).
  Path _postpartum() {
    final p = Path();
    // Mother's head
    p.addOval(Rect.fromCircle(center: Offset(8, 5.5), radius: 2.6));
    // Mother's body — teardrop
    p.moveTo(8, 8.5);
    p.cubicTo(4.5, 9.2, 3, 12, 3, 15);
    p.cubicTo(3, 18, 5, 20.5, 8, 21);
    p.cubicTo(9, 21, 9.5, 20, 9.5, 19);
    p.cubicTo(9.5, 16, 9, 13, 8, 8.5);
    p.close();
    // Baby head
    p.addOval(Rect.fromCircle(center: Offset(15.5, 11), radius: 2.3));
    // Baby body
    p.moveTo(15.5, 13.4);
    p.cubicTo(12, 14, 11.5, 17, 12.5, 20);
    p.cubicTo(13, 21, 14.5, 21.5, 16, 21);
    p.cubicTo(19, 20.5, 21, 18, 20.5, 15);
    p.cubicTo(20.2, 13.5, 18, 13, 15.5, 13.4);
    p.close();
    return p;
  }

  // =========================================================================
  // FEATURE ICONS
  // =========================================================================

  /// Heart
  Path _heart() {
    final p = Path();
    final double cx = 12, cy = 12;
    p.moveTo(cx, cy + 8);
    p.cubicTo(cx - 9, cy + 1.5, cx - 9, cy - 6, cx - 3, cy - 6);
    p.cubicTo(cx - 1.4, cy - 6, cx, cy - 4.5, cx, cy - 3);
    p.cubicTo(cx, cy - 4.5, cx + 1.4, cy - 6, cx + 3, cy - 6);
    p.cubicTo(cx + 9, cy - 6, cx + 9, cy + 1.5, cx, cy + 8);
    p.close();
    return p;
  }

  /// Heart with a pulse line through it.
  Path _heartPulse() {
    final p = _heart();
    // Pulse cut-out (horizontal squiggle through the heart)
    final pulse = Path();
    pulse.moveTo(3, 12);
    pulse.lineTo(8, 12);
    pulse.lineTo(9.5, 9);
    pulse.lineTo(11, 15);
    pulse.lineTo(12.5, 11);
    pulse.lineTo(14, 14);
    pulse.lineTo(15, 12);
    pulse.lineTo(21, 12);
    pulse.lineTo(21, 13.2);
    pulse.lineTo(14.5, 13.2);
    pulse.lineTo(13, 11);
    pulse.lineTo(11.5, 15);
    pulse.lineTo(10, 11);
    pulse.lineTo(8.5, 13.2);
    pulse.lineTo(3, 13.2);
    pulse.close();
    p.addPath(pulse, Offset.zero);
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Mood — soft smile face.
  Path _mood() {
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(12, 12), radius: 9));
    // Eye cutouts
    p.addOval(Rect.fromCircle(center: Offset(9, 10.5), radius: 1));
    p.addOval(Rect.fromCircle(center: Offset(15, 10.5), radius: 1));
    // Smile cutout (a thin crescent — overlay a smaller filled oval)
    p.addOval(Rect.fromCircle(center: Offset(12, 14.5), radius: 3.5));
    // Re-fill the lower half of the smile to make it crescent
    final mask = Path();
    mask.addRect(const Rect.fromLTWH(0, 12, 24, 12));
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Energy — lightning bolt.
  Path _energy() {
    final p = Path();
    p.moveTo(13, 2);
    p.lineTo(5, 13);
    p.lineTo(11, 13);
    p.lineTo(9, 22);
    p.lineTo(19, 10);
    p.lineTo(13, 10);
    p.lineTo(15, 2);
    p.close();
    return p;
  }

  /// Sleep — crescent moon.
  Path _sleep() {
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(12, 12), radius: 9));
    p.addOval(
      Rect.fromCircle(center: Offset(15, 10.5), radius: 7),
    );
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Droplet / water.
  Path _droplet() {
    final p = Path();
    p.moveTo(12, 2.5);
    p.cubicTo(8, 8, 5, 12, 5, 15.5);
    p.cubicTo(5, 19.5, 8, 22, 12, 22);
    p.cubicTo(16, 22, 19, 19.5, 19, 15.5);
    p.cubicTo(19, 12, 16, 8, 12, 2.5);
    p.close();
    // Tiny highlight cut-out
    p.addOval(Rect.fromCircle(center: Offset(9, 14), radius: 1.4));
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Weight / scale.
  Path _weight() {
    final p = Path();
    // Top bar
    p.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 4, 16, 2),
        const Radius.circular(1),
      ),
    );
    // Strings
    p.addRect(const Rect.fromLTWH(11.5, 6, 1, 4));
    p.addRect(const Rect.fromLTWH(7.5, 6, 1, 4));
    p.addRect(const Rect.fromLTWH(15.5, 6, 1, 4));
    // Trapezoid pan
    p.moveTo(5, 10);
    p.lineTo(11, 10);
    p.lineTo(10, 14);
    p.lineTo(6, 14);
    p.close();
    p.moveTo(13, 10);
    p.lineTo(19, 10);
    p.lineTo(18, 14);
    p.lineTo(14, 14);
    p.close();
    // Stem
    p.addRect(const Rect.fromLTWH(11.5, 14, 1, 5));
    // Base
    p.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 19, 10, 2.5),
        const Radius.circular(1),
      ),
    );
    return p;
  }

  /// Calendar.
  Path _calendar() {
    final p = Path();
    p.moveTo(7, 2.5);
    p.cubicTo(7, 1.5, 8, 1, 8.5, 2);
    p.lineTo(8.5, 4);
    p.lineTo(15.5, 4);
    p.lineTo(15.5, 2.5);
    p.cubicTo(15.5, 1.5, 17, 1.5, 17, 2.5);
    p.lineTo(17, 4);
    p.lineTo(18, 4);
    p.cubicTo(19.5, 4, 20.5, 5, 20.5, 6.5);
    p.lineTo(20.5, 19.5);
    p.cubicTo(20.5, 21, 19.5, 22, 18, 22);
    p.lineTo(6, 22);
    p.cubicTo(4.5, 22, 3.5, 21, 3.5, 19.5);
    p.lineTo(3.5, 6.5);
    p.cubicTo(3.5, 5, 4.5, 4, 6, 4);
    p.lineTo(7, 4);
    p.close();
    // Date dots (3x2 cut-outs)
    p.addOval(Rect.fromCircle(center: Offset(8, 10), radius: 0.9));
    p.addOval(Rect.fromCircle(center: Offset(12, 10), radius: 0.9));
    p.addOval(Rect.fromCircle(center: Offset(16, 10), radius: 0.9));
    p.addOval(Rect.fromCircle(center: Offset(8, 14), radius: 0.9));
    p.addOval(Rect.fromCircle(center: Offset(12, 14), radius: 0.9));
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Bell / notification.
  Path _bell() {
    final p = Path();
    p.moveTo(12, 2);
    p.cubicTo(8.5, 2, 6, 4.5, 6, 8);
    p.lineTo(6, 13);
    p.cubicTo(6, 14.5, 5, 15.5, 4, 16.5);
    p.lineTo(20, 16.5);
    p.cubicTo(19, 15.5, 18, 14.5, 18, 13);
    p.lineTo(18, 8);
    p.cubicTo(18, 4.5, 15.5, 2, 12, 2);
    p.close();
    // Clapper
    p.moveTo(10, 18);
    p.cubicTo(10, 19.5, 11, 20.5, 12, 20.5);
    p.cubicTo(13, 20.5, 14, 19.5, 14, 18);
    p.close();
    return p;
  }

  /// Sparkles / AI / insights — small 4-point star.
  Path _sparkles() {
    final p = Path();
    // Big star
    p.moveTo(11, 2);
    p.cubicTo(11, 6, 11, 8, 14, 8);
    p.cubicTo(11, 8, 11, 10, 11, 14);
    p.cubicTo(11, 10, 11, 8, 8, 8);
    p.cubicTo(11, 8, 11, 6, 11, 2);
    p.close();
    // Small star
    final s = Path();
    s.moveTo(17, 12);
    s.cubicTo(17, 15, 17, 16, 19, 16);
    s.cubicTo(17, 16, 17, 17, 17, 20);
    s.cubicTo(17, 17, 17, 16, 15, 16);
    s.cubicTo(17, 16, 17, 15, 17, 12);
    s.close();
    p.addPath(s, Offset.zero);
    p.fillType = PathFillType.nonZero;
    return p;
  }

  /// Bar chart / analytics.
  Path _chart() {
    final p = Path();
    // Three rounded bars
    p.addRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(4, 12, 4, 9),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
    );
    p.addRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(10, 7, 4, 14),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
    );
    p.addRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(16, 3, 4, 18),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
    );
    return p;
  }

  /// Doctor / stethoscope.
  Path _doctor() {
    final p = Path();
    // Chest piece
    p.addOval(Rect.fromCircle(center: Offset(6, 6), radius: 2.5));
    // Right chest piece
    p.addOval(Rect.fromCircle(center: Offset(18, 6), radius: 2.5));
    // Tubes
    p.addRect(const Rect.fromLTWH(4.5, 7, 3, 6));
    p.addRect(const Rect.fromLTWH(16.5, 7, 3, 6));
    // Vertical tube joining
    p.addRect(const Rect.fromLTWH(11, 10, 2, 4));
    // Bulb
    p.addOval(Rect.fromCircle(center: Offset(12, 17), radius: 3));
    p.addOval(Rect.fromCircle(center: Offset(12, 17), radius: 1.5));
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Shield.
  Path _shield() {
    final p = Path();
    p.moveTo(12, 2.5);
    p.cubicTo(8, 4, 5, 4.5, 5, 5);
    p.lineTo(5, 12);
    p.cubicTo(5, 17, 8.5, 20, 12, 21.5);
    p.cubicTo(15.5, 20, 19, 17, 19, 12);
    p.lineTo(19, 5);
    p.cubicTo(19, 4.5, 16, 4, 12, 2.5);
    p.close();
    return p;
  }

  /// Flame / hot flash.
  Path _flame() {
    final p = Path();
    p.moveTo(12, 2);
    p.cubicTo(8, 6, 5, 9, 5, 14);
    p.cubicTo(5, 18, 8, 22, 12, 22);
    p.cubicTo(16, 22, 19, 18, 19, 14);
    p.cubicTo(19, 11, 17, 9, 15, 7);
    p.cubicTo(14, 9, 14, 10, 13, 10);
    p.cubicTo(13, 7, 13, 4, 12, 2);
    p.close();
    // Inner flame cut-out
    p.addOval(Rect.fromCircle(center: Offset(12, 17), radius: 2.2));
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Leaf.
  Path _leaf() {
    final p = Path();
    p.moveTo(20, 4);
    p.cubicTo(14, 4, 9, 7, 6, 12);
    p.cubicTo(4, 15, 4, 19, 5, 20);
    p.cubicTo(7, 21, 11, 21, 14, 19);
    p.cubicTo(19, 16, 22, 11, 22, 5);
    p.cubicTo(22, 4, 21, 4, 20, 4);
    p.close();
    // Vein
    p.moveTo(8, 18);
    p.lineTo(15, 9);
    p.lineTo(16, 10);
    p.lineTo(9, 19);
    p.close();
    p.fillType = PathFillType.evenOdd;
    return p;
  }

  /// Baby.
  Path _baby() {
    final p = Path();
    p.addOval(Rect.fromCircle(center: Offset(12, 10), radius: 7));
    // Body
    p.addOval(const Rect.fromLTWH(5, 14, 14, 8));
    return p;
  }

  /// Lotus — small simple version.
  Path _lotus() {
    final p = Path();
    // Center petal
    p.moveTo(12, 5);
    p.cubicTo(9, 9, 9, 13, 12, 16);
    p.cubicTo(15, 13, 15, 9, 12, 5);
    p.close();
    // Left petal
    p.moveTo(12, 12);
    p.cubicTo(7, 11, 4, 14, 5, 18);
    p.cubicTo(8, 17, 11, 15, 12, 12);
    p.close();
    // Right petal
    p.moveTo(12, 12);
    p.cubicTo(17, 11, 20, 14, 19, 18);
    p.cubicTo(16, 17, 13, 15, 12, 12);
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _FeminineIconPaint old) =>
      old.icon != icon || old.color != color || old.gradient != gradient;
}





