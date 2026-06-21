// lib/theme/app_colors.dart
//
// Central color palette for LensGuard's "futuristic medical-tech" look:
// deep blues, cyan accents, clean whites, with status colors for
// open/closed, clean/contaminated, and alert states.

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand colors
  static const Color deepBlue = Color(0xFF0A1B3D);
  static const Color midBlue = Color(0xFF13294B);
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color cyanSoft = Color(0xFF7BF1FF);
  static const Color white = Color(0xFFF5FAFF);

  // Status colors
  static const Color statusGreen = Color(0xFF00E676);
  static const Color statusRed = Color(0xFFFF5252);
  static const Color statusAmber = Color(0xFFFFC400);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF060E22);
  static const Color darkSurface = Color(0xFF0F1F3D);
  static const Color darkGlass = Color(0x332979FF); // translucent blue glass

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFEFF6FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightGlass = Color(0x33FFFFFF);

  // Gradients
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF050B1A), Color(0xFF0A1B3D), Color(0xFF0F2A5C)],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F4FF), Color(0xFFF5FAFF), Color(0xFFDCEEFF)],
  );

  static const LinearGradient cyanBlueAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyan, electricBlue],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00B8D4)],
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
  );
}
