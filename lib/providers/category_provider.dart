import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model;
import 'package:aplikasi_kasir_seafood/services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

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

    _categories = await _categoryService.getCategories();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _categoryService.insertCategory(model.Category(name: name));
    await loadCategories();
  }

  Future<void> updateCategory(model.Category category) async {
    await _categoryService.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _categoryService.deleteCategory(id);
    await loadCategories();
  }
}
