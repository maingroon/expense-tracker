import 'package:flutter/material.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:flutter/scheduler.dart';

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

  Brightness getCurrentBrightness() {
    if (_themeMode == ThemeMode.light) {
      return Brightness.light;
    } else if (_themeMode == ThemeMode.dark) {
      return Brightness.dark;
    } else {
      return SchedulerBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  List<Shadow> getIconsShadows() {
    return [
      Shadow(
        blurRadius: 5,
        color: _themeMode == ThemeMode.light
            ? Colors.grey.withOpacity(0.7)
            : Colors.black.withOpacity(0.7),
        offset: const Offset(1, 1),
      ),
    ];
  }
}
