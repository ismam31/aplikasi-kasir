import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/services/database_helper.dart';

class OrderService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Metode untuk menambahkan pesanan dan item-itemnya secara bersamaan
  Future<int> insertOrder(
    model_order.Order order,
    List<model_order_item.OrderItem> items,
  ) async {
    final db = await _dbHelper.database;
    int orderId = 0;

    await db.transaction((txn) async {
      orderId = await txn.insert('orders', order.toMap());

      // update ID biar bisa dipakai di object order
      order.id = orderId;

      for (var item in items) {
        item.orderId = orderId;
        await txn.insert('order_items', {
          'order_id': item.orderId,
          'menu_id': item.menuId,
          'menu_name': item.menuName,
          'quantity': item.quantity,
          'price': item.price,
        });
      }
    });

    return orderId;
  }

  // Metode untuk memperbarui pesanan yang sudah ada
  Future<void> updateOrder(
    model_order.Order order,
    List<model_order_item.OrderItem> items,
  ) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Update order
      await txn.update(
        'orders',
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );

      // Hapus item lama
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );

      // Insert item baru, termasuk menu_name
      for (var item in items) {
        item.orderId = order.id!;
        await txn.insert('order_items', {
          'order_id': item.orderId,
          'menu_id': item.menuId,
          'menu_name': item.menuName,
          'quantity': item.quantity,
          'price': item.price,
        });
      }
    });
  }

  // Metode untuk mendapatkan semua pesanan atau pesanan berdasarkan tanggal
  Future<List<model_order.Order>> getOrders([DateTime? date]) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (date != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      maps = await db.query(
        'orders',
        where: "strftime('%Y-%m-%d', order_time) = ?",
        whereArgs: [formattedDate],
        orderBy: 'order_time DESC',
      );
    } else {
      maps = await db.query(
        'orders',
        orderBy: 'order_time DESC',
      );
    }

    return List.generate(maps.length, (i) {
      final orderMap = Map<String, dynamic>.from(maps[i]);
      // Pastikan total_amount diubah ke double
      if (orderMap['total_amount'] is int) {
        orderMap['total_amount'] = (orderMap['total_amount'] as int).toDouble();
      }
      return model_order.Order.fromMap(orderMap);
    });
  }

  // Metode untuk mendapatkan pesanan berdasarkan ID
  Future<model_order.Order?> getOrderById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final orderMap = Map<String, dynamic>.from(maps.first);
      // Pastikan total_amount diubah ke double
      if (orderMap['total_amount'] is int) {
        orderMap['total_amount'] = (orderMap['total_amount'] as int).toDouble();
      }
      return model_order.Order.fromMap(orderMap);
    }
    return null;
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

  // Metode baru untuk mengambil data pelanggan berdasarkan ID pelanggan
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
      await txn.delete('orders', where: 'id = ?', whereArgs: [orderId]);
    });
  }
}
