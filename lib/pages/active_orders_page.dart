import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/pages/order_details_page.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;

class ActiveOrdersPage extends StatefulWidget {
  const ActiveOrdersPage({super.key});

  @override
  State<ActiveOrdersPage> createState() => _ActiveOrdersPageState();
}

class _ActiveOrdersPageState extends State<ActiveOrdersPage> {
  final OrderService _orderService = OrderService();

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  Future<void> _refreshOrders() async {
    await Provider.of<OrderListProvider>(context, listen: false).loadOrders();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pesanan Aktif'),
      drawer: const CustomDrawer(currentPage: 'Pesanan Aktif'),
      body: Consumer<OrderListProvider>(
        builder: (context, orderListProvider, child) {
          if (orderListProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final activeOrders = orderListProvider.activeOrders;

          if (activeOrders.isEmpty) {
            return const Center(
              child: Text('Tidak ada pesanan aktif saat ini.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshOrders,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return FutureBuilder<model_customer.Customer?>(
                  future: order.customerId != null
                      ? _orderService.getCustomerById(order.customerId!)
                      : Future.value(null),
                  builder: (context, snapshot) {
                    final customer = snapshot.data;
                    final customerName =
                        customer?.name ?? 'Pelanggan Tidak Dikenal';
                    final tableNumber = customer?.tableNumber ?? '-';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderDetailsPage(order: order),
                            ),
                          );
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            FontAwesomeIcons.solidCircleUser,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          customerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blueGrey,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Meja: $tableNumber',
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: Rp ${_formatCurrency(order.totalAmount ?? 0)}',
                              style: const TextStyle(
                                color: Colors.teal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Text(
                          DateFormat(
                            'HH:mm',
                          ).format(DateTime.parse(order.orderTime)),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
