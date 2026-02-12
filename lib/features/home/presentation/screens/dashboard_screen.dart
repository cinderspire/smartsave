import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../goals/data/models/savings_goal.dart';
import '../../../goals/data/providers/savings_provider.dart';
import '../../../goals/data/providers/smart_tips_provider.dart';
import '../../../goals/data/providers/money_jar_provider.dart';
import '../../../goals/data/models/money_jar.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider);
    final totalSaved = ref.watch(totalSavedProvider);
    final totalRoundUps = ref.watch(totalRoundUpsProvider);
    final recentActivity = ref.watch(recentActivityProvider);
    final roundUps = ref.watch(roundUpProvider);
    final streak = ref.watch(savingsStreakProvider);
    final monthlySavings = ref.watch(monthlySavingsProvider);
    final smartTips = ref.watch(smartTipsProvider);
    final jars = ref.watch(moneyJarsProvider);
    final totalJarBalance = ref.watch(totalJarBalanceProvider);

    final weeklyRoundUps = roundUps
        .where((t) => t.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .fold(0.0, (sum, t) => sum + t.roundUpAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rebecca'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Balance Card
            _buildTotalBalanceCard(totalSaved, weeklyRoundUps),
            const SizedBox(height: 20),

            // Streak + Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: _buildStreakCard(streak.currentStreak, streak.bestStreak),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_circle_outline,
                    label: 'Deposit',
                    gradient: AppColors.wealthGradient,
                    onTap: () => _showDepositDialog(context, ref, goals),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Round-up',
                    gradient: AppColors.goldGradient,
                    onTap: () => _showSimulateRoundUpDialog(context, ref),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Smart Tips Section
            if (smartTips.isNotEmpty) ...[
              _buildSmartTipsSection(smartTips),
              const SizedBox(height: 24),
            ],

            // Money Jars Quick View
            if (jars.isNotEmpty) ...[
              _buildMoneyJarsQuickView(jars, totalJarBalance),
              const SizedBox(height: 24),
            ],

            // Monthly Savings Mini Chart
            _buildMiniMonthlyChart(monthlySavings),

            const SizedBox(height: 24),

            // Round-ups Summary
            _buildRoundUpsSummary(totalRoundUps, roundUps.length),

            const SizedBox(height: 24),

            // Goals Progress with Projected Completion
            Text(
              'Goals Progress',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (goals.isEmpty)
              _buildEmptyGoals()
            else
              ...goals.take(3).map((goal) => _buildGoalProgressCard(goal)),

            const SizedBox(height: 24),

            // Recent Activity
            Text(
              'Recent Activity',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (recentActivity.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No recent activity',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
                  ),
                ),
              )
            else
              ...recentActivity.take(6).map((a) => _buildActivityItem(a)),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(double totalSaved, double weeklyRoundUps) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.wealthGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Savings',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: totalSaved),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                '\$${NumberFormat('#,##0.00').format(value)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                '+\$${weeklyRoundUps.toStringAsFixed(2)} round-ups this week',
                style: TextStyle(color: Colors.white.withOpacity(0.9)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(int streak, int bestStreak) {
    // Determine streak level and celebration
    String streakLabel = 'day streak';
    Color streakGlow = const Color(0xFFFF6B35);
    IconData streakIcon = Icons.local_fire_department_rounded;

    if (streak >= 30) {
      streakLabel = 'LEGEND';
      streakGlow = const Color(0xFF10B981);
      streakIcon = Icons.emoji_events_rounded;
    } else if (streak >= 14) {
      streakLabel = 'ON FIRE';
      streakGlow = const Color(0xFFFFB020);
      streakIcon = Icons.whatshot_rounded;
    } else if (streak >= 7) {
      streakLabel = 'day streak';
      streakGlow = const Color(0xFFFF6B35);
      streakIcon = Icons.local_fire_department_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [streakGlow, streakGlow.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: streak >= 7
            ? [
                BoxShadow(
                  color: streakGlow.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Icon(streakIcon, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Text(
            '$streak',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          Text(
            streakLabel,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Smart Tips Section - personalized tips carousel
  Widget _buildSmartTipsSection(List<SmartTip> tips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: AppColors.accentGold, size: 22),
            const SizedBox(width: 8),
            Text(
              'Smart Tips',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tips.length > 5 ? 5 : tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(right: index < tips.length - 1 ? 12 : 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDarkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tip.color.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tip.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(tip.icon, color: tip.color, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tip.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: tip.color,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tip.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tip.potentialSaving,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: tip.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        tip.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryDark,
                          height: 1.4,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Money Jars Quick View
  Widget _buildMoneyJarsQuickView(List<MoneyJar> jars, double totalBalance) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_rounded,
                      color: const Color(0xFF06B6D4), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Money Jars',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${totalBalance.toStringAsFixed(0)} total',
                style: AppTextStyles.titleMedium.copyWith(
                  color: const Color(0xFF06B6D4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...jars.take(3).map((jar) {
            final color = Color(jar.colorValue);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_jarIcon(jar.purpose), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(jar.name,
                            style: AppTextStyles.titleSmall
                                .copyWith(color: AppColors.textPrimaryDark)),
                        if (jar.hasTarget)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: jar.progress,
                              backgroundColor: AppColors.backgroundDarkElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 4,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '\$${jar.balance.toStringAsFixed(0)}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (jars.length > 3)
            Center(
              child: Text(
                '+${jars.length - 3} more jars',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textTertiaryDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniMonthlyChart(Map<String, double> monthlySavings) {
    if (monthlySavings.isEmpty) return const SizedBox.shrink();

    final sortedKeys = monthlySavings.keys.toList()..sort();
    final last6 = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;
    final values = last6.map((k) => monthlySavings[k] ?? 0.0).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Savings',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Last 6 months',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= last6.length) return const Text('');
                        final key = last6[idx];
                        final month = int.tryParse(key.split('-').last) ?? 1;
                        return Text(
                          monthNames[month - 1],
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (last6.length - 1).toDouble(),
                minY: 0,
                maxY: maxVal * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(last6.length, (i) =>
                      FlSpot(i.toDouble(), values[i]),
                    ),
                    isCurved: true,
                    gradient: AppColors.wealthGradient,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: index == last6.length - 1 ? AppColors.primaryGreen : AppColors.primaryBlue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen.withOpacity(0.15),
                          AppColors.primaryBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItems: (spots) {
                      return spots.map((spot) => LineTooltipItem(
                        '\$${spot.y.toStringAsFixed(0)}',
                        AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      )).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundUpsSummary(double totalRoundUps, int txnCount) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Round-up Savings',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$txnCount transactions rounded up',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${totalRoundUps.toStringAsFixed(2)}',
                style: AppTextStyles.moneySmall.copyWith(color: AppColors.accentGold),
              ),
              Text(
                'total saved',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard(SavingsGoal goal) {
    final color = _goalColor(goal.category);
    final icon = _goalIcon(goal.category);

    // Projected completion date
    String projectedDate = '';
    if (!goal.isComplete && goal.currentAmount > 0) {
      final daysSinceCreation = DateTime.now().difference(goal.createdAt).inDays;
      if (daysSinceCreation > 0) {
        final dailyRate = goal.currentAmount / daysSinceCreation;
        if (dailyRate > 0) {
          final daysToComplete = (goal.remaining / dailyRate).ceil();
          final completionDate = DateTime.now().add(Duration(days: daysToComplete));
          projectedDate = DateFormat('MMM d, yyyy').format(completionDate);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
                    ),
                    Text(
                      '\$${goal.currentAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMilestoneIndicator(goal.progressPercent, color),
                  if (projectedDate.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 10, color: AppColors.textTertiaryDark),
                          const SizedBox(width: 3),
                          Text(
                            projectedDate,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiaryDark,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar with milestone markers
          _buildProgressBarWithMilestones(goal.progress, color),
        ],
      ),
    );
  }

  Widget _buildProgressBarWithMilestones(double progress, Color color) {
    return SizedBox(
      height: 20,
      child: Stack(
        children: [
          // Background
          Positioned(
            left: 0,
            right: 0,
            top: 7,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.backgroundDarkElevated,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          // Milestone markers at 25%, 50%, 75%
          for (final milestone in [0.25, 0.50, 0.75])
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: milestone,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: progress >= milestone
                          ? color
                          : AppColors.backgroundDarkElevated,
                      border: Border.all(
                        color: progress >= milestone
                            ? Colors.white
                            : AppColors.glassBorder,
                        width: 1.5,
                      ),
                    ),
                    child: progress >= milestone
                        ? const Icon(Icons.check, size: 7, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneIndicator(double percent, Color color) {
    IconData milestoneIcon;
    if (percent >= 100) {
      milestoneIcon = Icons.emoji_events_rounded;
    } else if (percent >= 75) {
      milestoneIcon = Icons.rocket_launch_rounded;
    } else if (percent >= 50) {
      milestoneIcon = Icons.local_fire_department_rounded;
    } else if (percent >= 25) {
      milestoneIcon = Icons.star_rounded;
    } else {
      return Text(
        '${percent.toStringAsFixed(0)}%',
        style: AppTextStyles.titleMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(milestoneIcon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: AppTextStyles.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyGoals() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(16),
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryGreen.withOpacity(0.12),
                          AppColors.primaryBlue.withOpacity(0.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.flag_rounded, color: AppColors.primaryGreen.withOpacity(0.6), size: 44),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'No savings goals yet',
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your savings journey by\ncreating your first goal!',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem item) {
    IconData icon;
    Color color;
    switch (item.type) {
      case ActivityType.roundUp:
        icon = Icons.currency_exchange_rounded;
        color = AppColors.accentGold;
        break;
      case ActivityType.goalDeposit:
        icon = Icons.add_circle_rounded;
        color = AppColors.primaryGreen;
        break;
      case ActivityType.goalCreated:
        icon = Icons.flag_rounded;
        color = AppColors.primaryBlue;
        break;
      case ActivityType.goalCompleted:
        icon = Icons.check_circle_rounded;
        color = AppColors.profit;
        break;
    }

    final timeAgo = _timeAgo(item.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.type == ActivityType.roundUp
                    ? '+\$${item.amount.toStringAsFixed(2)}'
                    : '\$${item.amount.toStringAsFixed(0)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: item.type == ActivityType.roundUp ? AppColors.accentGold : color,
                ),
              ),
              Text(
                timeAgo,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark),
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

  void _showDepositDialog(BuildContext context, WidgetRef ref, List<SavingsGoal> goals) {
    if (goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a savings goal first!')),
      );
      return;
    }

    final amountController = TextEditingController();
    String? selectedGoalId = goals.first.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
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
                'Add to Goal',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedGoalId,
                dropdownColor: AppColors.backgroundDarkElevated,
                decoration: InputDecoration(
                  labelText: 'Select Goal',
                  labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                ),
                items: goals.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Text(g.name, style: TextStyle(color: AppColors.textPrimaryDark)),
                )).toList(),
                onChanged: (v) => setSheetState(() => selectedGoalId = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.textPrimaryDark),
                decoration: InputDecoration(
                  labelText: 'Amount (\$)',
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount != null && amount > 0 && selectedGoalId != null) {
                      final milestone = await ref.read(savingsGoalsProvider.notifier).addToGoal(selectedGoalId!, amount);
                      ref.read(savingsStreakProvider.notifier).recordSaving();
                      ref.read(monthlySavingsProvider.notifier).addToMonth(amount);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added \$${amount.toStringAsFixed(2)} to goal!')),
                      );
                      if (milestone != null) {
                        _showMilestoneCelebration(context, milestone);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _showSimulateRoundUpDialog(BuildContext context, WidgetRef ref) {
    final merchantController = TextEditingController();
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
              'Simulate Round-up',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a purchase to see how round-ups save spare change',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: merchantController,
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Merchant',
                labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                hintText: 'e.g. Coffee Shop',
                hintStyle: TextStyle(color: AppColors.textTertiaryDark.withOpacity(0.5)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentGold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Purchase Amount (\$)',
                labelStyle: TextStyle(color: AppColors.textTertiaryDark),
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: AppColors.accentGold),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accentGold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  final merchant = merchantController.text.trim();
                  if (amount != null && amount > 0 && merchant.isNotEmpty) {
                    final txn = await ref.read(roundUpProvider.notifier).simulatePurchase(merchant, amount);
                    ref.read(savingsStreakProvider.notifier).recordSaving();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Round-up: \$${txn.roundUpAmount.toStringAsFixed(2)} saved from \$${amount.toStringAsFixed(2)} purchase!',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Simulate Purchase',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _goalColor(String category) {
    switch (category) {
      case 'emergency': return const Color(0xFF10B981);
      case 'safety': return const Color(0xFF10B981);
      case 'car': return const Color(0xFF3B82F6);
      case 'purchase': return const Color(0xFF3B82F6);
      case 'vacation': return const Color(0xFFFFB020);
      case 'travel': return const Color(0xFFFFB020);
      case 'home': return const Color(0xFFEC4899);
      case 'education': return const Color(0xFF8B5CF6);
      case 'gadget': return const Color(0xFF06B6D4);
      default: return AppColors.primaryGreen;
    }
  }

  IconData _goalIcon(String category) {
    switch (category) {
      case 'emergency': return Icons.shield_rounded;
      case 'safety': return Icons.shield_rounded;
      case 'car': return Icons.directions_car_rounded;
      case 'purchase': return Icons.shopping_bag_rounded;
      case 'vacation': return Icons.flight_rounded;
      case 'travel': return Icons.flight_rounded;
      case 'home': return Icons.home_rounded;
      case 'education': return Icons.school_rounded;
      case 'gadget': return Icons.devices_rounded;
      default: return Icons.flag_rounded;
    }
  }

  IconData _jarIcon(JarPurpose purpose) {
    switch (purpose) {
      case JarPurpose.emergency: return Icons.shield_rounded;
      case JarPurpose.vacation: return Icons.flight_rounded;
      case JarPurpose.education: return Icons.school_rounded;
      case JarPurpose.retirement: return Icons.elderly_rounded;
      case JarPurpose.gadget: return Icons.devices_rounded;
      case JarPurpose.custom: return Icons.star_rounded;
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
