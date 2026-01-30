import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_colors.dart';
import 'features/goals/data/providers/settings_provider.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ProviderScope(child: SmartSaveApp(showOnboarding: !onboardingComplete)));
}

class SmartSaveApp extends ConsumerWidget {
  final bool showOnboarding;
  const SmartSaveApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'SmartSave',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryBlue,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryGreen,
          secondary: AppColors.primaryBlue,
          surface: AppColors.backgroundDarkCard,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
      ),
      home: showOnboarding ? const OnboardingScreen() : const MainNavigationScreen(),
    );
  }
}
