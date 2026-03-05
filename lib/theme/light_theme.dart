import 'package:flutter/material.dart';
import 'app_theme.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: SmartSoleColors.lightBg,
  cardColor: SmartSoleColors.lightSurface,
  colorScheme: const ColorScheme.light(
    primary: SmartSoleColors.biNormal,
    onPrimary: Colors.white,
    secondary: SmartSoleColors.biTeal,
    tertiary: SmartSoleColors.biNavy,
    surface: SmartSoleColors.lightSurface,
    onSurface: SmartSoleColors.textPrimaryLight,
    error: SmartSoleColors.biAlert,
    outline: Color(0xFFE2E8F0),
  ),
  textTheme: SmartSoleTheme.textTheme(Brightness.light),
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
  cardTheme: CardThemeData(
    color: SmartSoleColors.lightSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(SmartSoleDesign.borderRadius),
    ),
  ),
);
