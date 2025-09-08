import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/order_item.dart'
    as model_order_item;
import 'package:aplikasi_kasir_seafood/providers/order_list_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/setting_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:aplikasi_kasir_seafood/pages/order_page.dart';
import 'package:aplikasi_kasir_seafood/pages/payment_page.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import "package:blue_thermal_printer/blue_thermal_printer.dart";
import 'package:aplikasi_kasir_seafood/models/setting.dart' as model_setting;
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/services/order_service.dart';
import 'dart:convert';
import 'dart:typed_data';

class OrderDetailsPage extends StatefulWidget {
  final model_order.Order order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;
  final OrderService _orderService = OrderService();

  model_order.Order? order;
  List<model_order_item.OrderItem> items = [];
  model_customer.Customer? customer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final fetchedOrder = await _orderService.getOrderById(widget.order.id!);
      final fetchedItems = await _orderService.getOrderItems(widget.order.id!);

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
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        'Gagal memuat data pesanan: $e',
        Colors.red,
        Icons.error_outline,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  void _showNotification(String message, Color color, IconData icon) {
    if (mounted) {
      CustomNotification.show(
        context,
        message,
        backgroundColor: color,
        icon: icon,
      );
    }
  }

  // Metode untuk menampilkan dialog cetak
  void _showPrintDialog(model_setting.Setting setting) async {
    List<BluetoothDevice> devices = await printer.getBondedDevices();
    BluetoothDevice? selectedDevice;
    bool isConnected = await printer.isConnected ?? false;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Cetak Struk"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isConnected
                          ? 'Status: Printer Terhubung'
                          : 'Status: Printer Belum Terhubung',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih perangkat Bluetooth:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // ini bagian device list biar bisa discroll
                    devices.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Tidak ada perangkat terhubung.'),
                          )
                        : SizedBox(
                            height: 200, // batas tinggi list (bisa lo atur)
                            child: ListView.builder(
                              itemCount: devices.length,
                              itemBuilder: (context, index) {
                                final device = devices[index];
                                return ListTile(
                                  title: Text(device.name ?? 'Unknown'),
                                  subtitle: Text(device.address ?? '-'),
                                  trailing: selectedDevice == device
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        )
                                      : null,
                                  onTap: () {
                                    setStateDialog(() {
                                      selectedDevice = device;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: selectedDevice != null
                      ? () async {
                          if (isConnected && selectedDevice != null) {
                            await _performPrint(setting, dialogContext);
                          } else {
                            // Coba koneksi
                            try {
                              await printer.connect(selectedDevice!);
                              await Future.delayed(const Duration(seconds: 1));
                              final finalCheck = await printer.isConnected;
                              if (finalCheck == true) {
                                isConnected = true;
                                _showNotification(
                                  "Berhasil konek",
                                  Colors.green,
                                  Icons.check,
                                );
                                await _performPrint(setting, dialogContext);
                              } else {
                                _showNotification(
                                  "Koneksi printer terputus.",
                                  Colors.red,
                                  Icons.error_outline,
                                );
                              }
                            } catch (e) {
                              _showNotification(
                                "Gagal koneksi: $e",
                                Colors.red,
                                Icons.error_outline,
                              );
                            }
                          }
                        }
                      : null,
                  child: Text(
                    isConnected ? 'Cetak Struk' : 'Hubungkan & Cetak',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performPrint(
    model_setting.Setting settings,
    BuildContext dialogContext,
  ) async {
    if (order == null || items.isEmpty || settings.restoName == null) {
      _showNotification(
        "Data pesanan tidak lengkap.",
        Colors.red,
        Icons.error_outline,
      );
      return;
    }

    try {
      // Reset printer
      await printer.writeBytes(Uint8List.fromList([27, 64])); // ESC @

      // Center align
      await printer.writeBytes(Uint8List.fromList([27, 97, 1])); // ESC a 1

      // Double height text
      await printer.writeBytes(Uint8List.fromList([27, 33, 16])); // ESC ! 16

      // Normal style lagi
      await printer.writeBytes(Uint8List.fromList([27, 33, 0])); // ESC ! 0

      // helper function
      String formatLine(String left, String right, {int width = 32}) {
        int space = width - left.length - right.length;
        if (space < 0) space = 1;
        return left + ' ' * space + right;
      }

      // ==== HEADER ====
      await printer.writeBytes(
        Uint8List.fromList([27, 97, 1]),
      ); // ESC a 1 (center)
      await printer.writeBytes(
        Uint8List.fromList([27, 33, 16]),
      ); // ESC ! 16 (double height, normal font)
      await printer.writeBytes(
        utf8.encode("${settings.restoName ?? "Nama Restoran"}\n"),
      );
      await printer.writeBytes(Uint8List.fromList([27, 33, 0])); // Balik normal
      await printer.writeBytes(
        utf8.encode("${settings.restoAddress ?? "Alamat Restoran"}\n"),
      );
      await printer.writeBytes(
        utf8.encode(
          "${settings.restoPhone ?? "Nomor Telepon Restoran"}/${settings.restoPhone2 ?? "Nomor Telepon Restoran"}\n",
        ),
      );
      await printer.writeBytes(
        utf8.encode("================================\n"),
      );

      // ==== INFO ORDER ====
      await printer.writeBytes(Uint8List.fromList([27, 97, 0]));
      // Tanggal (kiri) - jam (kanan)
      await printer.writeBytes(
        utf8.encode(
          "${formatLine(DateFormat('dd-MM-yyyy').format(DateTime.parse(order!.orderTime)), "Admin")}\n",
        ),
      );
      final customerName = customer?.name ?? "Pelanggan Tidak Dikenal";
      // Pesanan (kiri) - ID (kanan)
      await printer.writeBytes(
        utf8.encode(
          formatLine(
            DateFormat('HH:mm:ss').format(DateTime.parse(order!.orderTime)),
            customerName,
          ),
        ),
      );

      final tableNumber = customer?.tableNumber ?? "-";
      final guestCount = customer?.guestCount ?? 0;
      await printer.writeBytes(
        utf8.encode(
          formatLine(
            "No. #${order!.id}",
            "Meja $tableNumber/$guestCount orang",
          ),
        ),
      );
      await printer.writeBytes(
        utf8.encode("================================\n"),
      );

      // ==== ITEM PESANAN ====
      for (var item in items) {
        await printer.writeBytes(utf8.encode("${item.menuName}\n"));
        String qtyPrice =
            " ${item.quantity.toStringAsFixed(1)} x Rp${_formatCurrency(item.price)}";
        String totalLine = "Rp ${_formatCurrency(item.price * item.quantity)}";
        await printer.writeBytes(
          utf8.encode("${formatLine(qtyPrice, totalLine)}\n"),
        );
      }

      // ==== TOTAL ====
      await printer.writeBytes(
        utf8.encode("================================\n"),
      );
      await printer.writeBytes(
        utf8.encode(
          "${formatLine("Total", "Rp ${_formatCurrency(order!.totalAmount!)}")}\n",
        ),
      );
      await printer.writeBytes(
        utf8.encode(
          "${formatLine("Bayar", order!.paidAmount != null ? "Rp ${_formatCurrency(order!.paidAmount!)}" : "Belum Bayar")}\n",
        ),
      );
      await printer.writeBytes(
        utf8.encode(
          "${formatLine("Kembali", order!.changeAmount != null ? "Rp ${_formatCurrency(order!.changeAmount!)}" : "-")}\n",
        ),
      );

      // ==== FOOTER ====
      await printer.writeBytes(
        utf8.encode("================================\n"),
      );
      await printer.writeBytes(Uint8List.fromList([27, 97, 1])); // Center
      await printer.writeBytes(
        utf8.encode("${settings.receiptMessage ?? "Terima kasih"}\n\n\n"),
      );
      await printer.writeBytes(Uint8List.fromList([27, 100, 1]));

      _showNotification(
        "Perintah cetak berhasil dikirim",
        Colors.green,
        Icons.check,
      );

      Navigator.pop(dialogContext);
    } catch (e) {
      _showNotification("Gagal print: $e", Colors.red, Icons.error_outline);
    }
  }

  Widget _buildCustomerInfoCard(model_customer.Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pelanggan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 16, color: Colors.teal),
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

  Widget _buildOrderItemsList(
    List<model_order_item.OrderItem> items,
    MenuProvider menuProvider,
  ) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            title: Text(
              item.menuName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            subtitle: Text(
              '${item.quantity.toStringAsFixed(1)} ${menu.weightUnit ?? 'pcs'} x Rp ${_formatCurrency(item.price)}',
              style: TextStyle(color: Colors.blueGrey.shade700),
            ),
            trailing: Text(
              'Rp ${_formatCurrency(item.price * item.quantity)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionSection(
    BuildContext context,
    double totalAmount,
    model_order.Order order,
    model_customer.Customer customer,
    List<model_order_item.OrderItem> items,
    model_setting.Setting? setting,
  ) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              Text(
                'Rp ${_formatCurrency(totalAmount)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Provider.of<OrderProvider>(
                      context,
                      listen: false,
                    ).loadOrderToCart(order.id!);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderPage(),
                      ),
                    );
                  },
                  icon: const Icon(FontAwesomeIcons.solidPenToSquare, size: 20),
                  label: const Text('Edit', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
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
                  onPressed: () {
                    if (setting == null) {
                      _showNotification(
                        "Pengaturan belum diset",
                        Colors.red,
                        Icons.error_outline,
                      );
                      return;
                    }
                    _showPrintDialog(setting);
                  },
                  icon: const FaIcon(FontAwesomeIcons.print, size: 20),
                  label: const Text('Cetak', style: TextStyle(fontSize: 16)),
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
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Detail Pesanan', showBackButton: true),
      body: Consumer3<OrderListProvider, MenuProvider, CustomerProvider>(
        builder:
            (
              context,
              orderListProvider,
              menuProvider,
              customerProvider,
              child,
            ) {
              final order = widget.order;

              if (orderListProvider.isLoading ||
                  menuProvider.isLoading ||
                  customerProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final settingProvider = Provider.of<SettingProvider>(context);

              final customer = customerProvider.customers.firstWhere(
                (c) => c.id == order.customerId,
                orElse: () => model_customer.Customer(
                  id: 0,
                  name: 'Pelanggan Tidak Dikenal',
                  tableNumber: null,
                ),
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
                  final totalAmount = items.fold(
                    0.0,
                    (sum, item) => sum + (item.price * item.quantity),
                  );

                  return Column(
                    children: [
                      _buildCustomerInfoCard(customer),
                      Expanded(
                        child: _buildOrderItemsList(items, menuProvider),
                      ),
                      const Divider(),
                      _buildActionSection(
                        context,
                        totalAmount,
                        order,
                        customer,
                        items,
                        settingProvider.settings,
                      ),
                    ],
                  );
                },
              );
            },
      ),
    );
  }
}
