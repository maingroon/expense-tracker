import 'package:flutter/material.dart';
import 'package:expense_tracker/services/settings_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;

  ThemeProvider() : _themeMode = SettingsService.getThemeMode();

  ThemeMode getThemeMode() {
    return _themeMode;
  }

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    SettingsService.setThemeMode(themeMode);
    notifyListeners();
  }

  Brightness getCurrentBrightness() {
    if (_themeMode == ThemeMode.light) {
      return Brightness.light;
    } else if (_themeMode == ThemeMode.dark) {
      return Brightness.dark;
    } else {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  List<Shadow> getIconsShadows() {
    return [
      Shadow(
        blurRadius: 5,
        color: getCurrentBrightness() == Brightness.light
            ? Colors.grey.withValues(alpha: 0.7)
            : Colors.black.withValues(alpha: 0.7),
        offset: const Offset(1, 1),
      ),
    ];
  }
}
