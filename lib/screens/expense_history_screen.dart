import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../widgets/category_style.dart';
import 'expense_detail_screen.dart';

// Shows all ACTIVE expenses, newest first.
class ExpenseHistoryScreen extends StatefulWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  State<ExpenseHistoryScreen> createState() => _ExpenseHistoryScreenState();
}

class _ExpenseHistoryScreenState extends State<ExpenseHistoryScreen> {
  late Future<List<Expense>> _expensesFuture;

  @override
  void initState() {
    super.initState();
    // Load the expenses once, when the screen opens.
    _expensesFuture = DatabaseHelper.instance.getActiveExpenses();
  }

  void _reload() {
    setState(() {
      _expensesFuture = DatabaseHelper.instance.getActiveExpenses();
    });
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Expense History')),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          // 1. Still loading
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Something went wrong
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 3. Loaded, but nothing saved yet
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: colors.outline),
                  const SizedBox(height: 12),
                  const Text('No expenses yet'),
                ],
              ),
            );
          }

          // 4. Show the list
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final color = expense.category.color;
              final hasReceipt =
                  expense.receiptPath != null &&
                  expense.receiptPath!.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(expense.category.icon, color: color),
                  ),
                  title: Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${expense.category.label} • '
                          '${_formatDate(expense.date)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasReceipt) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.receipt, size: 14, color: colors.outline),
                      ],
                    ],
                  ),
                  trailing: Text(
                    '₱${expense.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ExpenseDetailScreen(expense: expense),
                      ),
                    );
                    // If the detail screen reported a change, reload the list.
                    if (changed == true) _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
