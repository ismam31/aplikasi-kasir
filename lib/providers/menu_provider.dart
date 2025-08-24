import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/services/category_service.dart';
import 'package:aplikasi_kasir_seafood/services/menu_service.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _menuService = MenuService();
  final CategoryService _categoryService = CategoryService();

  List<model_category.Category> _categories = [];
  List<model_menu.Menu> _menus = [];
  bool _isLoading = false;

  List<model_category.Category> get categories => _categories;
  List<model_menu.Menu> get menus => _menus;
  bool get isLoading => _isLoading;

  MenuProvider() {
    loadMenusAndCategories();
  }

  Future<void> updateMenuAvailability(int id, bool isAvailable) async {
    // Update di database / service
    await _menuService.updateMenuAvailability(id, isAvailable);

    // Update state lokal
    final index = _menus.indexWhere((menu) => menu.id == id);
    if (index != -1) {
      _menus[index].isAvailable = isAvailable;
      notifyListeners();
    }
  }

  // Metode untuk memuat data kategori dan menu
  Future<void> loadMenusAndCategories() async {
    _isLoading = true;
    notifyListeners();

    _categories = await _categoryService.getCategories();
    _menus = await _menuService.getMenus();
    
    _isLoading = false;
    notifyListeners();
  }

  // Metode untuk menambahkan menu baru
  Future<void> addMenu(model_menu.Menu menu) async {
    await _menuService.insertMenu(menu);
    await loadMenusAndCategories();
  }

  // Metode untuk memperbarui menu
  Future<void> updateMenu(model_menu.Menu menu) async {
    await _menuService.updateMenu(menu);
    await loadMenusAndCategories();
  }

  // Metode untuk menghapus menu
  Future<void> deleteMenu(int id) async {
    await _menuService.deleteMenu(id);
    await loadMenusAndCategories();
  }

  // Metode untuk mendapatkan nama kategori dari ID
  String getCategoryNameById(int? categoryId) {
    if (categoryId == null) return 'Tidak Ada Kategori';
    final category = _categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => model_category.Category(name: 'Tidak Ditemukan'),
    );
    return category.name!;
  }
}
