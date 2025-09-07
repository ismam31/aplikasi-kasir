import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model;
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<model.Category> _categories = [];
  bool _isLoading = false;

  List<model.Category> get categories => _categories;
  bool get isLoading => _isLoading;

  CategoryProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'categories',
        orderBy: 'orderPosition ASC',
      );
      _categories = maps.map((map) => model.Category.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    try {
      final db = await _dbHelper.database;
      final newCategory = model.Category(
        name: name,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        orderPosition: _categories.length,
      );
      await db.insert('categories', newCategory.toMap());
    } catch (e) {
      debugPrint('Error adding category: $e');
    }
    await loadCategories();
  }

  Future<void> updateCategory(model.Category category) async {
    try {
      final db = await _dbHelper.database;
      category.updatedAt = DateTime.now().toIso8601String();
      await db.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
    } catch (e) {
      debugPrint('Error updating category: $e');
    }
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error deleting category: $e');
    }
    await loadCategories();
  }

  Future<void> updateOrder(List<model.Category> reorderedCategories) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (int i = 0; i < reorderedCategories.length; i++) {
      final category = reorderedCategories[i];
      batch.update(
        'categories',
        {'orderPosition': i, 'updatedAt': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [category.id],
      );
    }

    try {
      await batch.commit();
      _categories = reorderedCategories;
      notifyListeners();
      debugPrint('Kategori berhasil diurutkan.');
    } catch (e) {
      debugPrint('Gagal memperbarui urutan kategori: $e');
    }
  }
}
