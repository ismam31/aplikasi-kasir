import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/models/order_item.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart' show rootBundle;

class PrintReceiptPage extends StatefulWidget {
  final model_order.Order order;
  final List<OrderItem> items;
  final double cashGiven;
  final double changeAmount;

  const PrintReceiptPage({
    super.key,
    required this.order,
    required this.items,
    required this.cashGiven,
    required this.changeAmount,
  });

  @override
  State<PrintReceiptPage> createState() => _PrintReceiptPageState();
}

class _PrintReceiptPageState extends State<PrintReceiptPage> {
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
    final pairedDevices = await bluetooth.getBondedDevices();
    setState(() => devices = pairedDevices);

    bluetooth.isConnected.then((isConnected) {
      setState(() => connected = isConnected ?? false);
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  void connect() async {
    if (selectedDevice == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Pilih printer dulu")));
      return;
    }
    try {
      await bluetooth.connect(selectedDevice!);
      setState(() => connected = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Berhasil konek")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal konek: $e")));
    }
  }

  void disconnect() async {
    await bluetooth.disconnect();
    setState(() => connected = false);
  }

  void _printReceipt() async {
    if (!connected) return;

    try {
      final bytes = await rootBundle.load('assets/store.png');
      final imageBytes = bytes.buffer.asUint8List();
      final original = img.decodeImage(imageBytes);

      if (original != null) {
        const int paperWidth = 384;
        final img.Image centeredImage = img.Image(paperWidth, original.height);
        img.fill(centeredImage, img.getColor(255, 255, 255));
        final int x = ((paperWidth - original.width) / 2).round();
        img.copyInto(centeredImage, original, dstX: x);
        final Uint8List printableBytes = Uint8List.fromList(
          img.encodePng(centeredImage),
        );
        bluetooth.printImageBytes(printableBytes);
      }
    } catch (_) {}

    bluetooth.printNewLine();
    bluetooth.printCustom("WARUNG TIKUNGAN", 3, 1);
    bluetooth.printCustom("Patimban, Kec Pusakanagara, Kabupaten Subang", 1, 1);
    bluetooth.printCustom(
      "================================",
      1,
      1,
    );
    bluetooth.printLeftRight(
      "Tanggal",
      DateFormat(
        'dd-MM-yyyy HH:mm',
      ).format(DateTime.parse(widget.order.orderTime)),
      1,
    );
    bluetooth.printLeftRight("Pesanan #${widget.order.id}", "Kasir: Admin", 1);

    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final customer = await customerProvider.loadCustomerById(
      widget.order.customerId,
    );
    if (customer != null && customer.name.isNotEmpty) {
      bluetooth.printLeftRight("Pelanggan", customer.name, 1);
    }

    bluetooth.printCustom(
      "================================",
      1,
      1,
    );
    for (var item in widget.items) {
      bluetooth.printCustom(item.menuName, 1, 0);
      String qtyPrice = "x${item.quantity} kg Rp ${_formatCurrency(item.price)}";
      bluetooth.printLeftRight(qtyPrice, "Rp ${_formatCurrency(item.price * item.quantity)}", 1);
    }

    bluetooth.printCustom(
      "================================",
      1,
      1,
    );
    bluetooth.printLeftRight(
      "Total",
      'Rp ${_formatCurrency(widget.order.totalAmount!)}',
      1,
    );
    bluetooth.printLeftRight(
      "Bayar",
      'Rp ${_formatCurrency(widget.cashGiven)}',
      1,
    );
    bluetooth.printLeftRight(
      "Kembali",
      'Rp ${_formatCurrency(widget.changeAmount)}',
      1,
    );

    bluetooth.printCustom(
      "================================",
      1,
      1,
    );
    bluetooth.printCustom("Terima kasih atas kunjungan anda", 1, 1);
    bluetooth.printNewLine();
    bluetooth.printNewLine();
    bluetooth.paperCut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Cetak Struk", showBackButton: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: devices
                  .map(
                    (device) => ListTile(
                      title: Text(device.name ?? "Unknown"),
                      subtitle: Text(device.address ?? ""),
                      trailing: selectedDevice == device
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () => setState(() => selectedDevice = device),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (connected)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Printer terhubung",
                style: TextStyle(color: Colors.green),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(onPressed: connect, child: const Text("Connect")),
              ElevatedButton(
                onPressed: disconnect,
                child: const Text("Disconnect"),
              ),
              ElevatedButton(
                onPressed: connected ? _printReceipt : null,
                child: const Text("Cetak"),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
