// lib/widgets/wear_duration_result_card.dart
//
// Brief success card shown right after the user confirms the lens has
// been placed back, displaying the final "Wear Duration" per the spec's
// example: "Wear Duration / 7 hr 14 min".

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class WearDurationResultCard extends StatelessWidget {
  final Duration duration;
  final VoidCallback onDismiss;

  const WearDurationResultCard({
    super.key,
    required this.duration,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');

    return GlassCard(
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.statusGreen, size: 40)
              .animate()
              .scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text('Wear Duration', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '$hours hr $minutes min',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: AppColors.statusGreen),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
        ],
      ),
    );
  }
}
