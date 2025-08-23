import 'package:aplikasi_kasir_seafood/models/setting.dart';
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class SettingService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk mendapatkan data pengaturan (hanya satu baris)
  Future<Setting?> getSettings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('settings');
    if (maps.isNotEmpty) {
      return Setting.fromMap(maps.first);
    }
    return null;
  }

  // Metode untuk menyimpan atau memperbarui data pengaturan
  Future<void> saveSettings(Setting settings) async {
    final db = await _dbHelper.database;
    final existingSettings = await getSettings();
    if (existingSettings == null) {
      // Jika belum ada, tambahkan (insert)
      await db.insert('settings', settings.toMap());
    } else {
      // Jika sudah ada, perbarui (update)
      await db.update(
        'settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [existingSettings.id],
      );
    }
  }
}
