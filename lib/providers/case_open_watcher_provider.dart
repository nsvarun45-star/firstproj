// lib/providers/case_open_watcher_provider.dart
//
// Watches the case status stream and starts a 2-minute timer whenever the
// case transitions to OPEN. If the case is still open when the timer
// fires, shows the "Case left open more than 2 minutes" notification.
// Cancels the timer (and any active notification) as soon as the case
// closes again.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ble_models.dart';
import 'ble_provider.dart';
import 'service_providers.dart';

const Duration kCaseOpenWarningThreshold = Duration(minutes: 2);

class CaseOpenWatcher extends Notifier<void> {
  Timer? _timer;
  CaseStatus _last = CaseStatus.unknown;

  @override
  void build() {
    ref.listen<CaseStatus>(caseStatusProvider, (previous, next) {
      if (next == _last) return;
      _last = next;

      if (next == CaseStatus.open) {
        _timer?.cancel();
        _timer = Timer(kCaseOpenWarningThreshold, () {
          ref.read(notificationServiceProvider).showCaseLeftOpen();
        });
      } else {
        _timer?.cancel();
        ref.read(notificationServiceProvider).cancelCaseLeftOpen();
      }
    });

    ref.onDispose(() => _timer?.cancel());
  }
}

final caseOpenWatcherProvider = NotifierProvider<CaseOpenWatcher, void>(
  CaseOpenWatcher.new,
);
