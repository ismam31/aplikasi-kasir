import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/pages/active_orders_page.dart';
import 'package:aplikasi_kasir_seafood/pages/payment_page.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _tableNumberController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _guestCountController = TextEditingController();

  model_customer.Customer? _selectedCustomer;
  String? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      if (orderProvider.editingCustomerId != null) {
        final customer = Provider.of<CustomerProvider>(context, listen: false)
            .customers
            .firstWhere(
              (c) => c.id == orderProvider.editingCustomerId,
              orElse: () => model_customer.Customer(
                name: 'Pelanggan Tidak Dikenal',
                id: 0,
              ),
            );
        if (customer.id != 0) {
          _selectedCustomer = customer;
          _customerNameController.text = customer.name;
          _tableNumberController.text = customer.tableNumber ?? '';
          _notesController.text = customer.notes ?? '';
          _guestCountController.text = customer.guestCount?.toString() ?? '';
        }
      }
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _tableNumberController.dispose();
    _notesController.dispose();
    _guestCountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  // ✅ Fungsi baru untuk menyimpan atau memperbarui data pelanggan
  Future<int?> _saveCustomerData() async {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );

    int? customerId = _selectedCustomer?.id;
    if (_customerNameController.text.isNotEmpty) {
      if (customerId == null) {
        final newCustomer = model_customer.Customer(
          name: _customerNameController.text.trim(),
          tableNumber: _tableNumberController.text.isEmpty
              ? null
              : _tableNumberController.text.trim(),
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          guestCount: int.tryParse(_guestCountController.text),
        );
        customerId = await customerProvider.addCustomer(newCustomer);
      } else {
        final updatedCustomer = model_customer.Customer(
          id: customerId,
          name: _customerNameController.text.trim(),
          tableNumber: _tableNumberController.text.isEmpty
              ? null
              : _tableNumberController.text.trim(),
          notes: _notesController.text.isEmpty
              ? null
              : _notesController.text.trim(),
          guestCount: int.tryParse(_guestCountController.text),
        );
        await customerProvider.updateCustomer(updatedCustomer);
      }
    }
    return customerId;
  }

  void _saveOrder(BuildContext context, {bool isPaid = false}) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // ✅ Ambil customerId yang valid setelah data disimpan
      int? customerId = await _saveCustomerData();

      final status = isPaid ? 'Selesai' : 'Diproses';
      final paymentMethod = isPaid ? _selectedPaymentMethod : null;

      await orderProvider.saveOrder(
        customerId: customerId,
        status: status,
        paymentMethod: paymentMethod,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const ActiveOrdersPage()),
        (route) => false,
      );

      CustomNotification.show(
        context,
        'Pesanan berhasil disimpan dengan status: $status',
        backgroundColor: Colors.green,
        icon: Icons.check_circle_outline,
      );
    }
  }

  void _showEditQuantityDialog(BuildContext context, item) {
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final menu = menuProvider.menus.firstWhere(
      (m) => m.id == item.menuId,
      orElse: () => model_menu.Menu(
        id: 0,
        name: 'Menu Tidak Ditemukan',
        priceSell: 0,
        isAvailable: false,
      ),
    );

    final TextEditingController quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final String unit = menu.weightUnit ?? 'pcs';

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      barrierLabel: 'Input Quantity ${menu.name}',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation.drive(
              Tween<double>(
                begin: 0,
                end: 1,
              ).chain(CurveTween(curve: Curves.easeIn)),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          title: Text(
            'Ubah Kuantitas ${menu.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          content: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  double current =
                      double.tryParse(quantityController.text) ?? 1;
                  if (current <= 1.0) {
                    current -= 0.1;
                    quantityController.text = current.toStringAsFixed(1);
                  } else {
                    current -= 1.0;
                    quantityController.text = current.toStringAsFixed(1);
                  }
                },
              ),
              Expanded(
                child: TextField(
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixText: unit,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  double current =
                      double.tryParse(quantityController.text) ?? 1;
                  if (current >= 10.0) {
                    current += 0.1;
                    quantityController.text = current.toStringAsFixed(1);
                  }
                  current += 1.0;
                  quantityController.text = current.toStringAsFixed(1);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () {
                item.quantity = double.tryParse(quantityController.text) ?? 1.0;
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomerSelectionDialog(
    BuildContext context,
    CustomerProvider customerProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Pelanggan'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customerProvider.customers.length,
              itemBuilder: (context, index) {
                final customer = customerProvider.customers[index];
                return ListTile(
                  title: Text(customer.name),
                  subtitle: Text('Meja: ${customer.tableNumber ?? '-'}'),
                  onTap: () {
                    setState(() {
                      _selectedCustomer = customer;
                      _customerNameController.text = customer.name;
                      _tableNumberController.text = customer.tableNumber ?? '';
                      _notesController.text = customer.notes ?? '';
                      _guestCountController.text =
                          customer.guestCount?.toString() ?? '';
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    // ✅ Ambil customerId yang valid setelah data disimpan
    int? customerId = await _saveCustomerData();
    
    // Pastikan ada item di keranjang sebelum melanjutkan
    if (orderProvider.cart.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            order: model_order.Order(
              id: orderProvider.editingOrderId,
              totalAmount: orderProvider.totalAmount,
              customerId: customerId, // ✅ Gunakan customerId yang sudah valid
              orderStatus: 'Diproses',
              orderTime: DateTime.now().toIso8601String(),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Keranjang Pesanan',
        showBackButton: true,
      ),
      body: Consumer3<OrderProvider, MenuProvider, CustomerProvider>(
        builder: (context, orderProvider, menuProvider, customerProvider, child) {
          final cartItems = orderProvider.cart;

          if (cartItems.isEmpty) {
            return const Center(child: Text('Keranjang kosong.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final menu = menuProvider.menus.firstWhere(
                      (m) => m.id == item.menuId,
                      orElse: () => model_menu.Menu(
                        id: 0,
                        name: 'Menu Tidak Ditemukan',
                        priceSell: 0,
                        isAvailable: false,
                      ),
                    );

                    return Dismissible(
                      key: Key(item.menuId.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        orderProvider.removeItemFromCart(item.menuId);
                        CustomNotification.show(
                          context,
                          '${menu.name} dihapus dari keranjang',
                          backgroundColor: Colors.orange,
                          icon: Icons.delete_outline,
                        );
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        onTap: () => _showEditQuantityDialog(context, item),
                        title: Text(item.menuName),
                        subtitle: Text(
                          '${item.quantity.toStringAsFixed(1)} ${menu.weightUnit ?? 'pcs'} x Rp ${_formatCurrency(item.price)}',
                        ),
                        trailing: Text(
                          'Rp ${_formatCurrency(item.price * item.quantity)}',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
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
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(orderProvider.totalAmount)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Pelanggan',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.person_search),
                            onPressed: () {
                              _showCustomerSelectionDialog(
                                context,
                                customerProvider,
                              );
                            },
                          ),
                        ],
                      ),
                      TextFormField(
                        controller: _tableNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Meja (opsional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _guestCountController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Tamu (opsional)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _saveOrder(context, isPaid: false),
                              icon: const Icon(
                                FontAwesomeIcons.solidFloppyDisk,
                                size: 20,
                              ),
                              label: const Text(
                                'Simpan',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showPaymentDialog(context),
                              icon: const Icon(
                                FontAwesomeIcons.solidCreditCard,
                                size: 20,
                              ),
                              label: const Text(
                                'Bayar',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
