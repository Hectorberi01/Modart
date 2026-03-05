import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'dark_theme.dart';
export 'light_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmartSole Design System v2 — "Biomechanics Observatory"
// Adapted for Modart with Google Fonts Outfit
// ─────────────────────────────────────────────────────────────────────────────

enum BIState { normal, warning, alert, neutral, teal, navy }

abstract final class SmartSoleColors {
  // Backgrounds
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1A2235);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Palette BI principale
  static const Color biNormal = Color(0xFFE25230);
  static const Color biWarning = Color(0xFFE55C2E);
  static const Color biAlert = Color(0xFFE78E39);
  static const Color biTeal = Color(0xFFE6BF74);
  static const Color biNavy = Color(0xFF6366F1);
  static const Color biSuccess = Color(0xFF22C55E);

  // Accents
  static const Color accent = Color(0xFFE55C2E);
  static const Color accentSoft = Color(0xFFE6BF74);
  static const Color glowGreen = Color(0xFFE78E39);
  static const Color glowCyan = Color(0xFFE6BF74);

  // Text
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // Glass
  static const Color glassDark = Color(0x14FFFFFF);
  static const Color glassBorderDark = Color(0x1AFFFFFF);
  static const Color glassLight = Color(0x0DFFFFFF);
  static const Color glassBorderLight = Color(0x1A000000);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [biNormal, biTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [biNavy, accentSoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFDC2626)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshDarkGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF111827), Color(0xFF0D1B2A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shimmer
  static const Color shimmerBase = Color(0xFF1A2235);
  static const Color shimmerHighlight = Color(0xFF253350);

  // Tooltip
  static const Color tooltipBg = Color(0xF0111827);
  static const Color tooltipBorder = Color(0x40FFFFFF);
  static const double tooltipRadius = 14.0;

  static Color colorForState(BIState state) {
    return switch (state) {
      BIState.normal => biNormal,
      BIState.warning => biWarning,
      BIState.alert => biAlert,
      BIState.teal => biTeal,
      BIState.navy => biNavy,
      BIState.neutral => textSecondaryDark,
    };
  }

  static Color getPressureColor(double v) {
    if (v <= 0.10) return biNormal;
    if (v <= 0.20) return Color.lerp(biNormal, biWarning, (v - 0.10) / 0.10)!;
    if (v <= 0.32) return Color.lerp(biWarning, const Color(0xFFF97316), (v - 0.20) / 0.12)!;
    if (v <= 0.50) return Color.lerp(const Color(0xFFF97316), biAlert, (v - 0.32) / 0.18)!;
    return Color.lerp(biAlert, const Color(0xFFDC2626), ((v - 0.50) / 0.50).clamp(0, 1))!;
  }

  static LinearGradient gradientForState(BIState state) {
    return switch (state) {
      BIState.normal => heroGradient,
      BIState.warning => warmGradient,
      BIState.alert => alertGradient,
      BIState.teal => const LinearGradient(colors: [biTeal, Color(0xFF0EA5E9)]),
      BIState.navy => accentGradient,
      BIState.neutral => const LinearGradient(colors: [textSecondaryDark, textTertiaryDark]),
    };
  }
}

abstract final class SmartSoleDesign {
  static const double borderRadius = 20.0;
  static const double borderRadiusSm = 14.0;
  static const double borderRadiusXs = 10.0;
  static const double blurSigma = 18.0;
  static const double cardElevation = 0.0;

  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  static const Curve animCurve = Curves.easeOutCubic;
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
}

abstract final class SmartSoleTheme {
  static TextTheme textTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary = isDark ? SmartSoleColors.textPrimaryDark : SmartSoleColors.textPrimaryLight;
    final Color secondary = isDark ? SmartSoleColors.textSecondaryDark : SmartSoleColors.textSecondaryLight;

    return GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, color: primary, letterSpacing: -2.5, height: 1.0),
        displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1.5, height: 1.1),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: primary, letterSpacing: -1.0, height: 1.1),
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary, letterSpacing: -0.3),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.2),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: primary, letterSpacing: -0.1),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: primary),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary, letterSpacing: 0.8),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: primary, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primary, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondary, height: 1.4),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary, letterSpacing: 0.3),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.3),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
      ),
    );
  }
}
