import 'package:flutter/material.dart';

final ThemeData kLightTheme = ThemeData.light().copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
  ),
);

final ThemeData kDarkTheme = ThemeData.dark().copyWith(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: Brightness.dark,
  ),
);
