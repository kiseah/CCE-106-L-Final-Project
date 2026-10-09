// The fields we try to find in a receipt's text. Any of them can be null
// if the parser could not find it.
class ParsedReceipt {
  final String? title;
  final double? amount;
  final DateTime? date;

  const ParsedReceipt({this.title, this.amount, this.date});
}

// Turns raw OCR text into a ParsedReceipt using simple rules.
class ReceiptParser {
  static ParsedReceipt parse(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ParsedReceipt(
      title: _findTitle(lines),
      amount: _findAmount(lines),
      date: _findDate(text),
    );
  }

  // ---------- Title ----------

  // Store names are usually at the top: take the first line (within the
  // first 5) that is mostly letters.
  static String? _findTitle(List<String> lines) {
    for (final line in lines.take(5)) {
      final letters = RegExp(r'[A-Za-z]').allMatches(line).length;
      if (letters >= 3 && letters >= line.length / 2) return line;
    }
    return null;
  }

  // ---------- Amount ----------

  // Matches money like 85.00, 1250.75 or 1,250.75.
  static final _moneyRegex = RegExp(r'\d{1,3}(?:,\d{3})+\.\d{2}|\d+\.\d{2}');

  static double? _parseMoney(String s) =>
      double.tryParse(s.replaceAll(',', ''));

  static double? _findAmount(List<String> lines) {
    // 1. Look for a "total" line (ignoring "subtotal"). Use the last one.
    double? fromTotalLine;
    for (var i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      final isTotalLine =
          (lower.contains('total') && !lower.contains('sub')) ||
          lower.contains('amount due');
      if (!isTotalLine) continue;

      var matches = _moneyRegex.allMatches(lines[i]).toList();
      // Sometimes the number is on the next line.
      if (matches.isEmpty && i + 1 < lines.length) {
        matches = _moneyRegex.allMatches(lines[i + 1]).toList();
      }
      if (matches.isNotEmpty) {
        fromTotalLine = _parseMoney(matches.last.group(0)!);
      }
    }
    if (fromTotalLine != null) return fromTotalLine;

    // 2. No total line found: fall back to the largest amount in the text.
    double? largest;
    for (final m in _moneyRegex.allMatches(lines.join('\n'))) {
      final value = _parseMoney(m.group(0)!);
      if (value != null && (largest == null || value > largest)) {
        largest = value;
      }
    }
    return largest;
  }

  // ---------- Date ----------

  static const _monthNames = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  static const _monthPattern =
      'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec';

  static DateTime? _findDate(String text) {
    final now = DateTime.now();

    // The form only allows dates from 2020 up to today, so we do the same.
    bool isAcceptable(DateTime? d) =>
        d != null && d.year >= 2020 && !d.isAfter(now);

    // Format 1: 2026-10-05 or 2026/10/05
    final yearFirst = RegExp(r'\b(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})\b');
    for (final m in yearFirst.allMatches(text)) {
      final d = _makeDate(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      if (isAcceptable(d)) return d;
    }

    // Format 2: 10/05/2026 or 10-05-26 (month first, as in the Philippines).
    final monthFirst = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{2,4})\b');
    for (final m in monthFirst.allMatches(text)) {
      var month = int.parse(m[1]!);
      var day = int.parse(m[2]!);
      var year = int.parse(m[3]!);
      if (year < 100) year += 2000;
      if (month > 12) {
        // Must be day/month/year instead, so swap.
        final temp = month;
        month = day;
        day = temp;
      }
      final d = _makeDate(year, month, day);
      if (isAcceptable(d)) return d;
    }

    // Format 3: Oct 5, 2026
    final nameFirst = RegExp(
      r'\b(' + _monthPattern + r')[a-z]*\.?\s+(\d{1,2}),?\s+(\d{4})\b',
      caseSensitive: false,
    );
    for (final m in nameFirst.allMatches(text)) {
      final d = _makeDate(
        int.parse(m[3]!),
        _monthNumber(m[1]!),
        int.parse(m[2]!),
      );
      if (isAcceptable(d)) return d;
    }

    // Format 4: 5 Oct 2026
    final dayFirst = RegExp(
      r'\b(\d{1,2})\s+(' + _monthPattern + r')[a-z]*\.?,?\s+(\d{4})\b',
      caseSensitive: false,
    );
    for (final m in dayFirst.allMatches(text)) {
      final d = _makeDate(
        int.parse(m[3]!),
        _monthNumber(m[2]!),
        int.parse(m[1]!),
      );
      if (isAcceptable(d)) return d;
    }

    return null;
  }

  static int _monthNumber(String name) {
    return _monthNames.indexOf(name.substring(0, 3).toLowerCase()) + 1;
  }

  // Builds a date, or returns null if it is not a real calendar date
  // (for example February 31).
  static DateTime? _makeDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final d = DateTime(year, month, day);
    if (d.month != month || d.day != day) return null;
    return d;
  }
}
