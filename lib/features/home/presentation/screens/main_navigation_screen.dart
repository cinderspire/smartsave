import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../jars/presentation/screens/jars_screen.dart';
import '../../../stats/presentation/screens/stats_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../coach/presentation/screens/coach_screen.dart';
import '../../../expenses/presentation/screens/expenses_screen.dart';
import 'dashboard_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  List<_NavTab> get _tabs {
    final tabs = <_NavTab>[
      _NavTab(Icons.home_rounded, 'Home', const DashboardScreen(), true),
      _NavTab(Icons.receipt_long_rounded, 'Expenses', const ExpensesScreen(), FeatureFlags.expenses),
      _NavTab(Icons.account_balance_rounded, 'Jars', const JarsScreen(), FeatureFlags.moneyJars),
      _NavTab(Icons.psychology_rounded, 'AI Coach', const CoachScreen(), FeatureFlags.aiCoach),
      _NavTab(Icons.settings_rounded, 'Settings', const ProfileScreen(), FeatureFlags.settingsTab),
    ];
    return tabs.where((t) => t.enabled).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activeTabs = _tabs;
    final safeIndex = _selectedIndex.clamp(0, activeTabs.length - 1);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: activeTabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: _buildBottomNav(activeTabs, safeIndex),
    );
  }

  Widget _buildBottomNav(List<_NavTab> tabs, int selected) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
              tabs.length,
              (index) => _buildNavItem(index, tabs, selected),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, List<_NavTab> tabs, int selected) {
    final isSelected = selected == index;
    final tab = tabs[index];

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
          tab.icon,
          color: isSelected ? Colors.white : AppColors.textTertiaryDark,
          size: 22,
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final Widget screen;
  final bool enabled;
  const _NavTab(this.icon, this.label, this.screen, this.enabled);
}
