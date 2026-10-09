import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../services/receipt_parser.dart';

// Shows what OCR detected so the user can fix it before saving.
class OcrReviewScreen extends StatefulWidget {
  final File image;
  final ParsedReceipt parsed;

  const OcrReviewScreen({super.key, required this.image, required this.parsed});

  @override
  State<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends State<OcrReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  final _noteController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.food;
  late DateTime _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final parsed = widget.parsed;
    // Pre-fill with what OCR found. Missing values stay empty (or today).
    _titleController = TextEditingController(text: parsed.title ?? '');
    _amountController = TextEditingController(
      text: parsed.amount == null ? '' : parsed.amount!.toStringAsFixed(2),
    );
    _date = parsed.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

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

  // Copies the photo from the temporary cache into permanent app storage.
  Future<String> _saveReceiptImage() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(p.join(docsDir.path, 'receipts'));
    await receiptsDir.create(recursive: true);

    final fileName =
        'receipt_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(widget.image.path)}';
    final saved = await widget.image.copy(p.join(receiptsDir.path, fileName));
    return saved.path;
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final receiptPath = await _saveReceiptImage();
      final note = _noteController.text.trim();

      final expense = Expense(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        category: _category,
        date: _date,
        note: note.isEmpty ? null : note,
        receiptPath: receiptPath,
      );

      final id = await DatabaseHelper.instance.insertExpense(expense);
      debugPrint('Saved receipt expense with id: $id');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Expense saved')));

      // Back to the Dashboard: review -> capture -> Add Expense -> Dashboard.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = widget.parsed;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Receipt')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                widget.image,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(height: 160),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Check the details below. OCR can make mistakes.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',

                helperText: parsed.title == null ? 'Not detected' : null,
              ),
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
              decoration: InputDecoration(
                labelText: 'Amount',

                helperText: parsed.amount == null ? 'Not detected' : null,
              ),
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
              title: Text(_formatDate(_date)),
              subtitle: parsed.date == null
                  ? const Text('Not detected, using today')
                  : null,
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
              onPressed: _isSaving ? null : _onSavePressed,
              child: Text(_isSaving ? 'Saving...' : 'Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
