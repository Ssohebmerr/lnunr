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

  // ── 2026 refresh: a decisive accent + ink tones for hierarchy & contrast ──
  /// Vivid berry-rose — the single colour that "pops" for primary actions.
  static const accent = Color(0xFFD84A83);

  /// Deeper accent placed behind white text so it clears WCAG AA (~5.4:1).
  static const accentDeep = Color(0xFFC02E6A);

  /// Near-black plum for high-contrast headings.
  static const ink = Color(0xFF3A2633);

  /// AA-safe secondary text — replaces the too-light plumMuted on tinted cards.
  static const inkSoft = Color(0xFF6E5561);

  // ── Semantic tones — the single source of truth for status colours.
  // Raw Material greens/reds/ambers clashed with the soft palette; these are
  // tuned to sit comfortably next to rose/lavender while staying legible.
  static const success = Color(0xFF4CAF7D);
  static const warning = Color(0xFFF0B429);
  static const danger = Color(0xFFD64550);

  /// Streak-fire accent (challenges, rituals) — warm ember, not raw orange.
  static const ember = Color(0xFFE0764A);

  /// Points / rewards star — soft gold, not raw amber.
  static const gold = Color(0xFFDD9A2B);

  // Dark palette
  static const darkBg = Color(0xFF1E1420);
  static const darkBgMid = Color(0xFF2A1A2E);
  static const darkBgDeep = Color(0xFF161018);
  static const darkRose = Color(0xFFF0B4C8);
  static const darkCream = Color(0xFFFFF5F7);
  static const darkCard = Color(0xFF2E2032);

  static const gradientRoseLavender = [rose, lavenderSoft];
  static const gradientPeachRose = [peachGold, rose];
  static const gradientPremium = [
    Color(0xFFFFCDB2),
    Color(0xFFE8A0BF),
    lavenderSoft,
  ];
  static const gradientCta = [accent, accentDeep];
  static const gradientAccent = [accent, Color(0xFFF06AA0)];
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
      color: (isDark ? AuraColors.darkRose : AuraColors.rose).withValues(
        alpha: isDark ? 0.2 : 0.18,
      ),
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
          colors: [AuraColors.darkBgDeep, AuraColors.darkBg, Color(0xFF241827)],
          stops: [0.0, 0.58, 1.0],
        ),
      );
    }
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBF9), Color(0xFFFFF5F8), Color(0xFFF8F3FC)],
        stops: [0.0, 0.55, 1.0],
      ),
    );
  }

  static BoxDecoration glassCard({
    required bool isDark,
    double radius = AppRadius.lg,
    Color? tint,
  }) {
    final surfaceColor = tint != null
        ? tint.withValues(alpha: isDark ? 0.14 : 0.16)
        : (isDark
              ? AuraColors.darkCard.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.94));
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: surfaceColor,
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : AuraColors.plum.withValues(alpha: 0.06),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : AuraColors.plum).withValues(
            alpha: isDark ? 0.24 : 0.055,
          ),
          blurRadius: 14,
          offset: const Offset(0, 6),
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
      return Container(padding: padding, decoration: decoration, child: child);
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

  /// Vivid call-to-action gradient (berry-rose). White text clears WCAG AA on
  /// the darker half — use for primary buttons / FAB, the actions that must pop.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AuraColors.gradientCta,
  );

  /// 2026 focal surface — a clean, low-blur card with a soft accent wash and a
  /// crisp lifted shadow. Replaces heavy glass for hero / headline content.
  static BoxDecoration heroSurface(bool isDark) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF37263A), AuraColors.darkCard]
            : [Colors.white, const Color(0xFFFFF2F7)],
      ),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.9),
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : AuraColors.accent).withValues(
            alpha: isDark ? 0.28 : 0.10,
          ),
          blurRadius: 20,
          offset: const Offset(0, 9),
        ),
      ],
    );
  }

  /// Clean solid-ish card for 2026 — minimal blur, crisp small shadow. Use as a
  /// lighter alternative to [glassCard] where blur costs more than it gives.
  static BoxDecoration softCard(bool isDark, {double radius = AppRadius.lg}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: isDark
          ? AuraColors.darkCard.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.9),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : AuraColors.plum.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: (isDark ? Colors.black : AuraColors.plum).withValues(
            alpha: isDark ? 0.28 : 0.06,
          ),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

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
          ? Icon(
              prefixIcon,
              size: 20,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AuraColors.plumMuted,
            )
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
