import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/order_item.dart'
    as model_order_item;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/setting_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';

class ReceiptPreviewPage extends StatefulWidget {
  final int orderId;
  final double cashGiven;
  final double changeAmount;

  const ReceiptPreviewPage({
    super.key,
    required this.orderId,
    required this.cashGiven,
    required this.changeAmount,
  });

  @override
  State<ReceiptPreviewPage> createState() => _ReceiptPreviewPageState();
}

class _ReceiptPreviewPageState extends State<ReceiptPreviewPage> {
  final OrderService _orderService = OrderService();
  model_order.Order? order;
  List<model_order_item.OrderItem> items = [];
  model_customer.Customer? customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiptData();
  }

  Future<void> _loadReceiptData() async {
    final fetchedOrder = await _orderService.getOrderById(widget.orderId);
    final fetchedItems = await _orderService.getOrderItems(widget.orderId);
    model_customer.Customer? fetchedCustomer;
    if (fetchedOrder?.customerId != null) {
      final customerProvider =
          Provider.of<CustomerProvider>(context, listen: false);
      fetchedCustomer =
          await customerProvider.getCustomerById(fetchedOrder!.customerId!);
    }

    if (!mounted) return;
    setState(() {
      order = fetchedOrder;
      items = fetchedItems;
      customer = fetchedCustomer;
      _isLoading = false;
    });
  }

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
      body: Consumer<SettingProvider>(
        builder: (context, settingProvider, child) {
          if (_isLoading || settingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (order == null) {
            return const Center(child: Text("Data pesanan tidak ditemukan."));
          }

          final settings = settingProvider.settings;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 Logo Restoran
                if (settings?.restoLogo != null && settings!.restoLogo!.isNotEmpty)
                  Center(
                    child: Image.file(
                      File(settings.restoLogo!),
                      height: 100,
                    ),
                  ),
                // 🔹 Nama Restoran
                Center(
                  child: Text(
                    settings?.restoName ?? "Nama Restoran",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 🔹 Alamat Restoran
                if (settings?.restoAddress != null && settings!.restoAddress!.isNotEmpty)
                  Center(
                    child: Text(
                      settings.restoAddress!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                // 🔹 Informasi Order
                Text(
                  'Tanggal: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(order!.orderTime))}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Kasir: Admin', // nanti bisa ambil dari user login
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'No. Order: ${order!.id}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (customer != null) ...[
                  Text(
                    'Pelanggan: ${customer!.name}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (customer!.tableNumber != null && customer!.tableNumber!.isNotEmpty)
                    Text(
                      'Meja: ${customer!.tableNumber}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
                const Divider(),
                // 🔹 Item Pesanan
                ListView.builder(
                  itemCount: items.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Column(
                      children: [
                        ListTile(
                          dense: true,
                          title: Text(item.menuName),
                          subtitle: Text(
                            'x${item.quantity} Rp ${_formatCurrency(item.price)}',
                          ),
                          trailing: Text(
                            'Rp ${_formatCurrency(item.price * item.quantity)}',
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  },
                ),
                const Divider(),
                // 🔹 Total & Pembayaran
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 12)),
                    Text(
                      'Rp ${_formatCurrency(order!.totalAmount ?? 0.0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bayar',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Rp ${_formatCurrency(widget.cashGiven)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Kembali',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Rp ${_formatCurrency(widget.changeAmount)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Divider(),
                // 🔹 Pesan Kaki Struk
                if (settings?.receiptMessage != null && settings!.receiptMessage!.isNotEmpty)
                  Center(
                    child: Text(
                      settings.receiptMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  )
                else
                  const Center(
                    child: Text(
                      'Terima kasih sudah berkunjung!',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
