// lib/screens/home/home_screen.dart
//
// The main "Home" tab: shows connection status, case status card, wear
// timer card (with circular progress + START WEARING button), and the
// solution quality card. Also triggers the "Did you place the lens back?"
// dialog when the wear timer provider enters the
// awaitingReplacementConfirmation state, and shows a brief success card
// after confirming lens replacement.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ble_provider.dart';
import '../../providers/wear_timer_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/solution_quality_provider.dart';
import '../../providers/case_open_watcher_provider.dart';
import '../../providers/service_providers.dart';
import '../../models/ble_models.dart';
import '../../services/ble_service.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/case_status_card.dart';
import '../../widgets/wear_timer_card.dart';
import '../../widgets/solution_quality_card.dart';
import '../../widgets/lens_replaced_dialog.dart';
import '../../widgets/wear_duration_result_card.dart';
import '../../theme/app_colors.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _dialogShowing = false;
  Duration? _lastSavedDuration;

  @override
  void initState() {
    super.initState();
    // Kick off the BLE connection (mock) when Home first mounts.
    Future.microtask(() => ref.read(bleServiceProvider).connectDevice());
  }

  @override
  Widget build(BuildContext context) {
    // Activate background watchers (side-effect only providers).
    ref.watch(solutionQualityWatcherProvider);
    ref.watch(caseOpenWatcherProvider);

    final connectionState = ref.watch(bleConnectionStateProvider);
    final caseStatus = ref.watch(caseStatusProvider);
    final turbidity = ref.watch(turbidityProvider);
    final wearState = ref.watch(wearTimerProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final quality = ref.watch(solutionQualityProvider);

    // React to "awaiting replacement confirmation" by showing the dialog.
    ref.listen<WearTimerState>(wearTimerProvider, (previous, next) {
      if (next.status == WearSessionStatus.awaitingReplacementConfirmation &&
          !_dialogShowing) {
        _dialogShowing = true;
        final savedElapsed = next.elapsed;
        LensReplacedDialog.show(
          context,
          onYes: () async {
            _dialogShowing = false;
            setState(() => _lastSavedDuration = savedElapsed);
            await ref.read(wearTimerProvider.notifier).confirmLensReplaced();
          },
          onNo: () {
            _dialogShowing = false;
            ref.read(wearTimerProvider.notifier).declineLensReplaced();
          },
        );
      }
    });

    final maxWearHours = settingsAsync.maybeWhen(
      data: (s) => s.maxWearHours,
      orElse: () => 8,
    );
    final turbidityThreshold = settingsAsync.maybeWhen(
      data: (s) => s.turbidityThreshold,
      orElse: () => 1500,
    );

    return AnimatedBackground(
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('LensGuard'),
              floating: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _ConnectionBadge(state: connectionState.value),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_lastSavedDuration != null) ...[
                    WearDurationResultCard(
                      duration: _lastSavedDuration!,
                      onDismiss: () => setState(() => _lastSavedDuration = null),
                    ),
                    const SizedBox(height: 16),
                  ],
                  CaseStatusCard(status: caseStatus),
                  const SizedBox(height: 16),
                  WearTimerCard(
                    elapsed: wearState.elapsed,
                    maxWearHours: maxWearHours,
                    isWearing: wearState.status == WearSessionStatus.wearing ||
                        wearState.status == WearSessionStatus.awaitingReplacementConfirmation,
                    limitExceeded: wearState.limitExceeded,
                    onStartWearing: () => ref.read(wearTimerProvider.notifier).startWearing(),
                  ),
                  const SizedBox(height: 16),
                  SolutionQualityCard(
                    turbidity: turbidity,
                    quality: quality,
                    threshold: turbidityThreshold,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  final BleConnectionState? state;

  const _ConnectionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final isConnected = state == BleConnectionState.connected;
    final isConnecting = state == BleConnectionState.connecting;
    final color = isConnected
        ? AppColors.statusGreen
        : (isConnecting ? AppColors.statusAmber : AppColors.statusRed);
    final label = isConnected ? 'Connected' : (isConnecting ? 'Connecting' : 'Offline');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_connected_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
