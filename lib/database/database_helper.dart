import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

// Handles opening the database and reading/writing expenses.
class DatabaseHelper {
  // Singleton: the whole app shares one DatabaseHelper.
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _tableName = 'expenses';
  Database? _database;

  // Opens the database the first time, then reuses it.
  Future<Database> get database async {
    _database ??= await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final dbPath = join(await getDatabasesPath(), 'expense_tracker.db');

    return openDatabase(
      dbPath,
      version: 2,
      onCreate: (db, version) async {
        // Runs only when the database file is first created (fresh install).
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            date TEXT NOT NULL,
            note TEXT,
            receiptPath TEXT,
            is_archived INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Runs when an existing database has an older version number.
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_tableName '
            'ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  // Saves a new expense and returns its new id.
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert(_tableName, expense.toMap());
  }

  // Updates an existing expense. Keeps its id and archive status.
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Returns only ACTIVE expenses, newest first.
  Future<List<Expense>> getActiveExpenses() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'is_archived = ?',
      whereArgs: [0],
      orderBy: 'date DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  // Returns the total spent per category for one month (ACTIVE expenses only).
  // Example result: {ExpenseCategory.food: 450.0, ExpenseCategory.bills: 1200.0}
  Future<Map<ExpenseCategory, double>> getCategoryTotalsForMonth(
    DateTime month,
  ) async {
    final db = await database;

    // Dates are stored as ISO text, so a simple text range works.
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final rows = await db.rawQuery(
      '''
      SELECT category, SUM(amount) AS total
      FROM $_tableName
      WHERE is_archived = 0 AND date >= ? AND date < ?
      GROUP BY category
      ''',
      [start.toIso8601String(), end.toIso8601String()],
    );

    final totals = <ExpenseCategory, double>{};
    for (final row in rows) {
      final category = ExpenseCategory.values.byName(row['category'] as String);
      totals[category] = (row['total'] as num).toDouble();
    }
    return totals;
  }

  // Returns 7 totals for the week starting at [weekStart] (a Monday).
  // Index 0 = Monday ... index 6 = Sunday. ACTIVE expenses only.
  Future<List<double>> getDailyTotalsForWeek(DateTime weekStart) async {
    final db = await database;

    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = DateTime(weekStart.year, weekStart.month, weekStart.day + 7);

    final rows = await db.query(
      _tableName,
      columns: ['amount', 'date'],
      where: 'is_archived = ? AND date >= ? AND date < ?',
      whereArgs: [0, start.toIso8601String(), end.toIso8601String()],
    );

    final totals = List<double>.filled(7, 0);
    for (final row in rows) {
      final date = DateTime.parse(row['date'] as String);
      totals[date.weekday - 1] += (row['amount'] as num).toDouble();
    }
    return totals;
  }

  // Soft delete: marks the expense as archived. The row stays in the database.
  Future<int> archiveExpense(int id) async {
    final db = await database;
    return db.update(
      _tableName,
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Returns only ARCHIVED expenses, newest first.
  Future<List<Expense>> getArchivedExpenses() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'is_archived = ?',
      whereArgs: [1],
      orderBy: 'date DESC',
    );
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  // Brings an archived expense back to the active records.
  Future<int> restoreExpense(int id) async {
    final db = await database;
    return db.update(
      _tableName,
      {'is_archived': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Permanently removes the row. Only the Archive screen uses this.
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }
}
