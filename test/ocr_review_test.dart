import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/screens/ocr_review_screen.dart';
import 'package:personal_expense_tracker/services/receipt_parser.dart';

void main() {
  testWidgets('Review screen is pre-filled with the OCR results', (
    WidgetTester tester,
  ) async {
    final parsed = ParsedReceipt(
      title: 'SM SUPERMARKET',
      amount: 130.5,
      date: DateTime(2026, 10, 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: OcrReviewScreen(image: File('fake.jpg'), parsed: parsed),
      ),
    );

    expect(find.text('Review Receipt'), findsOneWidget);
    expect(find.text('SM SUPERMARKET'), findsOneWidget);
    expect(find.text('130.50'), findsOneWidget);
    expect(find.text('2026-10-05'), findsOneWidget);
  });
}
