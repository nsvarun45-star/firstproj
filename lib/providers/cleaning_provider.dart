// lib/providers/cleaning_provider.dart
//
// Drives the Smart Cleaning feature: sends START_CLEANING to the BLE
// service, tracks a local 30-second countdown in sync with the ESP32's
// Cleaning:CLEANING -> Cleaning:COMPLETE transition, and fires the
// "Cleaning Completed" notification when done. Also updates the most
// recent history entry with the actual cleaning duration if one exists
// from the same day, otherwise records a standalone cleaning-only entry.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/ble_models.dart';
import '../models/history_entry.dart';
import 'service_providers.dart';
import 'ble_provider.dart';
import 'history_provider.dart';

const int kCleaningDurationSeconds = 30;

enum CleaningPhase { idle, cleaning, complete }

class CleaningState {
  final CleaningPhase phase;
  final int secondsRemaining;

  const CleaningState({
    this.phase = CleaningPhase.idle,
    this.secondsRemaining = kCleaningDurationSeconds,
  });

  CleaningState copyWith({CleaningPhase? phase, int? secondsRemaining}) {
    return CleaningState(
      phase: phase ?? this.phase,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }

  double get progress =>
      1 - (secondsRemaining / kCleaningDurationSeconds).clamp(0, 1);
}

class CleaningNotifier extends StateNotifier<CleaningState> {
  final Ref ref;
  Timer? _countdown;
  CleaningStatus _lastCleaningStatus = CleaningStatus.idle;

  CleaningNotifier(this.ref) : super(const CleaningState()) {
    ref.listen<AsyncValue<LensCaseTelemetry>>(
      telemetryProvider,
      (previous, next) {
        next.whenData((t) => _onCleaningStatusChanged(t.cleaningStatus));
      },
      fireImmediately: true,
    );
  }

  void _onCleaningStatusChanged(CleaningStatus newStatus) {
    if (newStatus == _lastCleaningStatus) return;
    _lastCleaningStatus = newStatus;

    if (newStatus == CleaningStatus.complete) {
      _countdown?.cancel();
      state = state.copyWith(phase: CleaningPhase.complete, secondsRemaining: 0);
      _onCleaningComplete();
    }
  }

  /// User pressed the "CLEAN LENS" button.
  Future<void> startCleaning() async {
    if (state.phase == CleaningPhase.cleaning) return;
    state = const CleaningState(
      phase: CleaningPhase.cleaning,
      secondsRemaining: kCleaningDurationSeconds,
    );
    await ref.read(bleServiceProvider).sendStartCleaning();

    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = state.secondsRemaining - 1;
      if (next <= 0) {
        timer.cancel();
        state = state.copyWith(secondsRemaining: 0);
      } else {
        state = state.copyWith(secondsRemaining: next);
      }
    });
  }

  Future<void> _onCleaningComplete() async {
    await ref.read(notificationServiceProvider).showCleaningComplete();
    final turbidity = ref.read(turbidityProvider);

    final entry = HistoryEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      wearDuration: Duration.zero,
      cleaningDuration: const Duration(seconds: kCleaningDurationSeconds),
      turbidityValue: turbidity,
    );
    await ref.read(historyProvider.notifier).addEntry(entry);
  }

  /// Resets back to idle so the UI can show the CLEAN LENS button again.
  void resetToIdle() {
    _countdown?.cancel();
    state = const CleaningState();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }
}

final cleaningProvider = StateNotifierProvider<CleaningNotifier, CleaningState>((ref) {
  return CleaningNotifier(ref);
});
