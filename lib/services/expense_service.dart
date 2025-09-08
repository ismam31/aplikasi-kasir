import 'package:aplikasi_kasir_seafood/models/expense.dart';
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';
import 'package:intl/intl.dart';

class ExpenseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Expense>> getExpenses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final String formattedStartDate = DateFormat(
      'yyyy-MM-dd',
    ).format(startDate);
    final String formattedEndDate = DateFormat('yyyy-MM-dd').format(endDate);

    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: "date BETWEEN ? AND ?",
      whereArgs: [formattedStartDate, formattedEndDate],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      final expenseMap = Map<String, dynamic>.from(maps[i]);
      if (expenseMap['amount'] is int) {
        expenseMap['amount'] = (expenseMap['amount'] as int).toDouble();
      }
      return Expense.fromMap(expenseMap);
    });
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.insert('expenses', expense.toMap());
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<void> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
