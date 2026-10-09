import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/models/expense.dart';
import 'package:personal_expense_tracker/screens/expense_detail_screen.dart';

void main() {
  testWidgets('Detail screen shows the expense fields', (
    WidgetTester tester,
  ) async {
    final expense = Expense(
      id: 1,
      title: 'Lunch',
      amount: 150.5,
      category: ExpenseCategory.food,
      date: DateTime(2026, 10, 5),
      note: 'With classmates',
    );

    await tester.pumpWidget(
      MaterialApp(home: ExpenseDetailScreen(expense: expense)),
    );

    expect(find.text('Expense Detail'), findsOneWidget);
    expect(find.text('₱150.50'), findsOneWidget);
    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('2026-10-05'), findsOneWidget);
    expect(find.text('With classmates'), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsOneWidget);
  });
}
