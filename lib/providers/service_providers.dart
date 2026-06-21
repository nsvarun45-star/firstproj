// lib/providers/service_providers.dart
//
// Riverpod providers that expose singleton instances of each service.
// Kept in one file so it's obvious at a glance what backing services
// exist and how they're wired up. Feature-specific state providers live
// in their own files (ble_provider.dart, timer_provider.dart, etc.) and
// depend on these.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_service.dart';
import '../services/notification_service.dart';
import '../services/history_service.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';

/// Singleton BLE service. autoDispose is intentionally NOT used here
/// because the BLE connection should persist for the app's lifetime.
final bleServiceProvider = Provider<BleService>((ref) {
  final service = RealBleServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final timerServiceProvider = Provider<TimerService>((ref) {
  final service = TimerService();
  ref.onDispose(service.dispose);
  return service;
});
