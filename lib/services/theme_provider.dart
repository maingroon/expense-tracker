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

  /// A subtle two-layer drop shadow that gives icons depth without the heavy
  /// grey/black blob the previous single-shadow produced. The bottom layer is
  /// a soft ambient shadow; the top layer is a tighter contact shadow.
  List<Shadow> getIconsShadows() {
    final isLight = getCurrentBrightness() == Brightness.light;
    final ambientColor = isLight
        ? Colors.black.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.55);
    final contactColor = isLight
        ? Colors.black.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.30);
    return [
      Shadow(
        blurRadius: 8,
        color: ambientColor,
        offset: const Offset(0, 2),
      ),
      Shadow(
        blurRadius: 2,
        color: contactColor,
        offset: const Offset(0, 1),
      ),
    ];
  }
}
