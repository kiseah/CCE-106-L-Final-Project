import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/models/expense.dart';

void main() {
  test('Expense survives a toMap -> fromMap round trip', () {
    final original = Expense(
      id: 1,
      title: 'Lunch',
      amount: 150.50,
      category: ExpenseCategory.food,
      date: DateTime(2026, 10, 5),
      note: 'With classmates',
    );

    final copy = Expense.fromMap(original.toMap());

    expect(copy.id, 1);
    expect(copy.title, 'Lunch');
    expect(copy.amount, 150.50);
    expect(copy.category, ExpenseCategory.food);
    expect(copy.date, DateTime(2026, 10, 5));
    expect(copy.note, 'With classmates');
    expect(copy.receiptPath, isNull);
    expect(copy.isArchived, false);
  });

  test('Archived flag is stored as 1 and read back as true', () {
    final archived = Expense(
      id: 2,
      title: 'Old bill',
      amount: 500,
      category: ExpenseCategory.bills,
      date: DateTime(2026, 9, 1),
      isArchived: true,
    );

    expect(archived.toMap()['is_archived'], 1);
    expect(Expense.fromMap(archived.toMap()).isArchived, true);
  });

  test('Category labels are correct', () {
    expect(ExpenseCategory.values.length, 5);
    expect(ExpenseCategory.transportation.label, 'Transportation');
  });
}
