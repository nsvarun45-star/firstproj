// lib/widgets/case_status_card.dart
//
// Displays the "Case Status" card from the spec: shows OPEN/CLOSED with
// an animated glowing icon (red pulsing for open, green for closed).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/ble_models.dart';
import '../theme/app_colors.dart';
import 'glass_card.dart';

class CaseStatusCard extends StatelessWidget {
  final CaseStatus status;

  const CaseStatusCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isOpen = status == CaseStatus.open;
    final isUnknown = status == CaseStatus.unknown;

    final color = isUnknown
        ? AppColors.statusAmber
        : (isOpen ? AppColors.statusRed : AppColors.statusGreen);
    final label = isUnknown ? 'Unknown' : (isOpen ? 'OPEN' : 'CLOSED');
    final message = isUnknown
        ? 'Waiting for sensor data...'
        : (isOpen ? 'Case is Open' : 'Case is Closed');
    final icon = isOpen ? Icons.lock_open_rounded : Icons.lock_rounded;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 18, spreadRadius: 1),
              ],
            ),
            child: Icon(icon, color: color, size: 32),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.08, duration: 900.ms)
              .fadeIn(duration: 0.ms),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Case Status',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1,
                      ),
                ),
                const SizedBox(height: 2),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
