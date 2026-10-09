// The five main expense categories from the project requirements.
enum ExpenseCategory {
  food('Food'),
  transportation('Transportation'),
  shopping('Shopping'),
  bills('Bills'),
  entertainment('Entertainment');

  const ExpenseCategory(this.label);

  // The text we show to the user.
  final String label;
}

// One expense record.
class Expense {
  final int? id; // null until the database assigns one
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note; // optional
  final String? receiptPath; // optional, photo path for scanned receipts
  final bool isArchived; // false = active, true = archived (soft-deleted)

  const Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.receiptPath,
    this.isArchived = false,
  });

  // Converts an Expense into a Map. We use this when saving to SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category.name, // e.g. "food"
      'date': date.toIso8601String(), // stored as text
      'note': note,
      'receiptPath': receiptPath,
      'is_archived': isArchived ? 1 : 0, // SQLite has no boolean type
    };
  }

  // Converts a Map (a database row) back into an Expense.
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: ExpenseCategory.values.byName(map['category'] as String),
      date: DateTime.parse(map['date'] as String),
      note: map['note'] as String?,
      receiptPath: map['receiptPath'] as String?,
      isArchived: (map['is_archived'] as int? ?? 0) == 1,
    );
  }
}
