class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String emoji;
  final DateTime date;
  final String? note;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.emoji = '💸',
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'amount': amount,
    'category': category, 'emoji': emoji,
    'date': date.toIso8601String(), 'note': note,
  };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
    id: j['id'] as String,
    title: j['title'] as String,
    amount: (j['amount'] as num).toDouble(),
    category: j['category'] as String,
    emoji: j['emoji'] as String? ?? '💸',
    date: DateTime.parse(j['date'] as String),
    note: j['note'] as String?,
  );
}
