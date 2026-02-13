import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';

class ExpenseNotifier extends StateNotifier<List<Expense>> {
  ExpenseNotifier() : super([]) {
    _load();
  }

  static const _key = 'expenses_data';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final list = (jsonDecode(raw) as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
      state = list;
    } else {
      // Demo data
      state = _demoExpenses();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> add(Expense expense) async {
    state = [...state, expense];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  double totalThisMonth() {
    final now = DateTime.now();
    return state
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> categoryTotals() {
    final totals = <String, double>{};
    final now = DateTime.now();
    for (final e in state.where((e) => e.date.month == now.month && e.date.year == now.year)) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  List<Expense> _demoExpenses() {
    final now = DateTime.now();
    return [
      Expense(id: '1', title: 'Groceries', amount: 85, category: 'Food', emoji: '🛒', date: now.subtract(const Duration(days: 1))),
      Expense(id: '2', title: 'Coffee', amount: 5.50, category: 'Food', emoji: '☕', date: now.subtract(const Duration(days: 1))),
      Expense(id: '3', title: 'Netflix', amount: 15.99, category: 'Subscriptions', emoji: '📺', date: now.subtract(const Duration(days: 3))),
      Expense(id: '4', title: 'Petrol', amount: 55, category: 'Transport', emoji: '⛽', date: now.subtract(const Duration(days: 2))),
      Expense(id: '5', title: 'Kids shoes', amount: 45, category: 'Shopping', emoji: '👟', date: now.subtract(const Duration(days: 4))),
      Expense(id: '6', title: 'Electricity bill', amount: 120, category: 'Bills', emoji: '💡', date: now.subtract(const Duration(days: 5))),
      Expense(id: '7', title: 'Takeaway pizza', amount: 28, category: 'Food', emoji: '🍕', date: now),
      Expense(id: '8', title: 'Gym membership', amount: 39.99, category: 'Health', emoji: '🏋️', date: now.subtract(const Duration(days: 6))),
      Expense(id: '9', title: 'School supplies', amount: 32, category: 'Kids', emoji: '📚', date: now.subtract(const Duration(days: 2))),
      Expense(id: '10', title: 'Spotify', amount: 9.99, category: 'Subscriptions', emoji: '🎵', date: now.subtract(const Duration(days: 3))),
    ];
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, List<Expense>>((ref) => ExpenseNotifier());

final monthlyTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(expenseProvider);
  final now = DateTime.now();
  return expenses
      .where((e) => e.date.month == now.month && e.date.year == now.year)
      .fold(0.0, (sum, e) => sum + e.amount);
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final expenses = ref.watch(expenseProvider);
  final now = DateTime.now();
  final totals = <String, double>{};
  for (final e in expenses.where((e) => e.date.month == now.month && e.date.year == now.year)) {
    totals[e.category] = (totals[e.category] ?? 0) + e.amount;
  }
  return totals;
});
