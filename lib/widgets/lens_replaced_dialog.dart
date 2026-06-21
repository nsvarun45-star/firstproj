// lib/widgets/lens_replaced_dialog.dart
//
// The "Did you place the lens back?" popup shown when the case is
// reopened during an active wear session, per the spec's workflow.

import 'package:flutter/material.dart';
import 'glass_card.dart';
import '../theme/app_colors.dart';

class LensReplacedDialog extends StatelessWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const LensReplacedDialog({super.key, required this.onYes, required this.onNo});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onYes,
    required VoidCallback onNo,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LensReplacedDialog(onYes: onYes, onNo: onNo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        borderRadius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.cyan, size: 42),
            const SizedBox(height: 16),
            Text(
              'Did you place the lens back?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'The case was reopened. Let us know if your lens is back in the case.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNo();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('NO'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onYes();
                    },
                    child: const Text('YES'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
