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
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: AppTheme.gradientBackground(context),
      child: child,
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
          padding: padding ??
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

/// Primary gradient button (rose → lavender).
class AppGradientButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onPressed = this.onPressed;
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading || onPressed == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AuraDecorations.ctaGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.softRose(opacity: isDark ? 0.2 : 0.25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else ...[
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
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
          Icon(icon, size: 15, color: theme.colorScheme.primary),
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
