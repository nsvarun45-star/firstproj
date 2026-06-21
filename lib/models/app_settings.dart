// lib/models/app_settings.dart
//
// User-configurable settings: maximum safe lens wear duration, the
// turbidity threshold below which the cleaning solution is considered
// contaminated, and the app's theme mode (light/dark/system).
// Persisted via SettingsService (shared_preferences).

import 'package:flutter/material.dart';

class AppSettings {
  /// Maximum safe wearing duration in hours. Spec examples: 8, 10, 12.
  final int maxWearHours;

  /// Turbidity threshold below which the solution is flagged contaminated.
  /// Spec default: 1500.
  final int turbidityThreshold;

  final ThemeMode themeMode;

  const AppSettings({
    this.maxWearHours = 8,
    this.turbidityThreshold = 1500,
    this.themeMode = ThemeMode.system,
  });

  static const List<int> allowedMaxWearHours = [8, 10, 12];

  AppSettings copyWith({
    int? maxWearHours,
    int? turbidityThreshold,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      maxWearHours: maxWearHours ?? this.maxWearHours,
      turbidityThreshold: turbidityThreshold ?? this.turbidityThreshold,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxWearHours': maxWearHours,
        'turbidityThreshold': turbidityThreshold,
        'themeMode': themeMode.index,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        maxWearHours: json['maxWearHours'] as int? ?? 8,
        turbidityThreshold: json['turbidityThreshold'] as int? ?? 1500,
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? ThemeMode.system.index],
      );
}
