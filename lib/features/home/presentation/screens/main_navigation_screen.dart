import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../challenges/presentation/screens/challenges_screen.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../roundup/presentation/screens/roundup_screen.dart';
import '../../../stats/presentation/screens/stats_screen.dart';
import '../../../tips/presentation/screens/tips_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const GoalsScreen(),
    const RoundUpScreen(),
    const ChallengesScreen(),
    const StatsScreen(),
    const TipsScreen(),
    const ProfileScreen(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.flag_rounded, 'label': 'Goals'},
    {'icon': Icons.currency_exchange_rounded, 'label': 'Round-Up'},
    {'icon': Icons.emoji_events_rounded, 'label': 'Challenges'},
    {'icon': Icons.bar_chart_rounded, 'label': 'Stats'},
    {'icon': Icons.lightbulb_rounded, 'label': 'Tips'},
    {'icon': Icons.settings_rounded, 'label': 'Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: GlassmorphicContainer(
          blur: 15,
          opacity: 0.3,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _navItems.length,
              (index) => _buildNavItem(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = _selectedIndex == index;
    final item = _navItems[index];

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.wealthGradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          item['icon'] as IconData,
          color: isSelected ? Colors.white : AppColors.textTertiaryDark,
          size: 22,
        ),
      ),
    );
  }
}
