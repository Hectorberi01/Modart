import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmartSole Design System v2 — "Biomechanics Observatory"
//
// Palette sombre premium, glassmorphism raffiné, typographie Outfit + Inter,
// couleurs BI dynamiques avec teintes profondes, animations fluides.
// ─────────────────────────────────────────────────────────────────────────────

// ─── BI States ──────────────────────────────────────────────────────────────

enum BIState { normal, warning, alert, neutral, teal, navy }

// ─── Design Tokens ──────────────────────────────────────────────────────────

abstract final class SmartSoleColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0A0E1A); // Bleu nuit profond
  static const Color darkSurface = Color(0xFF111827); // Surface cards
  static const Color darkCard = Color(0xFF1A2235); // Carte légèrement + claire
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // ── Palette BI principale ────────────────────────────────────────────────
  static const Color biNormal = Color(0xFF10B981); // Émeraude vibrant
  static const Color biWarning = Color(0xFFF59E0B); // Ambre chaud
  static const Color biAlert = Color(0xFFEF4444); // Rouge signal
  static const Color biTeal = Color(0xFF06B6D4); // Cyan-teal
  static const Color biNavy = Color(0xFF6366F1); // Indigo pro
  static const Color biSuccess = Color(0xFF22C55E); // Vert franc

  // ── Accents & Highlights ─────────────────────────────────────────────────
  static const Color accent = Color(0xFF818CF8); // Indigo clair
  static const Color accentSoft = Color(0xFF3B82F6); // Bleu doux
  static const Color glowGreen = Color(0xFF34D399); // Lueur verte
  static const Color glowCyan = Color(0xFF22D3EE); // Lueur cyan

  // ── Texte ────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  // ── Glass ────────────────────────────────────────────────────────────────
  static const Color glassDark = Color(0x14FFFFFF); // 8% white
  static const Color glassBorderDark = Color(0x1AFFFFFF); // 10% white
  static const Color glassLight = Color(0x0DFFFFFF);
  static const Color glassBorderLight = Color(0x1A000000);

  // ── Utilitaire BI ────────────────────────────────────────────────────────
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
}

// ─── Design Constants ───────────────────────────────────────────────────────

abstract final class SmartSoleDesign {
  static const double borderRadius = 20.0;
  static const double borderRadiusSm = 14.0;
  static const double borderRadiusXs = 10.0;
  static const double blurSigma = 18.0; // Glassmorphism blur
  static const double cardElevation = 0.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Animation Curves
  static const Curve animCurve = Curves.easeOutCubic;
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
}

// ─── Theme Factory ──────────────────────────────────────────────────────────

abstract final class SmartSoleTheme {
  // ── Dark Theme (défaut) ───────────────────────────────────────────────

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SmartSoleColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: SmartSoleColors.biNormal,
        secondary: SmartSoleColors.biTeal,
        tertiary: SmartSoleColors.biNavy,
        surface: SmartSoleColors.darkSurface,
        error: SmartSoleColors.biAlert,
        onPrimary: Colors.white,
        onSurface: SmartSoleColors.textPrimaryDark,
      ),
      textTheme: _textTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartSoleColors.biNormal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SmartSoleColors.biNormal,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: StadiumBorder(),
      ),
      cardTheme: CardThemeData(
        color: SmartSoleColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: SmartSoleColors.biNormal,
        inactiveTrackColor: SmartSoleColors.biNormal.withValues(alpha: 0.15),
        thumbColor: SmartSoleColors.biNormal,
        trackHeight: 3.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B),
        thickness: 0.5,
      ),
      iconTheme: const IconThemeData(
        color: SmartSoleColors.textSecondaryDark,
        size: 22,
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: SmartSoleColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: SmartSoleColors.biNormal,
        secondary: SmartSoleColors.biTeal,
        tertiary: SmartSoleColors.biNavy,
        surface: SmartSoleColors.lightSurface,
        error: SmartSoleColors.biAlert,
        onPrimary: Colors.white,
        onSurface: SmartSoleColors.textPrimaryLight,
      ),
      textTheme: _textTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartSoleColors.biNormal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: SmartSoleColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
        ),
      ),
    );
  }

  // ── Typography System ─────────────────────────────────────────────────

  static TextTheme _textTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary =
        isDark
            ? SmartSoleColors.textPrimaryDark
            : SmartSoleColors.textPrimaryLight;
    final Color secondary =
        isDark
            ? SmartSoleColors.textSecondaryDark
            : SmartSoleColors.textSecondaryLight;

    return TextTheme(
      // Display — grands chiffres éditoriaux (scores, KPI hero)
      displayLarge: GoogleFonts.outfit(
        fontSize: 72,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -2.5,
        height: 1.0,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -1.0,
        height: 1.1,
      ),
      // Headlines — titres de sections
      headlineLarge: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      // Titles — labels de cards
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.1,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
        letterSpacing: 0.8,
      ),
      // Body — texte courant
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      // Labels — chips, badges
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
