import 'package:shared_preferences/shared_preferences.dart';

enum AppRunMode {
  demo,
  server,
}

class AppConfig {
  static const String _modeKey = 'app_run_mode';

  static AppRunMode _mode = AppRunMode.demo;

  static const String baseUrl = 'http://10.0.2.2:3000';

  static AppRunMode get mode => _mode;

  static bool get useBackend => _mode == AppRunMode.server;

  static bool get isDemoMode => _mode == AppRunMode.demo;

  static String get modeLabel {
    switch (_mode) {
      case AppRunMode.demo:
        return 'Демо-режим';
      case AppRunMode.server:
        return 'Сервер + PostgreSQL';
    }
  }

  static Future<void> init() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final String savedMode = prefs.getString(_modeKey) ?? 'demo';

    _mode = _parseMode(savedMode);
  }

  static Future<void> setMode(AppRunMode mode) async {
    _mode = mode;

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_modeKey, mode.name);
  }

  static AppRunMode _parseMode(String value) {
    switch (value) {
      case 'server':
        return AppRunMode.server;
      case 'demo':
      default:
        return AppRunMode.demo;
    }
  }
}