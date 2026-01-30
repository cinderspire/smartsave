import 'dart:convert';

enum JarPurpose {
  emergency,
  vacation,
  education,
  retirement,
  gadget,
  custom,
}

class AllocationRule {
  final JarPurpose jarPurpose;
  final String jarId;
  final double percentage; // 0-100

  AllocationRule({
    required this.jarPurpose,
    required this.jarId,
    required this.percentage,
  });

  Map<String, dynamic> toJson() => {
        'jarPurpose': jarPurpose.index,
        'jarId': jarId,
        'percentage': percentage,
      };

  factory AllocationRule.fromJson(Map<String, dynamic> json) => AllocationRule(
        jarPurpose: JarPurpose.values[json['jarPurpose'] as int],
        jarId: json['jarId'] as String,
        percentage: (json['percentage'] as num).toDouble(),
      );
}

class MoneyJar {
  final String id;
  final String name;
  final JarPurpose purpose;
  final double balance;
  final double targetAmount;
  final String iconName;
  final int colorValue;
  final DateTime createdAt;
  final List<JarTransaction> transactions;
  final double allocationPercent;

  MoneyJar({
    required this.id,
    required this.name,
    required this.purpose,
    this.balance = 0.0,
    this.targetAmount = 0.0,
    required this.iconName,
    required this.colorValue,
    DateTime? createdAt,
    this.transactions = const [],
    this.allocationPercent = 0.0,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress =>
      targetAmount > 0 ? (balance / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get progressPercent => progress * 100;
  bool get hasTarget => targetAmount > 0;

  MoneyJar copyWith({
    String? id,
    String? name,
    JarPurpose? purpose,
    double? balance,
    double? targetAmount,
    String? iconName,
    int? colorValue,
    DateTime? createdAt,
    List<JarTransaction>? transactions,
    double? allocationPercent,
  }) {
    return MoneyJar(
      id: id ?? this.id,
      name: name ?? this.name,
      purpose: purpose ?? this.purpose,
      balance: balance ?? this.balance,
      targetAmount: targetAmount ?? this.targetAmount,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      transactions: transactions ?? this.transactions,
      allocationPercent: allocationPercent ?? this.allocationPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'purpose': purpose.index,
        'balance': balance,
        'targetAmount': targetAmount,
        'iconName': iconName,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'allocationPercent': allocationPercent,
      };

  factory MoneyJar.fromJson(Map<String, dynamic> json) => MoneyJar(
        id: json['id'] as String,
        name: json['name'] as String,
        purpose: JarPurpose.values[json['purpose'] as int],
        balance: (json['balance'] as num).toDouble(),
        targetAmount: (json['targetAmount'] as num).toDouble(),
        iconName: json['iconName'] as String,
        colorValue: json['colorValue'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        transactions: (json['transactions'] as List<dynamic>?)
                ?.map(
                    (t) => JarTransaction.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        allocationPercent:
            (json['allocationPercent'] as num?)?.toDouble() ?? 0.0,
      );

  String toJsonString() => jsonEncode(toJson());

  factory MoneyJar.fromJsonString(String source) =>
      MoneyJar.fromJson(jsonDecode(source) as Map<String, dynamic>);
}

class JarTransaction {
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final bool isDeposit;

  JarTransaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
    this.isDeposit = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'isDeposit': isDeposit,
      };

  factory JarTransaction.fromJson(Map<String, dynamic> json) =>
      JarTransaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        isDeposit: json['isDeposit'] as bool? ?? true,
      );
}
