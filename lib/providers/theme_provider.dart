import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService = SettingsService();

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final modeInt = await _settingsService.getThemeMode();
    state = _intToThemeMode(modeInt);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await _settingsService.setThemeMode(_themeModeToInt(mode));
  }

  ThemeMode _intToThemeMode(int value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int _themeModeToInt(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      default:
        return 0;
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
