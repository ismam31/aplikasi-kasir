import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/models/order_item.dart';
import 'package:aplikasi_kasir_seafood/providers/setting_provider.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:aplikasi_kasir_seafood/models/setting.dart' as model_setting;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'dart:typed_data';

class PrintReceiptPage extends StatefulWidget {
  final int orderId;
  final double cashGiven;
  final double changeAmount;

  const PrintReceiptPage({
    super.key,
    required this.orderId,
    required this.cashGiven,
    required this.changeAmount,
  });

  @override
  State<PrintReceiptPage> createState() => _PrintReceiptPageState();
}

class _PrintReceiptPageState extends State<PrintReceiptPage> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final OrderService _orderService = OrderService();

  BluetoothDevice? selectedDevice;
  List<BluetoothDevice> devices = [];
  bool connected = false;

  model_order.Order? order;
  List<OrderItem> items = [];
  model_customer.Customer? customer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getDevices();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final fetchedOrder = await _orderService.getOrderById(widget.orderId);
      final fetchedItems = await _orderService.getOrderItems(widget.orderId);

      model_customer.Customer? fetchedCustomer;
      if (fetchedOrder?.customerId != null) {
        fetchedCustomer = await _orderService.getCustomerById(
          fetchedOrder!.customerId!,
        );
      }

      if (!mounted) return;
      setState(() {
        order = fetchedOrder;
        items = fetchedItems;
        customer = fetchedCustomer;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      CustomNotification.show(
        context,
        'Gagal memuat data pesanan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _getDevices() async {
    final pairedDevices = await bluetooth.getBondedDevices();
    if (!mounted) return;
    setState(() => devices = pairedDevices);

    bluetooth.isConnected.then((isConnected) {
      if (!mounted) return;
      setState(() => connected = isConnected ?? false);
    });
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  void connect() async {
    if (selectedDevice == null) {
      CustomNotification.show(
        context,
        "Pilih printer dulu",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }
    try {
      await bluetooth.connect(selectedDevice!);
      if (!mounted) return;
      setState(() => connected = true);
      CustomNotification.show(
        context,
        "Berhasil Terkoneksi",
        backgroundColor: Colors.green,
        icon: Icons.check,
      );
    } catch (e) {
      CustomNotification.show(
        context,
        "Gagal koneksi: $e",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  void disconnect() async {
    await bluetooth.disconnect();
    if (!mounted) return;
    setState(() => connected = false);
  }

  void _printReceipt(model_setting.Setting settings) async {
    if (!connected || order == null) return;

    try {
      // Reset printer
      await bluetooth.writeBytes(Uint8List.fromList([27, 64])); // ESC @

      // Center align
      await bluetooth.writeBytes(Uint8List.fromList([27, 97, 1])); // ESC a 1

      // Double height text
      await bluetooth.writeBytes(Uint8List.fromList([27, 33, 16])); // ESC ! 16

      // Normal style lagi
      await bluetooth.writeBytes(Uint8List.fromList([27, 33, 0])); // ESC ! 0

      String formatLine(String left, String right, {int width = 32}) {
        // width = jumlah karakter per baris (cek manual di printermu, biasanya 32)
        int space = width - left.length - right.length;
        if (space < 0) space = 1;
        return left + ' ' * space + right;
      }

      // === HEADER ===
      await bluetooth.writeBytes(
        Uint8List.fromList([27, 97, 1]),
      ); // ESC a 1 (center)
      await bluetooth.writeBytes(
        Uint8List.fromList([27, 33, 16]),
      ); // ESC ! 16 (double height, normal font)
      await bluetooth.writeBytes(
        utf8.encode("${settings.restoName ?? "Nama Restoran"}\n"),
      );
      await bluetooth.writeBytes(
        Uint8List.fromList([27, 33, 0]),
      ); // Balik normal
      await bluetooth.writeBytes(
        utf8.encode("${settings.restoAddress ?? "Alamat Restoran"}\n"),
      );
      await bluetooth.writeBytes(
        utf8.encode(
          "${settings.restoPhone ?? "Nomor Telepon Restoran"}/${settings.restoPhone2 ?? "Nomor Telepon Restoran"}\n",
        ),
      );
      await bluetooth.writeBytes(
        utf8.encode("================================\n"),
      );

      // === INFO ORDER ===
      await bluetooth.writeBytes(Uint8List.fromList([27, 97, 0]));
      // Tanggal (kiri) - jam (kanan)
      await bluetooth.writeBytes(
        utf8.encode(
          "${formatLine(DateFormat('dd-MM-yyyy').format(DateTime.parse(order!.orderTime)), "Admin")}\n",
        ),
      );
      final customerName = customer?.name ?? "Pelanggan Tidak Dikenal";
      // Pesanan (kiri) - ID (kanan)
      await bluetooth.writeBytes(
        utf8.encode(
          formatLine(
            DateFormat('HH:mm:ss').format(DateTime.parse(order!.orderTime)),
            customerName,
          ),
        ),
      );

      final tableNumber = customer?.tableNumber ?? "-";
      final guestCount = customer?.guestCount ?? 0;
      await bluetooth.writeBytes(
        utf8.encode(
          formatLine(
            "No. #${order!.id}",
            "Meja $tableNumber/$guestCount orang",
          ),
        ),
      );

      await bluetooth.writeBytes(
        utf8.encode("================================\n"),
      );

      // === ITEM LIST ===
      for (var item in items) {
        await bluetooth.writeBytes(utf8.encode("${item.menuName}\n"));
        String qtyPrice =
            " ${item.quantity.toStringAsFixed(1)} x Rp${_formatCurrency(item.price)}";
        String totalLine = "Rp ${_formatCurrency(item.price * item.quantity)}";
        await bluetooth.writeBytes(
          utf8.encode("${formatLine(qtyPrice, totalLine)}\n"),
        );
      }

      // === TOTAL ===
      await bluetooth.writeBytes(
        utf8.encode("================================\n"),
      );
      await bluetooth.writeBytes(
        utf8.encode(
          "${formatLine("Total    :", "Rp ${_formatCurrency(order!.totalAmount!)}")}\n",
        ),
      );
      await bluetooth.writeBytes(
        utf8.encode(
          "${formatLine("Bayar    :", "Rp ${_formatCurrency(widget.cashGiven)}")}\n",
        ),
      );
      await bluetooth.writeBytes(
        utf8.encode(
          "${formatLine("Kembali  :", "Rp ${_formatCurrency(widget.changeAmount)}")}\n",
        ),
      );
      await bluetooth.writeBytes(
        utf8.encode("================================\n"),
      );

      // === FOOTER ===
      await bluetooth.writeBytes(Uint8List.fromList([27, 97, 1])); // Center
      await bluetooth.writeBytes(
        utf8.encode("${settings.receiptMessage ?? "Terima kasih"}\n\n\n"),
      );

      CustomNotification.show(
        context,
        "Perintah cetak berhasil dikirim",
        backgroundColor: Colors.green,
        icon: Icons.check,
      );
    } catch (e) {
      CustomNotification.show(
        context,
        "Gagal print: $e",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Cetak Struk", showBackButton: true),
      body: Consumer<SettingProvider>(
        builder: (context, settingProvider, child) {
          if (_isLoading || settingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (order == null) {
            return const Center(child: Text("Data pesanan tidak ditemukan."));
          }

          final setting = settingProvider.settings!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Perangkat Bluetooth',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: devices.isEmpty
                      ? const Center(
                          child: Text("Tidak ada perangkat terhubung"),
                        )
                      : ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index];
                            return Card(
                              elevation: selectedDevice == device ? 4 : 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: selectedDevice == device
                                    ? const BorderSide(
                                        color: Colors.blue,
                                        width: 2,
                                      )
                                    : BorderSide.none,
                              ),
                              child: ListTile(
                                leading: FaIcon(
                                  FontAwesomeIcons.bluetooth,
                                  color: selectedDevice == device
                                      ? Colors.blue
                                      : Colors.blueGrey,
                                ),
                                title: Text(device.name ?? "Unknown"),
                                subtitle: Text(device.address ?? "-"),
                                onTap: () => setState(() {
                                  selectedDevice = device;
                                }),
                                trailing: selectedDevice == device
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                if (connected)
                  const Text(
                    "Printer terhubung",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: connected ? disconnect : connect,
                        icon: FaIcon(
                          connected
                              ? FontAwesomeIcons.solidCircleXmark
                              : FontAwesomeIcons.solidCircleCheck,
                          size: 20,
                        ),
                        label: Text(
                          connected ? 'Disconnect' : 'Connect',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: connected
                              ? Colors.red.shade700
                              : Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            connected &&
                                settingProvider.settings != null &&
                                order != null
                            ? () => _printReceipt(setting)
                            : null,
                        icon: const FaIcon(FontAwesomeIcons.print, size: 20),
                        label: const Text(
                          'Cetak Struk',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
