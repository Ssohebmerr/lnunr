import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Gestational development stage — drives fetal silhouette shape.
enum FetalVisualStage {
  poppySeed,
  sesameSeed,
  lentil,
  blueberry,
  raspberry,
  cherry,
  strawberry,
  lime,
  plum,
  peaPod,
  lemon,
  apple,
  avocado,
  pear,
  bellPepper,
  mango,
  banana,
  carrot,
  papaya,
  grapefruit,
  cornCob,
  turnip,
  zucchini,
  cauliflower,
  eggplant,
  butternutSquash,
  cucumber,
  coconut,
  pineapple,
  honeydewMelon,
  cantaloupe,
  watermelon,
  romaine,
  chard,
  pumpkin,
  smallWatermelon,
  miniWatermelon,
}

extension FetalVisualStageLabels on FetalVisualStage {
  static FetalVisualStage forWeek(int week) {
    if (week <= 4) return FetalVisualStage.poppySeed;
    if (week <= 5) return FetalVisualStage.sesameSeed;
    if (week <= 6) return FetalVisualStage.lentil;
    if (week <= 7) return FetalVisualStage.blueberry;
    if (week <= 8) return FetalVisualStage.raspberry;
    if (week <= 9) return FetalVisualStage.cherry;
    if (week <= 10) return FetalVisualStage.strawberry;
    if (week <= 11) return FetalVisualStage.lime;
    if (week <= 12) return FetalVisualStage.plum;
    if (week <= 13) return FetalVisualStage.peaPod;
    if (week <= 14) return FetalVisualStage.lemon;
    if (week <= 15) return FetalVisualStage.apple;
    if (week <= 16) return FetalVisualStage.avocado;
    if (week <= 17) return FetalVisualStage.pear;
    if (week <= 18) return FetalVisualStage.bellPepper;
    if (week <= 19) return FetalVisualStage.mango;
    if (week <= 20) return FetalVisualStage.banana;
    if (week <= 21) return FetalVisualStage.carrot;
    if (week <= 22) return FetalVisualStage.papaya;
    if (week <= 23) return FetalVisualStage.grapefruit;
    if (week <= 24) return FetalVisualStage.cornCob;
    if (week <= 25) return FetalVisualStage.turnip;
    if (week <= 26) return FetalVisualStage.zucchini;
    if (week <= 27) return FetalVisualStage.cauliflower;
    if (week <= 28) return FetalVisualStage.eggplant;
    if (week <= 29) return FetalVisualStage.butternutSquash;
    if (week <= 30) return FetalVisualStage.cucumber;
    if (week <= 31) return FetalVisualStage.coconut;
    if (week <= 32) return FetalVisualStage.pineapple;
    if (week <= 33) return FetalVisualStage.honeydewMelon;
    if (week <= 34) return FetalVisualStage.cantaloupe;
    if (week <= 35) return FetalVisualStage.watermelon;
    if (week <= 36) return FetalVisualStage.romaine;
    if (week <= 37) return FetalVisualStage.chard;
    if (week <= 38) return FetalVisualStage.pumpkin;
    if (week <= 39) return FetalVisualStage.smallWatermelon;
    return FetalVisualStage.miniWatermelon;
  }

  String get labelEn => switch (this) {
        FetalVisualStage.poppySeed => 'Embryo',
        FetalVisualStage.sesameSeed => 'Embryo',
        FetalVisualStage.lentil => 'Embryo',
        FetalVisualStage.blueberry => 'Embryo',
        FetalVisualStage.raspberry => 'Embryo',
        FetalVisualStage.cherry => 'Embryo',
        FetalVisualStage.strawberry => 'Embryo',
        FetalVisualStage.lime => 'Early fetus',
        FetalVisualStage.plum => 'Early fetus',
        FetalVisualStage.peaPod => 'Early fetus',
        FetalVisualStage.lemon => 'Early fetus',
        FetalVisualStage.apple => 'Fetus',
        FetalVisualStage.avocado => 'Fetus',
        FetalVisualStage.pear => 'Fetus',
        FetalVisualStage.bellPepper => 'Fetus',
        FetalVisualStage.mango => 'Fetus',
        FetalVisualStage.banana => 'Fetus',
        FetalVisualStage.carrot => 'Fetus',
        FetalVisualStage.papaya => 'Fetus',
        FetalVisualStage.grapefruit => 'Fetus',
        FetalVisualStage.cornCob => 'Active fetus',
        FetalVisualStage.turnip => 'Active fetus',
        FetalVisualStage.zucchini => 'Active fetus',
        FetalVisualStage.cauliflower => 'Active fetus',
        FetalVisualStage.eggplant => 'Active fetus',
        FetalVisualStage.butternutSquash => 'Full term',
        FetalVisualStage.cucumber => 'Full term',
        FetalVisualStage.coconut => 'Full term',
        FetalVisualStage.pineapple => 'Full term',
        FetalVisualStage.honeydewMelon => 'Full term',
        FetalVisualStage.cantaloupe => 'Full term',
        FetalVisualStage.watermelon => 'Full term',
        FetalVisualStage.romaine => 'Near birth',
        FetalVisualStage.chard => 'Near birth',
        FetalVisualStage.pumpkin => 'Near birth',
        FetalVisualStage.smallWatermelon => 'Near birth',
        FetalVisualStage.miniWatermelon => 'Near birth',
      };

