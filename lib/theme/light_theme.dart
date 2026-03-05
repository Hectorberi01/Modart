import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF7F8FA),
  cardColor: Colors.white,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF1C1F2E),
    onPrimary: Colors.white,
    secondary: Color(0xFF2F80ED),
    surface: Colors.white,
    onSurface: Color(0xFF111827),
    outline: Color(0xFFE5E7EB),
  ),
  textTheme: GoogleFonts.outfitTextTheme(
    ThemeData.light().textTheme,
  ).apply(
    bodyColor: const Color(0xFF111827),
    displayColor: const Color(0xFF111827),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF7F8FA),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
);
