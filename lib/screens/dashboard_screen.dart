import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import '../widgets/category_style.dart';
import 'add_expense_screen.dart';
import 'archive_screen.dart';
import 'expense_history_screen.dart';

// Everything the Dashboard needs, loaded together.
class _DashboardData {
  final Map<ExpenseCategory, double> totals; // selected month, per category
  final List<double> week; // this week, Monday..Sunday

  const _DashboardData(this.totals, this.week);
}

// The first screen users see: a month's breakdown and this week's spending.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedMonth; // always the 1st day of the month
  late Future<_DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _dataFuture = _load();
  }

  // Monday of the current week.
  DateTime get _weekStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  Future<_DashboardData> _load() async {
    final totals = await DatabaseHelper.instance.getCategoryTotalsForMonth(
      _selectedMonth,
    );
    final week = await DatabaseHelper.instance.getDailyTotalsForWeek(
      _weekStart,
    );
    return _DashboardData(totals, week);
  }

  // Reloads the numbers for the selected month and the current week.
  void _reload() {
    setState(() {
      _dataFuture = _load();
    });
  }

  // Moves to another month. Use -1 for previous and 1 for next.
  void _changeMonth(int offset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
      1,
    );
    _reload();
  }

  // Expenses can't be in the future, so there is nothing after this month.
  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year && _selectedMonth.month == now.month;
  }

  // The expense form only allows dates from 2020, so stop at January 2020.
  bool get _isEarliestMonth =>
      _selectedMonth.year == 2020 && _selectedMonth.month == 1;

  // Opens a screen, and refreshes the Dashboard when the user comes back.
  Future<void> _open(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (mounted) _reload();
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final monthLabel =
        '${_months[_selectedMonth.month - 1]} '
        '${_selectedMonth.year}';
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Expense History',
            onPressed: () => _open(const ExpenseHistoryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Archive',
            onPressed: () => _open(const ArchiveScreen()),
          ),
        ],
      ),
      body: FutureBuilder<_DashboardData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final totals = data.totals;
          final grandTotal = totals.values.fold(0.0, (sum, v) => sum + v);

          final weekStart = _weekStart;
          final weekEnd = DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day + 6,
          );
          final weekLabel =
              '${_shortMonths[weekStart.month - 1]} ${weekStart.day} – '
              '${_shortMonths[weekEnd.month - 1]} ${weekEnd.day}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              // Month selector (a rounded pill with two arrows)
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous month',
                      onPressed: _isEarliestMonth
                          ? null
                          : () => _changeMonth(-1),
                    ),
                    Expanded(
                      child: Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next month',
                      onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Total card (filled with the main theme color)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total spent',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${grandTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: TextStyle(
                        color: colors.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Spending by Category: donut chart with legend
              _SectionCard(
                title: 'Spending by Category',
                subtitle: monthLabel,
                child: grandTotal == 0
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.savings_outlined,
                              size: 56,
                              color: colors.outline,
                            ),
                            const SizedBox(height: 12),
                            const Text('No expenses in this month'),
                          ],
                        ),
                      )
                    : _CategoryDonut(totals: totals, grandTotal: grandTotal),
              ),
              const SizedBox(height: 16),

              // This Week: bar chart, Monday to Sunday
              _SectionCard(
                title: 'This Week',
                subtitle: weekLabel,
                child: _WeekBarChart(
                  values: data.week,
                  todayIndex: DateTime.now().weekday - 1,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _open(const AddExpenseScreen()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// A card with a title, a small subtitle, and a chart inside.
class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ---------- Donut chart + legend ----------

class _CategoryDonut extends StatelessWidget {
  final Map<ExpenseCategory, double> totals;
  final double grandTotal;

  const _CategoryDonut({required this.totals, required this.grandTotal});

  @override
  Widget build(BuildContext context) {
    final categories = ExpenseCategory.values;

    return Column(
      children: [
        // The donut, with the total written in the middle.
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _DonutPainter(
                  values: [for (final c in categories) totals[c] ?? 0],
                  colors: [for (final c in categories) c.color],
                  trackColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    '₱${grandTotal.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Legend: one row per category.
        for (final category in categories)
          _LegendRow(
            category: category,
            amount: totals[category] ?? 0,
            percent: (totals[category] ?? 0) / grandTotal * 100,
          ),
      ],
    );
  }
}

// One legend line: colored dot, name, amount, and percentage.
class _LegendRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double percent;

  const _LegendRow({
    required this.category,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: category.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(category.label)),
          Text(
            '₱${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 52,
            child: Text(
              '${percent.toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// Draws the donut: a grey ring, with one colored arc per category on top.
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final Color trackColor;

  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 26.0;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Background ring
    paint.color = trackColor;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);

    final total = values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) return;

    // Start at the top (12 o'clock) and go clockwise.
    var startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;
      final sweep = values[i] / total * 2 * math.pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

// ---------- Weekly bar chart ----------

class _WeekBarChart extends StatelessWidget {
  final List<double> values; // Monday..Sunday
  final int todayIndex; // 0 = Monday ... 6 = Sunday

  const _WeekBarChart({required this.values, required this.todayIndex});

  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const double _maxBarHeight = 100;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxValue = values.fold(0.0, math.max);
    final weekTotal = values.fold(0.0, (sum, v) => sum + v);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₱${weekTotal.toStringAsFixed(2)} this week',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Amount above the bar (only if there is spending)
                      Text(
                        values[i] > 0 ? values[i].toStringAsFixed(0) : '',
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      // The bar. Empty days get a thin stub.
                      Container(
                        height: maxValue == 0
                            ? 4
                            : 4 + (values[i] / maxValue) * (_maxBarHeight - 4),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: i == todayIndex
                              ? colors.primary
                              : colors.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _letters[i],
                        style: TextStyle(
                          fontWeight: i == todayIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
