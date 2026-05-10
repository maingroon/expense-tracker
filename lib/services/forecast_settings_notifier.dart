import 'package:expense_tracker/services/settings_service.dart';
import 'package:flutter/material.dart';

class ForecastSettingsNotifier extends ChangeNotifier {
  ForecastSettingsNotifier()
      : _showTab = SettingsService.getForecastShowTab();

  bool _showTab;

  bool get showTab => _showTab;

  Future<void> setShowTab(bool value) async {
    if (_showTab == value) return;
    _showTab = value;
    await SettingsService.setForecastShowTab(value);
    notifyListeners();
  }
}
