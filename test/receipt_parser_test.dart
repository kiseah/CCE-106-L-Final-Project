import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_tracker/services/receipt_parser.dart';

void main() {
  test('Parses a typical receipt', () {
    const text = '''
SM SUPERMARKET
Mandaluyong City
Date: 10/05/2026
Milk 85.00
Bread 45.50
Subtotal 130.50
VAT 12% 13.97
TOTAL 130.50
Cash 200.00
''';

    final result = ReceiptParser.parse(text);

    expect(result.title, 'SM SUPERMARKET');
    expect(result.amount, 130.50);
    expect(result.date, DateTime(2026, 10, 5));
  });

  test('Ignores subtotal and reads thousands separators', () {
    final result = ReceiptParser.parse('Subtotal 100.00\nTotal: 1,250.75');
    expect(result.amount, 1250.75);
  });

  test('Uses the largest amount when there is no total line', () {
    final result = ReceiptParser.parse('CAFE\nCoffee 120.00\nCake 150.00');
    expect(result.amount, 150.00);
  });

  test('Title skips lines that are mostly numbers', () {
    final result = ReceiptParser.parse('12345\nJollibee\nTotal 99.00');
    expect(result.title, 'Jollibee');
  });

  test('Parses different date formats', () {
    expect(ReceiptParser.parse('2026-09-15').date, DateTime(2026, 9, 15));
    expect(ReceiptParser.parse('Sep 15, 2026').date, DateTime(2026, 9, 15));
    expect(ReceiptParser.parse('15 Sep 2026').date, DateTime(2026, 9, 15));
    expect(ReceiptParser.parse('15/09/2026').date, DateTime(2026, 9, 15));
  });

  test('Rejects future dates and impossible dates', () {
    expect(ReceiptParser.parse('12/31/2999').date, isNull);
    expect(ReceiptParser.parse('2026-02-31').date, isNull);
  });

  test('Empty text gives all nulls', () {
    final result = ReceiptParser.parse('');
    expect(result.title, isNull);
    expect(result.amount, isNull);
    expect(result.date, isNull);
  });
}
