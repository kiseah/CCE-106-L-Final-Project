import 'dart:io';

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import 'manual_expense_form_screen.dart';
import '../widgets/category_style.dart';

// Shows all the details of one expense. Can edit or archive it.
class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late Expense _expense;
  bool _changed = false; // true if the expense was edited on this screen

  @override
  void initState() {
    super.initState();
    _expense = widget.expense;
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // Opens the form in edit mode and waits for the updated expense.
  Future<void> _edit() async {
    final updated = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => ManualExpenseFormScreen(expense: _expense),
      ),
    );

    if (updated != null) {
      setState(() {
        _expense = updated;
        _changed = true;
      });
    }
  }

  // Asks for confirmation, archives the expense, then goes back.
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: const Text(
          'It will be moved to the Archive. You can restore it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await DatabaseHelper.instance.archiveExpense(_expense.id!);

    // The screen may have closed while we waited, so check first.
    if (!mounted) return;

    // Returning true tells the History screen to refresh its list.
    Navigator.pop(context, true);
  }

  // Returns the receipt file if the expense has one and it still exists.
  File? _receiptFile() {
    final path = _expense.receiptPath;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  // Opens the receipt full screen. InteractiveViewer allows pinch-to-zoom.
  void _openFullReceipt(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Receipt')),
          body: Center(child: InteractiveViewer(child: Image.file(file))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasNote = _expense.note != null && _expense.note!.isNotEmpty;
    final receipt = _receiptFile();
    final colors = Theme.of(context).colorScheme;
    final categoryColor = _expense.category.color;

    // PopScope makes the back arrow also report an edit to the History screen.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense Detail'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _edit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Header: category icon, amount, and title
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: categoryColor.withValues(alpha: 0.15),
                      child: Icon(
                        _expense.category.icon,
                        size: 30,
                        color: categoryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₱${_expense.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _expense.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Details
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: _expense.category.icon,
                      label: 'Category',
                      value: _expense.category.label,
                    ),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDate(_expense.date),
                    ),
                    _DetailRow(
                      icon: Icons.notes,
                      label: 'Note',
                      value: hasNote ? _expense.note! : 'None',
                    ),
                  ],
                ),
              ),
            ),

            // Receipt photo (only if the expense has one)
            if (receipt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Receipt',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _openFullReceipt(receipt),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    receipt,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tap the photo to view it full screen',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// One detail: a small icon, a label on top, and its value below.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
