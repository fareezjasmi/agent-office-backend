import 'package:flutter/material.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:receipt_app/widgets/receipt_card.dart';

enum SortOption {
  dateNewest('Date (Newest First)'),
  dateOldest('Date (Oldest First)'),
  amountHighest('Amount (High to Low)'),
  amountLowest('Amount (Low to High)'),
  merchantAZ('Merchant (A-Z)'),
  merchantZA('Merchant (Z-A)');

  final String label;

  const SortOption(this.label);
}

class SearchFilterScreen extends StatefulWidget {
  final List<Receipt> receipts;
  final Function(Receipt) onReceiptTap;

  const SearchFilterScreen({
    super.key,
    required this.receipts,
    required this.onReceiptTap,
  });

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  String _searchQuery = '';
  final Set<ExpenseCategory> _selectedCategories = {};
  DateTime? _dateFrom;
  DateTime? _dateTo;
  double _minAmount = 0;
  double _maxAmount = 1000;
  SortOption _sortOption = SortOption.dateNewest;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _minAmountController = TextEditingController(text: '');
    _maxAmountController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Receipt> get _filteredReceipts {
    var filtered = List<Receipt>.from(widget.receipts);

    // Filter by search query (merchant name)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((receipt) => receipt.merchantName.toLowerCase().contains(query))
          .toList();
    }

    // Filter by categories
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((receipt) => _selectedCategories.contains(receipt.category))
          .toList();
    }

    // Filter by date range
    if (_dateFrom != null) {
      filtered = filtered.where((receipt) => receipt.date.isAfter(_dateFrom!)).toList();
    }
    if (_dateTo != null) {
      final dateToEndOfDay = _dateTo!.add(const Duration(days: 1));
      filtered = filtered.where((receipt) => receipt.date.isBefore(dateToEndOfDay)).toList();
    }

    // Filter by amount range
    filtered = filtered
        .where((receipt) => receipt.amount >= _minAmount && receipt.amount <= _maxAmount)
        .toList();

    // Sort
    switch (_sortOption) {
      case SortOption.dateNewest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
      case SortOption.dateOldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
      case SortOption.amountHighest:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
      case SortOption.amountLowest:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
      case SortOption.merchantAZ:
        filtered.sort((a, b) => a.merchantName.compareTo(b.merchantName));
      case SortOption.merchantZA:
        filtered.sort((a, b) => b.merchantName.compareTo(a.merchantName));
    }

    return filtered;
  }

  void _toggleCategory(ExpenseCategory category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _selectDateFrom() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateFrom = picked;
      });
    }
  }

  Future<void> _selectDateTo() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateTo = picked;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _minAmountController.clear();
      _maxAmountController.clear();
      _searchQuery = '';
      _selectedCategories.clear();
      _dateFrom = null;
      _dateTo = null;
      _minAmount = 0;
      _maxAmount = 1000;
      _sortOption = SortOption.dateNewest;
    });
  }

  bool get _hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _dateFrom != null ||
        _dateTo != null ||
        _minAmount > 0 ||
        _maxAmount < 1000 ||
        _sortOption != SortOption.dateNewest;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReceipts;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Search & Filter'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'type to search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Filter Controls
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Category Filter Section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (_selectedCategories.isNotEmpty)
                              GestureDetector(
                                onTap: () => setState(() => _selectedCategories.clear()),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: ExpenseCategory.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = ExpenseCategory.values[index];
                            return GestureDetector(
                              onTap: () => _toggleCategory(category),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _selectedCategories.contains(category)
                                      ? category.color
                                      : category.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  category.displayName,
                                  style: TextStyle(
                                    color: _selectedCategories.contains(category)
                                        ? Colors.white
                                        : category.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Date Range Filter Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Date Range',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (_dateFrom != null || _dateTo != null)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _dateFrom = null;
                                  _dateTo = null;
                                }),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _selectDateFrom,
                                child: Text(_dateFrom == null
                                    ? 'From'
                                    : '${_dateFrom!.month}/${_dateFrom!.day}/${_dateFrom!.year}'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _selectDateTo,
                                child: Text(_dateTo == null
                                    ? 'To'
                                    : '${_dateTo!.month}/${_dateTo!.day}/${_dateTo!.year}'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Amount Range Filter Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Amount Range',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (_minAmount > 0 || _maxAmount < 1000)
                              GestureDetector(
                                onTap: () => setState(() {
                                  _minAmount = 0;
                                  _maxAmount = 1000;
                                }),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Min',
                                  hintText: '0',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _minAmount = double.tryParse(value) ?? 0;
                                  });
                                },
                                controller: _minAmountController,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Max',
                                  hintText: '1000',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _maxAmount = double.tryParse(value) ?? 1000;
                                  });
                                },
                                controller: _maxAmountController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Sorting Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sort By',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButton<SortOption>(
                            value: _sortOption,
                            isExpanded: true,
                            underline: const SizedBox(),
                            onChanged: (SortOption? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sortOption = newValue;
                                });
                              }
                            },
                            items: SortOption.values
                                .map<DropdownMenuItem<SortOption>>((SortOption value) {
                              return DropdownMenuItem<SortOption>(
                                value: value,
                                child: Text(value.label),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Reset Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _hasActiveFilters ? _resetFilters : null,
                        child: const Text('Reset Filters'),
                      ),
                    ),
                  ),
                ),
                // Divider
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                ),
                // Results Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Results (${filtered.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                // Results List
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
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
                            'No receipts found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final receipt = filtered[index];
                      return ReceiptCard(
                        receipt: receipt,
                        onTap: () => widget.onReceiptTap(receipt),
                      );
                    },
                  ),
                // Help text
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'start typing to filter your ledger',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
