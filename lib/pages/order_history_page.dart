import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Riwayat Pesanan'),
      drawer: const CustomDrawer(),
      body: Consumer<OrderListProvider>(
        builder: (context, orderListProvider, child) {
          if (orderListProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderHistory = orderListProvider.orderHistory;

          if (orderHistory.isEmpty) {
            return const Center(
              child: Text('Belum ada riwayat pesanan.'),
            );
          }

          return ListView.builder(
            itemCount: orderHistory.length,
            itemBuilder: (context, index) {
              final order = orderHistory[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Pesanan #${order.id}'),
                  subtitle: Text('Total: Rp ${order.totalAmount!.toStringAsFixed(0)}'),
                  trailing: Text('Waktu: ${order.orderTime}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
