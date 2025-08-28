import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/order_item.dart' as model_order_item;
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';

class ReceiptPreviewPage extends StatelessWidget {
  final model_order.Order order;
  final double cashGiven;
  final double changeAmount;

  const ReceiptPreviewPage({
    super.key,
    required this.order,
    required this.cashGiven,
    required this.changeAmount,
  });

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Pratinjau Struk',
        showBackButton: true,
      ),
      body: Consumer3<OrderListProvider, MenuProvider, CustomerProvider>(
        builder: (context, orderListProvider, menuProvider, customerProvider, child) {
          if (orderListProvider.isLoading || menuProvider.isLoading || customerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Warung Tikungan', // Ganti dengan data dari SettingProvider
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Center(
                      child: Text('Jl. QW29+6J3, Patimban, Kec. Pusakanagara', style: TextStyle(fontSize: 12)),
                    ),
                    const Center(
                      child: Text('Kabupaten Subang, Jawa Barat 41255, Indonesia', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    Text('Tanggal: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(order.orderTime))}', style: const TextStyle(fontSize: 14)),
                    Text('Waktu: ${DateFormat('HH:mm').format(DateTime.parse(order.orderTime))}', style: const TextStyle(fontSize: 14)),
                    Text('Kasir: Admin', style: const TextStyle(fontSize: 14)), // Ganti dengan data pengguna login
                    Text('No. Order: ${order.id}', style: const TextStyle(fontSize: 14)),
                    const Divider(),
                    ...items.map((item) {
                      final menu = menuProvider.menus.firstWhere(
                        (m) => m.id == item.menuId,
                        orElse: () => model_menu.Menu(
                          id: 0,
                          name: 'Menu Tidak Ditemukan',
                          priceSell: 0,
                          isAvailable: false,
                        ),
                      );
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.quantity.toStringAsFixed(1)} x ${menu.name}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text('Rp ${_formatCurrency(item.price)}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('Rp ${_formatCurrency(item.price * item.quantity)}'),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total'),
                        Text('Rp ${_formatCurrency(order.totalAmount ?? 0.0)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bayar'),
                        Text('Rp ${_formatCurrency(cashGiven)}'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembali'),
                        Text('Rp ${_formatCurrency(changeAmount)}'),
                      ],
                    ),
                    const Divider(),
                    const Center(
                      child: Text('Terima kasih sudah berkunjung!', style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
