import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_design_tokens.dart';

/// Legacy alias — use [AuraColors] for new code.
class AppColors {
  static const primary = AuraColors.rose;
  static const secondary = AuraColors.lavenderSoft;
  static const accent = AuraColors.peachGold;
  static const surface = AuraColors.cream;
  static const darkSurface = AuraColors.darkBg;
  static const darkCard = AuraColors.darkCard;
}

class AppTheme {
  static ThemeData light(Locale locale) => _build(locale, Brightness.light);

  static ThemeData dark(Locale locale) => _build(locale, Brightness.dark);

  static ThemeData _build(Locale locale, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = isDark ? _darkScheme : _lightScheme;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      // 2026 motion: soft fade + slight upward settle on every route push.
      // iOS keeps the native Cupertino transition so swipe-back still works.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AuraPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: _AuraPageTransitionsBuilder(),
          TargetPlatform.macOS: _AuraPageTransitionsBuilder(),
          TargetPlatform.linux: _AuraPageTransitionsBuilder(),
        },
      ),
      textTheme: _textTheme(base.textTheme, scheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        color: isDark
            ? AuraColors.darkCard.withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.75),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AuraColors.rose.withValues(alpha: 0.15),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AuraColors.rose.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? scheme.primary : AuraColors.accentDeep,
          foregroundColor: isDark ? AuraColors.darkBg : Colors.white,
          // Calm-premium: flatter buttons with a whisper of a shadow instead of
          // a strong berry glow, so labels lead and the accent stays contained.
          elevation: 1,
          shadowColor: AuraColors.accent.withValues(alpha: 0.22),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.6), width: 1.6),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          textStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? scheme.primary : AuraColors.accentDeep,
        foregroundColor: isDark ? AuraColors.darkBg : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.35),
        thickness: 1,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
        selectedColor:
            (isDark ? AuraColors.darkRose : AuraColors.accent).withValues(alpha: 0.20),
        checkmarkColor: isDark ? AuraColors.darkRose : AuraColors.accentDeep,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor:
              isDark ? scheme.primary : AuraColors.accentDeep,
          selectedForegroundColor: isDark ? AuraColors.darkBg : Colors.white,
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        backgroundColor: isDark ? AuraColors.darkCard : AuraColors.plum,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AuraColors.darkCard : AuraColors.cream,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w500, fontSize: 13),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AuraColors.darkCard : AuraColors.cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: isDark ? AuraColors.darkCard : AuraColors.cream,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor:
            isDark ? AuraColors.darkBgMid : AuraColors.accentDeep,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        todayBorder: const BorderSide(color: AuraColors.accent, width: 1.4),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AuraColors.accentDeep
              : null,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? Colors.white : null,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AuraColors.accentDeep,
        ),
      ),
    );
  }

  static ColorScheme get _lightScheme => ColorScheme.light(
        primary: AuraColors.roseDeep,
        onPrimary: Colors.white,
        primaryContainer: AuraColors.blush,
        onPrimaryContainer: AuraColors.plum,
        secondary: AuraColors.lavenderSoft,
        onSecondary: AuraColors.plum,
        secondaryContainer: AuraColors.lavender.withValues(alpha: 0.4),
        tertiary: AuraColors.peachGold,
        onTertiary: AuraColors.plum,
        surface: AuraColors.cream,
        onSurface: AuraColors.plum,
        onSurfaceVariant: AuraColors.inkSoft,
        outline: AuraColors.rose.withValues(alpha: 0.3),
        outlineVariant: AuraColors.lavender.withValues(alpha: 0.4),
      );

  static ColorScheme get _darkScheme => ColorScheme.dark(
        primary: AuraColors.darkRose,
        onPrimary: AuraColors.darkBg,
        primaryContainer: AuraColors.darkCard,
        onPrimaryContainer: AuraColors.darkCream,
        secondary: AuraColors.lavenderSoft,
        onSecondary: AuraColors.darkBg,
        secondaryContainer: AuraColors.darkBgMid,
        tertiary: AuraColors.peachGold,
        onTertiary: AuraColors.darkBg,
        surface: AuraColors.darkBg,
        onSurface: AuraColors.darkCream,
        onSurfaceVariant: AuraColors.darkCream.withValues(alpha: 0.65),
        outline: AuraColors.darkRose.withValues(alpha: 0.25),
        outlineVariant: Colors.white.withValues(alpha: 0.1),
      );

  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    return GoogleFonts.cairoTextTheme(base).copyWith(
      displayLarge: GoogleFonts.cairo(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -1,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.cairo(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.8,
        height: 1.05,
      ),
      displaySmall: GoogleFonts.cairo(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineSmall: GoogleFonts.cairo(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        letterSpacing: -0.3,
      ),
      titleLarge: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: GoogleFonts.cairo(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.cairo(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
        height: 1.45,
      ),
      labelLarge: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );
  }

  static BoxDecoration gradientBackground([BuildContext? context]) {
    final isDark = context != null &&
        Theme.of(context).brightness == Brightness.dark;
    return AuraDecorations.meshBackground(isDark);
  }
}

/// 2026-feel route transition: the incoming page fades in while settling
/// up from a few pixels below — quicker and softer than the stock zoom.
class _AuraPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AuraPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Comfort: honour the OS "reduce motion" accessibility setting.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
