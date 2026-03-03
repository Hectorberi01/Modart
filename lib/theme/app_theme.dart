import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SmartSole Design System — "Biomechanics Observatory"
//
// Palette BI dynamique : vert (normal) → ambre (vigilance) → rouge (alerte)
// Dark mode par défaut, mesh gradients, glassmorphism, bento grid, typo bold.
// ─────────────────────────────────────────────────────────────────────────────

/// État BI d'un indicateur — détermine la couleur contextuelle.
enum BIState { normal, warning, alert, neutral, teal }

/// Palette de couleurs SmartSole.
abstract final class SmartSoleColors {
  // ── Palette BI dynamique ──────────────────────────────────────────────────
  static const Color biNormal = Color(0xFF1A7A4A); // Vert doux
  static const Color biWarning = Color(0xFFB85C00); // Ambre vigilance
  static const Color biAlert = Color(0xFFC0392B); // Rouge alerte
  static const Color biTeal = Color(0xFF0E6655); // Profil Enfant / Pro
  static const Color biNavy = Color(0xFF1A3C5E); // Neutre navbar

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1A1F2E);
  static const Color lightBg = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  // ── Glassmorphism ─────────────────────────────────────────────────────────
  static const Color glassBgDark = Color(0x1AFFFFFF); // 10% blanc
  static const Color glassBgLight = Color(0x33FFFFFF); // 20% blanc
  static const Color glassBorder = Color(0x33FFFFFF); // 20% blanc

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF6B7280);

  // ── Mesh gradient ─────────────────────────────────────────────────────────
  static const Color meshGreen = Color(0xFF0D4D2F);
  static const Color meshBlue = Color(0xFF0E3357);
  static const Color meshPurple = Color(0xFF2D1B4E);
  static const Color meshTeal = Color(0xFF0A4D4D);

  /// Retourne la couleur BI pour un état donné.
  static Color colorForState(BIState state) {
    return switch (state) {
      BIState.normal => biNormal,
      BIState.warning => biWarning,
      BIState.alert => biAlert,
      BIState.teal => biTeal,
      BIState.neutral => biNavy,
    };
  }

  /// Retourne la couleur BI avec un glow adapté (pour les fonds).
  static Color glowForState(BIState state) {
    return colorForState(state).withValues(alpha: 0.3);
  }
}

/// Constantes de design SmartSole.
abstract final class SmartSoleDesign {
  static const double borderRadius = 20.0;
  static const double borderRadiusSm = 12.0;
  static const double borderRadiusLg = 28.0;
  static const double blurSigma = 12.0;
  static const double cardPadding = 16.0;
  static const double cardPaddingLg = 24.0;
  static const double glassBorderWidth = 1.0;

  /// BoxDecoration glassmorphism pour dark mode.
  static BoxDecoration glassDecorationDark({Color? accentColor}) {
    return BoxDecoration(
      color: SmartSoleColors.glassBgDark,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color:
            accentColor?.withValues(alpha: 0.3) ?? SmartSoleColors.glassBorder,
        width: glassBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// BoxDecoration glassmorphism pour light mode.
  static BoxDecoration glassDecorationLight({Color? accentColor}) {
    return BoxDecoration(
      color: SmartSoleColors.glassBgLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: accentColor?.withValues(alpha: 0.15) ?? const Color(0x22000000),
        width: glassBorderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

/// Thème complet SmartSole (dark + light).
class SmartSoleTheme {
  SmartSoleTheme._();

  // ── Dark Theme (défaut) ───────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: SmartSoleColors.darkBg,
      cardColor: SmartSoleColors.darkCard,
      colorScheme: const ColorScheme.dark(
        primary: SmartSoleColors.biNormal,
        onPrimary: Colors.white,
        secondary: SmartSoleColors.biTeal,
        surface: SmartSoleColors.darkSurface,
        onSurface: SmartSoleColors.textPrimaryDark,
        outline: SmartSoleColors.glassBorder,
        error: SmartSoleColors.biAlert,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: SmartSoleColors.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: SmartSoleColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SmartSoleColors.darkSurface,
        selectedItemColor: SmartSoleColors.biNormal,
        unselectedItemColor: SmartSoleColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartSoleColors.biNormal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: SmartSoleColors.glassBorder.withValues(alpha: 0.1),
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: SmartSoleColors.lightBg,
      cardColor: SmartSoleColors.lightCard,
      colorScheme: const ColorScheme.light(
        primary: SmartSoleColors.biNormal,
        onPrimary: Colors.white,
        secondary: SmartSoleColors.biTeal,
        surface: SmartSoleColors.lightSurface,
        onSurface: SmartSoleColors.textPrimaryLight,
        outline: Color(0xFFE5E7EB),
        error: SmartSoleColors.biAlert,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: const AppBarTheme(
        backgroundColor: SmartSoleColors.lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: SmartSoleColors.textPrimaryLight),
        titleTextStyle: TextStyle(
          color: SmartSoleColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SmartSoleColors.lightSurface,
        selectedItemColor: SmartSoleColors.biNormal,
        unselectedItemColor: SmartSoleColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SmartSoleColors.biNormal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E7EB)),
    );
  }

  // ── Text Theme ────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color primary =
        isDark
            ? SmartSoleColors.textPrimaryDark
            : SmartSoleColors.textPrimaryLight;
    final Color secondary =
        isDark
            ? SmartSoleColors.textSecondaryDark
            : SmartSoleColors.textSecondaryLight;

    // Outfit pour les titres et chiffres (bold, éditorial)
    final TextTheme outfitTheme = GoogleFonts.outfitTextTheme();
    // Inter pour le body text (lisibilité)
    final TextTheme interTheme = GoogleFonts.interTextTheme();

    return TextTheme(
      // Les "chiffres clés" — Outfit bold éditorial
      displayLarge: outfitTheme.displayLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w800,
        fontSize: 72,
        letterSpacing: -2,
        height: 1.0,
      ),
      displayMedium: outfitTheme.displayMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 48,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displaySmall: outfitTheme.displaySmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 36,
        letterSpacing: -1,
        height: 1.1,
      ),
      // Titres
      headlineLarge: outfitTheme.headlineLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w700,
        fontSize: 24,
        letterSpacing: -0.5,
      ),
      headlineMedium: outfitTheme.headlineMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
      headlineSmall: outfitTheme.headlineSmall?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      // Titres de carte
      titleLarge: outfitTheme.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      titleMedium: outfitTheme.titleMedium?.copyWith(
        color: primary,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      titleSmall: outfitTheme.titleSmall?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      // Body — Inter pour lisibilité
      bodyLarge: interTheme.bodyLarge?.copyWith(
        color: primary,
        fontSize: 16,
        height: 1.5,
      ),
      bodyMedium: interTheme.bodyMedium?.copyWith(
        color: primary,
        fontSize: 14,
        height: 1.5,
      ),
      bodySmall: interTheme.bodySmall?.copyWith(
        color: secondary,
        fontSize: 12,
        height: 1.4,
      ),
      // Labels
      labelLarge: interTheme.labelLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      labelMedium: interTheme.labelMedium?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
      labelSmall: interTheme.labelSmall?.copyWith(
        color: secondary,
        fontWeight: FontWeight.w400,
        fontSize: 10,
      ),
    );
  }
}
