import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_design_tokens.dart';
import '../theme/app_theme.dart';

/// Full-screen mesh gradient background wrapper.
class AppMeshBackground extends StatelessWidget {
  const AppMeshBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: AppTheme.gradientBackground(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                PositionedDirectional(
                  top: -120,
                  end: -90,
                  child: _MeshGlow(
                    size: 330,
                    color: isDark
                        ? AuraColors.darkRose.withValues(alpha: 0.20)
                        : AuraColors.rose.withValues(alpha: 0.32),
                  ),
                ),
                PositionedDirectional(
                  top: 235,
                  start: -145,
                  child: _MeshGlow(
                    size: 360,
                    color: isDark
                        ? AuraColors.lavender.withValues(alpha: 0.12)
                        : AuraColors.lavenderSoft.withValues(alpha: 0.28),
                  ),
                ),
                PositionedDirectional(
                  bottom: -160,
                  end: -95,
                  child: _MeshGlow(
                    size: 390,
                    color: isDark
                        ? AuraColors.peachGold.withValues(alpha: 0.08)
                        : AuraColors.peach.withValues(alpha: 0.20),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MeshGlow extends StatelessWidget {
  const _MeshGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}

/// Full-screen scaffold for pushed settings/detail pages: transparent app
/// bar over the mesh gradient — the same shell as the modern account
/// screens, so legacy menstrudel pages read as one app with the rest of
/// Lune. Visual wrapper only; pass the existing body through unchanged.
class AuraSettingsScaffold extends StatelessWidget {
  const AuraSettingsScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.centerTitle,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool? centerTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        centerTitle: centerTitle,
        leading: leading,
        actions: actions,
      ),
      extendBodyBehindAppBar: true,
      body: AppMeshBackground(child: SafeArea(child: body)),
    );
  }
}

/// Unified scaffold with mesh background and safe area.
class AuraScaffold extends StatelessWidget {
  const AuraScaffold({
    super.key,
    required this.body,
    this.padding,
    this.bottomPadding = 100,
  });

  final Widget body;
  final EdgeInsetsGeometry? padding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return AppMeshBackground(
      child: SafeArea(
        child: Padding(
          padding:
              padding ??
              EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                bottomPadding,
              ),
          child: body,
        ),
      ),
    );
  }
}

/// Glass morphism card container.
class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.onTap,
    this.margin,
    this.blur = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  /// Disable blur for heavy widgets (calendars, logs) to avoid freezes on device.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = AuraDecorations.glassWrapper(
      isDark: isDark,
      radius: radius,
      padding: padding,
      blur: blur,
      child: child,
    );

    if (margin != null) {
      return Padding(padding: margin!, child: _wrapTap(content));
    }
    return _wrapTap(content);
  }

  Widget _wrapTap(Widget child) {
    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

/// A genuinely translucent, high-blur surface for floating controls.
///
/// Use this for composers, compact toolbars, filters, and other elements that
/// sit above content. Standard feed cards should keep using [AppGlassCard] so
/// the interface stays readable and avoids stacking expensive blur layers.
class AppFloatingGlassPanel extends StatelessWidget {
  const AppFloatingGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.tint,
    this.gradient,
    this.highlighted = false,
    this.onTap,
    this.blurSigma = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? tint;
  final Gradient? gradient;
  final bool highlighted;
  final VoidCallback? onTap;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = tint ?? theme.colorScheme.primary;
    final borderColor = highlighted
        ? accent.withValues(alpha: isDark ? 0.62 : 0.48)
        : (isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.68));

    final glass = RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: (highlighted ? accent : Colors.black).withValues(
                alpha: highlighted
                    ? (isDark ? 0.16 : 0.10)
                    : (isDark ? 0.28 : 0.075),
              ),
              blurRadius: highlighted ? 24 : 20,
              offset: const Offset(0, 8),
              spreadRadius: -7,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient:
                    gradient ??
                    LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              AuraColors.darkCard.withValues(alpha: 0.68),
                              AuraColors.darkCard.withValues(alpha: 0.46),
                              accent.withValues(alpha: 0.12),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.64),
                              Colors.white.withValues(alpha: 0.38),
                              accent.withValues(alpha: 0.09),
                            ],
                      stops: const [0, 0.68, 1],
                    ),
                border: Border.all(
                  color: borderColor,
                  width: highlighted ? 1.4 : 1,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (onTap == null) return glass;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: glass,
      ),
    );
  }
}

/// Floating glass shell for the app's short modal option sheets.
class AppGlassSheetSurface extends StatelessWidget {
  const AppGlassSheetSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 10, 18, 22),
    this.showHandle = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: AppFloatingGlassPanel(
          radius: AppRadius.xl,
          tint: theme.colorScheme.primary,
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) ...[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.30,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary call-to-action button — bold berry pill with a glow and a
/// tactile press-scale. This is the app's signature 2026 button.
class AppGradientButton extends StatefulWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final bool loading;

  @override
  State<AppGradientButton> createState() => _AppGradientButtonState();
}

class _AppGradientButtonState extends State<AppGradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.loading && widget.onPressed != null;

    void setPressed(bool v) {
      if (_pressed != v) setState(() => _pressed = v);
    }

    final button = AnimatedScale(
      scale: _pressed ? 0.965 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AuraDecorations.ctaGradient,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: [
            // Calm-premium: the berry glow is dialled back ~60% (0.45→0.18) and
            // the blur tightened so the button reads as a solid pill with a
            // gentle lift, not a neon halo.
            BoxShadow(
              color: AuraColors.accent.withValues(alpha: enabled ? 0.18 : 0.06),
              blurRadius: _pressed ? 8 : 14,
              offset: Offset(0, _pressed ? 3 : 6),
              spreadRadius: -2,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  }
                : null,
            onTapDown: enabled ? (_) => setPressed(true) : null,
            onTapUp: enabled ? (_) => setPressed(false) : null,
            onTapCancel: enabled ? () => setPressed(false) : null,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Row(
                mainAxisSize: widget.expanded
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else ...[
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return widget.expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}

/// Phase / status badge pill.
class AppPhaseBadge extends StatelessWidget {
  const AppPhaseBadge({
    super.key,
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [
                  AuraColors.rose.withValues(alpha: isDark ? 0.35 : 0.25),
                  AuraColors.lavender.withValues(alpha: isDark ? 0.25 : 0.2),
                ],
              )
            : null,
        color: highlight
            ? null
            : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.65)),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: highlight
              ? AuraColors.rose.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
