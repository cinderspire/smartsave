import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/models/savings_goal.dart';
import '../../data/providers/savings_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);
    final totalSaved = ref.watch(totalSavedProvider);
    final totalTarget = ref.watch(totalTargetProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Goals', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddGoalSheet(context, ref),
          ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressOverview(totalSaved, totalTarget),
                const SizedBox(height: 24),
                Text(
                  'Your Goals',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  _buildEmptyState(context, ref)
                else
                  ...goals.map((goal) => _buildGoalCard(context, ref, goal)),
                const SizedBox(height: 24),
                _buildTipsCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverview(double totalSaved, double totalTarget) {
    final progress = totalTarget > 0 ? (totalSaved / totalTarget * 100) : 0.0;

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Progress', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: totalSaved),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        '\$${value.toStringAsFixed(0)}',
                        style: AppTextStyles.moneyLarge.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    '${progress.toStringAsFixed(0)}%',
                    style: AppTextStyles.titleLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progress / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'of \$${totalTarget.toStringAsFixed(0)} total goal',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final color = _goalColor(goal.category);
    final icon = _goalIcon(goal.category);

    // Determine milestone icon
    IconData? milestoneIcon;
    if (goal.progressPercent >= 100) {
      milestoneIcon = Icons.emoji_events_rounded;
    } else if (goal.progressPercent >= 75) {
      milestoneIcon = Icons.rocket_launch_rounded;
    } else if (goal.progressPercent >= 50) {
      milestoneIcon = Icons.local_fire_department_rounded;
    } else if (goal.progressPercent >= 25) {
      milestoneIcon = Icons.star_rounded;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showGoalDetailsSheet(context, ref, goal);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textTertiaryDark),
                          const SizedBox(width: 4),
                          Text(
                            '${goal.daysLeft} days left',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (milestoneIcon != null) ...[
                          Icon(milestoneIcon, color: color, size: 20),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          '${goal.progressPercent.toStringAsFixed(0)}%',
                          style: AppTextStyles.headlineSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      goal.isComplete ? 'done!' : 'complete',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: AppColors.backgroundDarkElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text(
                      '\$${goal.currentAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Target', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text(
                      '\$${goal.targetAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Remaining', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text(
                      '\$${goal.remaining.toStringAsFixed(0)}',
                      style: AppTextStyles.titleMedium.copyWith(color: color),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.12)),
      ),
      child: Center(
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentGold.withOpacity(0.15),
                          AppColors.primaryGreen.withOpacity(0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.savings_rounded,
                        color: AppColors.accentGold.withOpacity(0.7), size: 48),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'No savings goals yet',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 10),
            Text(
              'Set a target and watch your\nsavings grow over time!',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              text: 'Create Goal',
              onPressed: () {
                HapticFeedback.lightImpact();
                _showAddGoalSheet(context, ref);
              },
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.wealthGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Enable round-ups to automatically save spare change from every purchase!',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGoalDetailsSheet(BuildContext context, WidgetRef ref, SavingsGoal goal) {
    final color = _goalColor(goal.category);
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiaryDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              goal.name,
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.progressPercent.toStringAsFixed(1)}% complete  --  ${goal.daysLeft} days left',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            // Milestone badges row
            _buildMilestoneBadges(goal.progressPercent, color),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: AppColors.backgroundDarkCard,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${goal.currentAmount.toStringAsFixed(0)} saved', style: AppTextStyles.bodySmall.copyWith(color: color)),
                Text('\$${goal.remaining.toStringAsFixed(0)} remaining', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Add amount (\$)',
                labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: color),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    final milestone = await ref.read(savingsGoalsProvider.notifier).addToGoal(goal.id, amount);
                    ref.read(savingsStreakProvider.notifier).recordSaving();
                    ref.read(monthlySavingsProvider.notifier).addToMonth(amount);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added \$${amount.toStringAsFixed(2)} to ${goal.name}!')),
                    );
                    if (milestone != null) {
                      _showMilestoneCelebration(context, milestone);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Add Savings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  ref.read(savingsGoalsProvider.notifier).deleteGoal(goal.id);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${goal.name} deleted')),
                  );
                },
                child: Text(
                  'Delete Goal',
                  style: AppTextStyles.labelLarge.copyWith(color: AppColors.loss),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneBadges(double percent, Color color) {
    final milestones = [
      {'value': 25, 'icon': Icons.star_rounded, 'label': '25%'},
      {'value': 50, 'icon': Icons.local_fire_department_rounded, 'label': '50%'},
      {'value': 75, 'icon': Icons.rocket_launch_rounded, 'label': '75%'},
      {'value': 100, 'icon': Icons.emoji_events_rounded, 'label': '100%'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: milestones.map((m) {
        final reached = percent >= (m['value'] as int);
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: reached ? color.withOpacity(0.2) : AppColors.backgroundDarkCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: reached ? color : AppColors.glassBorder,
                  width: reached ? 2 : 1,
                ),
              ),
              child: Icon(
                m['icon'] as IconData,
                color: reached ? color : AppColors.textTertiaryDark,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              m['label'] as String,
              style: AppTextStyles.labelSmall.copyWith(
                color: reached ? color : AppColors.textTertiaryDark,
                fontWeight: reached ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showMilestoneCelebration(BuildContext context, MilestoneReached milestone) {
    IconData milestoneIcon;
    Color milestoneColor;
    switch (milestone.percentage) {
      case 25:
        milestoneIcon = Icons.star_rounded;
        milestoneColor = AppColors.accentGold;
        break;
      case 50:
        milestoneIcon = Icons.local_fire_department_rounded;
        milestoneColor = const Color(0xFFFF6B35);
        break;
      case 75:
        milestoneIcon = Icons.rocket_launch_rounded;
        milestoneColor = const Color(0xFF8B5CF6);
        break;
      case 100:
        milestoneIcon = Icons.emoji_events_rounded;
        milestoneColor = AppColors.primaryGreen;
        break;
      default:
        milestoneIcon = Icons.star_rounded;
        milestoneColor = AppColors.accentGold;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkElevated,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: milestoneColor.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: milestoneColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(milestoneIcon, color: milestoneColor, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                'Milestone Reached!',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: milestoneColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                milestone.goalName,
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondaryDark),
              ),
              const SizedBox(height: 12),
              Text(
                '${milestone.percentage}% Complete',
                style: AppTextStyles.moneyMedium.copyWith(color: AppColors.textPrimaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                milestone.message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: milestoneColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    String selectedCategory = 'emergency';
    int deadlineDays = 180;

    final categories = [
      {'value': 'emergency', 'label': 'Emergency Fund', 'icon': Icons.shield_rounded},
      {'value': 'vacation', 'label': 'Vacation', 'icon': Icons.flight_rounded},
      {'value': 'education', 'label': 'Education', 'icon': Icons.school_rounded},
      {'value': 'gadget', 'label': 'Gadget', 'icon': Icons.devices_rounded},
      {'value': 'home', 'label': 'Home', 'icon': Icons.home_rounded},
      {'value': 'car', 'label': 'Car', 'icon': Icons.directions_car_rounded},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: BoxDecoration(
            color: AppColors.backgroundDarkElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
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
                  'Create New Goal',
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set a savings target and track your progress',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 24),

                // Goal Name
                TextField(
                  controller: nameController,
                  style: TextStyle(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Goal Name',
                    labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                    hintText: 'e.g. Emergency Fund',
                    hintStyle: TextStyle(color: AppColors.textTertiaryDark.withOpacity(0.5)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Target Amount
                TextField(
                  controller: targetController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Target Amount',
                    labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                    prefixText: '\$ ',
                    prefixStyle: TextStyle(color: AppColors.primaryGreen),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category
                Text(
                  'Category',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat['value'];
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCategory = cat['value'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _goalColor(cat['value'] as String).withOpacity(0.2)
                              : AppColors.backgroundDarkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? _goalColor(cat['value'] as String)
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              color: isSelected
                                  ? _goalColor(cat['value'] as String)
                                  : AppColors.textTertiaryDark,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat['label'] as String,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected
                                    ? _goalColor(cat['value'] as String)
                                    : AppColors.textSecondaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Deadline
                Text(
                  'Deadline: $deadlineDays days',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppColors.primaryGreen,
                    inactiveTrackColor: AppColors.backgroundDarkCard,
                    thumbColor: AppColors.primaryGreen,
                    overlayColor: AppColors.primaryGreen.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: deadlineDays.toDouble(),
                    min: 30,
                    max: 1095,
                    divisions: 21,
                    onChanged: (v) => setSheetState(() => deadlineDays = v.round()),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 month', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                    Text('3 years', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                  ],
                ),

                const SizedBox(height: 24),
                GradientButton(
                  text: 'Create Goal',
                  onPressed: () {
                    final name = nameController.text.trim();
                    final target = double.tryParse(targetController.text);
                    if (name.isNotEmpty && target != null && target > 0) {
                      final goal = SavingsGoal(
                        id: const Uuid().v4(),
                        name: name,
                        targetAmount: target,
                        deadline: DateTime.now().add(Duration(days: deadlineDays)),
                        category: selectedCategory,
                      );
                      ref.read(savingsGoalsProvider.notifier).addGoal(goal);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Goal "$name" created!')),
                      );
                    }
                  },
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _goalColor(String category) {
    switch (category) {
      case 'emergency': return const Color(0xFF10B981);
      case 'safety': return const Color(0xFF10B981);
      case 'vacation': return const Color(0xFFFFB020);
      case 'travel': return const Color(0xFFFFB020);
      case 'education': return const Color(0xFF8B5CF6);
      case 'gadget': return const Color(0xFF06B6D4);
      case 'home': return const Color(0xFFEC4899);
      case 'car': return const Color(0xFF3B82F6);
      case 'purchase': return const Color(0xFF3B82F6);
      default: return AppColors.primaryGreen;
    }
  }

  IconData _goalIcon(String category) {
    switch (category) {
      case 'emergency': return Icons.shield_rounded;
      case 'safety': return Icons.shield_rounded;
      case 'vacation': return Icons.flight_rounded;
      case 'travel': return Icons.flight_rounded;
      case 'education': return Icons.school_rounded;
      case 'gadget': return Icons.devices_rounded;
      case 'home': return Icons.home_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'purchase': return Icons.shopping_bag_rounded;
      default: return Icons.flag_rounded;
    }
  }
}
