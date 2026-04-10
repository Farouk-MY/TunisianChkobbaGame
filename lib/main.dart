import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/profile_service.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/game_history_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/game/presentation/pages/rules_page.dart';
import 'features/tutorial/presentation/pages/tutorial_page.dart';
import 'features/game/presentation/providers/game_provider.dart';
import 'features/game/domain/usecases/initialize_game_usecase.dart';
import 'features/game/domain/usecases/play_card_usecase.dart';
import 'features/game/domain/usecases/validate_capture_usecase.dart';
import 'features/game/domain/usecases/calculate_score_usecase.dart';
import 'features/multiplayer/presentation/pages/lobby_page.dart';
import 'features/multiplayer/presentation/pages/online_game_page.dart';
import 'features/multiplayer/presentation/providers/online_game_provider.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/leaderboard/presentation/pages/leaderboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Supabase
  await SupabaseService.initialize();

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

        // Auth Provider
        ChangeNotifierProvider(
          create: (_) => AuthService(),
        ),

        // Profile Provider (caching layer over Supabase)
        ChangeNotifierProxyProvider<AuthService, ProfileService>(
          create: (_) => ProfileService(),
          update: (_, auth, profile) {
            final p = profile ?? ProfileService();
            // Load profile whenever the user changes
            if (auth.userId != null && !p.loaded) {
              p.load(auth.userId!);
            } else if (auth.userId == null && p.loaded) {
              p.clear();
            }
            return p;
          },
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

        // Online Game Provider
        ChangeNotifierProvider(
          create: (_) {
            final validateCapture = ValidateCaptureUseCase();
            final calculateScore = CalculateScoreUseCase();
            return OnlineGameProvider(
              initializeGameUseCase: InitializeGameUseCase(),
              playCardUseCase: PlayCardUseCase(
                validateCaptureUseCase: validateCapture,
                calculateScoreUseCase: calculateScore,
              ),
              validateCaptureUseCase: validateCapture,
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
              '/history': (context) => const GameHistoryPage(),
              '/settings': (context) => const SettingsPage(),
              '/rules': (context) => const RulesPage(),
              '/tutorial': (context) => const TutorialPage(),
              '/lobby': (context) => const LobbyPage(),
              '/online-game': (context) => const OnlineGamePage(),
              '/profile': (context) => const ProfilePage(),
              '/leaderboard': (context) => const LeaderboardPage(),
            },
          );
        },
      ),
    );
  }
}

