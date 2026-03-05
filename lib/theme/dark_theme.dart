import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0F1117),
  cardColor: const Color(0xFF1C1F2E),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF2F80ED),
    onPrimary: Colors.white,
    secondary: Color(0xFF2F80ED),
    surface: Color(0xFF1C1F2E),
    onSurface: Colors.white,
    outline: Color(0xFF374151),
  ),
  textTheme: GoogleFonts.outfitTextTheme(
    ThemeData.dark().textTheme,
  ).apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F1117),
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
);
