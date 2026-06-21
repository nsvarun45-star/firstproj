// lib/screens/history/history_screen.dart
//
// The "History" tab: scrollable list of glassmorphism cards, each showing
// date, wear duration, cleaning duration, and turbidity value, matching
// the spec's example layout. Supports swipe-to-delete and a clear-all
// action in the app bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/history_provider.dart';
import '../../models/history_entry.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_card.dart';
import '../../theme/app_colors.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return AnimatedBackground(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'History',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                  ),
                  historyAsync.maybeWhen(
                    data: (entries) => entries.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.delete_sweep_outlined),
                            tooltip: 'Clear all',
                            onPressed: () => _confirmClearAll(context, ref),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: historyAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 56, color: AppColors.cyan.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No history yet',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: AppColors.statusRed.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (_) =>
                              ref.read(historyProvider.notifier).deleteEntry(entry.id),
                          child: _HistoryCard(entry: entry),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => Center(child: Text('Failed to load history: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will permanently delete all saved records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(historyProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.statusRed)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMMM yyyy').format(entry.date);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.cyan),
              const SizedBox(width: 8),
              Text(dateLabel, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const Divider(height: 20),
          Row(
            children: [
              _StatColumn(
                icon: Icons.timer_outlined,
                label: 'Wear Time',
                value: entry.formattedWearDuration,
              ),
              _StatColumn(
                icon: Icons.cleaning_services_outlined,
                label: 'Cleaning',
                value: entry.formattedCleaningDuration,
              ),
              _StatColumn(
                icon: Icons.water_drop_outlined,
                label: 'Turbidity',
                value: '${entry.turbidityValue}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatColumn({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.cyan.withOpacity(0.8)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
