import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:receipt_app/widgets/category_chart.dart';
import 'package:receipt_app/widgets/monthly_chart.dart';

class StatsScreen extends StatelessWidget {
  final List<Receipt> receipts;

  const StatsScreen({super.key, required this.receipts});

  Map<String, double> _computeMonthlyTotals() {
    final Map<String, double> totals = {};
    for (final receipt in receipts) {
      final key = DateFormat('MMM yyyy').format(receipt.date);
      totals[key] = (totals[key] ?? 0) + receipt.amount;
    }
    return totals;
  }

  Map<ExpenseCategory, double> _computeCategoryTotals() {
    final Map<ExpenseCategory, double> totals = {};
    for (final receipt in receipts) {
      totals[receipt.category] =
          (totals[receipt.category] ?? 0) + receipt.amount;
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final monthlyTotals = _computeMonthlyTotals();
    final categoryTotals = _computeCategoryTotals();
    final totalSpending = receipts.fold<double>(0, (sum, r) => sum + r.amount);

    // Sort categories by amount descending
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Spending section
            Text(
              'Monthly Spending',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MonthlyChart(monthlyTotals: monthlyTotals),
              ),
            ),
            const SizedBox(height: 24),

            // Spending by Category section
            Text(
              'Spending by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CategoryChart(categoryTotals: categoryTotals),
              ),
            ),
            const SizedBox(height: 24),

            // Spending breakdown list
            Text(
              'Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...sortedCategories.map((entry) {
              final percentage = totalSpending > 0
                  ? (entry.value / totalSpending) * 100
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: entry.key.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key.displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[200],
                              color: entry.key.color,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
