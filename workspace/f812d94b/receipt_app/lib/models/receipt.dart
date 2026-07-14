import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ExpenseCategory {
  food,
  transport,
  shopping,
  utilities,
  entertainment,
  health,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transport:
        return Colors.blue;
      case ExpenseCategory.shopping:
        return Colors.purple;
      case ExpenseCategory.utilities:
        return Colors.red;
      case ExpenseCategory.entertainment:
        return Colors.teal;
      case ExpenseCategory.health:
        return Colors.green;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transport:
        return Icons.directions_car;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.utilities:
        return Icons.receipt_long;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.health:
        return Icons.favorite;
      case ExpenseCategory.other:
        return Icons.more_horiz;
    }
  }
}

class ReceiptItem {
  final String description;
  final double amount;

  const ReceiptItem({
    required this.description,
    required this.amount,
  });

  String get formattedAmount {
    final f = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return f.format(amount);
  }
}

class Receipt {
  final String id;
  final String merchantName;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? notes;
  final String? imagePath;
  final List<ReceiptItem> items;

  const Receipt({
    required this.id,
    required this.merchantName,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    this.imagePath,
    this.items = const [],
  });

  String get formattedAmount {
    final f = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    return f.format(amount);
  }

  String get formattedDate {
    final f = DateFormat('MMM dd, yyyy');
    return f.format(date);
  }
}

final List<Receipt> sampleReceipts = [
  Receipt(
    id: 'r1',
    merchantName: 'Starbucks',
    amount: 5.75,
    date: DateTime(2026, 7, 10),
    category: ExpenseCategory.food,
    items: [
      const ReceiptItem(description: 'Grande Latte', amount: 5.75),
    ],
  ),
  Receipt(
    id: 'r2',
    merchantName: 'Shell Gas Station',
    amount: 52.00,
    date: DateTime(2026, 7, 8),
    category: ExpenseCategory.transport,
    items: [
      const ReceiptItem(description: 'Gasoline (Premium)', amount: 50.00),
      const ReceiptItem(description: 'Car Wash', amount: 2.00),
    ],
  ),
  Receipt(
    id: 'r3',
    merchantName: 'Amazon',
    amount: 89.99,
    date: DateTime(2026, 6, 25),
    category: ExpenseCategory.shopping,
    items: [
      const ReceiptItem(description: 'Wireless Earbuds', amount: 49.99),
      const ReceiptItem(description: 'USB-C Cable (2-pack)', amount: 15.99),
      const ReceiptItem(description: 'Phone Case', amount: 24.01),
    ],
  ),
  Receipt(
    id: 'r4',
    merchantName: 'Electric Company',
    amount: 120.50,
    date: DateTime(2026, 6, 15),
    category: ExpenseCategory.utilities,
    items: [
      const ReceiptItem(description: 'Monthly Electric Bill', amount: 120.50),
    ],
  ),
  Receipt(
    id: 'r5',
    merchantName: 'Netflix',
    amount: 15.99,
    date: DateTime(2026, 7, 1),
    category: ExpenseCategory.entertainment,
    items: [
      const ReceiptItem(description: 'Monthly Subscription', amount: 15.99),
    ],
  ),
  Receipt(
    id: 'r6',
    merchantName: 'CVS Pharmacy',
    amount: 23.45,
    date: DateTime(2026, 6, 20),
    category: ExpenseCategory.health,
    items: [
      const ReceiptItem(description: 'Vitamins', amount: 9.99),
      const ReceiptItem(description: 'Pain Relief', amount: 5.99),
      const ReceiptItem(description: 'Sunscreen', amount: 7.47),
    ],
  ),
  Receipt(
    id: 'r7',
    merchantName: 'Uber Ride',
    amount: 18.75,
    date: DateTime(2026, 7, 5),
    category: ExpenseCategory.transport,
    items: [
      const ReceiptItem(description: 'Ride to Downtown', amount: 15.50),
      const ReceiptItem(description: 'Service Fee', amount: 3.25),
    ],
  ),
  Receipt(
    id: 'r8',
    merchantName: 'Whole Foods',
    amount: 67.80,
    date: DateTime(2026, 6, 28),
    category: ExpenseCategory.food,
    items: [
      const ReceiptItem(description: 'Organic Chicken Breast', amount: 18.99),
      const ReceiptItem(description: 'Wild Salmon', amount: 16.50),
      const ReceiptItem(description: 'Mixed Vegetables', amount: 9.99),
      const ReceiptItem(description: 'Olive Oil', amount: 12.99),
      const ReceiptItem(description: 'Almond Butter', amount: 8.99),
      const ReceiptItem(description: 'Tea', amount: 0.34),
    ],
  ),
  Receipt(
    id: 'r9',
    merchantName: 'Target',
    amount: 52.30,
    date: DateTime(2026, 5, 18),
    category: ExpenseCategory.shopping,
    items: [
      const ReceiptItem(description: 'Socks (6 pack)', amount: 14.99),
      const ReceiptItem(description: 'T-Shirts (2)', amount: 29.98),
      const ReceiptItem(description: 'Deodorant', amount: 7.33),
    ],
  ),
  Receipt(
    id: 'r10',
    merchantName: 'Internet Provider',
    amount: 79.99,
    date: DateTime(2026, 5, 2),
    category: ExpenseCategory.utilities,
    items: [
      const ReceiptItem(description: 'Monthly Internet Bill', amount: 79.99),
    ],
  ),
  Receipt(
    id: 'r11',
    merchantName: 'McDonald\'s',
    amount: 12.39,
    date: DateTime(2026, 7, 12),
    category: ExpenseCategory.food,
    items: [
      const ReceiptItem(description: 'Big Mac', amount: 5.99),
      const ReceiptItem(description: 'Large Fries', amount: 3.19),
      const ReceiptItem(description: 'Drink (Large)', amount: 3.21),
    ],
  ),
  Receipt(
    id: 'r12',
    merchantName: 'Gym Membership',
    amount: 49.99,
    date: DateTime(2026, 6, 1),
    category: ExpenseCategory.health,
    items: [
      const ReceiptItem(description: 'Monthly Membership', amount: 49.99),
    ],
  ),
];
