import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:receipt_app/screens/add_receipt_screen.dart';

class MonthlyViewScreen extends StatefulWidget {
  final List<Receipt> receipts;

  const MonthlyViewScreen({
    super.key,
    required this.receipts,
  });

  @override
  State<MonthlyViewScreen> createState() => _MonthlyViewScreenState();
}

class _MonthlyViewScreenState extends State<MonthlyViewScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );
  }

  List<Receipt> get _monthlyReceipts {
    return widget.receipts
        .where((receipt) =>
            receipt.date.year == _currentMonth.year &&
            receipt.date.month == _currentMonth.month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<int, List<Receipt>> get _receiptsByDate {
    final grouped = <int, List<Receipt>>{};
    for (final receipt in _monthlyReceipts) {
      final day = receipt.date.day;
      grouped.putIfAbsent(day, () => []).add(receipt);
    }
    // Sort by day descending (newest first)
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  double get _monthlyTotal {
    return _monthlyReceipts.fold<double>(0, (sum, r) => sum + r.amount);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month - 1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(
        _currentMonth.year,
        _currentMonth.month + 1,
      );
    });
  }

  Future<void> _navigateToEditReceipt(Receipt receipt) async {
    final index = widget.receipts.indexOf(receipt);
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddReceiptScreen(
          editIndex: index,
          existingReceipt: receipt,
        ),
      ),
    );

    if (result == null) return;

    // Handle the result in parent screen
    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  String _formatMonthYear() {
    final formatter = DateFormat('MMMM yyyy');
    return formatter.format(_currentMonth).toUpperCase();
  }

  String _formatDay(int day) {
    final date = DateTime(_currentMonth.year, _currentMonth.month, day);
    final formatter = DateFormat('EEE, MMM d');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    final monthYear = _formatMonthYear();
    final receiptsByDate = _receiptsByDate;
    final monthlyTotal = _monthlyTotal;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            monthYear,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
        ),
        body: Column(
          children: [
            // Month Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousMonth,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextMonth,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Total Spending Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Spending',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '\$${monthlyTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Receipts List
            Expanded(
              child: receiptsByDate.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No receipts this month',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: receiptsByDate.length,
                      itemBuilder: (context, index) {
                        final day = receiptsByDate.keys.elementAt(index);
                        final receipts = receiptsByDate[day]!;
                        final dayTotal =
                            receipts.fold<double>(0, (sum, r) => sum + r.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date Header
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12,
                                bottom: 8,
                                left: 4,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDay(day),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: \$${dayTotal.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Receipts for this day
                            ...receipts.map((receipt) {
                              return _buildReceiptTile(context, receipt);
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptTile(BuildContext context, Receipt receipt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToEditReceipt(receipt),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: receipt.category.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    receipt.category.icon,
                    color: receipt.category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        receipt.category.displayName,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  receipt.formattedAmount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
