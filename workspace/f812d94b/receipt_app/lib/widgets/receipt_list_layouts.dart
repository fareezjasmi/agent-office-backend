import 'package:flutter/material.dart';
import 'package:receipt_app/models/receipt.dart';

enum LayoutDirection {
  paperTape,
  tornCard,
  bareList,
}

/// Paper-tape scroll layout - Continuous vertical ledger-style list
class PaperTapeReceiptList extends StatelessWidget {
  final List<Receipt> receipts;
  final Function(int) onReceiptTap;

  const PaperTapeReceiptList({
    super.key,
    required this.receipts,
    required this.onReceiptTap,
  });

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) {
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

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          return InkWell(
            onTap: () => onReceiptTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                        const SizedBox(height: 2),
                        Text(
                          receipt.formattedDate,
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
          );
        },
      ),
    );
  }
}

/// Torn-card stock layout - Chunky bordered cards with details
class TornCardReceiptList extends StatelessWidget {
  final List<Receipt> receipts;
  final Function(int) onReceiptTap;

  const TornCardReceiptList({
    super.key,
    required this.receipts,
    required this.onReceiptTap,
  });

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) {
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

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: receipts.length,
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(
                color: Colors.black26,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onReceiptTap(index),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant name
                    Text(
                      receipt.merchantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Itemized list
                    if (receipt.items.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...receipt.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.formattedAmount,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 6),
                          Divider(
                            color: Colors.grey[300],
                            height: 8,
                            thickness: 1,
                          ),
                          const SizedBox(height: 4),
                          // Total row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                receipt.formattedAmount,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    // Category and date row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: receipt.category.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            receipt.category.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: receipt.category.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          receipt.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bare list layout - Ruled ledger lines, table-like appearance
class BareListReceiptList extends StatelessWidget {
  final List<Receipt> receipts;
  final Function(int) onReceiptTap;

  const BareListReceiptList({
    super.key,
    required this.receipts,
    required this.onReceiptTap,
  });

  @override
  Widget build(BuildContext context) {
    if (receipts.isEmpty) {
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

    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: receipts.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey[300],
          height: 1,
          thickness: 1,
        ),
        itemBuilder: (context, index) {
          final receipt = receipts[index];
          return InkWell(
            onTap: () => onReceiptTap(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Store name (left-aligned, wider)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.merchantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          receipt.category.displayName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount (center)
                  Expanded(
                    child: Text(
                      receipt.formattedAmount,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date (right-aligned)
                  Expanded(
                    child: Text(
                      receipt.formattedDate,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
