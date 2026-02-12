import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../goals/data/providers/savings_provider.dart';
import '../../../goals/data/providers/challenge_provider.dart';
import '../../../goals/data/providers/settings_provider.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../../premium/presentation/screens/paywall_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    final totalSaved = ref.watch(totalSavedProvider);
    final totalRoundUps = ref.watch(totalRoundUpsProvider);
    final roundUpsEnabled = ref.watch(roundUpsEnabledProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final streak = ref.watch(savingsStreakProvider);
    final challengeSavings = ref.watch(totalChallengeSavingsProvider);
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final roundUpRule = ref.watch(roundUpRuleProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);

    final monthlyAvg = goals.isEmpty
        ? 0.0
        : goals.fold(0.0, (sum, g) {
            final months = DateTime.now().difference(g.createdAt).inDays / 30.0;
            return sum + (months > 0 ? g.currentAmount / months : 0);
          });

    final activeGoals =
        goals.where((g) => g.currentAmount > 0 && !g.isComplete).length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Profile & Settings',
            style: AppTextStyles.headlineMedium
                .copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundDark.withBlue(30)
            ],
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
                _buildStatsGrid(
                    totalSaved, monthlyAvg, totalRoundUps, challengeSavings),
                const SizedBox(height: 24),
                _buildPremiumSection(),
                const SizedBox(height: 16),
                _buildCurrencySection(currency),
                const SizedBox(height: 16),
                _buildThemeSection(themeMode),
                const SizedBox(height: 16),
                _buildRoundUpRulesSection(roundUpsEnabled, roundUpRule),
                const SizedBox(height: 16),
                _buildNotificationsSection(notificationsEnabled),
                const SizedBox(height: 16),
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
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
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
                border:
                    Border.all(color: AppColors.backgroundDark, width: 3),
              ),
              child: const Icon(Icons.star_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Smart Saver',
            style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('user@smartsave.app',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textTertiaryDark)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$activeGoals Active',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFFB020)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$streak Day Streak',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(double totalSaved, double monthlyAvg,
      double roundUps, double challengeSavings) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Total Saved',
                    '\$${totalSaved.toStringAsFixed(0)}',
                    Icons.savings_rounded, AppColors.primaryGreen)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Monthly Avg',
                    '\$${monthlyAvg.toStringAsFixed(0)}',
                    Icons.trending_up_rounded, AppColors.primaryBlue)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard('Round-ups',
                    '\$${roundUps.toStringAsFixed(0)}',
                    Icons.currency_exchange_rounded, AppColors.accentGold)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard('Challenges',
                    '\$${challengeSavings.toStringAsFixed(0)}',
                    Icons.emoji_events_rounded, const Color(0xFF8B5CF6))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textTertiaryDark),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPremiumSection() {
    final isPremium = ref.watch(premiumProvider);

    return GlassCard(
      margin: EdgeInsets.zero,
      onTap: isPremium ? null : () => PaywallScreen.show(context),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isPremium ? AppColors.wealthGradient : AppColors.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Rebecca Premium' : 'Upgrade to Premium',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? 'You have full access to all features'
                      : 'Unlock AI insights, export, multi-currency & more',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
          if (!isPremium)
            const Icon(Icons.chevron_right_rounded, color: AppColors.accentGold),
        ],
      ),
    );
  }

  Widget _buildCurrencySection(String currency) {
    final currencies = [
      {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'name': 'Euro', 'symbol': '\u20AC'},
      {'code': 'GBP', 'name': 'British Pound', 'symbol': '\u00A3'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '\u00A5'},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'CA\$'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'AU\$'},
      {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
      {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '\u20B9'},
      {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '\u20BA'},
      {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    ];

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.attach_money_rounded,
                    color: AppColors.accentGold, size: 22),
              ),
              const SizedBox(width: 12),
              Text('Currency',
                  style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: currencies.map((c) {
              final isSelected = currency == c['code'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(currencyProvider.notifier)
                      .setCurrency(c['code']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGold.withValues(alpha: 0.2)
                        : AppColors.backgroundDarkCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGold
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Text(
                    '${c['symbol']} ${c['code']}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.accentGold
                          : AppColors.textSecondaryDark,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(ThemeMode themeMode) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            themeMode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: AppColors.primaryBlue,
            size: 22,
          ),
        ),
        title: Text('Dark Theme',
            style: AppTextStyles.titleSmall
                .copyWith(color: AppColors.textPrimaryDark)),
        subtitle: Text(
            themeMode == ThemeMode.dark ? 'Currently active' : 'Switch to dark mode',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiaryDark)),
        trailing: Switch(
          value: themeMode == ThemeMode.dark,
          onChanged: (v) {
            HapticFeedback.lightImpact();
            ref.read(themeModeProvider.notifier).toggle();
          },
          activeThumbColor: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildRoundUpRulesSection(bool roundUpsEnabled, int roundUpRule) {
    final ruleLabels = ['Nearest \$1', 'Nearest \$2', 'Nearest \$5'];
    final ruleDescriptions = [
      'Round purchases up to the next whole dollar',
      'Round purchases up to the next \$2 increment',
      'Round purchases up to the next \$5 increment',
    ];

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded,
                        color: AppColors.accentGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Round-Up Rules',
                      style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Switch(
                value: roundUpsEnabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  ref.read(roundUpsEnabledProvider.notifier).set(v);
                },
                activeThumbColor: AppColors.accentGold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(3, (i) {
            final isSelected = roundUpRule == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(roundUpRuleProvider.notifier).setRule(i);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentGold.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGold
                        : AppColors.glassBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.accentGold
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentGold
                              : AppColors.textTertiaryDark,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ruleLabels[i],
                            style: AppTextStyles.titleSmall.copyWith(
                              color: isSelected
                                  ? AppColors.accentGold
                                  : AppColors.textPrimaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ruleDescriptions[i],
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textTertiaryDark),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection(bool notificationsEnabled) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: AppColors.primaryGreen, size: 22),
            ),
            title: Text('Notifications',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.textPrimaryDark)),
            subtitle: Text('Savings reminders & milestones',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiaryDark)),
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                ref.read(notificationsProvider.notifier).toggle();
              },
              activeThumbColor: AppColors.primaryGreen,
            ),
          ),
          Divider(color: AppColors.glassBorder, indent: 70, endIndent: 20),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint_rounded,
                  color: Color(0xFF8B5CF6), size: 22),
            ),
            title: Text('Biometric Login',
                style: AppTextStyles.titleSmall
                    .copyWith(color: AppColors.textPrimaryDark)),
            subtitle: Text('Face ID / Fingerprint',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiaryDark)),
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: (v) {
                HapticFeedback.lightImpact();
                setState(() => _biometricEnabled = v);
              },
              activeThumbColor: const Color(0xFF8B5CF6),
            ),
          ),
        ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('ACCOUNT',
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiaryDark, letterSpacing: 1)),
          ),
          _buildSettingsItem(Icons.account_balance_rounded, 'Linked Accounts',
              onTap: () {}),
          _buildDivider(),
          _buildSettingsItem(Icons.security_rounded, 'Security',
              onTap: () {}),
          _buildDivider(),
          _buildSettingsItem(Icons.help_outline_rounded, 'Help & Support',
              onTap: () {}),
          _buildDivider(),
          _buildSettingsItem(Icons.info_outline_rounded, 'About Rebecca',
              onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Rebecca',
              applicationVersion: '1.0.0',
              applicationLegalese:
                  'Personal finance, budget tracking & micro-savings.\nPowered by RevenueCat.',
            );
          }),
          _buildDivider(),
          _buildSettingsItem(Icons.logout_rounded, 'Sign Out',
              textColor: AppColors.loss, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title,
      {Color? textColor, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (textColor ?? AppColors.primaryGreen).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: textColor ?? AppColors.primaryGreen, size: 22),
      ),
      title: Text(title,
          style: AppTextStyles.titleSmall
              .copyWith(color: textColor ?? AppColors.textPrimaryDark)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textTertiaryDark),
    );
  }

  Widget _buildDivider() =>
      Divider(color: AppColors.glassBorder, indent: 70, endIndent: 20);
}
