import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyNewCardsPerDay = 'new_cards_per_day';
  
  static const int defaultNewCardsPerDay = 20;

  static const String _keyThemeMode = 'theme_mode'; // 0: System, 1: Light, 2: Dark

  Future<int> getNewCardsPerDay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNewCardsPerDay) ?? defaultNewCardsPerDay;
  }

  Future<void> setNewCardsPerDay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNewCardsPerDay, value);
  }

  Future<int> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyThemeMode) ?? 0;
  }

  Future<void> setThemeMode(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, value);
  }
}
