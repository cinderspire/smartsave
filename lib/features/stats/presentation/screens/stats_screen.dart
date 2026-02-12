import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../../core/widgets/premium_gate.dart';
import '../../../goals/data/providers/savings_provider.dart';
import '../../../goals/data/providers/challenge_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSavedAllTime = ref.watch(totalSavedAllTimeProvider);
    final savingsRate = ref.watch(savingsRateProvider);
    final streak = ref.watch(savingsStreakProvider);
    final completedGoals = ref.watch(completedGoalsCountProvider);
    final monthlySavings = ref.watch(monthlySavingsProvider);
    final goals = ref.watch(savingsGoalsProvider);
    final totalRoundUps = ref.watch(totalRoundUpsProvider);
    final challengeSavings = ref.watch(totalChallengeSavingsProvider);
    final dailyTarget = ref.watch(dailyTargetProvider);
    final weeklyTarget = ref.watch(weeklyTargetProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Stats & Insights',
          style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                // Summary cards
                _buildSummaryCards(totalSavedAllTime, savingsRate, streak.currentStreak, completedGoals),
                const SizedBox(height: 24),

                // Monthly Savings Chart
                Text(
                  'Monthly Savings Trend',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMonthlySavingsChart(monthlySavings),
                const SizedBox(height: 24),

                // Streak Section
                _buildStreakSection(streak.currentStreak, streak.bestStreak),
                const SizedBox(height: 24),

                // Daily/Weekly Targets
                _buildTargetsSection(context, ref, dailyTarget, weeklyTarget),
                const SizedBox(height: 24),

                // Savings Breakdown
                Text(
                  'Savings Breakdown',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSavingsBreakdownChart(
                  goals.fold(0.0, (sum, g) => sum + g.currentAmount),
                  totalRoundUps,
                  challengeSavings,
                ),
                const SizedBox(height: 24),

                // Goals Analytics
                Text(
                  'Goals Analytics',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildGoalsAnalytics(goals),
                const SizedBox(height: 24),

                // Insights (Premium)
                PremiumGate(
                  featureName: 'AI Insights',
                  child: _buildInsightsSection(savingsRate, streak.currentStreak, totalSavedAllTime),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double totalSaved, double avgMonthly, int streak, int completed) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                'Total Saved',
                '\$${totalSaved.toStringAsFixed(0)}',
                Icons.savings_rounded,
                AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Monthly Avg',
                '\$${avgMonthly.toStringAsFixed(0)}',
                Icons.trending_up_rounded,
                AppColors.primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatBox(
                'Current Streak',
                '$streak days',
                Icons.local_fire_department_rounded,
                AppColors.accentGold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatBox(
                'Goals Done',
                '$completed',
                Icons.check_circle_rounded,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySavingsChart(Map<String, double> monthlySavings) {
    if (monthlySavings.isEmpty) {
      return GlassCard(
        margin: EdgeInsets.zero,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Text(
              'No monthly data yet',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
            ),
          ),
        ),
      );
    }

    final sortedKeys = monthlySavings.keys.toList()..sort();
    final last6 = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;
    final maxVal = last6.map((k) => monthlySavings[k]!).reduce((a, b) => a > b ? a : b);

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        AppTextStyles.labelMedium.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark),
                        );
                      },
                    ),
                  ),
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
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxVal / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.glassBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(last6.length, (i) {
                  final value = monthlySavings[last6[i]] ?? 0.0;
                  final isLast = i == last6.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        gradient: isLast
                            ? AppColors.wealthGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.primaryBlue.withValues(alpha: 0.5),
                                  AppColors.primaryBlue.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakSection(int currentStreak, int bestStreak) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings Streak',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save daily to build your streak',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$currentStreak',
                        style: AppTextStyles.moneyLarge.copyWith(color: AppColors.accentGold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Current Streak',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$bestStreak',
                        style: AppTextStyles.moneyLarge.copyWith(color: AppColors.primaryGreen),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Best Streak',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Week overview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) {
              final day = DateTime.now().subtract(Duration(days: 6 - i));
              final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isActive = i >= (7 - currentStreak).clamp(0, 7);
              return Column(
                children: [
                  Text(
                    dayNames[day.weekday - 1],
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.accentGold : AppColors.backgroundDarkCard,
                      border: !isActive ? Border.all(color: AppColors.glassBorder) : null,
                    ),
                    child: isActive
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsSection(BuildContext context, WidgetRef ref, double dailyTarget, double weeklyTarget) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings Targets',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTargetRow(
            'Daily Target',
            '\$${dailyTarget.toStringAsFixed(0)}',
            Icons.today_rounded,
            AppColors.primaryGreen,
            () => _showTargetDialog(context, ref, 'Daily Target', dailyTarget, true),
          ),
          const SizedBox(height: 12),
          _buildTargetRow(
            'Weekly Target',
            '\$${weeklyTarget.toStringAsFixed(0)}',
            Icons.date_range_rounded,
            AppColors.primaryBlue,
            () => _showTargetDialog(context, ref, 'Weekly Target', weeklyTarget, false),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(String label, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark),
              ),
            ),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_rounded, color: AppColors.textTertiaryDark, size: 18),
          ],
        ),
      ),
    );
  }

  void _showTargetDialog(BuildContext context, WidgetRef ref, String title, double current, bool isDaily) {
    final controller = TextEditingController(text: current.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.backgroundDarkElevated,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              'Set $title',
              style: AppTextStyles.headlineMedium.copyWith(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Amount (\$)',
                labelStyle: const TextStyle(color: AppColors.textTertiaryDark),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: AppColors.primaryGreen),
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
                onPressed: () {
                  final amount = double.tryParse(controller.text);
                  if (amount != null && amount > 0) {
                    if (isDaily) {
                      ref.read(dailyTargetProvider.notifier).setTarget(amount);
                    } else {
                      ref.read(weeklyTargetProvider.notifier).setTarget(amount);
                    }
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Target', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsBreakdownChart(double goalSavings, double roundUpSavings, double challengeSavings) {
    final total = goalSavings + roundUpSavings + challengeSavings;
    if (total == 0) {
      return GlassCard(
        margin: EdgeInsets.zero,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Text(
              'No savings data yet',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
            ),
          ),
        ),
      );
    }

    final sections = <MapEntry<String, double>>[];
    if (goalSavings > 0) sections.add(MapEntry('Goal Savings', goalSavings));
    if (roundUpSavings > 0) sections.add(MapEntry('Round-ups', roundUpSavings));
    if (challengeSavings > 0) sections.add(MapEntry('Challenges', challengeSavings));

    final colors = [AppColors.primaryGreen, AppColors.accentGold, const Color(0xFF8B5CF6)];

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 50,
                sections: List.generate(sections.length, (i) {
                  final percent = sections[i].value / total * 100;
                  return PieChartSectionData(
                    value: sections[i].value,
                    title: '${percent.toStringAsFixed(0)}%',
                    titleStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    color: colors[i],
                    radius: 45,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(sections.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 14, height: 14,
                  decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sections[i].key,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondaryDark),
                  ),
                ),
                Text(
                  '\$${sections[i].value.toStringAsFixed(2)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGoalsAnalytics(List goals) {
    if (goals.isEmpty) {
      return GlassCard(
        margin: EdgeInsets.zero,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Text(
              'No goals to analyze',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiaryDark),
            ),
          ),
        ),
      );
    }

    final activeGoals = goals.where((g) => !g.isComplete).length;
    final completedGoals = goals.where((g) => g.isComplete).length;
    final avgProgress = goals.fold(0.0, (double sum, g) => sum + g.progressPercent) / goals.length;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalyticItem('Active', '$activeGoals', AppColors.primaryBlue),
              ),
              Expanded(
                child: _buildAnalyticItem('Completed', '$completedGoals', AppColors.primaryGreen),
              ),
              Expanded(
                child: _buildAnalyticItem('Avg Progress', '${avgProgress.toStringAsFixed(0)}%', AppColors.accentGold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...goals.take(5).map((goal) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    goal.name,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress,
                      backgroundColor: AppColors.backgroundDarkElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        goal.isComplete ? AppColors.primaryGreen : AppColors.primaryBlue,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${goal.progressPercent.toStringAsFixed(0)}%',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiaryDark),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.headlineSmall.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
        ),
      ],
    );
  }

  Widget _buildInsightsSection(double avgMonthly, int streak, double totalSaved) {
    final insights = <Map<String, dynamic>>[];

    if (streak >= 7) {
      insights.add({
        'icon': Icons.local_fire_department_rounded,
        'color': AppColors.accentGold,
        'title': 'Impressive Streak!',
        'text': 'You have been saving for $streak consecutive days. Keep it up!',
      });
    } else if (streak > 0) {
      insights.add({
        'icon': Icons.trending_up_rounded,
        'color': AppColors.primaryGreen,
        'title': 'Building Momentum',
        'text': 'You are on a $streak day streak. Save daily to build it higher!',
      });
    }

    if (avgMonthly > 1500) {
      insights.add({
        'icon': Icons.star_rounded,
        'color': const Color(0xFF8B5CF6),
        'title': 'Great Saver',
        'text': 'You save \$${avgMonthly.toStringAsFixed(0)} per month on average. That is above the national average!',
      });
    }

    if (totalSaved > 10000) {
      insights.add({
        'icon': Icons.emoji_events_rounded,
        'color': AppColors.accentGold,
        'title': 'Major Milestone',
        'text': 'You have saved over \$${(totalSaved / 1000).toStringAsFixed(0)}K total. Amazing progress!',
      });
    }

    insights.add({
      'icon': Icons.lightbulb_rounded,
      'color': AppColors.primaryBlue,
      'title': 'Tip',
      'text': 'Try the 52-Week Challenge to save an extra \$1,378 this year automatically.',
    });

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insights',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (insight['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(insight['icon'] as IconData, color: insight['color'] as Color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insight['title'] as String,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: insight['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        insight['text'] as String,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
