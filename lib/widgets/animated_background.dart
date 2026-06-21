// lib/widgets/animated_background.dart
//
// Full-screen gradient backdrop with two slow-drifting soft glow blobs to
// give the app a subtle "alive" futuristic feel without being distracting.
// Wraps the page content passed in as [child].

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient =
        isDark ? AppColors.darkBackgroundGradient : AppColors.lightBackgroundGradient;

    return Stack(
      children: [
        Container(decoration: BoxDecoration(gradient: gradient)),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              children: [
                Positioned(
                  top: -80 + (40 * t),
                  left: -60 + (30 * t),
                  child: _glowBlob(AppColors.cyan.withOpacity(isDark ? 0.18 : 0.12), 220),
                ),
                Positioned(
                  bottom: -100 + (30 * (1 - t)),
                  right: -60 + (20 * (1 - t)),
                  child: _glowBlob(
                      AppColors.electricBlue.withOpacity(isDark ? 0.20 : 0.10), 260),
                ),
              ],
            );
          },
        ),
        widget.child,
      ],
    );
  }

  Widget _glowBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
      ),
    );
  }
}
