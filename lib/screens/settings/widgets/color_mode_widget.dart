import 'package:flutter/material.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:provider/provider.dart';

class ColorModeWidget extends StatefulWidget {
  const ColorModeWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ColorModeState();
  }
}

class _ColorModeState extends State<ColorModeWidget> {
  ThemeMode _themeMode = SettingsService.getThemeMode();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SegmentedButton<ThemeMode>(
      segments: const <ButtonSegment<ThemeMode>>[
        ButtonSegment(
          icon: Icon(Icons.phone_iphone),
          value: ThemeMode.system,
        ),
        ButtonSegment(
          icon: Icon(Icons.light_mode),
          value: ThemeMode.light,
        ),
        ButtonSegment(
          icon: Icon(Icons.dark_mode),
          value: ThemeMode.dark,
        ),
      ],
      selected: <ThemeMode>{_themeMode},
      onSelectionChanged: (Set<ThemeMode> selected) {
        setState(() {
          _themeMode = selected.first;
          themeProvider.setThemeMode(_themeMode);
        });
      },
      showSelectedIcon: false,
      style: const ButtonStyle(
          visualDensity: VisualDensity(
            horizontal: -3,
            vertical: -2,
          ),
          iconSize: WidgetStatePropertyAll(22)),
    );
  }
}
