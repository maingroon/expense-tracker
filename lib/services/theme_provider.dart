import 'package:flutter/material.dart';
import 'package:expense_tracker/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeMode _themeMode;

  ThemeProvider() {
    _themeMode = ThemeMode.system;
    setPersistentTheme();
  }

  setPersistentTheme() async {
    _themeMode = SettingsService.getThemeMode();
    notifyListeners();
  }

  ThemeMode getThemeMode() {
    return _themeMode;
  }

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    SettingsService.setThemeMode(themeMode);
    notifyListeners();
  }
}
