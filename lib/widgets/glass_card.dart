// lib/widgets/glass_card.dart
//
// A reusable frosted-glass container: blurred translucent background,
// subtle border, soft shadow. Used as the base building block for nearly
// every card in the app (status cards, history cards, settings rows).

import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final Gradient? borderGradient;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.blurSigma = 16,
    this.borderGradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark ? AppColors.darkGlass : AppColors.lightGlass;
    final borderColor = (isDark ? AppColors.cyan : AppColors.electricBlue).withOpacity(0.25);

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.deepBlue).withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}
