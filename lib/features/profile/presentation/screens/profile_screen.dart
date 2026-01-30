import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../goals/data/providers/savings_provider.dart';
import '../../../goals/data/providers/challenge_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    final totalSaved = ref.watch(totalSavedProvider);
    final totalRoundUps = ref.watch(totalRoundUpsProvider);
    final roundUpsEnabled = ref.watch(roundUpsEnabledProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final streak = ref.watch(savingsStreakProvider);
    final challengeSavings = ref.watch(totalChallengeSavingsProvider);

    final monthlyAvg = goals.isEmpty
        ? 0.0
        : goals.fold(0.0, (sum, g) {
            final months = DateTime.now().difference(g.createdAt).inDays / 30.0;
            return sum + (months > 0 ? g.currentAmount / months : 0);
          });

    final activeGoals = goals.where((g) => g.currentAmount > 0 && !g.isComplete).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings_rounded), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundDark, AppColors.backgroundDark.withBlue(30)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileHeader(activeGoals, streak.currentStreak),
                const SizedBox(height: 24),
                _buildStatsGrid(totalSaved, monthlyAvg, totalRoundUps, challengeSavings),
                const SizedBox(height: 24),
                _buildPremiumCard(),
                const SizedBox(height: 24),
                _buildSettingsSection(roundUpsEnabled),
                const SizedBox(height: 24),
                _buildAccountSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(int activeGoals, int streak) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.wealthGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.person_rounded, color: Colors.white, size: 48),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.backgroundDark, width: 3),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Smart Saver', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('user@smartsave.app', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$activeGoals Active', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFFB020)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$streak Day Streak', style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(double totalSaved, double monthlyAvg, double roundUps, double challengeSavings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard('Total Saved', '\$${totalSaved.toStringAsFixed(0)}', Icons.savings_rounded, AppColors.primaryGreen)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Monthly Avg', '\$${monthlyAvg.toStringAsFixed(0)}', Icons.trending_up_rounded, AppColors.primaryBlue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Round-ups', '\$${roundUps.toStringAsFixed(0)}', Icons.currency_exchange_rounded, AppColors.accentGold)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Challenges', '\$${challengeSavings.toStringAsFixed(0)}', Icons.emoji_events_rounded, const Color(0xFF8B5CF6))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen.withOpacity(0.3), AppColors.primaryBlue.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upgrade to Premium', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
                    Text('Unlock advanced features', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GradientButton(text: 'Start Free Trial', onPressed: () {}, width: double.infinity, height: 48, gradient: AppColors.goldGradient),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool roundUpsEnabled) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('SETTINGS', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark, letterSpacing: 1)),
          ),
          _buildToggleSetting(
            Icons.currency_exchange_rounded,
            'Round-ups',
            'Auto-save spare change',
            roundUpsEnabled,
            (v) => ref.read(roundUpsEnabledProvider.notifier).set(v),
          ),
          _buildDivider(),
          _buildToggleSetting(Icons.notifications_rounded, 'Notifications', 'Savings reminders', _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
          _buildDivider(),
          _buildToggleSetting(Icons.fingerprint_rounded, 'Biometric Login', 'Face ID / Fingerprint', _biometricEnabled, (v) => setState(() => _biometricEnabled = v)),
        ],
      ),
    );
  }

  Widget _buildToggleSetting(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 22),
      ),
      title: Text(title, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark)),
      subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          HapticFeedback.lightImpact();
          onChanged(v);
        },
        activeColor: AppColors.primaryGreen,
      ),
    );
  }

  Widget _buildAccountSection() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('ACCOUNT', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark, letterSpacing: 1)),
          ),
          _buildSettingsItem(Icons.account_balance_rounded, 'Linked Accounts', onTap: () {}),
          _buildDivider(),
          _buildSettingsItem(Icons.security_rounded, 'Security', onTap: () {}),
          _buildDivider(),
          _buildSettingsItem(Icons.help_outline_rounded, 'Help & Support', onTap: () {}),
          _buildDivider(),
          _buildSettingsItem(Icons.logout_rounded, 'Sign Out', textColor: AppColors.loss, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {Color? textColor, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primaryGreen).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: textColor ?? AppColors.primaryGreen, size: 22),
      ),
      title: Text(title, style: AppTextStyles.titleSmall.copyWith(color: textColor ?? AppColors.textPrimaryDark)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textTertiaryDark),
    );
  }

  Widget _buildDivider() => Divider(color: AppColors.glassBorder, indent: 70, endIndent: 20);
}
