class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type; // income | expense
  final String date; // ISO-8601
  final String category;
  final String note;

  const TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    this.category = 'Khác',
    this.note = '',
  });

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'type': type,
    'date': date,
    'category': category,
    'note': note,
  };

  factory TransactionModel.fromMap(Map<String, Object?> m) => TransactionModel(
    id: m['id'] as int?,
    title: m['title'] as String,
    amount: (m['amount'] as num).toDouble(),
    type: m['type'] as String,
    date: m['date'] as String,
    category: (m['category'] as String?) ?? 'Khác',
    note: (m['note'] as String?) ?? '',
  );
}
