import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/savings_goal.dart';
import '../models/round_up_transaction.dart';
import '../models/savings_streak.dart';

const _goalsKey = 'smartsave_goals';
const _roundUpsKey = 'smartsave_roundups';
const _roundUpsEnabledKey = 'smartsave_roundups_enabled';
const _streakKey = 'smartsave_streak';
const _monthlySavingsKey = 'smartsave_monthly_savings';
const _dailyTargetKey = 'smartsave_daily_target';
const _weeklyTargetKey = 'smartsave_weekly_target';

// ── Savings Goals ──

class SavingsGoalsNotifier extends StateNotifier<List<SavingsGoal>> {
  SavingsGoalsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_goalsKey);
    if (raw != null && raw.isNotEmpty) {
      state = raw.map((e) => SavingsGoal.fromJsonString(e)).toList();
    } else {
      state = _seedGoals();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _goalsKey,
      state.map((g) => g.toJsonString()).toList(),
    );
  }

  Future<void> addGoal(SavingsGoal goal) async {
    state = [...state, goal];
    await _save();
  }

  Future<void> updateGoal(SavingsGoal updated) async {
    state = [
      for (final g in state)
        if (g.id == updated.id) updated else g,
    ];
    await _save();
  }

  Future<void> deleteGoal(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _save();
  }

  Future<MilestoneReached?> addToGoal(String goalId, double amount) async {
    MilestoneReached? milestone;
    state = [
      for (final g in state)
        if (g.id == goalId) () {
          final oldPercent = g.progressPercent;
          final updated = g.copyWith(currentAmount: g.currentAmount + amount);
          final newPercent = updated.progressPercent;
          milestone = _checkMilestone(oldPercent, newPercent, g.name);
          return updated;
        }() else g,
    ];
    await _save();
    return milestone;
  }

  MilestoneReached? _checkMilestone(double oldPercent, double newPercent, String goalName) {
    final milestones = [25.0, 50.0, 75.0, 100.0];
    for (final m in milestones) {
      if (oldPercent < m && newPercent >= m) {
        return MilestoneReached(
          percentage: m.toInt(),
          goalName: goalName,
          message: _milestoneMessage(m.toInt()),
          emoji: _milestoneEmoji(m.toInt()),
        );
      }
    }
    return null;
  }

  String _milestoneMessage(int percent) {
    switch (percent) {
      case 25: return 'Great start! You are 25% there!';
      case 50: return 'Halfway there! Keep going!';
      case 75: return 'Almost there! Just 25% more!';
      case 100: return 'Goal completed! Amazing work!';
      default: return 'Keep saving!';
    }
  }

  String _milestoneEmoji(int percent) {
    switch (percent) {
      case 25: return 'star';
      case 50: return 'fire';
      case 75: return 'rocket';
      case 100: return 'trophy';
      default: return 'star';
    }
  }

  List<SavingsGoal> _seedGoals() {
    const uuid = Uuid();
    return [
      SavingsGoal(
        id: uuid.v4(),
        name: 'Emergency Fund',
        targetAmount: 10000,
        currentAmount: 6500,
        deadline: DateTime.now().add(const Duration(days: 180)),
        category: 'emergency',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      SavingsGoal(
        id: uuid.v4(),
        name: 'New Car',
        targetAmount: 25000,
        currentAmount: 8200,
        deadline: DateTime.now().add(const Duration(days: 365)),
        category: 'car',
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
      ),
      SavingsGoal(
        id: uuid.v4(),
        name: 'Vacation',
        targetAmount: 3000,
        currentAmount: 2100,
        deadline: DateTime.now().add(const Duration(days: 90)),
        category: 'vacation',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      SavingsGoal(
        id: uuid.v4(),
        name: 'Home Down Payment',
        targetAmount: 50000,
        currentAmount: 12000,
        deadline: DateTime.now().add(const Duration(days: 730)),
        category: 'home',
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
      ),
      SavingsGoal(
        id: uuid.v4(),
        name: 'New Laptop',
        targetAmount: 2000,
        currentAmount: 1500,
        deadline: DateTime.now().add(const Duration(days: 60)),
        category: 'gadget',
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      SavingsGoal(
        id: uuid.v4(),
        name: 'Online Course',
        targetAmount: 500,
        currentAmount: 350,
        deadline: DateTime.now().add(const Duration(days: 30)),
        category: 'education',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];
  }
}

class MilestoneReached {
  final int percentage;
  final String goalName;
  final String message;
  final String emoji;

  MilestoneReached({
    required this.percentage,
    required this.goalName,
    required this.message,
    required this.emoji,
  });
}

final savingsGoalsProvider =
    StateNotifierProvider<SavingsGoalsNotifier, List<SavingsGoal>>(
  (ref) => SavingsGoalsNotifier(),
);

final totalSavedProvider = Provider<double>((ref) {
  final goals = ref.watch(savingsGoalsProvider);
  return goals.fold(0.0, (sum, g) => sum + g.currentAmount);
});

final totalTargetProvider = Provider<double>((ref) {
  final goals = ref.watch(savingsGoalsProvider);
  return goals.fold(0.0, (sum, g) => sum + g.targetAmount);
});

// ── Round-Up Transactions ──

class RoundUpNotifier extends StateNotifier<List<RoundUpTransaction>> {
  RoundUpNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_roundUpsKey);
    if (raw != null && raw.isNotEmpty) {
      state = raw.map((e) => RoundUpTransaction.fromJsonString(e)).toList();
    } else {
      state = _seedRoundUps();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _roundUpsKey,
      state.map((t) => t.toJsonString()).toList(),
    );
  }

  Future<void> addTransaction(RoundUpTransaction txn) async {
    state = [txn, ...state];
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    await _save();
  }

  Future<RoundUpTransaction> simulatePurchase(String merchant, double amount) async {
    const uuid = Uuid();
    final roundUp = _computeRoundUp(amount);
    final txn = RoundUpTransaction(
      id: uuid.v4(),
      merchant: merchant,
      originalAmount: amount,
      roundUpAmount: roundUp,
      date: DateTime.now(),
    );
    await addTransaction(txn);
    return txn;
  }

  double _computeRoundUp(double amount) {
    final cents = amount - amount.floor();
    if (cents == 0) return 1.0;
    return double.parse((1.0 - cents).toStringAsFixed(2));
  }

  List<RoundUpTransaction> _seedRoundUps() {
    const uuid = Uuid();
    final now = DateTime.now();
    return [
      RoundUpTransaction(id: uuid.v4(), merchant: 'Coffee Shop', originalAmount: 4.75, roundUpAmount: 0.25, date: now.subtract(const Duration(hours: 2))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Gas Station', originalAmount: 42.38, roundUpAmount: 0.62, date: now.subtract(const Duration(hours: 5))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Grocery Store', originalAmount: 67.23, roundUpAmount: 0.77, date: now.subtract(const Duration(hours: 12))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Online Subscription', originalAmount: 9.99, roundUpAmount: 0.01, date: now.subtract(const Duration(days: 1))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Restaurant', originalAmount: 32.50, roundUpAmount: 0.50, date: now.subtract(const Duration(days: 1, hours: 4))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Pharmacy', originalAmount: 15.67, roundUpAmount: 0.33, date: now.subtract(const Duration(days: 2))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Book Store', originalAmount: 22.15, roundUpAmount: 0.85, date: now.subtract(const Duration(days: 2, hours: 6))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Fast Food', originalAmount: 8.49, roundUpAmount: 0.51, date: now.subtract(const Duration(days: 3))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Electronics', originalAmount: 149.99, roundUpAmount: 0.01, date: now.subtract(const Duration(days: 3, hours: 8))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Clothing Store', originalAmount: 55.30, roundUpAmount: 0.70, date: now.subtract(const Duration(days: 4))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Parking', originalAmount: 3.25, roundUpAmount: 0.75, date: now.subtract(const Duration(days: 5))),
      RoundUpTransaction(id: uuid.v4(), merchant: 'Movie Theater', originalAmount: 14.50, roundUpAmount: 0.50, date: now.subtract(const Duration(days: 5, hours: 10))),
    ];
  }
}

final roundUpProvider =
    StateNotifierProvider<RoundUpNotifier, List<RoundUpTransaction>>(
  (ref) => RoundUpNotifier(),
);

final totalRoundUpsProvider = Provider<double>((ref) {
  final txns = ref.watch(roundUpProvider);
  return txns.fold(0.0, (sum, t) => sum + t.roundUpAmount);
});

// ── Round-ups enabled toggle ──

class RoundUpsEnabledNotifier extends StateNotifier<bool> {
  RoundUpsEnabledNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_roundUpsEnabledKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_roundUpsEnabledKey, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_roundUpsEnabledKey, value);
  }
}

