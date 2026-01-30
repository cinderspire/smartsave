import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/savings_challenge.dart';

const _challengesKey = 'smartsave_challenges';

class ChallengesNotifier extends StateNotifier<List<SavingsChallenge>> {
  ChallengesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_challengesKey);
    if (raw != null && raw.isNotEmpty) {
      state = raw.map((e) => SavingsChallenge.fromJsonString(e)).toList();
    } else {
      state = _seedChallenges();
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _challengesKey,
      state.map((c) => c.toJsonString()).toList(),
    );
  }

  Future<void> addChallenge(SavingsChallenge challenge) async {
    state = [...state, challenge];
    await _save();
  }

  Future<void> updateChallenge(SavingsChallenge updated) async {
    state = [
      for (final c in state)
        if (c.id == updated.id) updated else c,
    ];
    await _save();
  }

  Future<void> deleteChallenge(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _save();
  }

  Future<void> toggleActive(String id) async {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(isActive: !c.isActive) else c,
    ];
    await _save();
  }

  Future<void> addEntry(String challengeId, ChallengeEntry entry) async {
    state = [
      for (final c in state)
        if (c.id == challengeId)
          c.copyWith(
            entries: [...c.entries, entry],
            totalSaved: c.totalSaved + entry.amount,
          )
        else
          c,
    ];
    await _save();
  }

  Future<void> logNoSpendDay(String challengeId) async {
    final entry = ChallengeEntry(
      date: DateTime.now(),
      amount: 10.0,
      completed: true,
      note: 'No-spend day completed',
    );
    await addEntry(challengeId, entry);
  }

  Future<void> logWeeklySaving(String challengeId, int week) async {
    final entry = ChallengeEntry(
      date: DateTime.now(),
      amount: week.toDouble(),
      completed: true,
      note: 'Week $week saving',
    );
    await addEntry(challengeId, entry);
  }

  Future<void> logPennySaving(String challengeId, int day) async {
    final entry = ChallengeEntry(
      date: DateTime.now(),
      amount: day * 0.01,
      completed: true,
      note: 'Day $day penny saving',
    );
    await addEntry(challengeId, entry);
  }

  Future<void> logRoundUpEntry(String challengeId, double amount) async {
    final entry = ChallengeEntry(
      date: DateTime.now(),
      amount: amount,
      completed: true,
      note: 'Round-up saving',
    );
    await addEntry(challengeId, entry);
  }

  List<SavingsChallenge> _seedChallenges() {
    const uuid = Uuid();
    final now = DateTime.now();
    return [
      SavingsChallenge(
        id: uuid.v4(),
        type: ChallengeType.fiftyTwoWeek,
        name: '52-Week Challenge',
        description: 'Save \$1 in week 1, \$2 in week 2, and so on. By week 52, you will have saved \$1,378!',
        startDate: now.subtract(const Duration(days: 42)),
        durationDays: 364,
        entries: List.generate(6, (i) => ChallengeEntry(
          date: now.subtract(Duration(days: 42 - (i * 7))),
          amount: (i + 1).toDouble(),
          completed: true,
          note: 'Week ${i + 1} saving',
        )),
        totalSaved: 21.0,
      ),
      SavingsChallenge(
        id: uuid.v4(),
        type: ChallengeType.noSpend,
        name: 'No-Spend Challenge',
        description: 'Track days where you spend nothing. Save \$10 for each no-spend day!',
        startDate: now.subtract(const Duration(days: 14)),
        durationDays: 30,
        entries: List.generate(5, (i) => ChallengeEntry(
          date: now.subtract(Duration(days: 14 - (i * 3))),
          amount: 10.0,
          completed: true,
          note: 'No-spend day completed',
        )),
        totalSaved: 50.0,
      ),
      SavingsChallenge(
        id: uuid.v4(),
        type: ChallengeType.penny,
        name: 'Penny Challenge',
        description: 'Save 1 cent on day 1, 2 cents on day 2, etc. By day 365, you save \$667.95!',
        startDate: now.subtract(const Duration(days: 30)),
        durationDays: 365,
        isActive: false,
        entries: List.generate(15, (i) => ChallengeEntry(
          date: now.subtract(Duration(days: 30 - (i * 2))),
          amount: (i + 1) * 0.01,
          completed: true,
          note: 'Day ${i + 1} penny saving',
        )),
        totalSaved: 1.20,
      ),
      SavingsChallenge(
        id: uuid.v4(),
        type: ChallengeType.roundUp,
        name: 'Round-Up Challenge',
        description: 'Log your purchases and automatically save the spare change by rounding up to the nearest dollar.',
        startDate: now.subtract(const Duration(days: 21)),
        durationDays: 90,
        entries: List.generate(8, (i) => ChallengeEntry(
          date: now.subtract(Duration(days: 21 - (i * 2))),
          amount: [0.25, 0.62, 0.77, 0.01, 0.50, 0.33, 0.85, 0.51][i],
          completed: true,
          note: 'Round-up saving',
        )),
        totalSaved: 3.84,
      ),
    ];
  }
}

final challengesProvider =
    StateNotifierProvider<ChallengesNotifier, List<SavingsChallenge>>(
  (ref) => ChallengesNotifier(),
);

final activeChallengesProvider = Provider<List<SavingsChallenge>>((ref) {
  final challenges = ref.watch(challengesProvider);
  return challenges.where((c) => c.isActive).toList();
});

final totalChallengeSavingsProvider = Provider<double>((ref) {
  final challenges = ref.watch(challengesProvider);
  return challenges.fold(0.0, (sum, c) => sum + c.totalSaved);
});
