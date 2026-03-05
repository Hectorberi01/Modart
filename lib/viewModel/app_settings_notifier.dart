import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state/app_settings_state.dart';

class AppSettingsNotifier extends StateNotifier<AppSettingsState> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs)
      : super(AppSettingsState(
          themeMode: _parseThemeMode(_prefs.getString('themeMode')),
          locale: Locale(_prefs.getString('locale') ?? 'fr'),
        ));

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('themeMode', mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString('locale', locale.languageCode);
    state = state.copyWith(locale: locale);
  }
}