final roundUpsEnabledProvider =
    StateNotifierProvider<RoundUpsEnabledNotifier, bool>(
  (ref) => RoundUpsEnabledNotifier(),
);

// ── Savings Streak ──

class SavingsStreakNotifier extends StateNotifier<SavingsStreak> {
  SavingsStreakNotifier() : super(SavingsStreak()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_streakKey);
    if (raw != null && raw.isNotEmpty) {
      state = SavingsStreak.fromJsonString(raw);
    } else {
      state = _seedStreak();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_streakKey, state.toJsonString());
  }

  Future<void> recordSaving() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Check if already recorded today
    final alreadyRecorded = state.savingDates.any((d) {
      final dDate = DateTime(d.year, d.month, d.day);
      return dDate == todayDate;
    });

    if (alreadyRecorded) return;

    final newDates = [...state.savingDates, todayDate];
    int newStreak = state.currentStreak;

    if (state.lastSavingDate != null) {
      final lastDate = DateTime(
        state.lastSavingDate!.year,
        state.lastSavingDate!.month,
        state.lastSavingDate!.day,
      );
      final diff = todayDate.difference(lastDate).inDays;
      if (diff == 1) {
        newStreak += 1;
      } else if (diff > 1) {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newBest = newStreak > state.bestStreak ? newStreak : state.bestStreak;

    state = SavingsStreak(
      currentStreak: newStreak,
      bestStreak: newBest,
      lastSavingDate: todayDate,
      savingDates: newDates,
    );
    await _save();
  }

  SavingsStreak _seedStreak() {
    final now = DateTime.now();
    final dates = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      dates.add(DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    }
    return SavingsStreak(
      currentStreak: 7,
      bestStreak: 14,
      lastSavingDate: DateTime(now.year, now.month, now.day),
      savingDates: dates,
    );
  }
}

