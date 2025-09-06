import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class CustomerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk menambahkan data pelanggan baru
  Future<int> insertCustomer(model_customer.Customer customer) async {
    final db = await _dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<model_customer.Customer?> getCustomerById(int id) async {
  final db = await _dbHelper.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'customers',
    where: 'id = ?',
    whereArgs: [id],
  );

  if (maps.isNotEmpty) {
    return model_customer.Customer.fromMap(maps.first);
  }
  return null;
}
  // Future<model_customer.Customer?> getCustomer(int id) async {
  //   final db = await _dbHelper.database;
  //   final List<Map<String, dynamic>> maps = await db.query(
  //     'customers',
  //     where: 'id = ?',
  //     whereArgs: [id],
  //   );
  //   if (maps.isNotEmpty) {
  //     return model_customer.Customer.fromMap(maps.first);
  //   }
  //   return null;
  // }

  // Metode untuk mendapatkan semua data pelanggan
  Future<List<model_customer.Customer>> getCustomers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) {
      final customerMap = Map<String, dynamic>.from(maps[i]);
      // Pastikan guest_count diubah ke int jika perlu
      if (customerMap['guest_count'] is double) {
        customerMap['guest_count'] = (customerMap['guest_count'] as double)
            .toInt();
      }
      return model_customer.Customer.fromMap(customerMap);
    });
  }

  // Metode untuk memperbarui data pelanggan
  Future<int> updateCustomer(model_customer.Customer customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  // Metode untuk menghapus data pelanggan
  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}
