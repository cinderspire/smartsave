import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/money_jar.dart';

const _jarsKey = 'smartsave_money_jars';

class MoneyJarsNotifier extends StateNotifier<List<MoneyJar>> {
  MoneyJarsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_jarsKey);
    if (raw != null && raw.isNotEmpty) {
      state = raw.map((e) => MoneyJar.fromJsonString(e)).toList();
    } else {
      state = _seedJars();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _jarsKey,
      state.map((j) => j.toJsonString()).toList(),
    );
  }

  Future<void> addJar(MoneyJar jar) async {
    state = [...state, jar];
    await _save();
  }

  Future<void> updateJar(MoneyJar updated) async {
    state = [
      for (final j in state)
        if (j.id == updated.id) updated else j,
    ];
    await _save();
  }

  Future<void> deleteJar(String id) async {
    state = state.where((j) => j.id != id).toList();
    await _save();
  }

  Future<void> depositToJar(String jarId, double amount, String description) async {
    const uuid = Uuid();
    state = [
      for (final j in state)
        if (j.id == jarId)
          j.copyWith(
            balance: j.balance + amount,
            transactions: [
              JarTransaction(
                id: uuid.v4(),
                amount: amount,
                description: description,
                date: DateTime.now(),
                isDeposit: true,
              ),
              ...j.transactions,
            ],
          )
        else
          j,
    ];
    await _save();
  }

  Future<void> withdrawFromJar(String jarId, double amount, String description) async {
    const uuid = Uuid();
    state = [
      for (final j in state)
        if (j.id == jarId)
          j.copyWith(
            balance: (j.balance - amount).clamp(0.0, double.infinity),
            transactions: [
              JarTransaction(
                id: uuid.v4(),
                amount: amount,
                description: description,
                date: DateTime.now(),
                isDeposit: false,
              ),
              ...j.transactions,
            ],
          )
        else
          j,
    ];
    await _save();
  }

  Future<void> distributeByAllocation(double totalAmount) async {
    final jarsWithAlloc = state.where((j) => j.allocationPercent > 0).toList();
    if (jarsWithAlloc.isEmpty) return;

    const uuid = Uuid();
    final totalPercent =
        jarsWithAlloc.fold(0.0, (sum, j) => sum + j.allocationPercent);

    state = [
      for (final j in state)
        if (j.allocationPercent > 0)
          j.copyWith(
            balance: j.balance +
                (totalAmount * j.allocationPercent / totalPercent),
            transactions: [
              JarTransaction(
                id: uuid.v4(),
                amount: totalAmount * j.allocationPercent / totalPercent,
                description: 'Auto-allocation',
                date: DateTime.now(),
                isDeposit: true,
              ),
              ...j.transactions,
            ],
          )
        else
          j,
    ];
    await _save();
  }

  Future<void> updateAllocation(String jarId, double percent) async {
    state = [
      for (final j in state)
        if (j.id == jarId) j.copyWith(allocationPercent: percent) else j,
    ];
    await _save();
  }

  List<MoneyJar> _seedJars() {
    const uuid = Uuid();
    final now = DateTime.now();
    return [
      MoneyJar(
        id: uuid.v4(),
        name: 'Emergency Fund',
        purpose: JarPurpose.emergency,
        balance: 2500.0,
        targetAmount: 10000.0,
        iconName: 'shield',
        colorValue: 0xFF10B981,
        createdAt: now.subtract(const Duration(days: 90)),
        allocationPercent: 40.0,
        transactions: [
          JarTransaction(id: uuid.v4(), amount: 500.0, description: 'Monthly deposit', date: now.subtract(const Duration(days: 7)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 500.0, description: 'Monthly deposit', date: now.subtract(const Duration(days: 37)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 1000.0, description: 'Initial deposit', date: now.subtract(const Duration(days: 67)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 500.0, description: 'Bonus deposit', date: now.subtract(const Duration(days: 50)), isDeposit: true),
        ],
      ),
      MoneyJar(
        id: uuid.v4(),
        name: 'Vacation Fund',
        purpose: JarPurpose.vacation,
        balance: 1200.0,
        targetAmount: 3000.0,
        iconName: 'flight',
        colorValue: 0xFFFFB020,
        createdAt: now.subtract(const Duration(days: 60)),
        allocationPercent: 25.0,
        transactions: [
          JarTransaction(id: uuid.v4(), amount: 400.0, description: 'Monthly deposit', date: now.subtract(const Duration(days: 5)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 400.0, description: 'Monthly deposit', date: now.subtract(const Duration(days: 35)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 400.0, description: 'Initial deposit', date: now.subtract(const Duration(days: 60)), isDeposit: true),
        ],
      ),
      MoneyJar(
        id: uuid.v4(),
        name: 'Education',
        purpose: JarPurpose.education,
        balance: 800.0,
        targetAmount: 5000.0,
        iconName: 'school',
        colorValue: 0xFF8B5CF6,
        createdAt: now.subtract(const Duration(days: 45)),
        allocationPercent: 20.0,
        transactions: [
          JarTransaction(id: uuid.v4(), amount: 300.0, description: 'Monthly deposit', date: now.subtract(const Duration(days: 10)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 500.0, description: 'Initial deposit', date: now.subtract(const Duration(days: 45)), isDeposit: true),
        ],
      ),
      MoneyJar(
        id: uuid.v4(),
        name: 'New Gadget',
        purpose: JarPurpose.gadget,
        balance: 350.0,
        targetAmount: 1500.0,
        iconName: 'devices',
        colorValue: 0xFF06B6D4,
        createdAt: now.subtract(const Duration(days: 30)),
        allocationPercent: 15.0,
        transactions: [
          JarTransaction(id: uuid.v4(), amount: 200.0, description: 'Monthly deposit', date: now.subtract(const Duration(days: 3)), isDeposit: true),
          JarTransaction(id: uuid.v4(), amount: 150.0, description: 'Initial deposit', date: now.subtract(const Duration(days: 30)), isDeposit: true),
        ],
      ),
    ];
  }
}

final moneyJarsProvider =
    StateNotifierProvider<MoneyJarsNotifier, List<MoneyJar>>(
  (ref) => MoneyJarsNotifier(),
);

final totalJarBalanceProvider = Provider<double>((ref) {
  final jars = ref.watch(moneyJarsProvider);
  return jars.fold(0.0, (sum, j) => sum + j.balance);
});