final savingsStreakProvider =
    StateNotifierProvider<SavingsStreakNotifier, SavingsStreak>(
  (ref) => SavingsStreakNotifier(),
);

// ── Monthly Savings Data ──

class MonthlySavingsNotifier extends StateNotifier<Map<String, double>> {
  MonthlySavingsNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_monthlySavingsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      state = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } else {
      state = _seedMonthlyData();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_monthlySavingsKey, jsonEncode(state));
  }

  Future<void> addToMonth(double amount) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final current = state[key] ?? 0.0;
    state = {...state, key: current + amount};
    await _save();
  }

  Map<String, double> _seedMonthlyData() {
    final now = DateTime.now();
    final data = <String, double>{};
    final amounts = [1200.0, 980.0, 1450.0, 1100.0, 1680.0, 2100.0, 1850.0, 2350.0, 1920.0, 2500.0, 2180.0, 1750.0];
    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      data[key] = amounts[11 - i];
    }
    return data;
  }
}

final monthlySavingsProvider =
    StateNotifierProvider<MonthlySavingsNotifier, Map<String, double>>(
  (ref) => MonthlySavingsNotifier(),
);

// ── Daily/Weekly Targets ──

class DailyTargetNotifier extends StateNotifier<double> {
  DailyTargetNotifier() : super(10.0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_dailyTargetKey) ?? 10.0;
  }

  Future<void> setTarget(double value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dailyTargetKey, value);
  }
}

final dailyTargetProvider =
    StateNotifierProvider<DailyTargetNotifier, double>(
  (ref) => DailyTargetNotifier(),
);

class WeeklyTargetNotifier extends StateNotifier<double> {
  WeeklyTargetNotifier() : super(50.0) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble(_weeklyTargetKey) ?? 50.0;
  }

  Future<void> setTarget(double value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_weeklyTargetKey, value);
  }
}

final weeklyTargetProvider =
    StateNotifierProvider<WeeklyTargetNotifier, double>(
  (ref) => WeeklyTargetNotifier(),
);

// ── Activity Feed ──

class ActivityItem {
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final ActivityType type;

  ActivityItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
  });
}

enum ActivityType { roundUp, goalDeposit, goalCreated, goalCompleted }

final recentActivityProvider = Provider<List<ActivityItem>>((ref) {
  final roundUps = ref.watch(roundUpProvider);
  final goals = ref.watch(savingsGoalsProvider);

  final activities = <ActivityItem>[];

  for (final txn in roundUps.take(5)) {
    activities.add(ActivityItem(
      title: 'Round-up from ${txn.merchant}',
      subtitle: '\$${txn.originalAmount.toStringAsFixed(2)} purchase',
      amount: txn.roundUpAmount,
      date: txn.date,
      type: ActivityType.roundUp,
    ));
  }

  for (final goal in goals) {
    activities.add(ActivityItem(
      title: 'Goal: ${goal.name}',
      subtitle: goal.isComplete ? 'Goal completed!' : '${goal.progressPercent.toStringAsFixed(0)}% complete',
      amount: goal.currentAmount,
      date: goal.createdAt,
      type: goal.isComplete ? ActivityType.goalCompleted : ActivityType.goalCreated,
    ));
  }

  activities.sort((a, b) => b.date.compareTo(a.date));
  return activities.take(10).toList();
});

// ── Stats Providers ──

final totalSavedAllTimeProvider = Provider<double>((ref) {
  final goalsSaved = ref.watch(totalSavedProvider);
  final roundUpsSaved = ref.watch(totalRoundUpsProvider);
  return goalsSaved + roundUpsSaved;
});

final savingsRateProvider = Provider<double>((ref) {
  final monthly = ref.watch(monthlySavingsProvider);
  if (monthly.isEmpty) return 0.0;
  final total = monthly.values.fold(0.0, (a, b) => a + b);
  return total / monthly.length;
});

final completedGoalsCountProvider = Provider<int>((ref) {
  final goals = ref.watch(savingsGoalsProvider);
  return goals.where((g) => g.isComplete).length;
});
