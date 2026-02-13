import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/gemini_service.dart';
import '../../data/models/expense.dart';
import '../../data/providers/expense_provider.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  String? _aiAnalysis;
  bool _analyzing = false;

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expenseProvider);
    final monthTotal = ref.watch(monthlyTotalProvider);
    final categories = ref.watch(categoryTotalsProvider);

    // Sort categories by amount desc
    final sortedCats = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: Text('Expenses', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimaryDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_analyzing ? Icons.hourglass_top : Icons.auto_awesome, color: AppColors.primaryGreen),
            onPressed: _analyzing ? null : () => _analyzeWithAI(expenses, categories),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpense(context),
        backgroundColor: AppColors.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month total
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent.withValues(alpha: 0.2), Colors.orange.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('This Month', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
                  const SizedBox(height: 4),
                  Text('\$${monthTotal.toStringAsFixed(2)}',
                      style: AppTextStyles.headlineMedium.copyWith(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  Text('${expenses.where((e) => e.date.month == DateTime.now().month).length} transactions',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Analysis
            if (_aiAnalysis != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryGreen.withValues(alpha: 0.15), AppColors.primaryGreen.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('AI Analysis', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_aiAnalysis!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimaryDark, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Category breakdown
            Text('By Category', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final cat in sortedCats) ...[
              _buildCategoryRow(cat.key, cat.value, monthTotal, _catEmoji(cat.key), _catColor(cat.key)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 20),

            // Recent transactions
            Text('Recent', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final e in expenses.take(10)) ...[
              _buildExpenseRow(e),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String name, double amount, double total, String emoji, Color color) {
    final pct = total > 0 ? amount / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryDark)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${amount.toStringAsFixed(0)}', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
              Text('${(pct * 100).toStringAsFixed(0)}%', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseRow(Expense e) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundDarkCard,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(e.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimaryDark)),
                Text('${e.category} • ${DateFormat('MMM d').format(e.date)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark)),
              ],
            ),
          ),
          Text('-\$${e.amount.toStringAsFixed(2)}', style: AppTextStyles.labelMedium.copyWith(color: Colors.redAccent)),
        ],
      ),
    );
  }

  String _catEmoji(String cat) {
    const map = {'Food': '🍽️', 'Transport': '🚗', 'Shopping': '🛍️', 'Bills': '🏠', 'Subscriptions': '📱', 'Health': '💊', 'Kids': '👶', 'Entertainment': '🎬'};
    return map[cat] ?? '💸';
  }

  Color _catColor(String cat) {
    const map = {'Food': Colors.orange, 'Transport': Colors.blue, 'Shopping': Colors.pink, 'Bills': Colors.red, 'Subscriptions': Colors.purple, 'Health': Colors.green, 'Kids': Colors.teal, 'Entertainment': Colors.amber};
    return map[cat] ?? Colors.grey;
  }

  Future<void> _showAddExpense(BuildContext ctx) async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? result;

    result = await showModalBottomSheet<String>(
      context: ctx,
      backgroundColor: AppColors.backgroundDarkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(c).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Expense', style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Describe it naturally — AI will categorize it.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondaryDark)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'e.g. "Coffee at Starbucks \$5.50" or "Groceries \$85"',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiaryDark),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(c, titleCtrl.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Add ✨', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _addWithAI(result);
    }
    titleCtrl.dispose();
    amountCtrl.dispose();
  }

  Future<void> _addWithAI(String input) async {
    try {
      final raw = await GeminiService().generate(
        input,
        systemInstruction: 'Parse this expense into JSON. Respond ONLY with valid JSON:\n{"title":"...","amount":0.0,"category":"Food|Transport|Shopping|Bills|Subscriptions|Health|Kids|Entertainment|Other","emoji":"🛒"}\nExtract amount from text. If no amount, estimate reasonably.',
      );
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll('```', '').trim();
      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      final expense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: parsed['title'] as String? ?? input,
        amount: (parsed['amount'] as num?)?.toDouble() ?? 0,
        category: parsed['category'] as String? ?? 'Other',
        emoji: parsed['emoji'] as String? ?? '💸',
      );
      ref.read(expenseProvider.notifier).add(expense);
    } catch (_) {
      // Fallback: add as-is
      ref.read(expenseProvider.notifier).add(Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: input, amount: 0, category: 'Other',
      ));
    }
  }

  Future<void> _analyzeWithAI(List<Expense> expenses, Map<String, double> categories) async {
    setState(() => _analyzing = true);
    try {
      final catStr = categories.entries.map((e) => '${e.key}: \$${e.value.toStringAsFixed(0)}').join(', ');
      final total = categories.values.fold(0.0, (s, v) => s + v);
      final analysis = await GeminiService().generate(
        'My monthly expenses: $catStr. Total: \$${total.toStringAsFixed(0)}. Analyze and give 3 specific savings suggestions.',
        systemInstruction: 'You are a friendly financial advisor. Keep response under 100 words. Be specific with numbers. Use bullet points.',
      );
      setState(() {
        _aiAnalysis = analysis;
        _analyzing = false;
      });
    } catch (_) {
      setState(() => _analyzing = false);
    }
  }
}