  String get labelAr => switch (this) {
        FetalVisualStage.poppySeed => 'جنين مبكر',
        FetalVisualStage.sesameSeed => 'جنين مبكر',
        FetalVisualStage.lentil => 'جنين مبكر',
        FetalVisualStage.blueberry => 'جنين مبكر',
        FetalVisualStage.raspberry => 'جنين مبكر',
        FetalVisualStage.cherry => 'جنين مبكر',
        FetalVisualStage.strawberry => 'جنين مبكر',
        FetalVisualStage.lime => 'بداية تشكّل الجنين',
        FetalVisualStage.plum => 'بداية تشكّل الجنين',
        FetalVisualStage.peaPod => 'بداية تشكّل الجنين',
        FetalVisualStage.lemon => 'بداية تشكّل الجنين',
        FetalVisualStage.apple => 'جنين',
        FetalVisualStage.avocado => 'جنين',
        FetalVisualStage.pear => 'جنين',
        FetalVisualStage.bellPepper => 'جنين',
        FetalVisualStage.mango => 'جنين',
        FetalVisualStage.banana => 'جنين',
        FetalVisualStage.carrot => 'جنين',
        FetalVisualStage.papaya => 'جنين',
        FetalVisualStage.grapefruit => 'جنين',
        FetalVisualStage.cornCob => 'جنين نشط',
        FetalVisualStage.turnip => 'جنين نشط',
        FetalVisualStage.zucchini => 'جنين نشط',
        FetalVisualStage.cauliflower => 'جنين نشط',
        FetalVisualStage.eggplant => 'جنين نشط',
        FetalVisualStage.butternutSquash => 'ناضج',
        FetalVisualStage.cucumber => 'ناضج',
        FetalVisualStage.coconut => 'ناضج',
        FetalVisualStage.pineapple => 'ناضج',
        FetalVisualStage.honeydewMelon => 'ناضج',
        FetalVisualStage.cantaloupe => 'ناضج',
        FetalVisualStage.watermelon => 'ناضج',
        FetalVisualStage.romaine => 'قرب الولادة',
        FetalVisualStage.chard => 'قرب الولادة',
        FetalVisualStage.pumpkin => 'قرب الولادة',
        FetalVisualStage.smallWatermelon => 'قرب الولادة',
        FetalVisualStage.miniWatermelon => 'قرب الولادة',
      };

  String labelFor(String lang) => lang.startsWith('ar') ? labelAr : labelEn;
}

/// Flo-style fetal preview — warm skin tones, amniotic sac, week-accurate shape.
class FetalWeekIllustration extends StatelessWidget {
  const FetalWeekIllustration({
    super.key,
    required this.week,
    this.size = 200,
    this.hero = false,
  });

  final int week;
  final double size;

