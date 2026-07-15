import 'package:flutter/material.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:receipt_app/screens/add_receipt_screen.dart';
import 'package:receipt_app/screens/search_filter_screen.dart';
import 'package:receipt_app/widgets/category_chip.dart';
import 'package:receipt_app/widgets/receipt_list_layouts.dart';
import 'package:receipt_app/widgets/spending_summary_card.dart';

class StoreDetailScreen extends StatefulWidget {
  final String merchantName;
  final List<Receipt> allReceipts;

  const StoreDetailScreen({
    super.key,
    required this.merchantName,
    required this.allReceipts,
  });

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isSearching = false;
  LayoutDirection _layoutDirection = LayoutDirection.bareList;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Receipt> get _merchantReceipts {
    return widget.allReceipts
        .where((r) =>
            r.merchantName.toLowerCase() == widget.merchantName.toLowerCase())
        .toList();
  }

  List<Receipt> get _filteredReceipts {
    var filtered = List<Receipt>.from(_merchantReceipts);

    // Filter by category
    if (_selectedCategory != null) {
      filtered = filtered.where((r) => r.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((r) =>
              r.merchantName.toLowerCase().contains(query) ||
              r.notes?.toLowerCase().contains(query) == true ||
              r.items.any((item) => item.description.toLowerCase().contains(query)))
          .toList();
    }

    // Sort by date descending (most recent first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  double get _totalSpending {
    return _filteredReceipts.fold<double>(0, (sum, r) => sum + r.amount);
  }

  void _onCategorySelected(ExpenseCategory? category) {
    setState(() {
      _selectedCategory =
          _selectedCategory == category ? null : category;
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _changeLayoutDirection(LayoutDirection direction) {
    setState(() {
      _layoutDirection = direction;
    });
  }

  Future<void> _navigateToAddReceipt({int? index}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddReceiptScreen(
          editIndex: index,
          existingReceipt: index != null ? widget.allReceipts[index] : null,
        ),
      ),
    );

    if (result == null) return;

    if (result['saved'] == true) {
      // Refresh the screen to show updated data
      setState(() {});
    }
  }

  void _navigateToSearchFilter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchFilterScreen(
          receipts: _merchantReceipts,
          onReceiptTap: (receipt) {
            final index = widget.allReceipts.indexOf(receipt);
            Navigator.pop(context);
            _navigateToAddReceipt(index: index);
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _toggleSearch,
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search receipts...',
            border: InputBorder.none,
            filled: false,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
        ],
      );
    }

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('→ ${widget.merchantName}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: _navigateToSearchFilter,
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [null, ...ExpenseCategory.values];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          return CategoryChip(
            category: category,
            isSelected: category == _selectedCategory,
            onTap: () => _onCategorySelected(category),
          );
        },
      ),
    );
  }

  Widget _buildLayoutSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildLayoutButton(
              label: 'Paper-tape',
              direction: LayoutDirection.paperTape,
              icon: Icons.list,
            ),
            const SizedBox(width: 8),
            _buildLayoutButton(
              label: 'Torn-card',
              direction: LayoutDirection.tornCard,
              icon: Icons.credit_card,
            ),
            const SizedBox(width: 8),
            _buildLayoutButton(
              label: 'Bare-list',
              direction: LayoutDirection.bareList,
              icon: Icons.view_agenda,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutButton({
    required String label,
    required LayoutDirection direction,
    required IconData icon,
  }) {
    final isSelected = _layoutDirection == direction;
    return OutlinedButton.icon(
      onPressed: () => _changeLayoutDirection(direction),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[400]!,
          width: isSelected ? 2 : 1,
        ),
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildReceiptList() {
    final filtered = _filteredReceipts;

    if (filtered.isEmpty) {
      return const Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No receipts found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    switch (_layoutDirection) {
      case LayoutDirection.paperTape:
        return PaperTapeReceiptList(
          receipts: filtered,
          onReceiptTap: (index) {
            final receipt = filtered[index];
            final originalIndex = widget.allReceipts.indexOf(receipt);
            _navigateToAddReceipt(index: originalIndex);
          },
        );
      case LayoutDirection.tornCard:
        return TornCardReceiptList(
          receipts: filtered,
          onReceiptTap: (index) {
            final receipt = filtered[index];
            final originalIndex = widget.allReceipts.indexOf(receipt);
            _navigateToAddReceipt(index: originalIndex);
          },
        );
      case LayoutDirection.bareList:
        return BareListReceiptList(
          receipts: filtered,
          onReceiptTap: (index) {
            final receipt = filtered[index];
            final originalIndex = widget.allReceipts.indexOf(receipt);
            _navigateToAddReceipt(index: originalIndex);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          SpendingSummaryCard(
            totalAmount: _totalSpending,
            receiptCount: _filteredReceipts.length,
          ),
          _buildCategoryFilters(),
          _buildLayoutSwitcher(),
          _buildReceiptList(),
        ],
      ),
    );
  }
}
