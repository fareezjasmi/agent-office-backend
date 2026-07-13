import 'package:intl/intl.dart';

class Receipt {
  final int? id;
  final String title;
  final String imagePath;
  final int categoryId;
  final DateTime date;
  final double amount;
  final String notes;

  Receipt({
    this.id,
    required this.title,
    required this.imagePath,
    required this.categoryId,
    required this.date,
    required this.amount,
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'imagePath': imagePath,
    'categoryId': categoryId,
    'date': date.toIso8601String(),
    'amount': amount,
    'notes': notes,
  };

  factory Receipt.fromMap(Map<String, dynamic> map) => Receipt(
    id: map['id'] as int?,
    title: map['title'] as String,
    imagePath: map['imagePath'] as String,
    categoryId: map['categoryId'] as int,
    date: DateTime.parse(map['date'] as String),
    amount: (map['amount'] as num).toDouble(),
    notes: map['notes'] as String? ?? '',
  );

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';
}
