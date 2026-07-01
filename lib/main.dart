import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'presentation/router.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/game_repository.dart';

// DESIGN.md 기반 색상 토큰
class SabotageColors {
  // Background & Surface
  static const background = Color(0xFF121316);
  static const surfaceDim = Color(0xFF121316);
  static const surfaceContainerLowest = Color(0xFF0D0E11);
  static const surfaceContainerLow = Color(0xFF1B1B1F);
  static const surfaceContainer = Color(0xFF1F1F23);
  static const surfaceContainerHigh = Color(0xFF292A2D);
  static const surfaceContainerHighest = Color(0xFF343538);
  static const panelCharcoal = Color(0xFF292A2D);

  // Text
  static const onSurface = Color(0xFFE3E2E6);
  static const onSurfaceVariant = Color(0xFFD0C6AB);
  static const muted = Color(0xFF999077);

  // Primary (Gold)
  static const primary = Color(0xFFFFF6DF);
  static const primaryContainer = Color(0xFFFFD700);
  static const surfaceTint = Color(0xFFE9C400);
  static const onPrimary = Color(0xFF3A3000);

  // Secondary (Burnt Sienna)
  static const secondary = Color(0xFFFFB68C);
  static const secondaryContainer = Color(0xFF753401);
  static const onSecondaryContainer = Color(0xFFFC9E65);

  // Outline / Border
  static const outline = Color(0xFF999077);
  static const outlineVariant = Color(0xFF4D4732);
  static const borderBrass = Color(0xFF4D4732);

  // Error
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);

  // Glow
  static const goldGlow = Color(0x66753401); // rgba(117, 52, 1, 0.4)
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (flutterfire configure를 통해 생성된 옵션 사용)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 익명 로그인 수행
  final authRepo = AuthRepository();
  await authRepo.signInAnonymously();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        Provider<GameRepository>(create: (_) => GameRepository()),
      ],
      child: const SabotageApp(),
    ),
  );
}

class SabotageApp extends StatelessWidget {
  const SabotageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saboteur: Under the Surface',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: SabotageColors.primaryContainer,   // #FFD700 골드
          onPrimary: SabotageColors.onPrimary,
          secondary: SabotageColors.secondary,         // #FFB68C 번트 시에나
          onSecondary: Color(0xFF532200),
          surface: SabotageColors.surfaceContainerLow,
          onSurface: SabotageColors.onSurface,
          error: SabotageColors.error,
          outline: SabotageColors.outline,
          outlineVariant: SabotageColors.outlineVariant,
        ),
        scaffoldBackgroundColor: SabotageColors.background,
        fontFamily: 'Work Sans',  // body-md / body-lg
      ),
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
