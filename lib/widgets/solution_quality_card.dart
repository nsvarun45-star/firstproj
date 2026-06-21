// lib/widgets/solution_quality_card.dart
//
// Displays the "Solution Quality" card: turbidity value, a clean/
// contaminated indicator (green/red animated dot), and the warning
// message when the solution has degraded below threshold.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/solution_quality_provider.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class SolutionQualityCard extends StatelessWidget {
  final int turbidity;
  final SolutionQuality quality;
  final int threshold;

  const SolutionQualityCard({
    super.key,
    required this.turbidity,
    required this.quality,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final isContaminated = quality == SolutionQuality.contaminated;
    final color = quality == SolutionQuality.unknown
        ? AppColors.statusAmber
        : (isContaminated ? AppColors.statusRed : AppColors.statusGreen);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 8)],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(
                    duration: 700.ms,
                    begin: 0.4,
                  ),
              const SizedBox(width: 10),
              Text(
                'Solution Quality',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$turbidity',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 6),
              Text('NTU', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Threshold: $threshold',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          if (isContaminated)
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.statusRed, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Solution contaminated — please replace cleaning solution',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.statusRed, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            )
          else if (quality == SolutionQuality.clear)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.statusGreen, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Solution Clear',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.statusGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
