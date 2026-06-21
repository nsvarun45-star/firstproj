// lib/theme/app_theme.dart
//
// Builds the Material 3 ThemeData for both light and dark modes, using the
// LensGuard color palette. Typography leans on a clean, technical sans
// serif feel suitable for a medical-tech product.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyan,
        secondary: AppColors.electricBlue,
        surface: AppColors.darkSurface,
        onSurface: AppColors.white,
        error: AppColors.statusRed,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.white,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface.withOpacity(0.85),
        selectedItemColor: AppColors.cyan,
        unselectedItemColor: AppColors.white.withOpacity(0.5),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.white,
        displayColor: AppColors.white,
      ),
      iconTheme: const IconThemeData(color: AppColors.cyan),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(color: AppColors.white),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.darkSurface),
        ),
      ),
      dividerColor: AppColors.white.withOpacity(0.08),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(AppColors.cyan),
        trackColor: WidgetStatePropertyAll(AppColors.electricBlue.withOpacity(0.4)),
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricBlue,
        secondary: AppColors.cyan,
        surface: AppColors.lightSurface,
        onSurface: AppColors.deepBlue,
        error: AppColors.statusRed,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.deepBlue,
        titleTextStyle: TextStyle(
          color: AppColors.deepBlue,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface.withOpacity(0.9),
        selectedItemColor: AppColors.electricBlue,
        unselectedItemColor: AppColors.deepBlue.withOpacity(0.4),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.deepBlue,
        displayColor: AppColors.deepBlue,
      ),
      iconTheme: const IconThemeData(color: AppColors.electricBlue),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.electricBlue,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      dividerColor: AppColors.deepBlue.withOpacity(0.08),
    );
  }
}
