import 'package:flutter/material.dart';

class AppSettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const AppSettingsState({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('fr'),
  });

  AppSettingsState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}
