// lib/providers/ble_provider.dart
//
// Exposes the live BLE connection state and telemetry stream from
// BleService as Riverpod StreamProviders, so any widget can reactively
// rebuild on case status, turbidity, cleaning status, motor, or buzzer
// changes without manually managing subscriptions.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ble_models.dart';
import '../services/ble_service.dart';
import 'service_providers.dart';

/// Live connection state: disconnected / connecting / connected.
final bleConnectionStateProvider = StreamProvider<BleConnectionState>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.connectionStateStream;
});

/// Live telemetry snapshot from the ESP32 (or mock simulator).
final telemetryProvider = StreamProvider<LensCaseTelemetry>((ref) {
  final service = ref.watch(bleServiceProvider);
  return service.telemetryStream;
});

/// Convenience derived provider: just the current case status, defaulting
/// to `unknown` while the stream hasn't emitted yet.
final caseStatusProvider = Provider<CaseStatus>((ref) {
  return ref.watch(telemetryProvider).maybeWhen(
        data: (t) => t.caseStatus,
        orElse: () => CaseStatus.unknown,
      );
});

/// Convenience derived provider: current turbidity reading.
final turbidityProvider = Provider<int>((ref) {
  return ref.watch(telemetryProvider).maybeWhen(
        data: (t) => t.turbidity,
        orElse: () => 0,
      );
});
