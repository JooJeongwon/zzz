import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  static void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  static void setLight() {
    if (themeMode.value != ThemeMode.light) {
      themeMode.value = ThemeMode.light;
    }
  }

  static void setDark() {
    if (themeMode.value != ThemeMode.dark) {
      themeMode.value = ThemeMode.dark;
    }
  }
}
