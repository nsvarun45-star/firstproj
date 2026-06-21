// lib/screens/cleaning/cleaning_screen.dart
//
// The "Cleaning" tab: large CLEAN LENS button, a circular animated
// countdown (30 -> 0) while cleaning is in progress, motor status, and a
// green success/checkmark animation on completion.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/cleaning_provider.dart';
import '../../providers/ble_provider.dart';
import '../../models/ble_models.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../theme/app_colors.dart';

class CleaningScreen extends ConsumerWidget {
  const CleaningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cleaningState = ref.watch(cleaningProvider);
    final motorState = ref.watch(telemetryProvider).maybeWhen(
          data: (t) => t.motorState,
          orElse: () => PeripheralState.unknown,
        );

    return AnimatedBackground(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Cleaning',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(context, ref, cleaningState, motorState),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    CleaningState state,
    PeripheralState motorState,
  ) {
    switch (state.phase) {
      case CleaningPhase.idle:
        return _IdleView(onPressed: () => ref.read(cleaningProvider.notifier).startCleaning());
      case CleaningPhase.cleaning:
        return _CleaningInProgressView(state: state, motorState: motorState);
      case CleaningPhase.complete:
        return _CompleteView(onDone: () => ref.read(cleaningProvider.notifier).resetToIdle());
    }
  }
}

class _IdleView extends StatelessWidget {
  final VoidCallback onPressed;

  const _IdleView({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.water_drop_outlined, size: 72, color: AppColors.cyan.withOpacity(0.8)),
        const SizedBox(height: 16),
        Text(
          'Ready to clean your lens',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 180,
            height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.cyanBlueAccent,
              boxShadow: [
                BoxShadow(color: AppColors.cyan, blurRadius: 40, spreadRadius: -10),
              ],
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text(
                    'CLEAN LENS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
              begin: 1.0,
              end: 1.04,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }
}

class _CleaningInProgressView extends StatelessWidget {
  final CleaningState state;
  final PeripheralState motorState;

  const _CleaningInProgressView({required this.state, required this.motorState});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: state.progress,
                  strokeWidth: 12,
                  backgroundColor: AppColors.cyan.withOpacity(0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${state.secondsRemaining}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('seconds', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.vibration_rounded,
                color: motorState.isOn ? AppColors.cyan : Colors.grey,
              ).animate(onPlay: (c) => c.repeat()).shake(hz: motorState.isOn ? 4 : 0),
              const SizedBox(width: 10),
              Text(
                'Motor: ${motorState.isOn ? 'ON' : 'OFF'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Cleaning In Progress',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: AppColors.cyan),
        ),
      ],
    );
  }
}

class _CompleteView extends StatelessWidget {
  final VoidCallback onDone;

  const _CompleteView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.successGradient,
            boxShadow: [
              BoxShadow(color: AppColors.statusGreen.withOpacity(0.5), blurRadius: 30),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 72),
        ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        Text(
          'Cleaning Completed',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.statusGreen),
        ),
        const SizedBox(height: 8),
        Text('Lens is ready to use', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: onDone, child: const Text('Done')),
      ],
    );
  }
}