  /// Larger sac glow and padding for the main home hero.
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FetalPainter(
            week: week.clamp(4, 40),
            hero: hero,
            accent: theme.colorScheme.primary,
            accentSoft: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

class _FetalPalette {
  static const skinHighlight = Color(0xFFFFEDE4);
  static const skinBase = Color(0xFFF8C9B8);
  static const skinShadow = Color(0xFFE5A08E);
  static const skinDeep = Color(0xFFD88978);
  static const sacInner = Color(0xFFFCEEF5);
  static const sacOuter = Color(0xFFE8D4F0);
}

class _FetalPainter extends CustomPainter {
  _FetalPainter({
    required this.week,
    required this.hero,
    required this.accent,
    required this.accentSoft,
  });

  final int week;
  final bool hero;
  final Color accent;
  final Color accentSoft;

  FetalVisualStage get _stage => FetalVisualStageLabels.forWeek(week);

  double get _growth {
    final t = (week - 4) / 36.0;
    return 0.1 + t * 0.82;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    _drawSac(canvas, center, r);
    _drawBaby(canvas, center, r * _growth);
  }

  void _drawSac(Canvas canvas, Offset center, double r) {
    final sacR = r * (hero ? 0.94 : 0.9);
    final glow = Paint()
      ..shader = ui.Gradient.radial(
        center,
        sacR,
        [
          _FetalPalette.sacInner.withValues(alpha: hero ? 0.95 : 0.88),
          accentSoft.withValues(alpha: 0.12),
          _FetalPalette.sacOuter.withValues(alpha: 0.35),
        ],
        [0.0, 0.55, 1.0],
      );
    canvas.drawCircle(center, sacR, glow);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hero ? 2.5 : 1.8
      ..color = accent.withValues(alpha: 0.22);
    canvas.drawCircle(center, sacR, ring);

    final highlight = Paint()
      ..shader = ui.Gradient.radial(
        center + Offset(-sacR * 0.25, -sacR * 0.3),
        sacR * 0.5,
        [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(center, sacR * 0.85, highlight);
  }

  Paint _skinPaint(Rect bounds, {bool shadow = false}) {
    return Paint()
      ..shader = ui.Gradient.linear(
        bounds.topLeft,
        bounds.bottomRight,
        shadow
            ? [_FetalPalette.skinShadow, _FetalPalette.skinDeep]
            : [_FetalPalette.skinHighlight, _FetalPalette.skinBase, _FetalPalette.skinShadow],
        [0.0, 0.45, 1.0],
      );
  }

  void _drawBaby(Canvas canvas, Offset center, double scale) {
    canvas.save();
    canvas.translate(center.dx, center.dy + scale * 0.12);

    switch (_stage) {
      case FetalVisualStage.poppySeed:
      case FetalVisualStage.sesameSeed:
        _drawEmbryo(canvas, scale, tiny: true);
      case FetalVisualStage.lentil:
      case FetalVisualStage.blueberry:
        _drawEmbryo(canvas, scale);
      case FetalVisualStage.raspberry:
      case FetalVisualStage.cherry:
      case FetalVisualStage.strawberry:
        _drawEarlyEmbryo(canvas, scale);
      case FetalVisualStage.lime:
      case FetalVisualStage.plum:
      case FetalVisualStage.peaPod:
        _drawEarlyFetus(canvas, scale);
      case FetalVisualStage.lemon:
      case FetalVisualStage.apple:
      case FetalVisualStage.avocado:
        _drawMidEarlyFetus(canvas, scale);
      case FetalVisualStage.pear:
      case FetalVisualStage.bellPepper:
      case FetalVisualStage.mango:
      case FetalVisualStage.banana:
        _drawMidFetus(canvas, scale);
      case FetalVisualStage.carrot:
      case FetalVisualStage.papaya:
      case FetalVisualStage.grapefruit:
      case FetalVisualStage.cornCob:
        _drawMidLateFetus(canvas, scale);
      case FetalVisualStage.turnip:
      case FetalVisualStage.zucchini:
      case FetalVisualStage.cauliflower:
      case FetalVisualStage.eggplant:
        _drawLateFetus(canvas, scale);
      case FetalVisualStage.butternutSquash:
      case FetalVisualStage.cucumber:
      case FetalVisualStage.coconut:
      case FetalVisualStage.pineapple:
        _drawLateFetusDetail(canvas, scale);
      case FetalVisualStage.honeydewMelon:
      case FetalVisualStage.cantaloupe:
      case FetalVisualStage.watermelon:
      case FetalVisualStage.romaine:
        _drawFullFetus(canvas, scale);
      case FetalVisualStage.chard:
      case FetalVisualStage.pumpkin:
      case FetalVisualStage.smallWatermelon:
      case FetalVisualStage.miniWatermelon:
        _drawNearTermFetus(canvas, scale);
    }

    canvas.restore();
  }

  /// Weeks 4-5: tiny curved shape.
  void _drawEmbryo(Canvas canvas, double s, {bool tiny = false}) {
    final m = tiny ? 0.6 : 1.0;
    final path = Path();
    path.moveTo(-s * 0.08 * m, s * 0.35 * m);
    path.cubicTo(
      -s * 0.55 * m, s * 0.15 * m,
      -s * 0.45 * m, -s * 0.55 * m,
      s * 0.05 * m, -s * 0.62 * m,
    );
    path.cubicTo(
      s * 0.42 * m, -s * 0.58 * m,
      s * 0.38 * m, s * 0.05 * m,
      s * 0.12 * m, s * 0.42 * m,
    );
    path.cubicTo(
      s * 0.02 * m, s * 0.58 * m,
      -s * 0.18 * m, s * 0.52 * m,
      -s * 0.08 * m, s * 0.35 * m,
    );
    path.close();

    final bounds = path.getBounds();
    canvas.drawPath(path, _skinPaint(bounds));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.04 * m
        ..color = _FetalPalette.skinDeep.withValues(alpha: 0.35),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-s * 0.12 * m, -s * 0.38 * m),
        width: s * 0.38 * m,
        height: s * 0.34 * m,
      ),
      _skinPaint(bounds, shadow: true),
    );
  }

  /// Weeks 6-7: developing embryo with limb buds.
  void _drawEarlyEmbryo(Canvas canvas, double s) {
    _drawEmbryo(canvas, s, tiny: false);

    final bud = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.8);
    for (final dx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx * s * 0.35, s * 0.08),
          width: s * 0.12,
          height: s * 0.18,
        ),
        bud,
      );
    }
  }

  /// Weeks 8-10: large head, tiny oval torso, limb buds.
  void _drawEarlyFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(0, -s * 0.42),
      width: s * 0.78,
      height: s * 0.72,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final bodyRect = Rect.fromCenter(
      center: Offset(0, s * 0.08),
      width: s * 0.52,
      height: s * 0.62,
    );
    canvas.drawOval(bodyRect, _skinPaint(bodyRect, shadow: true));

    final bud = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.9);
    for (final dx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx * s * 0.42, s * 0.02),
          width: s * 0.16,
          height: s * 0.28,
        ),
        bud,
      );
    }

    _drawFace(canvas, s * 0.9, Offset(0, -s * 0.42), subtle: true);
  }

  /// Weeks 11-14: more defined body, small curled posture.
  void _drawMidEarlyFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.06, -s * 0.4),
      width: s * 0.72,
      height: s * 0.66,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final bodyPath = Path()
      ..moveTo(-s * 0.25, -s * 0.05)
      ..quadraticBezierTo(-s * 0.3, s * 0.3, -s * 0.1, s * 0.5)
      ..quadraticBezierTo(s * 0.12, s * 0.55, s * 0.25, s * 0.3)
      ..quadraticBezierTo(s * 0.28, s * 0.05, s * 0.12, -s * 0.1)
      ..close();
    canvas.drawPath(bodyPath, _skinPaint(bodyPath.getBounds(), shadow: true));

    final limb = Paint()..color = _FetalPalette.skinBase;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dx * s * 0.32, s * 0.04),
            width: s * 0.14,
            height: s * 0.32,
          ),
          Radius.circular(s * 0.06),
        ),
        limb,
      );
    }

    _drawFace(canvas, s, Offset(-s * 0.06, -s * 0.4));
  }

  /// Weeks 15-20: curled fetus, clear arms, legs tucked.
  void _drawMidFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.08, -s * 0.38),
      width: s * 0.68,
      height: s * 0.64,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final bodyPath = Path()
      ..moveTo(-s * 0.28, -s * 0.05)
      ..quadraticBezierTo(-s * 0.35, s * 0.35, -s * 0.12, s * 0.55)
      ..quadraticBezierTo(s * 0.15, s * 0.62, s * 0.28, s * 0.35)
      ..quadraticBezierTo(s * 0.32, s * 0.05, s * 0.15, -s * 0.12)
      ..close();
    canvas.drawPath(bodyPath, _skinPaint(bodyPath.getBounds(), shadow: true));

    final limb = Paint()..color = _FetalPalette.skinBase;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(dx * s * 0.35, s * 0.06),
            width: s * 0.16,
            height: s * 0.4,
          ),
          Radius.circular(s * 0.07),
        ),
        limb,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.1, s * 0.6),
          width: s * 0.18,
          height: s * 0.35,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.12, s * 0.56),
          width: s * 0.16,
          height: s * 0.32,
        ),
        Radius.circular(s * 0.06),
      ),
      limb,
    );

    _drawFace(canvas, s, Offset(-s * 0.08, -s * 0.38));
    if (week >= 18) _drawCord(canvas, s);
  }

  /// Weeks 21-24: larger fetus, fuller body.
  void _drawMidLateFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.06, -s * 0.42),
      width: s * 0.64,
      height: s * 0.6,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final torso = Rect.fromCenter(
      center: Offset(0, s * 0.0),
      width: s * 0.54,
      height: s * 0.68,
    );
    canvas.drawOval(torso, _skinPaint(torso, shadow: true));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.04, s * 0.14),
        width: s * 0.44,
        height: s * 0.38,
      ),
      Paint()..color = _FetalPalette.skinBase.withValues(alpha: 0.8),
    );

    final limb = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.36, s * 0.04),
          width: s * 0.16,
          height: s * 0.44,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.3, s * 0.08),
          width: s * 0.14,
          height: s * 0.4,
        ),
        Radius.circular(s * 0.06),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.12, s * 0.64),
          width: s * 0.18,
          height: s * 0.38,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.14, s * 0.6),
          width: s * 0.16,
          height: s * 0.35,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );

    _drawFace(canvas, s, Offset(-s * 0.06, -s * 0.42));
    _drawCord(canvas, s);
  }

  /// Weeks 25-28: full proportions, rounded belly.
  void _drawLateFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.06, -s * 0.46),
      width: s * 0.62,
      height: s * 0.58,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final torso = Rect.fromCenter(
      center: Offset(0, s * 0.02),
      width: s * 0.56,
      height: s * 0.7,
    );
    canvas.drawOval(torso, _skinPaint(torso, shadow: true));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.05, s * 0.18),
        width: s * 0.46,
        height: s * 0.4,
      ),
      Paint()..color = _FetalPalette.skinBase.withValues(alpha: 0.85),
    );

    final limb = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.38, s * 0.06),
          width: s * 0.16,
          height: s * 0.46,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.32, s * 0.1),
          width: s * 0.14,
          height: s * 0.42,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.13, s * 0.66),
          width: s * 0.18,
          height: s * 0.4,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.15, s * 0.62),
          width: s * 0.16,
          height: s * 0.38,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );

    _drawFace(canvas, s * 0.95, Offset(-s * 0.06, -s * 0.46));
    _drawCord(canvas, s);

    for (final dx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(-s * 0.06 + dx * s * 0.13, -s * 0.42), s * 0.05, Paint()..color = accent.withValues(alpha: 0.15));
    }
  }

  /// Weeks 29-32: detailed features, chunkier body.
  void _drawLateFetusDetail(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.05, -s * 0.48),
      width: s * 0.6,
      height: s * 0.56,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final torso = Rect.fromCenter(
      center: Offset(0, s * 0.04),
      width: s * 0.58,
      height: s * 0.72,
    );
    canvas.drawOval(torso, _skinPaint(torso, shadow: true));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.06, s * 0.2),
        width: s * 0.5,
        height: s * 0.44,
      ),
      Paint()..color = _FetalPalette.skinBase.withValues(alpha: 0.85),
    );

    final limb = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.4, s * 0.08),
          width: s * 0.16,
          height: s * 0.48,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.34, s * 0.12),
          width: s * 0.14,
          height: s * 0.44,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.14, s * 0.68),
          width: s * 0.19,
          height: s * 0.42,
        ),
        Radius.circular(s * 0.09),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.16, s * 0.64),
          width: s * 0.17,
          height: s * 0.4,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );

    _drawFace(canvas, s * 0.95, Offset(-s * 0.05, -s * 0.48));
    _drawCord(canvas, s);

    for (final dx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(-s * 0.05 + dx * s * 0.14, -s * 0.44), s * 0.06, Paint()..color = accent.withValues(alpha: 0.18));
    }
  }

  /// Weeks 33-36: full body, near-natural proportions.
  void _drawFullFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.04, -s * 0.5),
      width: s * 0.58,
      height: s * 0.54,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final torso = Rect.fromCenter(
      center: Offset(0, s * 0.06),
      width: s * 0.6,
      height: s * 0.74,
    );
    canvas.drawOval(torso, _skinPaint(torso, shadow: true));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.06, s * 0.22),
        width: s * 0.52,
        height: s * 0.46,
      ),
      Paint()..color = _FetalPalette.skinBase.withValues(alpha: 0.85),
    );

    final limb = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.42, s * 0.1),
          width: s * 0.16,
          height: s * 0.5,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.36, s * 0.14),
          width: s * 0.14,
          height: s * 0.46,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.14, s * 0.7),
          width: s * 0.2,
          height: s * 0.44,
        ),
        Radius.circular(s * 0.09),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.16, s * 0.66),
          width: s * 0.18,
          height: s * 0.42,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );

    _drawFace(canvas, s, Offset(-s * 0.04, -s * 0.5));
    _drawCord(canvas, s);

    for (final dx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(-s * 0.04 + dx * s * 0.15, -s * 0.46), s * 0.07, Paint()..color = accent.withValues(alpha: 0.2));
    }
  }

  /// Weeks 37-40: near-term, chubby, fully formed.
  void _drawNearTermFetus(Canvas canvas, double s) {
    final headRect = Rect.fromCenter(
      center: Offset(-s * 0.03, -s * 0.52),
      width: s * 0.56,
      height: s * 0.52,
    );
    canvas.drawOval(headRect, _skinPaint(headRect));

    final torso = Rect.fromCenter(
      center: Offset(0, s * 0.08),
      width: s * 0.62,
      height: s * 0.76,
    );
    canvas.drawOval(torso, _skinPaint(torso, shadow: true));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(s * 0.06, s * 0.24),
        width: s * 0.54,
        height: s * 0.48,
      ),
      Paint()..color = _FetalPalette.skinBase.withValues(alpha: 0.85),
    );

    final limb = Paint()..color = _FetalPalette.skinShadow.withValues(alpha: 0.92);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.44, s * 0.12),
          width: s * 0.16,
          height: s * 0.52,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.38, s * 0.16),
          width: s * 0.14,
          height: s * 0.48,
        ),
        Radius.circular(s * 0.07),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-s * 0.14, s * 0.72),
          width: s * 0.2,
          height: s * 0.46,
        ),
        Radius.circular(s * 0.09),
      ),
      limb,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(s * 0.16, s * 0.68),
          width: s * 0.18,
          height: s * 0.44,
        ),
        Radius.circular(s * 0.08),
      ),
      limb,
    );

    _drawFace(canvas, s, Offset(-s * 0.03, -s * 0.52));
    _drawCord(canvas, s);

    for (final dx in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(-s * 0.03 + dx * s * 0.15, -s * 0.48), s * 0.07, Paint()..color = accent.withValues(alpha: 0.22));
    }
  }

  void _drawFace(Canvas canvas, double s, Offset headCenter, {bool subtle = false}) {
    final eyePaint = Paint()..color = _FetalPalette.skinDeep.withValues(alpha: subtle ? 0.35 : 0.55);
    final eyeY = headCenter.dy + s * 0.02;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(headCenter.dx + dx * s * 0.12, eyeY),
          width: s * (subtle ? 0.05 : 0.06),
          height: s * (subtle ? 0.04 : 0.05),
        ),
        eyePaint,
      );
    }
    if (!subtle && week >= 14) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(headCenter.dx, headCenter.dy + s * 0.14),
          width: s * 0.1,
          height: s * 0.06,
        ),
        0.1,
        math.pi - 0.2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.025
          ..color = _FetalPalette.skinDeep.withValues(alpha: 0.4),
      );
    }
  }

  void _drawCord(Canvas canvas, double s) {
    final cord = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.05
      ..strokeCap = StrokeCap.round
      ..color = accentSoft.withValues(alpha: 0.55);
    final path = Path()
      ..moveTo(s * 0.05, s * 0.28)
      ..cubicTo(
        s * 0.42, s * 0.42,
        s * 0.38, s * 0.78,
        s * 0.1, s * 0.88,
      );
    canvas.drawPath(path, cord);
  }

  @override
  bool shouldRepaint(covariant _FetalPainter oldDelegate) =>
      oldDelegate.week != week || oldDelegate.hero != hero;
}
