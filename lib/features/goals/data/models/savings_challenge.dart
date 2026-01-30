import 'dart:convert';

enum ChallengeType {
  fiftyTwoWeek,
  penny,
  noSpend,
  roundUp,
}

class SavingsChallenge {
  final String id;
  final ChallengeType type;
  final String name;
  final String description;
  final DateTime startDate;
  final int durationDays;
  final bool isActive;
  final List<ChallengeEntry> entries;
  final double totalSaved;

  SavingsChallenge({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.startDate,
    required this.durationDays,
    this.isActive = true,
    this.entries = const [],
    this.totalSaved = 0.0,
  });

  DateTime get endDate => startDate.add(Duration(days: durationDays));
  int get daysCompleted => DateTime.now().difference(startDate).inDays.clamp(0, durationDays);
  double get progressPercent => durationDays > 0 ? (daysCompleted / durationDays * 100).clamp(0, 100) : 0;
  int get currentWeek => (daysCompleted / 7).ceil().clamp(1, 52);
  int get currentDay => daysCompleted.clamp(1, durationDays);
  bool get isCompleted => daysCompleted >= durationDays;

  double get expectedSavings {
    switch (type) {
      case ChallengeType.fiftyTwoWeek:
        final weeks = currentWeek;
        return List.generate(weeks, (i) => (i + 1).toDouble()).fold(0.0, (a, b) => a + b);
      case ChallengeType.penny:
        final days = currentDay;
        return List.generate(days, (i) => (i + 1) * 0.01).fold(0.0, (a, b) => a + b);
      case ChallengeType.noSpend:
        return entries.where((e) => e.completed).length.toDouble() * 10.0;
      case ChallengeType.roundUp:
        return totalSaved;
    }
  }

  SavingsChallenge copyWith({
    String? id,
    ChallengeType? type,
    String? name,
    String? description,
    DateTime? startDate,
    int? durationDays,
    bool? isActive,
    List<ChallengeEntry>? entries,
    double? totalSaved,
  }) {
    return SavingsChallenge(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      durationDays: durationDays ?? this.durationDays,
      isActive: isActive ?? this.isActive,
      entries: entries ?? this.entries,
      totalSaved: totalSaved ?? this.totalSaved,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'durationDays': durationDays,
      'isActive': isActive,
      'entries': entries.map((e) => e.toJson()).toList(),
      'totalSaved': totalSaved,
    };
  }

  factory SavingsChallenge.fromJson(Map<String, dynamic> json) {
    return SavingsChallenge(
      id: json['id'] as String,
      type: ChallengeType.values[json['type'] as int],
      name: json['name'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      durationDays: json['durationDays'] as int,
      isActive: json['isActive'] as bool? ?? true,
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => ChallengeEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory SavingsChallenge.fromJsonString(String source) =>
      SavingsChallenge.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

class ChallengeEntry {
  final DateTime date;
  final double amount;
  final bool completed;
  final String? note;

  ChallengeEntry({
    required this.date,
    required this.amount,
    this.completed = true,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'amount': amount,
      'completed': completed,
      'note': note,
    };
  }

  factory ChallengeEntry.fromJson(Map<String, dynamic> json) {
    return ChallengeEntry(
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      completed: json['completed'] as bool? ?? true,
      note: json['note'] as String?,
    );
  }
}
