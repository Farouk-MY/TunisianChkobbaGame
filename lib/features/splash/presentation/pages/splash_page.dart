// lib/features/splash/presentation/pages/splash_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/theme/theme_provider.dart';
import 'dart:math' as math;

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late AnimationController _progressController;
  late AnimationController _sparkleController;

  late Animation<double> _fadeAnimation;

  String _loadingText = AppStrings.shufflingCards;
  int _currentMessageIndex = 0;

  final List<String> _loadingMessages = [
    AppStrings.shufflingCards,
    AppStrings.preparingGame,
    AppStrings.welcomeMessage,
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: AppDurations.slower,
      vsync: this,
    );

    _cardController = AnimationController(
      duration: AppDurations.veryLong,
      vsync: this,
    );

    _progressController = AnimationController(
      duration: AppDurations.extraLong,
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: AppDurations.long,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  void _startAnimations() {
    _fadeController.forward();
    _cardController.repeat();
    _sparkleController.repeat();

    _progressController.addListener(_onProgressChanged);
    _progressController.forward().then((_) => _navigateToLogin());
  }

  void _onProgressChanged() {
    if (_progressController.value > 0.3 && _currentMessageIndex == 0) {
      setState(() {
        _loadingText = _loadingMessages[1];
        _currentMessageIndex = 1;
      });
    } else if (_progressController.value > 0.7 && _currentMessageIndex == 1) {
      setState(() {
        _loadingText = _loadingMessages[2];
        _currentMessageIndex = 2;
      });
    }
  }

  void _navigateToLogin() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    _progressController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.isRedTheme
                  ? AppColors.primaryGradient
                  : AppColors.whiteGradient,
            ),
            child: Stack(
              children: [
                _buildBackground(themeProvider),
                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _buildContent(themeProvider),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(ThemeProvider themeProvider) {
    return Stack(
      children: [
        _buildSparkle(themeProvider, top: 60, left: 50, size: 25),
        _buildSparkle(themeProvider, top: 100, right: 70, size: 20),
        _buildSparkle(themeProvider, bottom: 80, left: 80, size: 18),
      ],
    );
  }

  Widget _buildSparkle(ThemeProvider themeProvider, {double? top, double? bottom, double? left, double? right, required double size}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: _sparkleController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _sparkleController.value * 2 * math.pi,
            child: Icon(
              Icons.star,
              color: themeProvider.isRedTheme
                  ? AppColors.goldOpacity(0.4)
                  : AppColors.primaryRedOpacity(0.4),
              size: size,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Cards Animation
          _buildAnimatedCards(themeProvider),

          const SizedBox(width: 60),

          // Text Content
          _buildTextContent(themeProvider),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildAnimatedCards(ThemeProvider themeProvider) {
    return SizedBox(
      width: 140,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildCard(themeProvider, isBack: true, offset: 0, rotation: -12),
          _buildCard(themeProvider, symbol: AppStrings.diamondSymbol, color: AppColors.primaryRed, offset: 1, rotation: -4),
          _buildCard(themeProvider, symbol: AppStrings.heartSymbol, color: AppColors.primaryRed, offset: 2, rotation: 4),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeProvider themeProvider, {String? symbol, Color? color, bool isBack = false, required double offset, required double rotation}) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            rotation + 2 * math.sin(_cardController.value * 2 * math.pi + offset),
            3 * math.sin(_cardController.value * 2 * math.pi + offset + 1),
          ),
          child: Transform.rotate(
            angle: (rotation * 0.01) + 0.03 * math.sin(_cardController.value * 2 * math.pi + offset),
            child: Container(
              width: 85,
              height: 130,
              decoration: BoxDecoration(
                color: isBack ? AppColors.grey100 : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackOpacity(0.25),
                    offset: const Offset(0, 6),
                    blurRadius: 12,
                  ),
                ],
                border: Border.all(
                  color: isBack ? AppColors.grey300 : AppColors.grey200,
                  width: 1,
                ),
              ),
              child: isBack ? null : Center(
                child: Text(
                  symbol ?? '',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.black,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextContent(ThemeProvider themeProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: themeProvider.isRedTheme
                ? [AppColors.white, AppColors.gold]
                : [AppColors.primaryRed, AppColors.gold],
          ).createShader(bounds),
          child: Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              shadows: [
                Shadow(
                  offset: const Offset(2, 2),
                  blurRadius: 8,
                  color: themeProvider.isRedTheme
                      ? Colors.black54
                      : Colors.grey.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          AppStrings.appSubtitle,
          style: TextStyle(
            fontSize: 16,
            color: themeProvider.isRedTheme
                ? AppColors.gold
                : AppColors.primaryRed,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 40),

        _buildProgressBar(themeProvider),

        const SizedBox(height: 16),

        AnimatedSwitcher(
          duration: AppDurations.quick,
          child: Text(
            _loadingText,
            key: ValueKey(_loadingText),
            style: TextStyle(
              color: themeProvider.textColor,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeProvider themeProvider) {
    return Container(
      width: 200,
      height: 6,
      decoration: BoxDecoration(
        color: themeProvider.isRedTheme
            ? AppColors.whiteOpacity(0.2)
            : AppColors.grey300,
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 200 * _progressController.value,
              height: 6,
              decoration: BoxDecoration(
                gradient: themeProvider.isRedTheme
                    ? AppColors.goldGradient
                    : AppColors.redToWhiteGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        },
      ),
    );
  }
}