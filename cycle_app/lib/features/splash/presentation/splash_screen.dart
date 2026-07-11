import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/storage/user_prefs.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/widgets/aura_scaffold.dart';

/// Branded splash — the logo draws itself directly on the screen.
///
/// No tile, no ripples, no text. The mark is physically two pen strokes
/// (verified by measuring the artwork's pixels), and the animation draws
/// them exactly as constructed:
///
///  1. The MOON: the crescent's stroke — from its small cut tip, through
///     the lightning kink, down the concave edge and around to the horn
///     tip at the bottom right.
///  2. The DROP: one unbroken stroke that starts at the very point where
///     the moon ended — rises along the crescent's outer edge (completing
///     the moon), reaches the apex, then sweeps the whole teardrop around
///     to the angled cut. The moon is completed by the drop.
///
/// Every point below was measured from assets/icon/app_icon.png scanlines,
/// so the finished strokes reproduce the original mark.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// One-shot controller for the logo assembly.
  late final AnimationController _intro;

  /// Looping controller for the finished mark's life: glow pulse + breathe.
  late final AnimationController _ambient;

  late final Animation<double> _canvasFade;
  late final Animation<double> _canvasScale;
  late final Animation<double> _moonDraw;
  late final Animation<double> _dropDraw;
  late final Animation<double> _bloom;

  /// Minimum time the splash stays on screen so the assembly can finish.
  static const _minVisible = Duration(milliseconds: 3200);

  @override
  void initState() {
    super.initState();

    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    CurvedAnimation curve(double begin, double end,
            [Curve c = Curves.easeOutCubic]) =>
        CurvedAnimation(parent: _intro, curve: Interval(begin, end, curve: c));

    // Timeline: canvas settles → the moon stroke draws itself → the drop
    // stroke picks up from the moon's endpoint and wraps the whole mark →
    // glow blooms with a small pop.
    _canvasFade = curve(0.0, 0.12);
    _canvasScale =
        Tween<double>(begin: 0.92, end: 1.0).animate(curve(0.0, 0.25));
    _moonDraw = curve(0.05, 0.38, Curves.easeInOutCubic);
    _dropDraw = curve(0.42, 0.90, Curves.easeInOutCubic);
    _bloom = curve(0.88, 1.0);

    _intro.forward();
    _routeNext();
  }

  Future<void> _routeNext() async {
    await Future<void>.delayed(_minVisible);
    if (!mounted) return;
    final done = await UserPrefs.isOnboardingDone();
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;
    context.go(_canEnterHome(done, user) ? '/home' : '/welcome');
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppMeshBackground(
        child: AnimatedBuilder(
          animation: Listenable.merge([_intro, _ambient]),
          builder: (context, _) => Center(child: _hero(isDark)),
        ),
      ),
    );
  }

  Widget _hero(bool isDark) {
    final pulse = (math.sin(_ambient.value * 2 * math.pi) + 1) / 2; // 0..1
    final breathe = math.sin(_ambient.value * 2 * math.pi);
    // Small pop as the mark completes, then back to rest.
    final settle = 1 + 0.04 * math.sin(math.pi * _bloom.value);
    // The ambient life (breathe + float) starts once the mark is whole.
    final alive = _bloom.value;

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft glow halo — blooms once the mark completes, then pulses.
          Opacity(
            opacity: (_bloom.value * (isDark ? 0.55 : 0.7)).clamp(0.0, 1.0),
            child: Transform.scale(
              scale: (0.75 + 0.25 * _bloom.value) * (0.94 + 0.12 * pulse),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AuraColors.rose.withValues(alpha: 0.32),
                      AuraColors.lavenderSoft.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // The mark itself, drawing directly on the screen.
          Transform.translate(
            offset: Offset(0, -4.0 * breathe * alive),
            child: Transform.scale(
              scale:
                  _canvasScale.value * settle * (1 + 0.015 * breathe * alive),
              child: Opacity(
                opacity: _canvasFade.value.clamp(0.0, 1.0),
                child: CustomPaint(
                  size: const Size.square(250),
                  painter: _LogoDrawPainter(
                    moon: _moonDraw.value,
                    drop: _dropDraw.value,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Routing helpers -----------------------------------------------------

  bool _hasEmailAccount(User? user) {
    if (user == null) return false;
    final email = user.email?.trim();
    return email != null && email.isNotEmpty && !user.isAnonymous;
  }

  bool _canEnterHome(bool onboardingDone, User? user) {
    if (_hasEmailAccount(user)) return true;
    return onboardingDone;
  }
}

/// Draws the brand mark as its two real pen strokes so it can assemble
/// itself exactly as the artwork is constructed.
///
/// [moon] trims the crescent's stroke: from its small cut tip, through the
/// lightning kink, down the concave edge and around to the horn tip.
/// [drop] trims the single unbroken drop stroke, which begins at that very
/// horn tip, rises along the crescent's outer edge (completing the moon),
/// bends at the apex and sweeps the whole teardrop around to the angled
/// cut on the upper left.
///
/// Every point was measured from assets/icon/app_icon.png scanlines
/// (0–100 frame), so the finished strokes reproduce the original mark.
class _LogoDrawPainter extends CustomPainter {
  _LogoDrawPainter({
    required this.moon,
    required this.drop,
    required this.isDark,
  });

  final double moon;
  final double drop;
  final bool isDark;

  /// Original artwork gradient (salmon → pink → lavender).
  static const _strokeColorsDark = [
    Color(0xFFF2A6AC),
    Color(0xFFEB9FC1),
    Color(0xFFC9A5DE),
  ];

  /// Same hues, deepened so the mark stays crisp on the pale light-mode mesh.
  static const _strokeColorsLight = [
    Color(0xFFE0868F),
    Color(0xFFD97BA9),
    Color(0xFFA87BD0),
  ];

  /// The moon stroke: cut tip → lightning kink → concave edge → horn tip.
  static const _moonPts = [
    Offset(43.6, 42.6), Offset(42.9, 43.5), Offset(42.2, 44.3),
    Offset(41.4, 45.2), Offset(40.6, 46.0), Offset(38.3, 46.7),
    Offset(42.0, 47.3), Offset(41.6, 48.2), Offset(41.2, 49.0),
    Offset(40.8, 50.0), Offset(40.4, 51.2), Offset(40.1, 52.6),
    Offset(39.9, 54.0), Offset(39.8, 55.5), Offset(39.9, 57.0),
    Offset(40.1, 58.5), Offset(40.5, 60.0), Offset(41.1, 61.7),
    Offset(42.0, 63.3), Offset(43.1, 64.9), Offset(44.5, 66.3),
    Offset(46.2, 67.7), Offset(48.2, 68.9), Offset(50.4, 70.0),
    Offset(52.4, 71.2), Offset(53.9, 72.4), Offset(54.9, 73.5),
    Offset(55.2, 74.4),
  ];

  /// The drop stroke: horn tip → up the crescent's outer edge → apex →
  /// right side → bottom circle → left side → angled cut.
  static const _dropPts = [
    Offset(55.4, 74.1), Offset(56.1, 72.9), Offset(56.7, 71.7),
    Offset(57.4, 70.4), Offset(58.1, 69.1), Offset(58.7, 68.0),
    Offset(59.0, 66.9), Offset(59.4, 65.5), Offset(59.7, 64.0),
    Offset(59.9, 62.4), Offset(59.8, 60.9), Offset(59.5, 59.3),
    Offset(59.1, 57.6), Offset(58.5, 56.1), Offset(57.9, 54.7),
    Offset(57.0, 53.2), Offset(56.0, 51.8), Offset(55.3, 50.8),
    Offset(54.5, 49.8), Offset(53.6, 48.8), Offset(52.8, 47.9),
    Offset(52.1, 47.1), Offset(51.5, 46.4), Offset(50.8, 45.7),
    Offset(50.1, 44.9), Offset(49.2, 43.9), Offset(48.4, 43.0),
    Offset(47.6, 42.0), Offset(46.9, 41.0), Offset(45.9, 39.5),
    Offset(45.0, 38.1), Offset(44.5, 36.8), Offset(44.0, 35.5),
    Offset(43.9, 34.3), Offset(44.1, 33.0), Offset(44.3, 32.0),
    Offset(45.0, 30.3), Offset(45.8, 29.3), Offset(46.5, 28.3),
    Offset(47.2, 27.3), Offset(48.1, 26.0), Offset(49.0, 24.3),
    Offset(49.6, 23.0), Offset(50.0, 21.7), Offset(50.5, 22.6),
    Offset(51.1, 23.9), Offset(51.8, 26.0), Offset(52.4, 27.0),
    Offset(53.2, 28.1), Offset(54.1, 29.3), Offset(55.2, 30.7),
    Offset(56.3, 32.2), Offset(57.4, 33.7), Offset(58.5, 35.2),
    Offset(59.6, 36.6), Offset(60.7, 38.1), Offset(61.7, 39.5),
    Offset(62.7, 41.0), Offset(63.4, 42.0), Offset(64.0, 43.0),
    Offset(64.6, 44.0), Offset(65.1, 44.9), Offset(65.9, 46.4),
    Offset(66.6, 47.9), Offset(67.4, 49.8), Offset(68.0, 51.8),
    Offset(68.4, 53.2), Offset(68.8, 54.7), Offset(69.0, 57.6),
    Offset(68.8, 60.5), Offset(68.2, 63.5), Offset(67.6, 65.0),
    Offset(67.0, 66.4), Offset(66.2, 68.0), Offset(65.4, 69.0),
    Offset(64.6, 70.0), Offset(63.8, 71.0), Offset(62.7, 72.0),
    Offset(61.4, 73.0), Offset(59.9, 74.0), Offset(58.9, 74.6),
    Offset(57.4, 75.5), Offset(55.5, 76.1), Offset(53.2, 76.5),
    Offset(50.6, 76.7), Offset(48.0, 76.6), Offset(45.6, 76.3),
    Offset(43.4, 75.7), Offset(41.5, 74.8), Offset(39.9, 74.0),
    Offset(38.4, 73.0), Offset(37.2, 72.0), Offset(36.2, 71.0),
    Offset(35.3, 70.0), Offset(34.5, 69.0), Offset(33.7, 68.0),
    Offset(33.2, 67.0), Offset(32.9, 66.4), Offset(32.2, 65.0),
    Offset(31.7, 63.5), Offset(31.3, 62.0), Offset(31.1, 60.5),
    Offset(31.0, 59.0), Offset(31.0, 57.6), Offset(31.1, 56.2),
    Offset(31.3, 54.7), Offset(31.8, 53.2), Offset(32.4, 51.8),
    Offset(32.9, 50.8), Offset(33.5, 49.8), Offset(33.8, 48.8),
    Offset(34.2, 47.6), Offset(34.5, 46.6), Offset(34.9, 45.6),
    Offset(35.3, 44.5), Offset(35.9, 43.0), Offset(36.5, 42.0),
    Offset(37.2, 41.0), Offset(37.9, 39.9), Offset(38.6, 38.9),
    Offset(39.2, 38.1), Offset(39.6, 37.0), Offset(39.8, 36.0),
    Offset(40.2, 35.0), Offset(40.5, 34.0), Offset(40.6, 33.7),
  ];

  /// Indices that must stay sharp: the moon's lightning kink and the
  /// drop's apex point. Everything else gets smoothed.
  static const _moonCorners = {5, 6};
  static const _dropCorners = {43};

  /// One 1-2-1 smoothing pass over the measured points; endpoints and
  /// pinned corners keep their exact measured position. This removes the
  /// scanline jitter that made the raw polyline look patchy.
  static List<Offset> _relax(List<Offset> pts, Set<int> pinned) {
    final out = List.of(pts);
    for (var i = 1; i < pts.length - 1; i++) {
      if (pinned.contains(i)) continue;
      out[i] = Offset(
        (pts[i - 1].dx + 2 * pts[i].dx + pts[i + 1].dx) / 4,
        (pts[i - 1].dy + 2 * pts[i].dy + pts[i + 1].dy) / 4,
      );
    }
    return out;
  }

  static final _moonSmooth =
      _relax(_relax(_moonPts, _moonCorners), _moonCorners);
  static final _dropSmooth =
      _relax(_relax(_dropPts, _dropCorners), _dropCorners);

  /// Catmull-Rom spline through the smoothed points → one flowing cubic
  /// path. At pinned corners the handles collapse so the angle stays crisp.
  Path _spline(List<Offset> pts, Set<int> corners, double s) {
    Offset at(int i) {
      final j = i < 0 ? 0 : (i >= pts.length ? pts.length - 1 : i);
      return Offset(pts[j].dx * s / 100, pts[j].dy * s / 100);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final p2 = at(i + 1);
      final p3 = at(i + 2);
      var c1 = p1 + (p2 - p0) / 6;
      var c2 = p2 - (p3 - p1) / 6;
      if (corners.contains(i)) c1 = p1;
      if (corners.contains(i + 1)) c2 = p2;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.032
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark ? _strokeColorsDark : _strokeColorsLight,
      ).createShader(Offset.zero & size);

    _drawTrimmed(canvas, _spline(_moonSmooth, _moonCorners, s), moon, paint);
    _drawTrimmed(canvas, _spline(_dropSmooth, _dropCorners, s), drop, paint);
  }

  void _drawTrimmed(Canvas canvas, Path path, double t, Paint paint) {
    if (t <= 0) return;
    if (t >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(_LogoDrawPainter oldDelegate) =>
      oldDelegate.moon != moon ||
      oldDelegate.drop != drop ||
      oldDelegate.isDark != isDark;
}
