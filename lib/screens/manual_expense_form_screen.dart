import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';

// Form for entering an expense by hand.
// If [expense] is given, the form edits it. Otherwise it adds a new one.
class ManualExpenseFormScreen extends StatefulWidget {
  final Expense? expense;

  const ManualExpenseFormScreen({super.key, this.expense});

  @override
  State<ManualExpenseFormScreen> createState() =>
      _ManualExpenseFormScreenState();
}

class _ManualExpenseFormScreenState extends State<ManualExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late ExpenseCategory _category;
  late DateTime _date;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    // Pre-fill the fields when editing; use defaults when adding.
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(2),
    );
    _noteController = TextEditingController(text: e?.note ?? '');
    _category = e?.category ?? ExpenseCategory.food;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    // Free the controllers when the screen closes.
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Opens the calendar popup so the user can pick a date.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _onSavePressed() async {
    // validate() runs every field's validator and returns true if all pass.
    if (!_formKey.currentState!.validate()) return;

    final note = _noteController.text.trim();
    final old = widget.expense;

    final expense = Expense(
      id: old?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      date: _date,
      note: note.isEmpty ? null : note,
      receiptPath: old?.receiptPath,
      isArchived: old?.isArchived ?? false,
    );

    if (_isEditing) {
      await DatabaseHelper.instance.updateExpense(expense);
    } else {
      final id = await DatabaseHelper.instance.insertExpense(expense);
      debugPrint('Saved expense with id: $id');
    }

    // The screen may have been closed while we waited, so check first.
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isEditing ? 'Expense updated' : 'Expense saved')),
    );

    if (_isEditing) {
      // Return the updated expense to the Detail screen.
      Navigator.pop(context, expense);
    } else {
      // Go back to the Dashboard: form -> Add Expense -> Dashboard.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Manual Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: ExpenseCategory.values
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              tileColor: Theme.of(context).colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.4),
              leading: const Icon(Icons.calendar_today),
              title: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-'
                '${_date.day.toString().padLeft(2, '0')}',
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _onSavePressed,
              child: Text(_isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
