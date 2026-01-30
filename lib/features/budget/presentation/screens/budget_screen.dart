import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'spent': 450.0, 'budget': 600.0, 'icon': Icons.restaurant, 'color': const Color(0xFFFF6B6B)},
    {'name': 'Transportation', 'spent': 180.0, 'budget': 250.0, 'icon': Icons.directions_car, 'color': const Color(0xFF4ECDC4)},
    {'name': 'Shopping', 'spent': 320.0, 'budget': 300.0, 'icon': Icons.shopping_bag, 'color': const Color(0xFFFFE66D)},
    {'name': 'Entertainment', 'spent': 85.0, 'budget': 150.0, 'icon': Icons.movie, 'color': const Color(0xFF95E1D3)},
    {'name': 'Utilities', 'spent': 120.0, 'budget': 200.0, 'icon': Icons.bolt, 'color': const Color(0xFFA8E6CF)},
  ];

  double get _totalSpent => _categories.fold(0, (sum, cat) => sum + (cat['spent'] as double));
  double get _totalBudget => _categories.fold(0, (sum, cat) => sum + (cat['budget'] as double));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Budget', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded), onPressed: () {}),
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
                _buildOverviewCard(),
                const SizedBox(height: 24),
                _buildSpendingChart(),
                const SizedBox(height: 24),
                Text('Categories', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._categories.map((cat) => _buildCategoryCard(cat)).toList(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final percentUsed = (_totalSpent / _totalBudget * 100).clamp(0, 100);
    final remaining = _totalBudget - _totalSpent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.wealthGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
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
                  Text('Monthly Budget', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('\$${_totalBudget.toStringAsFixed(0)}', style: AppTextStyles.moneyLarge.copyWith(color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${percentUsed.toStringAsFixed(0)}% used', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentUsed / 100,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(remaining >= 0 ? Colors.white : AppColors.loss),
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
                  Text('Spent', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                  Text('\$${_totalSpent.toStringAsFixed(0)}', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Remaining', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                  Text('\$${remaining.toStringAsFixed(0)}', style: AppTextStyles.titleLarge.copyWith(color: remaining >= 0 ? Colors.white : AppColors.loss)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart() {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Spending Breakdown', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: _categories.map((cat) {
                  final percent = (cat['spent'] as double) / _totalSpent * 100;
                  return PieChartSectionData(
                    value: cat['spent'] as double,
                    title: '${percent.toStringAsFixed(0)}%',
                    titleStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    color: cat['color'] as Color,
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: _categories.map((cat) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: cat['color'] as Color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(cat['name'] as String, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    final percent = ((category['spent'] as double) / (category['budget'] as double) * 100).clamp(0.0, 100.0);
    final isOverBudget = category['spent'] > category['budget'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(16),
        border: isOverBudget ? Border.all(color: AppColors.loss.withOpacity(0.5)) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (category['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(category['icon'] as IconData, color: category['color'] as Color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category['name'] as String, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark)),
                    Text('\$${(category['spent'] as double).toStringAsFixed(0)} / \$${(category['budget'] as double).toStringAsFixed(0)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                  ],
                ),
              ),
              Text('${percent.toStringAsFixed(0)}%', style: AppTextStyles.titleMedium.copyWith(color: isOverBudget ? AppColors.loss : AppColors.profit)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppColors.backgroundDarkElevated,
              valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? AppColors.loss : category['color'] as Color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
