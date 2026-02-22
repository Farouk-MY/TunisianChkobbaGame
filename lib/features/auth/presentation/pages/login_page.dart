// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/theme/theme_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _cardController;
  late AnimationController _shimmerController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String _loadingProvider = '';

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _cardController.repeat();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _cardController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleSocialLogin(String provider) {
    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  void _handleGuestLogin() {
    Navigator.pushReplacementNamed(context, '/home');
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
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildContent(themeProvider),
                    ),
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
        Positioned(
          top: 60,
          left: 50,
          child: AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _shimmerController.value * 2 * math.pi,
                child: Icon(
                  Icons.star,
                  color: themeProvider.isRedTheme
                      ? AppColors.goldOpacity(0.4)
                      : AppColors.primaryRedOpacity(0.4),
                  size: 25,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: 80,
          right: 100,
          child: AnimatedBuilder(
            animation: _cardController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  3 * math.sin(_cardController.value * 2 * math.pi),
                  6 * math.sin(_cardController.value * 2 * math.pi + 1),
                ),
                child: Container(
                  width: 24,
                  height: 34,
                  decoration: BoxDecoration(
                    color: themeProvider.isRedTheme
                        ? AppColors.whiteOpacity(0.12)
                        : AppColors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: themeProvider.isRedTheme
                          ? AppColors.goldOpacity(0.3)
                          : AppColors.primaryRedOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.heartSymbol,
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    return Center(
      child: Row(
        children: [
          const Spacer(),

          // Left side - Logo
          Expanded(
            flex: 2,
            child: _buildLogo(themeProvider),
          ),

          const SizedBox(width: 40),

          // Right side - Login Card
          Expanded(
            flex: 3,
            child: _buildLoginCard(themeProvider),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildLogo(ThemeProvider themeProvider) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildMiniCard(AppStrings.heartSymbol, AppColors.primaryRed, -10, 0),
              _buildMiniCard(AppStrings.diamondSymbol, AppColors.gold, 10, 2),
            ],
          ),
        ),

        const SizedBox(height: 16),

        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: themeProvider.isRedTheme
                ? [AppColors.white, AppColors.gold]
                : [AppColors.primaryRed, AppColors.gold],
          ).createShader(bounds),
          child: const Text(
            AppStrings.appName,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: themeProvider.isRedTheme
                ? AppColors.goldOpacity(0.15)
                : AppColors.primaryRedOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: themeProvider.isRedTheme
                  ? AppColors.goldOpacity(0.3)
                  : AppColors.primaryRedOpacity(0.3),
            ),
          ),
          child: Text(
            AppStrings.traditionalGame,
            style: TextStyle(
              fontSize: 11,
              color: themeProvider.accentColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard(String symbol, Color color, double offsetX, double animOffset) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            offsetX + 2 * math.sin(_cardController.value * 2 * math.pi + animOffset),
            2 * math.sin(_cardController.value * 2 * math.pi + animOffset + 1),
          ),
          child: Container(
            width: 28,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackOpacity(0.2),
                  offset: const Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                symbol,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCard(ThemeProvider themeProvider) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeProvider.isRedTheme
            ? AppColors.whiteOpacity(0.1)
            : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: themeProvider.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.shadowColor,
            offset: const Offset(0, 8),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSocialButton(
            'Facebook',
            Icons.facebook,
            const Color(0xFF1877F2),
            themeProvider,
          ),

          const SizedBox(height: 16),

          _buildSocialButton(
            'Google',
            Icons.g_mobiledata,
            AppColors.white,
            themeProvider,
            isGoogle: true,
          ),

          const SizedBox(height: 20),

          _buildDivider(themeProvider),

          const SizedBox(height: 16),

          _buildGuestButton(themeProvider),

          const SizedBox(height: 20),

          _buildFooter(themeProvider),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color bgColor, ThemeProvider themeProvider, {bool isGoogle = false}) {
    final isLoading = _isLoading && _loadingProvider == label;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : () => _handleSocialLogin(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: isGoogle ? AppColors.grey900 : AppColors.white,
          elevation: isGoogle ? 0 : 2,
          side: isGoogle ? BorderSide(color: AppColors.grey300) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeProvider themeProvider) {
    return Row(
      children: [
        Expanded(child: Divider(color: themeProvider.dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppStrings.or,
            style: TextStyle(
              color: themeProvider.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: themeProvider.dividerColor)),
      ],
    );
  }

  Widget _buildGuestButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: _handleGuestLogin,
        style: TextButton.styleFrom(
          foregroundColor: themeProvider.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          AppStrings.continueAsGuest,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeProvider themeProvider) {
    return Text.rich(
      TextSpan(
        text: AppStrings.byContinuing,
        style: TextStyle(
          color: themeProvider.secondaryTextColor,
          fontSize: 11,
        ),
        children: [
          TextSpan(
            text: ' ${AppStrings.terms}',
            style: TextStyle(
              color: themeProvider.accentColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          TextSpan(text: AppStrings.and),
          TextSpan(
            text: AppStrings.privacy,
            style: TextStyle(
              color: themeProvider.accentColor,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}