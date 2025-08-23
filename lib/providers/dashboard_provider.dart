import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';
import 'package:aplikasi_kasir_seafood/services/expense_service.dart';

class DashboardProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final ExpenseService _expenseService = ExpenseService();

  double _totalRevenue = 0.0;
  double _totalExpenses = 0.0;
  int _totalSales = 0;

  double get totalRevenue => _totalRevenue;
  double get totalExpenses => _totalExpenses;
  int get totalSales => _totalSales;

  // Metode untuk memuat semua data dashboard
  Future<void> loadDashboardData() async {
    await _loadTotalRevenue();
    await _loadTotalExpenses();
    await _loadTotalSales();
    // Beri tahu widget yang 'mendengarkan' bahwa data telah berubah
    notifyListeners();
  }

  // Metode untuk memuat total pendapatan dari database
  Future<void> _loadTotalRevenue() async {
    final orders = await _orderService.getOrders();
    double sum = 0.0;
    for (var order in orders) {
      if (order.totalAmount != null) {
        sum += order.totalAmount!;
      }
    }
    _totalRevenue = sum;
  }

  // Metode untuk memuat total pengeluaran dari database
  Future<void> _loadTotalExpenses() async {
    final expenses = await _expenseService.getExpenses();
    double sum = 0.0;
    for (var expense in expenses) {
      sum += expense.amount;
    }
    _totalExpenses = sum;
  }

  // Metode untuk memuat total penjualan (jumlah order) dari database
  Future<void> _loadTotalSales() async {
    final orders = await _orderService.getOrders();
    _totalSales = orders.length;
  }
}
