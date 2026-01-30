import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../goals/data/providers/savings_provider.dart';
import '../../../goals/data/providers/settings_provider.dart';
import '../../../goals/data/models/round_up_transaction.dart';

class RoundUpScreen extends ConsumerWidget {
  const RoundUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roundUps = ref.watch(roundUpProvider);
    final totalRoundUps = ref.watch(totalRoundUpsProvider);
    final roundUpsEnabled = ref.watch(roundUpsEnabledProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final roundUpRule = ref.watch(roundUpRuleProvider);

    final weeklyRoundUps = roundUps
        .where(
            (t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold(0.0, (sum, t) => sum + t.roundUpAmount);

    final monthlyRoundUps = roundUps
        .where(
            (t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .fold(0.0, (sum, t) => sum + t.roundUpAmount);

    final ruleLabels = ['Nearest \$1', 'Nearest \$2', 'Nearest \$5'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Round-Up Savings',
          style:
              AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showSimulateRoundUpDialog(context, ref),
          ),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total round-ups hero card
                _buildHeroCard(totalRoundUps, weeklyRoundUps, monthlyRoundUps),
                const SizedBox(height: 20),

                // Enable toggle + rule
                _buildSettingsCard(
                    context, ref, roundUpsEnabled, roundUpRule, ruleLabels),
                const SizedBox(height: 20),

                // Simulate purchase button
                _buildSimulateButton(context, ref),
                const SizedBox(height: 24),

                // Assign to goal
                if (goals.isNotEmpty) ...[
                  _buildAssignToGoalCard(context, ref, roundUps, goals),
                  const SizedBox(height: 24),
                ],

                // Transaction history
                Text(
                  'Transaction History',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (roundUps.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: AppColors.textTertiaryDark, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No round-up transactions yet',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textTertiaryDark),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...roundUps
                      .take(20)
                      .map((txn) => _buildTransactionItem(txn)),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(
      double total, double weekly, double monthly) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Round-Up Savings',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white70)),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: total),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Text(
                          '\$${NumberFormat('#,##0.00').format(value)}',
                          style: AppTextStyles.moneyLarge
                              .copyWith(color: Colors.white),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.currency_exchange_rounded,
                    color: Colors.white, size: 36),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Week',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70)),
                    Text('+\$${weekly.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('This Month',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white70)),
                    Text('+\$${monthly.toStringAsFixed(2)}',
                        style: AppTextStyles.titleLarge
                            .copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, WidgetRef ref,
      bool enabled, int rule, List<String> ruleLabels) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.currency_exchange_rounded,
                      color: AppColors.accentGold, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Round-Ups Active',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.textPrimaryDark),
                  ),
                ],
              ),
              Switch(
                value: enabled,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  ref.read(roundUpsEnabledProvider.notifier).set(v);
                },
                activeColor: AppColors.accentGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Round-up rule: ',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiaryDark)),
              const Spacer(),
              ...List.generate(3, (i) {
                final isSelected = rule == i;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(roundUpRuleProvider.notifier).setRule(i);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold.withOpacity(0.2)
                            : AppColors.backgroundDarkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.accentGold
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Text(
                        ruleLabels[i],
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected
                              ? AppColors.accentGold
                              : AppColors.textTertiaryDark,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulateButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () => _showSimulateRoundUpDialog(context, ref),
        icon: const Icon(Icons.shopping_cart_rounded, size: 22),
        label: const Text('Simulate Purchase',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGold,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildAssignToGoalCard(BuildContext context, WidgetRef ref,
      List<RoundUpTransaction> roundUps, List goals) {
    final unassigned = roundUps.where((t) => t.goalId == null).toList();
    final totalUnassigned =
        unassigned.fold(0.0, (sum, t) => sum + t.roundUpAmount);

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_rounded,
                  color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Assign to Goal',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '\$${totalUnassigned.toStringAsFixed(2)} unassigned',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Tap a goal to add your unassigned round-ups to it',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiaryDark),
          ),
          const SizedBox(height: 12),
          if (totalUnassigned > 0)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goals.take(4).map<Widget>((goal) {
                return GestureDetector(
                  onTap: () async {
                    if (totalUnassigned > 0) {
                      final milestone = await ref
                          .read(savingsGoalsProvider.notifier)
                          .addToGoal(goal.id, totalUnassigned);
                      ref
                          .read(savingsStreakProvider.notifier)
                          .recordSaving();
                      ref
                          .read(monthlySavingsProvider.notifier)
                          .addToMonth(totalUnassigned);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Added \$${totalUnassigned.toStringAsFixed(2)} to ${goal.name}!')),
                        );
                        if (milestone != null) {
                          _showCelebration(context, milestone);
                        }
                      }
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded,
                            color: AppColors.primaryGreen, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          goal.name,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'All round-ups have been assigned',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiaryDark),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(RoundUpTransaction txn) {
    final timeStr = _timeAgo(txn.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag_rounded,
                color: AppColors.accentGold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.merchant,
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.textPrimaryDark),
                ),
                Text(
                  'Purchase: \$${txn.originalAmount.toStringAsFixed(2)}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+\$${txn.roundUpAmount.toStringAsFixed(2)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                timeStr,
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textTertiaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  void _showSimulateRoundUpDialog(BuildContext context, WidgetRef ref) {
    final merchantController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final amount = double.tryParse(amountController.text) ?? 0.0;
          final rule = ref.read(roundUpRuleProvider);
          double roundUp = 0.0;
          if (amount > 0) {
            final target = rule == 0 ? 1.0 : (rule == 1 ? 2.0 : 5.0);
            final remainder = amount % target;
            roundUp = remainder == 0 ? target : double.parse((target - remainder).toStringAsFixed(2));
          }

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkElevated,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiaryDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Simulate Purchase',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a purchase to see how round-ups save spare change',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: merchantController,
                  style: TextStyle(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Merchant',
                    labelStyle:
                        TextStyle(color: AppColors.textTertiaryDark),
                    hintText: 'e.g. Coffee Shop',
                    hintStyle: TextStyle(
                        color:
                            AppColors.textTertiaryDark.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accentGold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: TextStyle(color: AppColors.textPrimaryDark),
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Purchase Amount (\$)',
                    labelStyle:
                        TextStyle(color: AppColors.textTertiaryDark),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(color: AppColors.accentGold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accentGold),
                    ),
                  ),
                ),
                if (amount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.accentGold.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Round-up amount',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiaryDark)),
                            Text(
                              '\$${roundUp.toStringAsFixed(2)}',
                              style: AppTextStyles.moneyMedium.copyWith(
                                  color: AppColors.accentGold),
                            ),
                          ],
                        ),
                        Icon(Icons.savings_rounded,
                            color: AppColors.accentGold, size: 32),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final purchaseAmount =
                          double.tryParse(amountController.text);
                      final merchant = merchantController.text.trim();
                      if (purchaseAmount != null &&
                          purchaseAmount > 0 &&
                          merchant.isNotEmpty) {
                        final txn = await ref
                            .read(roundUpProvider.notifier)
                            .simulatePurchase(merchant, purchaseAmount);
                        ref
                            .read(savingsStreakProvider.notifier)
                            .recordSaving();
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Round-up: \$${txn.roundUpAmount.toStringAsFixed(2)} saved from \$${purchaseAmount.toStringAsFixed(2)} purchase!',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Simulate Purchase',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCelebration(BuildContext context, MilestoneReached milestone) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: AppColors.primaryGreen.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.emoji_events_rounded,
                    color: AppColors.primaryGreen, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Milestone Reached!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(milestone.message,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondaryDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Awesome!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
