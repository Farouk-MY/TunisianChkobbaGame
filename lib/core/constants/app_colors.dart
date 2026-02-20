// lib/core/constants/app_colors.dart

import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Tunisian Red Theme)
  static const Color primaryRed = Color(0xFFE31E24);
  static const Color secondaryRed = Color(0xFFC41E3A);
  static const Color darkRed = Color(0xFF8B0000);
  static const Color gold = Color(0xFFFFD700);
  static const Color orange = Color(0xFFFFA500);

  // System Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE31E24);
  static const Color warning = Color(0xFFFFA500);
  static const Color info = Color(0xFF2196F3);

  // Grayscale
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Section Colors
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color lightPurple = Color(0xFFF3E5F5);

  static const Color orangeSection = Color(0xFFFF9800);
  static const Color blueSection = Color(0xFF2196F3);
  static const Color purpleSection = Color(0xFF9C27B0);
  static const Color greySection = Color(0xFF607D8B);

  static const Color orangeSectionLight = Color(0xFFFFF3E0);
  static const Color blueSectionLight = Color(0xFFE3F2FD);
  static const Color purpleSectionLight = Color(0xFFF3E5F5);
  static const Color greySectionLight = Color(0xFFECEFF1);

  // Opacity Helpers
  static Color whiteOpacity(double opacity) => white.withOpacity(opacity);
  static Color blackOpacity(double opacity) => black.withOpacity(opacity);
  static Color goldOpacity(double opacity) => gold.withOpacity(opacity);
  static Color primaryRedOpacity(double opacity) => primaryRed.withOpacity(opacity);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, secondaryRed, darkRed],
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, orange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient whiteGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [white, grey50, grey100],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient redToWhiteGradient = LinearGradient(
    colors: [primaryRed, white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}