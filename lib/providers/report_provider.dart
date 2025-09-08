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
  List<Map<String, dynamic>> _hourlyData = [];
  bool _isLoading = false;
  int _totalOrders = 0;

  List<model_order.Order> get completedOrders => _completedOrders;
  List<model_expense.Expense> get allExpenses => _allExpenses;
  bool get isLoading => _isLoading;
  int get totalOrders => _totalOrders;
  List<Map<String, dynamic>> get hourlyData => _hourlyData;

  double get totalRevenue {
    return _completedOrders.fold(
      0.0,
      (sum, order) => sum + (order.totalAmount ?? 0.0),
    );
  }

  double get totalExpenses {
    return _allExpenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double get netProfit {
    return totalRevenue - totalExpenses;
  }

  Future<void> loadReports(DateTime dateTime, {DateTime? date}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final allOrders = await _orderService.getOrders();

      // Filter pesanan yang sudah selesai
      var filteredOrders = allOrders
          .where((order) => order.orderStatus == 'Selesai')
          .toList();

      // Filter berdasarkan tanggal jika disediakan
      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        filteredOrders = filteredOrders.where((order) {
          final orderTime = DateTime.parse(order.orderTime);
          return orderTime.isAfter(startOfDay) && orderTime.isBefore(endOfDay);
        }).toList();
      }

      _completedOrders = filteredOrders;
      _allExpenses = await _expenseService.getExpenses();
      _totalOrders = _completedOrders.length;

      _calculateHourlyData();
    } catch (e) {
      // Handle error jika gagal memuat data
      if (kDebugMode) {
        print('Error loading reports: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void _calculateHourlyData() {
    Map<int, double> tempHourlyData = {};
    for (var i = 0; i < 24; i++) {
      tempHourlyData[i] = 0.0;
    }

    for (var order in _completedOrders) {
      final hour = DateTime.parse(order.orderTime).hour;
      final totalAmount = order.totalAmount ?? 0.0;
      tempHourlyData.update(
        hour,
        (value) => value + totalAmount,
        ifAbsent: () => totalAmount,
      );
    }

    _hourlyData = tempHourlyData.entries
        .map((e) => {'hour': e.key.toDouble(), 'value': e.value})
        .toList();

    // Pastikan data terurut berdasarkan jam
    _hourlyData.sort((a, b) => a['hour']!.compareTo(b['hour']!));
  }

  Future<void> loadReportsByRange(DateTime startDate, DateTime endDate) async {
    _allExpenses = await _expenseService.getExpensesByDateRange(startDate, endDate);
    _isLoading = true;
    notifyListeners();

    try {
      final allOrders = await _orderService.getOrders();
      var filteredOrders = allOrders
          .where((order) => order.orderStatus == 'Selesai')
          .toList();

      // Filter berdasarkan rentang tanggal
      filteredOrders = filteredOrders.where((order) {
        final orderTime = DateTime.parse(order.orderTime);
        return orderTime.isAfter(startDate) && orderTime.isBefore(endDate);
      }).toList();

      _completedOrders = filteredOrders;
      _allExpenses = await _expenseService.getExpenses();
      _totalOrders = _completedOrders.length;

      _calculateHourlyData();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading reports by range: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(String description, double amount) async {
  final newExpense = model_expense.Expense(
    description: description,
    amount: amount,
    date: DateTime.now().toIso8601String(),
  );

  await _expenseService.insertExpense(newExpense); // simpan ke DB
  _allExpenses.add(newExpense); // update provider
  notifyListeners();
}

}
