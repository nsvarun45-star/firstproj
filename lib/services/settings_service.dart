// lib/services/settings_service.dart
//
// Persists AppSettings (max wear duration, turbidity threshold, theme
// mode) locally using shared_preferences as a JSON-encoded string.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const _storageKey = 'lensguard_app_settings';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const AppSettings();
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(settings.toJson()));
  }
}
