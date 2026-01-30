import 'dart:convert';

class SavingsStreak {
  final int currentStreak;
  final int bestStreak;
  final DateTime? lastSavingDate;
  final List<DateTime> savingDates;

  SavingsStreak({
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.lastSavingDate,
    this.savingDates = const [],
  });

  SavingsStreak copyWith({
    int? currentStreak,
    int? bestStreak,
    DateTime? lastSavingDate,
    List<DateTime>? savingDates,
  }) {
    return SavingsStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      lastSavingDate: lastSavingDate ?? this.lastSavingDate,
      savingDates: savingDates ?? this.savingDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'lastSavingDate': lastSavingDate?.toIso8601String(),
      'savingDates': savingDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  factory SavingsStreak.fromJson(Map<String, dynamic> json) {
    return SavingsStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      lastSavingDate: json['lastSavingDate'] != null
          ? DateTime.parse(json['lastSavingDate'] as String)
          : null,
      savingDates: (json['savingDates'] as List<dynamic>?)
              ?.map((d) => DateTime.parse(d as String))
              .toList() ??
          [],
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SavingsStreak.fromJsonString(String source) =>
      SavingsStreak.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
