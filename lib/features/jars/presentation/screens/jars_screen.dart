import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/glassmorphic_container.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../goals/data/models/money_jar.dart';
import '../../../goals/data/providers/money_jar_provider.dart';

class JarsScreen extends ConsumerWidget {
  const JarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jars = ref.watch(moneyJarsProvider);
    final totalBalance = ref.watch(totalJarBalanceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Money Jars',
            style: AppTextStyles.headlineMedium
                .copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateJarSheet(context, ref),
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
                _buildTotalCard(totalBalance, jars.length),
                const SizedBox(height: 20),
                _buildAllocationOverview(jars),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Jars',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showDistributeSheet(context, ref, jars),
                      icon: const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.accentGold, size: 18),
                      label: Text('Auto-Split',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.accentGold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (jars.isEmpty)
                  _buildEmptyState(context, ref)
                else
                  ...jars.map((jar) => _buildJarCard(context, ref, jar)),
                const SizedBox(height: 24),
                _buildJarTipsCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(double totalBalance, int jarCount) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total in Jars',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  '\$${totalBalance.toStringAsFixed(2)}',
                  style: AppTextStyles.moneyLarge.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text('$jarCount jars active',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationOverview(List<MoneyJar> jars) {
    final allocatedJars = jars.where((j) => j.allocationPercent > 0).toList();
    final totalAlloc =
        allocatedJars.fold(0.0, (sum, j) => sum + j.allocationPercent);

    if (allocatedJars.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Allocation Rules',
              style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimaryDark,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('How deposits are auto-distributed',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiaryDark)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: allocatedJars.map((jar) {
                  final fraction = jar.allocationPercent / (totalAlloc > 0 ? totalAlloc : 1);
                  return Expanded(
                    flex: (fraction * 100).round().clamp(1, 100),
                    child: Container(
                      color: Color(jar.colorValue),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: allocatedJars
                .map((jar) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: Color(jar.colorValue),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(
                            '${jar.name} ${jar.allocationPercent.toStringAsFixed(0)}%',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondaryDark)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildJarCard(
      BuildContext context, WidgetRef ref, MoneyJar jar) {
    final color = Color(jar.colorValue);
    final icon = _jarIcon(jar.purpose);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showJarDetailSheet(context, ref, jar);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundDarkCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(jar.name,
                          style: AppTextStyles.titleLarge.copyWith(
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      if (jar.allocationPercent > 0)
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                size: 14, color: AppColors.textTertiaryDark),
                            const SizedBox(width: 4),
                            Text(
                                '${jar.allocationPercent.toStringAsFixed(0)}% allocation',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiaryDark)),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${jar.balance.toStringAsFixed(2)}',
                        style: AppTextStyles.moneySmall
                            .copyWith(color: color)),
                    if (jar.hasTarget)
                      Text(
                          '${jar.progressPercent.toStringAsFixed(0)}%',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiaryDark)),
                  ],
                ),
              ],
            ),
            if (jar.hasTarget) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: jar.progress,
                  backgroundColor: AppColors.backgroundDarkElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '\$${jar.balance.toStringAsFixed(0)} saved',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: color)),
                  Text(
                      'of \$${jar.targetAmount.toStringAsFixed(0)}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiaryDark)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.account_balance_rounded,
                color: AppColors.textTertiaryDark, size: 56),
            const SizedBox(height: 16),
            Text('No money jars yet',
                style: AppTextStyles.headlineSmall
                    .copyWith(color: AppColors.textSecondaryDark)),
            const SizedBox(height: 8),
            Text(
              'Create virtual jars to organize savings by purpose',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textTertiaryDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            GradientButton(
              text: 'Create Jar',
              onPressed: () => _showCreateJarSheet(context, ref),
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJarTipsCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Jar System Tip',
                    style: AppTextStyles.titleSmall.copyWith(
                        color: const Color(0xFF06B6D4),
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Set allocation percentages so every deposit is auto-split across your jars!',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJarDetailSheet(
      BuildContext context, WidgetRef ref, MoneyJar jar) {
    final color = Color(jar.colorValue);
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.backgroundDarkElevated,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_jarIcon(jar.purpose),
                            color: color, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(jar.name,
                                style: AppTextStyles.headlineMedium.copyWith(
                                    color: AppColors.textPrimaryDark,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '\$${jar.balance.toStringAsFixed(2)} balance',
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondaryDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (jar.hasTarget) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: jar.progress,
                        backgroundColor: AppColors.backgroundDarkCard,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${jar.progressPercent.toStringAsFixed(1)}% complete',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: color)),
                        Text(
                            '\$${(jar.targetAmount - jar.balance).clamp(0, jar.targetAmount).toStringAsFixed(0)} remaining',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textTertiaryDark)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Deposit/Withdraw
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    style: const TextStyle(color: AppColors.textPrimaryDark),
                    decoration: InputDecoration(
                      labelText: 'Amount (\$)',
                      labelStyle:
                          const TextStyle(color: AppColors.textTertiaryDark),
                      prefixText: '\$ ',
                      prefixStyle: TextStyle(color: color),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final amount =
                                double.tryParse(amountController.text);
                            if (amount != null && amount > 0) {
                              ref
                                  .read(moneyJarsProvider.notifier)
                                  .depositToJar(
                                      jar.id, amount, 'Manual deposit');
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Deposited \$${amount.toStringAsFixed(2)} to ${jar.name}')),
                              );
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Deposit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final amount =
                                double.tryParse(amountController.text);
                            if (amount != null &&
                                amount > 0 &&
                                amount <= jar.balance) {
                              ref
                                  .read(moneyJarsProvider.notifier)
                                  .withdrawFromJar(
                                      jar.id, amount, 'Manual withdrawal');
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Withdrew \$${amount.toStringAsFixed(2)} from ${jar.name}')),
                              );
                            }
                          },
                          icon: const Icon(Icons.remove_rounded, size: 20),
                          label: const Text('Withdraw'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondaryDark,
                            side: BorderSide(color: AppColors.glassBorder),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent Transactions',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: jar.transactions.isEmpty
                  ? Center(
                      child: Text('No transactions yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textTertiaryDark)),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: jar.transactions.length,
                      itemBuilder: (context, index) {
                        final txn = jar.transactions[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundDarkCard,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                txn.isDeposit
                                    ? Icons.add_circle_rounded
                                    : Icons.remove_circle_rounded,
                                color: txn.isDeposit
                                    ? AppColors.profit
                                    : AppColors.loss,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(txn.description,
                                        style: AppTextStyles.titleSmall
                                            .copyWith(
                                                color: AppColors
                                                    .textPrimaryDark)),
                                    Text(_formatDate(txn.date),
                                        style: AppTextStyles.bodySmall
                                            .copyWith(
                                                color: AppColors
                                                    .textTertiaryDark)),
                                  ],
                                ),
                              ),
                              Text(
                                '${txn.isDeposit ? '+' : '-'}\$${txn.amount.toStringAsFixed(2)}',
                                style: AppTextStyles.titleMedium.copyWith(
                                    color: txn.isDeposit
                                        ? AppColors.profit
                                        : AppColors.loss,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(moneyJarsProvider.notifier)
                        .deleteJar(jar.id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${jar.name} deleted')),
                    );
                  },
                  child: Text('Delete Jar',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: AppColors.loss)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistributeSheet(
      BuildContext context, WidgetRef ref, List<MoneyJar> jars) {
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
        decoration: const BoxDecoration(
          color: AppColors.backgroundDarkElevated,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
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
            Text('Auto-Split Deposit',
                style: AppTextStyles.headlineMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                'Distribute a deposit across jars based on allocation rules',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondaryDark)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Total Amount (\$)',
                labelStyle:
                    const TextStyle(color: AppColors.textTertiaryDark),
                prefixText: '\$ ',
                prefixStyle:
                    const TextStyle(color: AppColors.primaryGreen),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primaryGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final amount =
                      double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    ref
                        .read(moneyJarsProvider.notifier)
                        .distributeByAllocation(amount);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Distributed \$${amount.toStringAsFixed(2)} across jars!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Distribute',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateJarSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    final allocController = TextEditingController();
    JarPurpose selectedPurpose = JarPurpose.emergency;

    final purposeOptions = [
      {
        'purpose': JarPurpose.emergency,
        'label': 'Emergency',
        'icon': Icons.shield_rounded,
        'color': 0xFF10B981
      },
      {
        'purpose': JarPurpose.vacation,
        'label': 'Vacation',
        'icon': Icons.flight_rounded,
        'color': 0xFFFFB020
      },
      {
        'purpose': JarPurpose.education,
        'label': 'Education',
        'icon': Icons.school_rounded,
        'color': 0xFF8B5CF6
      },
      {
        'purpose': JarPurpose.retirement,
        'label': 'Retirement',
        'icon': Icons.elderly_rounded,
        'color': 0xFF3B82F6
      },
      {
        'purpose': JarPurpose.gadget,
        'label': 'Gadget',
        'icon': Icons.devices_rounded,
        'color': 0xFF06B6D4
      },
      {
        'purpose': JarPurpose.custom,
        'label': 'Custom',
        'icon': Icons.star_rounded,
        'color': 0xFFEC4899
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: const BoxDecoration(
            color: AppColors.backgroundDarkElevated,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(24)),
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
                Text('Create Money Jar',
                    style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimaryDark,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    'Create a virtual jar for a specific savings purpose',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryDark)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style:
                      const TextStyle(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Jar Name',
                    labelStyle: const TextStyle(
                        color: AppColors.textTertiaryDark),
                    hintText: 'e.g. Emergency Fund',
                    hintStyle: TextStyle(
                        color: AppColors.textTertiaryDark
                            .withValues(alpha: 0.5)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  style:
                      const TextStyle(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Target Amount (optional)',
                    labelStyle: const TextStyle(
                        color: AppColors.textTertiaryDark),
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(
                        color: AppColors.primaryGreen),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: allocController,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  style:
                      const TextStyle(color: AppColors.textPrimaryDark),
                  decoration: InputDecoration(
                    labelText: 'Allocation % (optional)',
                    labelStyle: const TextStyle(
                        color: AppColors.textTertiaryDark),
                    suffixText: '%',
                    suffixStyle: const TextStyle(
                        color: AppColors.textTertiaryDark),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Purpose',
                    style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textSecondaryDark)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: purposeOptions.map((opt) {
                    final isSelected =
                        selectedPurpose == opt['purpose'];
                    final optColor =
                        Color(opt['color'] as int);
                    return GestureDetector(
                      onTap: () => setSheetState(() =>
                          selectedPurpose =
                              opt['purpose'] as JarPurpose),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? optColor.withValues(alpha: 0.2)
                              : AppColors.backgroundDarkCard,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? optColor
                                  : AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(opt['icon'] as IconData,
                                color: isSelected
                                    ? optColor
                                    : AppColors
                                        .textTertiaryDark,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(opt['label'] as String,
                                style: AppTextStyles
                                    .labelMedium
                                    .copyWith(
                                        color: isSelected
                                            ? optColor
                                            : AppColors
                                                .textSecondaryDark)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  text: 'Create Jar',
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final target =
                        double.tryParse(targetController.text) ??
                            0.0;
                    final alloc =
                        double.tryParse(allocController.text) ??
                            0.0;
                    final opt = purposeOptions.firstWhere(
                        (o) => o['purpose'] == selectedPurpose);
                    final jar = MoneyJar(
                      id: const Uuid().v4(),
                      name: name,
                      purpose: selectedPurpose,
                      targetAmount: target,
                      iconName: '',
                      colorValue: opt['color'] as int,
                      allocationPercent: alloc.clamp(0, 100),
                    );
                    ref
                        .read(moneyJarsProvider.notifier)
                        .addJar(jar);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Jar "$name" created!')),
                    );
                  },
                  width: double.infinity,
                  icon: Icons.account_balance_rounded,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF06B6D4),
                      Color(0xFF8B5CF6)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _jarIcon(JarPurpose purpose) {
    switch (purpose) {
      case JarPurpose.emergency:
        return Icons.shield_rounded;
      case JarPurpose.vacation:
        return Icons.flight_rounded;
      case JarPurpose.education:
        return Icons.school_rounded;
      case JarPurpose.retirement:
        return Icons.elderly_rounded;
      case JarPurpose.gadget:
        return Icons.devices_rounded;
      case JarPurpose.custom:
        return Icons.star_rounded;
    }
  }
}
