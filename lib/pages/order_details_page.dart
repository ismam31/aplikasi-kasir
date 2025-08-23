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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:aplikasi_kasir_seafood/pages/order_page.dart';
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
              return Column(
                children: [
                  // Header Informasi Pelanggan
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nama Pelanggan: ${customer.name}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nomor Meja: ${customer.tableNumber ?? '-'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Jumlah Tamu: ${customer.guestCount ?? '-'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Catatan: ${customer.notes ?? '-'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Daftar Item Pesanan
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final menu = menuProvider.menus.firstWhere(
                          (m) => m.id == item.menuId,
                          orElse: () => model_menu.Menu(
                            id: 0,
                            name: 'Menu Tidak Ditemukan',
                            priceSell: 0,
                          ),
                        );
                        return ListTile(
                          title: Text(menu.name),
                          subtitle: Text('Rp ${_formatCurrency(item.price)} x ${item.quantity.toStringAsFixed(1)}'),
                          trailing: Text('Rp ${_formatCurrency(item.price * item.quantity)}'),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  // Bagian Total dan Tombol Aksi
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Rp ${_formatCurrency(order.totalAmount!)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                                icon: const Icon(FontAwesomeIcons.circlePlus, size: 20),
                                label: const Text('Tambah Pesanan', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showPaymentDialog(context, order.id!);
                                },
                                icon: const Icon(FontAwesomeIcons.solidCreditCard, size: 20),
                                label: const Text('Bayar', style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
  
  void _showPaymentDialog(BuildContext context, int orderId) {
    String? selectedMethod;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Selesaikan Pembayaran'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Metode Pembayaran:'),
                  RadioListTile(
                    title: const Text('Cash'),
                    value: 'Cash',
                    groupValue: selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value as String?;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('Debit'),
                    value: 'Debit',
                    groupValue: selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value as String?;
                      });
                    },
                  ),
                  RadioListTile(
                    title: const Text('QRIS'),
                    value: 'QRIS',
                    groupValue: selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        selectedMethod = value as String?;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMethod != null) {
                      Provider.of<OrderListProvider>(context, listen: false).updateOrderStatus(orderId, 'Selesai');
                      Navigator.pop(context); // Tutup dialog
                      Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu!')),
                      );
                    }
                  },
                  child: const Text('Selesaikan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
