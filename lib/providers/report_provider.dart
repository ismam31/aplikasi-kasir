import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';
import 'package:aplikasi_kasir_seafood/services/expense_service.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/expense.dart' as model_expense;

class ReportProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final ExpenseService _expenseService = ExpenseService();

  List<model_order.Order> _completedOrders = [];
  List<model_expense.Expense> _allExpenses = [];
  bool _isLoading = false;

  List<model_order.Order> get completedOrders => _completedOrders;
  List<model_expense.Expense> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;

  double get totalRevenue {
    return _completedOrders.fold(0.0, (sum, order) => sum + (order.totalAmount ?? 0.0));
  }

  double get totalExpenses {
    return _allExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get netProfit {
    return totalRevenue - totalExpenses;
  }

  ReportProvider() {
    loadReports();
  }

  Future<void> loadReports() async {
    _isLoading = true;
    notifyListeners();

    final allOrders = await _orderService.getOrders();
    _completedOrders = allOrders.where((order) => order.orderStatus == 'Selesai').toList();
    _allExpenses = await _expenseService.getExpenses();
    
    _isLoading = false;
    notifyListeners();
  }
}
