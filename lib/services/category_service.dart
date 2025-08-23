import 'package:aplikasi_kasir_seafood/models/category.dart';
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class CategoryService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk menambahkan data kategori baru
  Future<int> insertCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  // Metode untuk mendapatkan semua data kategori
  Future<List<Category>> getCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) {
      return Category.fromMap(maps[i]);
    });
  }

  // Metode untuk memperbarui data kategori
  Future<int> updateCategory(Category category) async {
    final db = await _dbHelper.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Metode untuk menghapus data kategori
  Future<int> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
