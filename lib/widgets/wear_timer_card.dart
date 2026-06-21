// lib/widgets/wear_timer_card.dart
//
// Displays the lens wearing timer: elapsed duration in "HH hr MM min"
// format, a circular progress indicator relative to the configured max
// safe wear duration, and the START WEARING button (shown only when no
// session is active).

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class WearTimerCard extends StatelessWidget {
  final Duration elapsed;
  final int maxWearHours;
  final bool isWearing;
  final bool limitExceeded;
  final VoidCallback onStartWearing;

  const WearTimerCard({
    super.key,
    required this.elapsed,
    required this.maxWearHours,
    required this.isWearing,
    required this.limitExceeded,
    required this.onStartWearing,
  });

  String get _formatted {
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    return '$hours hr $minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final maxSeconds = maxWearHours * 3600;
    final progress = maxSeconds == 0 ? 0.0 : (elapsed.inSeconds / maxSeconds).clamp(0.0, 1.0);
    final progressColor = limitExceeded ? AppColors.statusRed : AppColors.cyan;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lens Wearing Timer',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: progressColor.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatted,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of $maxWearHours hr limit',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (limitExceeded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.statusRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.statusRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safe limit exceeded — remove lens immediately',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.statusRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!isWearing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartWearing,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START WEARING'),
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Timer running',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.cyan, fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
