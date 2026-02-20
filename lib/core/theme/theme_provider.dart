// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import '../constants/app_colors.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  bool _isRedTheme = true;

  bool get isRedTheme => _isRedTheme;
  bool get isWhiteTheme => !_isRedTheme;

  ThemeData get currentTheme => _isRedTheme ? AppTheme.redTheme : AppTheme.whiteTheme;
  String get currentThemeName => _isRedTheme ? 'Rouge' : 'Blanc';

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isRedTheme = prefs.getBool(_themeKey) ?? true;
      _updateSystemUI();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isRedTheme);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  void _updateSystemUI() {
    if (_isRedTheme) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.darkRed,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
    }
  }

  Future<void> toggleTheme() async {
    _isRedTheme = !_isRedTheme;
    _updateSystemUI();
    notifyListeners();
    await _saveTheme();
  }

  IconData get themeIcon => _isRedTheme ? Icons.palette : Icons.palette_outlined;
  IconData get themeIconAlt => _isRedTheme ? Icons.dark_mode : Icons.light_mode;

  Color get themeColor => _isRedTheme ? AppColors.primaryRed : AppColors.white;
  Color get contrastColor => _isRedTheme ? AppColors.white : AppColors.primaryRed;
  Color get backgroundColor => _isRedTheme ? AppColors.darkRed : AppColors.white;
  Color get surfaceColor => _isRedTheme ? AppColors.secondaryRed : AppColors.white;
  Color get textColor => _isRedTheme ? AppColors.white : AppColors.grey900;
  Color get secondaryTextColor => _isRedTheme ? AppColors.whiteOpacity(0.7) : AppColors.grey700;
  Color get accentColor => _isRedTheme ? AppColors.gold : AppColors.primaryRed;
  Color get borderColor => _isRedTheme ? AppColors.whiteOpacity(0.3) : AppColors.grey300;
  Color get dividerColor => _isRedTheme ? AppColors.whiteOpacity(0.2) : AppColors.grey200;
  Color get shadowColor => _isRedTheme ? AppColors.blackOpacity(0.3) : AppColors.grey300;
}