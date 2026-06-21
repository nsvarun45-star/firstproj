// lib/providers/settings_provider.dart
//
// Exposes AppSettings as an AsyncNotifier so screens can read and update
// max wear duration, turbidity threshold, and theme mode, with changes
// automatically persisted via SettingsService.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import 'service_providers.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final service = ref.read(settingsServiceProvider);
    return service.loadSettings();
  }

  Future<void> updateMaxWearHours(int hours) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(maxWearHours: hours);
    state = AsyncData(updated);
    await ref.read(settingsServiceProvider).saveSettings(updated);
  }

  Future<void> updateTurbidityThreshold(int threshold) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(turbidityThreshold: threshold);
    state = AsyncData(updated);
    await ref.read(settingsServiceProvider).saveSettings(updated);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(themeMode: mode);
    state = AsyncData(updated);
    await ref.read(settingsServiceProvider).saveSettings(updated);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
