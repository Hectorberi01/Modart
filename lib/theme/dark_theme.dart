import 'package:flutter/material.dart';
import 'app_theme.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: SmartSoleColors.darkBg,
  cardColor: SmartSoleColors.darkCard,
  colorScheme: const ColorScheme.dark(
    primary: SmartSoleColors.biNormal,
    onPrimary: Colors.white,
    secondary: SmartSoleColors.biTeal,
    tertiary: SmartSoleColors.biNavy,
    surface: SmartSoleColors.darkSurface,
    onSurface: SmartSoleColors.textPrimaryDark,
    error: SmartSoleColors.biAlert,
    outline: Color(0xFF1E293B),
  ),
  textTheme: SmartSoleTheme.textTheme(Brightness.dark),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
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
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
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
  dividerTheme: const DividerThemeData(color: Color(0xFF1E293B), thickness: 0.5),
  iconTheme: const IconThemeData(color: SmartSoleColors.textSecondaryDark, size: 22),
);
