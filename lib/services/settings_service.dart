import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  SettingsService._();

  static late final SharedPreferences _settingsStorage;

  static Future<bool> init() async {
    _settingsStorage = await SharedPreferences.getInstance();
    return true;
  }

  static Future<bool> setThemeMode(ThemeMode themeMode) {
    return _settingsStorage.setInt('themeMode', themeMode.index);
  }

  static ThemeMode getThemeMode() {
    final themeModeIndex =
        _settingsStorage.getInt('themeMode') ?? ThemeMode.system.index;
    return ThemeMode.values[themeModeIndex];
  }
}
