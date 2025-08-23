import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<model_order_item.OrderItem> _cart = [];
  int? _editingOrderId;
  int? _editingCustomerId;

  List<model_order_item.OrderItem> get cart => _cart;
  int? get editingOrderId => _editingOrderId;
  int? get editingCustomerId => _editingCustomerId;

  double get totalAmount {
    double total = 0.0;
    for (var item in _cart) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // Metode untuk memuat pesanan ke keranjang untuk diedit
  Future<void> loadOrderToCart(int orderId) async {
    final orderItems = await _orderService.getOrderItems(orderId);
    final order = (await _orderService.getOrders()).firstWhere((o) => o.id == orderId);
    
    _cart = orderItems;
    _editingOrderId = orderId;
    _editingCustomerId = order.customerId;
    
    notifyListeners();
  }

  void addItemToCart({
    required model_menu.Menu menu,
    required double quantity,
  }) {
    final existingItemIndex = _cart.indexWhere((item) => item.menuId == menu.id);
    
    if (existingItemIndex != -1) {
      _cart[existingItemIndex].quantity += quantity;
    } else {
      final newItem = model_order_item.OrderItem(
        menuId: menu.id!,
        quantity: quantity,
        price: menu.priceSell,
        orderId: _editingOrderId ?? 0,
        menuName: menu.name,
      );
      _cart.add(newItem);
    }
    notifyListeners();
  }

  // Metode baru untuk mengubah kuantitas item
  void updateItemQuantity(int menuId, double newQuantity) {
    final itemIndex = _cart.indexWhere((item) => item.menuId == menuId);
    if (itemIndex != -1) {
      _cart[itemIndex].quantity = newQuantity;
      notifyListeners();
    }
  }

  // Metode untuk menghapus item dari keranjang
  void removeItemFromCart(int menuId) {
    _cart.removeWhere((item) => item.menuId == menuId);
    notifyListeners();
  }

  // Metode untuk membersihkan keranjang
  void clearCart() {
    _cart = [];
    _editingOrderId = null;
    _editingCustomerId = null;
    notifyListeners();
  }

  // Metode untuk menyimpan atau memperbarui pesanan ke database
  Future<void> saveOrder({
    required int? customerId,
    required String status,
    required String? paymentMethod,
  }) async {
    final newOrder = model_order.Order(
      id: _editingOrderId,
      customerId: customerId,
      orderStatus: status,
      paymentMethod: paymentMethod,
      orderTime: DateTime.now().toIso8601String(),
      totalAmount: totalAmount,
    );
    
    if (_editingOrderId != null) {
      await _orderService.updateOrder(newOrder, _cart);
    } else {
      await _orderService.insertOrder(newOrder, _cart);
    }
    clearCart();
  }
}
