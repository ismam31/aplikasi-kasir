import 'package:aplikasi_kasir_seafood/models/menu.dart';
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class MenuService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk menambahkan data menu baru
  Future<int> insertMenu(Menu menu) async {
    final db = await _dbHelper.database;
    return await db.insert('menu', menu.toMap());
  }

  // Metode untuk mendapatkan semua data menu
  Future<List<Menu>> getMenus() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('menu');
    return List.generate(maps.length, (i) {
      return Menu.fromMap(maps[i]);
    });
  }

  // Metode untuk memperbarui data menu
  Future<int> updateMenu(Menu menu) async {
    final db = await _dbHelper.database;
    return await db.update(
      'menu',
      menu.toMap(),
      where: 'id = ?',
      whereArgs: [menu.id],
    );
  }

  // Metode untuk menghapus data menu
  Future<int> deleteMenu(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'menu',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
