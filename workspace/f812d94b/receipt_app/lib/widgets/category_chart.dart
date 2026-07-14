import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:receipt_app/models/receipt.dart';

class CategoryChart extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryTotals;

  const CategoryChart({super.key, required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final entries = categoryTotals.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: entries.map((entry) {
                final percentage = (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  color: entry.key.color,
                  radius: 60,
                  title: '${percentage.toStringAsFixed(0)}%',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: entries.map((entry) {
            final percentage = (entry.value / total) * 100;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: entry.key.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${entry.key.displayName} \$${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
