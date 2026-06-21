// lib/providers/wear_timer_provider.dart
//
// Implements the Lens Wearing Timer workflow from the spec:
//
//   Case OPEN -> user presses START WEARING -> timer starts
//   Case CLOSED -> timer keeps running (lens is being worn outside case)
//   Case OPEN again -> show "Did you place the lens back?" popup
//     YES -> stop timer, save to history, reset
//     NO  -> timer keeps running, popup dismissed
//
// Also watches the live timer duration against the configured max wear
// duration and fires the "exceeded safe limit" notification exactly once
// per session when the threshold is crossed.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/ble_models.dart';
import '../models/history_entry.dart';
import 'service_providers.dart';
import 'ble_provider.dart';
import 'settings_provider.dart';
import 'history_provider.dart';
import 'package:uuid/uuid.dart';

enum WearSessionStatus { notStarted, wearing, awaitingReplacementConfirmation }

class WearTimerState {
  final WearSessionStatus status;
  final Duration elapsed;
  final bool limitExceeded;

  const WearTimerState({
    this.status = WearSessionStatus.notStarted,
    this.elapsed = Duration.zero,
    this.limitExceeded = false,
  });

  WearTimerState copyWith({
    WearSessionStatus? status,
    Duration? elapsed,
    bool? limitExceeded,
  }) {
    return WearTimerState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      limitExceeded: limitExceeded ?? this.limitExceeded,
    );
  }
}

class WearTimerNotifier extends StateNotifier<WearTimerState> {
  final Ref ref;
  CaseStatus _lastCaseStatus = CaseStatus.unknown;
  StreamSubscription? _tickSub;
  bool _notifiedExceeded = false;

  WearTimerNotifier(this.ref) : super(const WearTimerState()) {
    _listenToCaseStatus();
    _listenToTicks();
  }

  void _listenToCaseStatus() {
    // ref.listen registers a listener tied to this notifier's lifecycle;
    // Riverpod automatically cleans it up when this notifier is disposed.
    ref.listen<AsyncValue<LensCaseTelemetry>>(
      telemetryProvider,
      (previous, next) {
        next.whenData((telemetry) => _onCaseStatusChanged(telemetry.caseStatus));
      },
      fireImmediately: true,
    );
  }

  void _onCaseStatusChanged(CaseStatus newStatus) {
    if (newStatus == _lastCaseStatus) return;
    final wasOpen = _lastCaseStatus == CaseStatus.open;
    _lastCaseStatus = newStatus;

    // Case reopened while a wear session is active -> ask user to confirm.
    if (newStatus.isOpen &&
        state.status == WearSessionStatus.wearing &&
        !wasOpen) {
      state = state.copyWith(status: WearSessionStatus.awaitingReplacementConfirmation);
    }
  }

  void _listenToTicks() {
    final timerService = ref.read(timerServiceProvider);
    _tickSub = timerService.tickStream.listen((duration) async {
      state = state.copyWith(elapsed: duration);
      await _checkLimitExceeded(duration);
    });
  }

  Future<void> _checkLimitExceeded(Duration duration) async {
    final settings = ref.read(settingsProvider).value;
    if (settings == null) return;
    final maxDuration = Duration(hours: settings.maxWearHours);

    if (duration >= maxDuration && !_notifiedExceeded) {
      _notifiedExceeded = true;
      state = state.copyWith(limitExceeded: true);
      await ref.read(notificationServiceProvider).showWearLimitExceeded();
    } else if (duration < maxDuration && _notifiedExceeded) {
      // Shouldn't normally happen (time doesn't go backward) but guards
      // against settings changes mid-session.
      _notifiedExceeded = false;
      state = state.copyWith(limitExceeded: false);
      await ref.read(notificationServiceProvider).cancelWearLimitExceeded();
    }
  }

  /// User pressed "START WEARING" after removing the lens from the case.
  void startWearing() {
    if (state.status == WearSessionStatus.wearing) return;
    ref.read(timerServiceProvider).start();
    _notifiedExceeded = false;
    state = state.copyWith(
      status: WearSessionStatus.wearing,
      elapsed: Duration.zero,
      limitExceeded: false,
    );
  }

  /// User confirmed "YES" to "Did you place the lens back?" — stop timer,
  /// persist a history entry, and reset to notStarted.
  Future<void> confirmLensReplaced() async {
    final timerService = ref.read(timerServiceProvider);
    final wearDuration = timerService.stop();
    final turbidity = ref.read(turbidityProvider);

    final entry = HistoryEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      wearDuration: wearDuration,
      cleaningDuration: Duration.zero, // filled in once cleaning runs
      turbidityValue: turbidity,
    );
    await ref.read(historyProvider.notifier).addEntry(entry);

    await ref.read(notificationServiceProvider).cancelWearLimitExceeded();
    _notifiedExceeded = false;
    state = const WearTimerState();
  }

  /// User answered "NO" — lens not back in yet, keep the timer running.
  void declineLensReplaced() {
    state = state.copyWith(status: WearSessionStatus.wearing);
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    super.dispose();
  }
}

final wearTimerProvider =
    StateNotifierProvider<WearTimerNotifier, WearTimerState>((ref) {
  return WearTimerNotifier(ref);
});
