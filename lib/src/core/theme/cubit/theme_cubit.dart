import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themePreferenceKey = 'quizwiz_theme_mode';
  bool _wasChangedByUser = false;

  ThemeCubit() : super(ThemeMode.dark) {
    _restoreTheme();
  }

  Future<void> _restoreTheme() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final savedTheme = preferences.getString(_themePreferenceKey);
      if (!isClosed &&
          !_wasChangedByUser &&
          savedTheme == ThemeMode.light.name) {
        emit(ThemeMode.light);
      }
    } catch (_) {
      // Keep the default theme if preferences are unavailable.
    }
  }

  void setTheme(ThemeMode mode) {
    _wasChangedByUser = true;
    if (state != mode) emit(mode);
    unawaited(_saveTheme(mode));
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themePreferenceKey, mode.name);
    } catch (_) {
      // Theme changes remain active for the current app session.
    }
  }

  void toggleTheme() {
    setTheme(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
