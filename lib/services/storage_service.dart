import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/analysis_result.dart';

class StorageService {
  static const String _historyKey = 'analysis_history';
  static const String _themeModeKey = 'theme_mode';
  static const String _analysisCountKey = 'analysis_count';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const int _maxHistory = 50;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
          'StorageService not initialized. Call StorageService.init() first.');
    }
    return _prefs!;
  }

  // History
  static List<AnalysisResult> getHistory() {
    final historyJson = _instance.getStringList(_historyKey) ?? [];
    return historyJson.map((json) {
      try {
        return AnalysisResult.fromJsonString(json);
      } catch (_) {
        return null;
      }
    }).whereType<AnalysisResult>().toList();
  }

  static Future<void> addToHistory(AnalysisResult result) async {
    final history = getHistory();
    history.insert(0, result);
    final trimmed = history.take(_maxHistory).toList();
    final jsonList = trimmed.map((r) => r.toJsonString()).toList();
    await _instance.setStringList(_historyKey, jsonList);
    await incrementAnalysisCount();
  }

  static Future<void> removeFromHistory(int index) async {
    final history = getHistory();
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      final jsonList = history.map((r) => r.toJsonString()).toList();
      await _instance.setStringList(_historyKey, jsonList);
    }
  }

  static Future<void> clearHistory() async {
    await _instance.setStringList(_historyKey, []);
  }

  // Theme
  static ThemeMode getThemeMode() {
    final value = _instance.getString(_themeModeKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static Future<void> saveThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
      case ThemeMode.dark:
        value = 'dark';
      case ThemeMode.system:
        value = 'system';
    }
    await _instance.setString(_themeModeKey, value);
  }

  // Analysis count
  static int getAnalysisCount() {
    return _instance.getInt(_analysisCountKey) ?? 0;
  }

  static Future<void> incrementAnalysisCount() async {
    final count = getAnalysisCount() + 1;
    await _instance.setInt(_analysisCountKey, count);
  }

  // Onboarding
  static bool isOnboardingComplete() {
    return _instance.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    await _instance.setBool(_onboardingCompleteKey, true);
  }
}
