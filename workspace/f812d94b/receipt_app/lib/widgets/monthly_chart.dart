import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyChart extends StatelessWidget {
  final Map<String, double> monthlyTotals;

  const MonthlyChart({super.key, required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = monthlyTotals.entries.toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final ceiling = (maxY * 1.2).ceilToDouble();
    // Ensure ceiling is at least 100
    final yAxisMax = ceiling < 100 ? 100.0 : ceiling;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: yAxisMax,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    // Show abbreviated month name
                    final label = entries[idx].key.length > 3
                        ? entries[idx].key.substring(0, 3)
                        : entries[idx].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label, style: const TextStyle(fontSize: 11)),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: yAxisMax / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: theme.colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
