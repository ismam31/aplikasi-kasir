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
      // ✅ Ambil order
      final fetchedOrder = await _orderService.getOrderById(widget.orderId);

      // ✅ Ambil item-item
      final fetchedItems = await _orderService.getOrderItems(widget.orderId);

      // ✅ Ambil customer (jika ada)
      model_customer.Customer? fetchedCustomer;
      if (fetchedOrder?.customerId != null) {
        // ✅ Perbaikan: Ambil data pelanggan langsung dari OrderService
        fetchedCustomer =
            await _orderService.getCustomerById(fetchedOrder!.customerId!);
      }

      if (!mounted) return;
      setState(() {
        order = fetchedOrder;
        items = fetchedItems;
        customer = fetchedCustomer;
        _isLoading = false; // ✅ Selesai loading
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Pilih printer dulu")));
      return;
    }
    try {
      await bluetooth.connect(selectedDevice!);
      if (!mounted) return;
      setState(() => connected = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Berhasil konek")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Gagal konek: $e")));
    }
  }

  void disconnect() async {
    await bluetooth.disconnect();
    if (!mounted) return;
    setState(() => connected = false);
  }

  void _printReceipt(model_setting.Setting settings) async {
    if (!connected || order == null) return;

    // === CETAK HEADER ===
    bluetooth.printCustom(settings.restoName ?? "Nama Restoran", 3, 1);
    bluetooth.printCustom(settings.restoAddress ?? "Alamat Restoran", 1, 1);
    bluetooth.printCustom("================================", 1, 1);

    bluetooth.printLeftRight(
      "Tanggal",
      DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(order!.orderTime)),
      1,
    );
    bluetooth.printLeftRight("Pesanan #${order!.id}", "Kasir: Admin", 1);

    // === CETAK CUSTOMER ===
    bluetooth.printLeftRight(
      "Pelanggan",
      (customer != null && customer!.name.isNotEmpty) ? customer!.name : "-",
      1,
    );
    bluetooth.printLeftRight(
      "Meja",
      (customer != null && customer!.tableNumber != null)
          ? customer!.tableNumber.toString()
          : "-",
      1,
    );

    // === CETAK ITEM PESANAN ===
    bluetooth.printCustom("================================", 1, 1);
    for (var item in items) {
      bluetooth.printCustom(item.menuName, 1, 0);
      String qtyPrice = "x${item.quantity} Rp${_formatCurrency(item.price)}";
      bluetooth.printLeftRight(
        qtyPrice,
        "Rp ${_formatCurrency(item.price * item.quantity)}",
        1,
      );
    }

    // === CETAK TOTAL ===
    bluetooth.printCustom("================================", 1, 1);
    bluetooth.printLeftRight(
      "Total",
      'Rp ${_formatCurrency(order!.totalAmount!)}',
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

    // === FOOTER ===
    bluetooth.printCustom("================================", 1, 1);
    bluetooth.printCustom(settings.receiptMessage ?? "Terima kasih", 1, 1);

    bluetooth.printNewLine();
    bluetooth.printNewLine();
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
            return const Center(
              child: Text("Data pesanan tidak ditemukan."),
            );
          }

          return Column(
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
                  ElevatedButton(onPressed: disconnect, child: const Text("Disconnect")),
                  ElevatedButton(
                    onPressed: connected &&
                            settingProvider.settings != null &&
                            order != null
                        ? () => _printReceipt(settingProvider.settings!)
                        : null,
                    child: const Text("Cetak"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
