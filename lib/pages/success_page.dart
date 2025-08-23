import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/pages/order_page.dart';
import 'package:aplikasi_kasir_seafood/pages/receipt_preview_page.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/customer.dart';
import 'package:aplikasi_kasir_seafood/models/order_item.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:aplikasi_kasir_seafood/pages/print_receipt_page.dart';

class SuccessPage extends StatefulWidget {
  final double changeAmount;
  final model_order.Order? order;
  final double cashGiven;
  final Customer? customer;
  final List<OrderItem> items;

  const SuccessPage({
    super.key,
    required this.changeAmount,
    this.order,
    required this.cashGiven,
    this.customer,
    required this.items,
  });

  @override
  State<SuccessPage> createState() => SuccessPageState();
}

class SuccessPageState extends State<SuccessPage> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? selectedDevice;
  List<BluetoothDevice> devices = [];
  bool connected = false;

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  void _getDevices() async {
    final List<BluetoothDevice> pairedDevices = await bluetooth
        .getBondedDevices();
    setState(() {
      devices = pairedDevices;
    });

    bluetooth.isConnected.then((isConnected) {
      setState(() {
        connected = isConnected ?? false;
      });
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
        title: 'Pembayaran Berhasil',
        showBackButton: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white, size: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Good Job!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('Transaksi berhasil!', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian', style: TextStyle(fontSize: 18)),
                  Text(
                    'Rp ${_formatCurrency(widget.changeAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Transaksi Baru',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.order != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrintReceiptPage(
                            order: widget.order!,
                            items: widget.items,
                            cashGiven: widget.cashGiven,
                            changeAmount: widget.changeAmount,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.print),
                  label: const Text(
                    'Cetak Struk',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.order != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReceiptPreviewPage(
                            order: widget.order!,
                            cashGiven: widget.cashGiven,
                            changeAmount: widget.changeAmount,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.remove_red_eye),
                  label: const Text(
                    'Lihat Struk',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
