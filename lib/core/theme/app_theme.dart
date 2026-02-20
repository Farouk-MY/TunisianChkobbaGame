// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get redTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryRed,
      scaffoldBackgroundColor: AppColors.darkRed,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.dark,
        primary: AppColors.primaryRed,
        secondary: AppColors.gold,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.darkRed,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.white),
        bodyMedium: TextStyle(color: AppColors.white),
      ),
    );
  }

  static ThemeData get whiteTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primaryRed,
      scaffoldBackgroundColor: AppColors.white,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.light,
        primary: AppColors.primaryRed,
        secondary: AppColors.gold,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: AppColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.grey900),
        bodyMedium: TextStyle(color: AppColors.grey700),
      ),
    );
  }
}