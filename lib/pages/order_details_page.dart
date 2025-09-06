import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/pages/order_page.dart';
import 'package:aplikasi_kasir_seafood/pages/payment_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatefulWidget {
  final model_order.Order order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderListProvider>(context, listen: false).loadOrders();
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      Provider.of<MenuProvider>(context, listen: false).loadMenus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Detail Pesanan',
        showBackButton: true,
      ),
      body: Consumer3<OrderListProvider, MenuProvider, CustomerProvider>(
        builder: (context, orderListProvider, menuProvider, customerProvider, child) {
          final order = widget.order;

          if (orderListProvider.isLoading || menuProvider.isLoading || customerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final customer = customerProvider.customers.firstWhere(
            (c) => c.id == order.customerId,
            orElse: () => model_customer.Customer(name: 'Pelanggan Tidak Dikenal'),
          );

          return FutureBuilder<List<model_order_item.OrderItem>>(
            future: orderListProvider.getOrderItems(order.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final items = snapshot.data ?? [];
              final totalAmount = items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

              return Column(
                children: [
                  // Header Informasi Pelanggan
                  _buildCustomerInfoCard(customer),
                  // Daftar Item Pesanan
                  Expanded(
                    child: _buildOrderItemsList(items, menuProvider),
                  ),
                  const Divider(),
                  // Bagian Total dan Tombol Aksi
                  _buildActionSection(context, totalAmount, order),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCustomerInfoCard(model_customer.Customer customer) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: FontAwesomeIcons.user,
              label: 'Nama Pelanggan',
              value: customer.name,
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.chair,
              label: 'Nomor Meja',
              value: customer.tableNumber ?? '-',
            ),
            _buildInfoRow(
              icon: FontAwesomeIcons.users,
              label: 'Jumlah Tamu',
              value: customer.guestCount?.toString() ?? '-',
            ),
            if (customer.notes != null && customer.notes!.isNotEmpty)
              _buildInfoRow(
                icon: FontAwesomeIcons.noteSticky,
                label: 'Catatan',
                value: customer.notes!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          FaIcon(icon, size: 16, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsList(List<model_order_item.OrderItem> items, MenuProvider menuProvider) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final menu = menuProvider.menus.firstWhere(
          (m) => m.id == item.menuId,
          orElse: () => model_menu.Menu(
            id: 0,
            name: 'Menu Tidak Ditemukan',
            priceSell: 0,
            isAvailable: false,
          ),
        );
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          elevation: 2,
          child: ListTile(
            title: Text(
              menu.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Rp ${_formatCurrency(item.price)} x ${item.quantity.toStringAsFixed(1)}',
            ),
            trailing: Text(
              'Rp ${_formatCurrency(item.price * item.quantity)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSection(BuildContext context, double totalAmount, model_order.Order order) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Rp ${_formatCurrency(totalAmount)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Provider.of<OrderProvider>(context, listen: false).loadOrderToCart(order.id!);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderPage()),
                    );
                  },
                  icon: const Icon(FontAwesomeIcons.solidPenToSquare, size: 20),
                  label: const Text('Edit Pesanan', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to PaymentPage, passing the total amount and order ID
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          order: model_order.Order(
                            id: order.id!,
                            totalAmount: totalAmount,
                            customerId: order.customerId,
                            orderStatus: 'Diproses',
                            orderTime: DateTime.now().toIso8601String(),
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(FontAwesomeIcons.solidCreditCard, size: 20),
                  label: const Text('Bayar', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
