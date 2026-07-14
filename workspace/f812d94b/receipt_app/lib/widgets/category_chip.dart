import 'package:flutter/material.dart';
import 'package:receipt_app/models/receipt.dart';

class CategoryChip extends StatelessWidget {
  final ExpenseCategory? category; // null = "All"
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String label = category?.displayName ?? 'All';
    final Color color = category?.color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
