import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App opens on the Dashboard screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.archive), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Plus button opens the Add Expense screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExpenseTrackerApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Enter Manually'), findsOneWidget);
    expect(find.text('Scan Receipt'), findsOneWidget);
  });

  testWidgets('Enter Manually opens the form and validates empty input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExpenseTrackerApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enter Manually'));
    await tester.pumpAndSettle();

    expect(find.text('Manual Entry'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please enter a title'), findsOneWidget);
    expect(find.text('Enter an amount greater than 0'), findsOneWidget);
  });

  testWidgets('Scan Receipt opens the Receipt Capture screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExpenseTrackerApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan Receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Capture'), findsOneWidget);
    expect(find.text('No photo yet'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
  });
}
