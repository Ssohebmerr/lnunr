import 'dart:ui';

import 'package:flutter/material.dart';

/// Soft Premium design tokens for Cycle Aura.
class AuraColors {
  AuraColors._();

  // Light palette
  static const rose = Color(0xFFE8A0BF);
  static const roseDeep = Color(0xFFD484A8);
  static const blush = Color(0xFFFADADD);
  static const peach = Color(0xFFFFD6C9);
  static const peachGold = Color(0xFFFFB4A2);
  static const lavender = Color(0xFFD4C4F0);
  static const lavenderSoft = Color(0xFFC9B8E8);
  static const cream = Color(0xFFFFFBF8);
  static const plum = Color(0xFF5C3D52);
  static const plumMuted = Color(0xFF8B6B7A);

  // Dark palette
  static const darkBg = Color(0xFF1E1420);
  static const darkBgMid = Color(0xFF2A1A2E);
  static const darkBgDeep = Color(0xFF161018);
  static const darkRose = Color(0xFFF0B4C8);
  static const darkCream = Color(0xFFFFF5F7);
  static const darkCard = Color(0xFF2E2032);

  static const gradientRoseLavender = [rose, lavenderSoft];
  static const gradientPeachRose = [peachGold, rose];
  static const gradientPremium = [Color(0xFFFFCDB2), Color(0xFFE8A0BF), lavenderSoft];
}

class AppSpacing {
  AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> softRose({double opacity = 0.12}) => [
        BoxShadow(
          color: AuraColors.rose.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> softPlum({double opacity = 0.08}) => [
        BoxShadow(
          color: AuraColors.plum.withValues(alpha: opacity),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> navFloat(bool isDark) => [
        BoxShadow(
          color: (isDark ? AuraColors.darkRose : AuraColors.rose)
              .withValues(alpha: isDark ? 0.2 : 0.18),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

class AuraDecorations {
  AuraDecorations._();

  static BoxDecoration meshBackground(bool isDark) {
    if (isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AuraColors.darkBgDeep,
            AuraColors.darkBg,
            AuraColors.darkBgMid,
            Color(0xFF241828),
          ],
          stops: [0.0, 0.35, 0.7, 1.0],
        ),
      );
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF8F5),
          Color(0xFFFFF0F5),
          Color(0xFFF5EDFF),
          Color(0xFFFFEDE8),
        ],
        stops: [0.0, 0.3, 0.65, 1.0],
      ),
    );
  }

  static BoxDecoration glassCard({
    required bool isDark,
    double radius = AppRadius.lg,
    Color? tint,
  }) {
    final tintColor = tint ?? (isDark ? Colors.white : Colors.white);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: isDark
          ? tintColor.withValues(alpha: 0.07)
          : tintColor.withValues(alpha: 0.65),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.9),
        width: 1.0,
      ),
      boxShadow: [
        // Soft ambient shadow
        BoxShadow(
          color: (isDark ? AuraColors.darkRose : AuraColors.rose)
              .withValues(alpha: isDark ? 0.12 : 0.08),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
        // Inner highlight (top edge glow)
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.5),
          blurRadius: 0,
          offset: const Offset(0, 1),
          spreadRadius: 0,
        ),
      ],
    );
  }

  static Widget glassWrapper({
    required Widget child,
    required bool isDark,
    double radius = AppRadius.lg,
    EdgeInsetsGeometry? padding,
    bool blur = true,
  }) {
    final decoration = glassCard(isDark: isDark, radius: radius);
    if (!blur) {
      return Container(
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AuraColors.gradientRoseLavender,
  );

  static LinearGradient premiumGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AuraColors.gradientPremium,
  );

  /// Glass-styled input decoration for text fields.
  static InputDecoration glassInput({
    required bool isDark,
    required String hint,
    IconData? prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : AuraColors.plumMuted)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AuraColors.rose.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(
          color: AuraColors.rose.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
    );
  }
}
