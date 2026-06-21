// lib/providers/solution_quality_provider.dart
//
// Watches turbidity readings against the user-configured threshold and
// fires a "Solution quality degraded" notification once per contamination
// episode (not on every single packet below threshold, to avoid spamming).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ble_provider.dart';
import 'settings_provider.dart';
import 'service_providers.dart';

enum SolutionQuality { clear, contaminated, unknown }

final solutionQualityProvider = Provider<SolutionQuality>((ref) {
  final turbidity = ref.watch(turbidityProvider);
  final settingsAsync = ref.watch(settingsProvider);

  final threshold = settingsAsync.maybeWhen(
    data: (s) => s.turbidityThreshold,
    orElse: () => 1500,
  );

  if (turbidity <= 0) return SolutionQuality.unknown;
  return turbidity < threshold ? SolutionQuality.contaminated : SolutionQuality.clear;
});

/// Side-effect watcher: call `ref.watch(solutionQualityWatcherProvider)`
/// once near the app root (done in HomeScreen) to trigger the contamination
/// notification exactly once per transition into the contaminated state.
class SolutionQualityWatcher extends Notifier<void> {
  SolutionQuality _last = SolutionQuality.unknown;

  @override
  void build() {
    ref.listen<SolutionQuality>(solutionQualityProvider, (previous, next) {
      if (next == SolutionQuality.contaminated && _last != SolutionQuality.contaminated) {
        ref.read(notificationServiceProvider).showSolutionContaminated();
      }
      _last = next;
    });
  }
}

final solutionQualityWatcherProvider = NotifierProvider<SolutionQualityWatcher, void>(
  SolutionQualityWatcher.new,
);
