import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_colors.dart';
import 'core/services/revenue_cat_service.dart';
import 'features/goals/data/providers/settings_provider.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? true; // Demo mode: skip onboarding

  // Initialize RevenueCat (non-blocking – app works in free-tier if this fails).
  RevenueCatService.instance.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ProviderScope(child: RebeccaApp(showOnboarding: !onboardingComplete)));
}

class RebeccaApp extends ConsumerWidget {
  final bool showOnboarding;
  const RebeccaApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Rebecca',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.accentGreen,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accentGreen,
          secondary: AppColors.secondary,
          tertiary: AppColors.accentBlue,
          surface: AppColors.backgroundDarkCard,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
      ),
      home: showOnboarding ? const OnboardingScreen() : const MainNavigationScreen(),
    );
  }
}
