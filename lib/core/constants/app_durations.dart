// lib/core/constants/app_durations.dart

class AppDurations {
  // Short Animations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration quick = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 500);

  // Normal Animations
  static const Duration normal = Duration(milliseconds: 800);
  static const Duration slow = Duration(milliseconds: 1200);
  static const Duration slower = Duration(milliseconds: 1500);

  // Long Animations
  static const Duration long = Duration(seconds: 2);
  static const Duration veryLong = Duration(seconds: 3);
  static const Duration extraLong = Duration(seconds: 4);

  // Navigation
  static const Duration navigationDelay = Duration(milliseconds: 500);
  static const Duration splashMinDuration = Duration(seconds: 2);

  // Snackbar
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarLong = Duration(seconds: 3);
}