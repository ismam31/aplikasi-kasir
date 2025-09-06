import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/pages/receipt_preview_page.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  String _selectedDateFilter = 'Today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderListProvider>(context, listen: false).loadOrders(DateTime.now());
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
    });
  }

  Future<void> _loadOrdersByDateFilter(String filter) async {
    DateTime? dateToLoad;
    setState(() {
      _selectedDateFilter = filter;
    });

    switch (filter) {
      case 'Today':
        dateToLoad = DateTime.now();
        break;
      case 'Yesterday':
        dateToLoad = DateTime.now().subtract(const Duration(days: 1));
        break;
      case 'Last 7 Days':
        dateToLoad = DateTime.now().subtract(const Duration(days: 7));
        break;
    }

    if (dateToLoad != null) {
      await Provider.of<OrderListProvider>(context, listen: false).loadOrders(dateToLoad);
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  String _getFormattedDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  String _getCustomerName(int? customerId, List<model_customer.Customer> customers) {
    if (customerId == null) return 'Pelanggan (Tanpa Nama)';
    try {
      final customer = customers.firstWhere((c) => c.id == customerId);
      return customer.name.isNotEmpty ? customer.name : 'Pelanggan (Tanpa Nama)';
    } catch (e) {
      return 'Pelanggan (Tidak Ditemukan)';
    }
  }

  void _navigateToReceiptPreview(model_order.Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceiptPreviewPage(
          orderId: order.id!,
          // Note: cashGiven dan changeAmount tidak tersedia di riwayat
          cashGiven: 0.0,
          changeAmount: 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Riwayat Pesanan'),
      drawer: const CustomDrawer(),
      body: Consumer2<OrderListProvider, CustomerProvider>(
        builder: (context, orderListProvider, customerProvider, child) {
          if (orderListProvider.isLoading || customerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderHistory = orderListProvider.orderHistory;
          final customers = customerProvider.customers;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<String>(
                      value: _selectedDateFilter,
                      items: const [
                        DropdownMenuItem(value: 'Today', child: Text('Today')),
                        DropdownMenuItem(value: 'Yesterday', child: Text('Yesterday')),
                        DropdownMenuItem(value: 'Last 7 Days', child: Text('Last 7 Days')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _loadOrdersByDateFilter(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _loadOrdersByDateFilter(_selectedDateFilter),
                  child: orderHistory.isEmpty
                      ? const Center(child: Text('Belum ada riwayat pesanan.'))
                      : ListView.builder(
                          itemCount: orderHistory.length,
                          itemBuilder: (context, index) {
                            final order = orderHistory[index];
                            final customerName = _getCustomerName(order.customerId, customers);
                            return GestureDetector(
                              onTap: () => _navigateToReceiptPreview(order),
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            customerName,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Total: Rp ${_formatCurrency(order.totalAmount ?? 0.0)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Waktu: ${_getFormattedDate(DateTime.parse(order.orderTime))}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
