import 'package:flutter/material.dart';

class AppStateProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _profileName = 'Student';

  int _activitiesCompleted = 0;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get profileName => _profileName;
  int get activitiesCompleted => _activitiesCompleted;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setProfileName(String name) {
    if (name.trim().isEmpty) return;
    _profileName = name.trim();
    notifyListeners();
  }

  void markActivityCompleted() {
    _activitiesCompleted++;
    notifyListeners();
  }

  void resetProgress() {
    _activitiesCompleted = 0;
    notifyListeners();
  }
}
