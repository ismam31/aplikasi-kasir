import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/expense.dart' as model_expense;
import 'package:aplikasi_kasir_seafood/services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<model_expense.Expense> _expenses = [];
  bool _isLoading = false;

  List<model_expense.Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  ExpenseProvider() {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      _expenses = await _expenseService.getExpenses();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> insertExpense(model_expense.Expense expense) async {
    await _expenseService.insertExpense(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _expenseService.deleteExpense(id);
    await loadExpenses();
  }
}
