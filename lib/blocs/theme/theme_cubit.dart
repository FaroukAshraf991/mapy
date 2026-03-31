import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeSetting = prefs.getString('theme_setting') ?? 'light';

    switch (themeSetting) {
      case 'dark':
        emit(ThemeMode.dark);
        break;
      case 'system':
        emit(ThemeMode.system);
        break;
      default:
        emit(ThemeMode.light);
    }
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_setting', mode);

    switch (mode) {
      case 'dark':
        emit(ThemeMode.dark);
        break;
      case 'system':
        emit(ThemeMode.system);
        break;
      default:
        emit(ThemeMode.light);
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(newMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', newMode == ThemeMode.dark);
    await prefs.setString(
        'theme_setting', newMode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', mode == ThemeMode.dark);

    String setting;
    if (mode == ThemeMode.system) {
      setting = 'system';
    } else if (mode == ThemeMode.dark) {
      setting = 'dark';
    } else {
      setting = 'light';
    }
    await prefs.setString('theme_setting', setting);
  }
}
