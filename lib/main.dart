// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/game/presentation/pages/rules_page.dart';
import 'features/game/presentation/providers/game_provider.dart';
import 'features/game/domain/usecases/initialize_game_usecase.dart';
import 'features/game/domain/usecases/play_card_usecase.dart';
import 'features/game/domain/usecases/validate_capture_usecase.dart';
import 'features/game/domain/usecases/calculate_score_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ChkobaApp());
}

class ChkobaApp extends StatelessWidget {
  const ChkobaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),

        // Game Provider
        ChangeNotifierProvider(
          create: (_) {
            final validateCaptureUseCase = ValidateCaptureUseCase();
            final calculateScoreUseCase = CalculateScoreUseCase();

            return GameProvider(
              initializeGameUseCase: InitializeGameUseCase(),
              playCardUseCase: PlayCardUseCase(
                validateCaptureUseCase: validateCaptureUseCase,
                calculateScoreUseCase: calculateScoreUseCase,
              ),
              validateCaptureUseCase: validateCaptureUseCase,
            );
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Chkoba Tunisienne',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashPage(),
              '/login': (context) => const LoginPage(),
              '/home': (context) => const ChkobaHomePage(),
              '/settings': (context) => const SettingsPage(),
              '/rules': (context) => const RulesPage(),
            },
          );
        },
      ),
    );
  }
}