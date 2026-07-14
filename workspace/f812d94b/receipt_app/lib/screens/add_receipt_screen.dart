import 'package:flutter/material.dart';
import 'package:receipt_app/models/receipt.dart';
import 'package:intl/intl.dart';

class AddReceiptScreen extends StatefulWidget {
  final int? editIndex;
  final Receipt? existingReceipt;
  final String? imagePath;

  const AddReceiptScreen({
    super.key,
    this.editIndex,
    this.existingReceipt,
    this.imagePath,
  });

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;
  String? _imagePath;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editIndex != null && widget.existingReceipt != null;

    if (_isEditing && widget.existingReceipt != null) {
      final receipt = widget.existingReceipt!;
      _merchantController = TextEditingController(text: receipt.merchantName);
      _amountController =
          TextEditingController(text: receipt.amount.toStringAsFixed(2));
      _notesController = TextEditingController(text: receipt.notes ?? '');
      _selectedDate = receipt.date;
      _selectedCategory = receipt.category;
      _imagePath = receipt.imagePath;
    } else {
      _merchantController = TextEditingController();
      _amountController = TextEditingController();
      _notesController = TextEditingController();
      _selectedDate = DateTime.now();
      _selectedCategory = ExpenseCategory.other;
      _imagePath = widget.imagePath;
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveReceipt() {
    if (!_formKey.currentState!.validate()) return;

    final merchant = _merchantController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final notes = _notesController.text.trim();

    final receipt = Receipt(
      id: _isEditing && widget.existingReceipt != null
          ? widget.existingReceipt!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      merchantName: merchant,
      amount: amount,
      date: _selectedDate,
      category: _selectedCategory,
      notes: notes.isEmpty ? null : notes,
      imagePath: _imagePath,
    );

    Navigator.pop(context, {
      'saved': true,
      'receipt': receipt,
      'index': widget.editIndex,
    });
  }

  void _deleteReceipt() {
    Navigator.pop(context, {
      'deleted': true,
      'index': widget.editIndex,
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Receipt' : 'Add Receipt'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt image area
              GestureDetector(
                onTap: () {
                  // Photo picker would go here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo picker not yet implemented')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            _imagePath!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Merchant Name
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant Name',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a merchant name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\$ ',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                controller: TextEditingController(text: dateFormat.format(_selectedDate)),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(category.icon, size: 20, color: category.color),
                        const SizedBox(width: 12),
                        Text(category.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _saveReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Receipt',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),

              // Delete button (edit mode only)
              if (_isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _deleteReceipt,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Delete Receipt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
