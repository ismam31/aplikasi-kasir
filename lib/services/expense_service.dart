import 'package:aplikasi_kasir_seafood/models/expense.dart';
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class ExpenseService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk menambahkan data pengeluaran baru
  Future<int> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert('expenses', expense.toMap());
  }

  // Metode untuk mendapatkan semua data pengeluaran
  Future<List<Expense>> getExpenses() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('expenses');
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Metode untuk memperbarui data pengeluaran
  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Metode untuk menghapus data pengeluaran
  Future<int> deleteExpense(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
