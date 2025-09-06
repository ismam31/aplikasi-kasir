import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/services/order_service.dart';

class OrderListProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<model_order.Order> _allOrders = [];
  bool _isLoading = false;

  List<model_order.Order> get allOrders => _allOrders;
  List<model_order.Order> get activeOrders => _allOrders.where((order) => order.orderStatus == 'Diproses').toList();
  List<model_order.Order> get orderHistory => _allOrders.where((order) => order.orderStatus == 'Selesai').toList();
  bool get isLoading => _isLoading;

  OrderListProvider() {
    loadOrders();
  }

  Future<void> loadOrders([DateTime? date]) async {
    _isLoading = true;
    notifyListeners();
    // Mengambil data pesanan dari layanan berdasarkan tanggal (jika disediakan)
    _allOrders = await _orderService.getOrders(date);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(int id, String status) async {
    await _orderService.updateOrderStatus(id, status);
    await loadOrders(); // Memuat ulang data setelah pembaruan status
  }

  Future<List<model_order_item.OrderItem>> getOrderItems(int orderId) async {
    return await _orderService.getOrderItems(orderId);
  }
}
