import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class OrderService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk menambahkan pesanan dan item-itemnya secara bersamaan
  Future<void> insertOrder(model_order.Order order, List<model_order_item.OrderItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      int orderId = await txn.insert('orders', order.toMap());
      for (var item in items) {
        item.orderId = orderId;
        await txn.insert('order_items', item.toMap());
      }
    });
  }

  // Metode untuk memperbarui pesanan yang sudah ada
  Future<void> updateOrder(model_order.Order order, List<model_order_item.OrderItem> items) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Perbarui data pesanan utama
      await txn.update(
        'orders',
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Hapus item pesanan lama
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // Tambahkan item pesanan baru
      for (var item in items) {
        item.orderId = order.id!;
        await txn.insert('order_items', item.toMap());
      }
    });
  }

  // Metode untuk mendapatkan semua pesanan
  Future<List<model_order.Order>> getOrders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'order_time DESC');
    return List.generate(maps.length, (i) {
      final orderMap = Map<String, dynamic>.from(maps[i]);
      // Pastikan total_amount diubah ke double
      if (orderMap['total_amount'] is int) {
        orderMap['total_amount'] = (orderMap['total_amount'] as int).toDouble();
      }
      return model_order.Order.fromMap(orderMap);
    });
  }

  // Metode untuk mendapatkan item pesanan berdasarkan ID pesanan
  Future<List<model_order_item.OrderItem>> getOrderItems(int orderId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return List.generate(maps.length, (i) {
      final itemMap = Map<String, dynamic>.from(maps[i]);
      // Pastikan price dan quantity diubah ke double jika perlu
      if (itemMap['price'] is int) {
        itemMap['price'] = (itemMap['price'] as int).toDouble();
      }
      if (itemMap['quantity'] is int) {
        itemMap['quantity'] = (itemMap['quantity'] as int).toDouble();
      }
      return model_order_item.OrderItem.fromMap(itemMap);
    });
  }

  // Metode untuk memperbarui status pesanan
  Future<int> updateOrderStatus(int id, String status) async {
    final db = await _dbHelper.database;
    return await db.update(
      'orders',
      {'order_status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Metode untuk menghapus pesanan dan semua itemnya
  Future<void> deleteOrder(int orderId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      await txn.delete(
        'orders',
        where: 'id = ?',
        whereArgs: [orderId],
      );
    });
  }
}
