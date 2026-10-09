import 'package:flutter/material.dart';

import '../models/expense.dart';

// Gives each category its own icon and color, so every screen looks consistent.
extension ExpenseCategoryStyle on ExpenseCategory {
  IconData get icon {
    return switch (this) {
      ExpenseCategory.food => Icons.restaurant,
      ExpenseCategory.transportation => Icons.directions_bus,
      ExpenseCategory.shopping => Icons.shopping_bag,
      ExpenseCategory.bills => Icons.receipt_long,
      ExpenseCategory.entertainment => Icons.movie,
    };
  }

  Color get color {
    return switch (this) {
      ExpenseCategory.food => Colors.orange.shade700,
      ExpenseCategory.transportation => Colors.blue.shade600,
      ExpenseCategory.shopping => Colors.purple.shade500,
      ExpenseCategory.bills => Colors.red.shade600,
      ExpenseCategory.entertainment => Colors.pink.shade400,
    };
  }
}
