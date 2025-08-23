import 'package:flutter/foundation.dart';
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/services/customer_service.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();

  List<model_customer.Customer> _customers = [];
  bool _isLoading = false;

  List<model_customer.Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  CustomerProvider() {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    _customers = await _customerService.getCustomers();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<model_customer.Customer?> loadCustomerById(int? customerId) async {
    if (customerId == null) return null;
    final customer = _customers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => model_customer.Customer(name: 'Tidak Ditemukan', id: 0),
    );
    if (customer.id == 0) return null;
    return customer;
  }

  Future<int> addCustomer(model_customer.Customer customer) async {
    final int id = await _customerService.insertCustomer(customer);
    await loadCustomers();
    return id;
  }

  Future<void> updateCustomer(model_customer.Customer customer) async {
    await _customerService.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _customerService.deleteCustomer(id);
    await loadCustomers();
  }
}
