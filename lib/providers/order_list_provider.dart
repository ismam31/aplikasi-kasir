import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/services/order_service.dart';

class OrderListProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<model_order.Order> _activeOrders = [];
  List<model_order.Order> _orderHistory = [];
  bool _isLoading = false;

  List<model_order.Order> get activeOrders => _activeOrders;
  List<model_order.Order> get orderHistory => _orderHistory;
  bool get isLoading => _isLoading;

  OrderListProvider() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    final allOrders = await _orderService.getOrders();
    _activeOrders = allOrders.where((order) => order.orderStatus == 'Diproses').toList();
    _orderHistory = allOrders.where((order) => order.orderStatus == 'Selesai').toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateOrderStatus(int id, String status) async {
    await _orderService.updateOrderStatus(id, status);
    await loadOrders(); // Muat ulang data setelah perubahan
  }

  Future<List<model_order_item.OrderItem>> getOrderItems(int orderId) async {
    return await _orderService.getOrderItems(orderId);
  }
}
