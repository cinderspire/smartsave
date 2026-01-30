import 'dart:convert';

class RoundUpTransaction {
  final String id;
  final String merchant;
  final double originalAmount;
  final double roundUpAmount;
  final DateTime date;
  final String? goalId;

  RoundUpTransaction({
    required this.id,
    required this.merchant,
    required this.originalAmount,
    required this.roundUpAmount,
    required this.date,
    this.goalId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant': merchant,
      'originalAmount': originalAmount,
      'roundUpAmount': roundUpAmount,
      'date': date.toIso8601String(),
      'goalId': goalId,
    };
  }

  factory RoundUpTransaction.fromJson(Map<String, dynamic> json) {
    return RoundUpTransaction(
      id: json['id'] as String,
      merchant: json['merchant'] as String,
      originalAmount: (json['originalAmount'] as num).toDouble(),
      roundUpAmount: (json['roundUpAmount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      goalId: json['goalId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory RoundUpTransaction.fromJsonString(String source) =>
      RoundUpTransaction.fromJson(jsonDecode(source) as Map<String, dynamic>);
}
