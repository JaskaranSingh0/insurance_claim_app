import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/claim.dart';

class BillDialog extends StatefulWidget {
  final Bill? bill; // null for new, existing for edit
  final Function(Bill) onSave;

  const BillDialog({super.key, this.bill, required this.onSave});

  @override
  State<BillDialog> createState() => _BillDialogState();
}

class _BillDialogState extends State<BillDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  String _selectedCategory = 'General';

  final List<String> _categories = [
    'General',
    'Room',
    'Surgery',
    'Medication',
    'Lab',
    'Consultation',
    'Medical Supplies',
    'Diagnostic',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.bill?.description ?? '',
    );
    _amountController = TextEditingController(
      text: widget.bill != null ? widget.bill!.amount.toStringAsFixed(0) : '',
    );
    _selectedCategory = widget.bill?.category ?? 'General';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.bill != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Bill' : 'Add Bill'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Room charges, Lab tests',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: 'Enter amount',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final amount = double.tryParse(val);
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategory = val ?? 'General');
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveBill,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveBill() {
    if (!_formKey.currentState!.validate()) return;

    final bill = widget.bill != null
        ? widget.bill!.copyWith(
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text),
            category: _selectedCategory,
          )
        : Bill(
            description: _descriptionController.text.trim(),
            amount: double.parse(_amountController.text),
            category: _selectedCategory,
          );

    widget.onSave(bill);
    Navigator.pop(context);
  }
}
