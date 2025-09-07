import 'dart:io';

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

  // Fungsi baru untuk menyimpan atau memperbarui data pelanggan
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
    double price = menu.priceSell;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: 'Input Quantity ${menu.name}',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Text(
            menu.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.teal,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Harga per $unit: Rp ${_formatCurrency(price)}',
                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        double current =
                            double.tryParse(quantityController.text) ?? 1;
                        if (current > 1) {
                          current -= (unit == 'pcs' || unit == 'porsi')
                              ? 1.0
                              : 0.1;
                        }
                        quantityController.text =
                            (unit == 'pcs' || unit == 'porsi')
                            ? current.toStringAsFixed(0)
                            : current.toStringAsFixed(1);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blueGrey.shade200,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        double current =
                            double.tryParse(quantityController.text) ?? 0;
                        if (current == 0 &&
                            (unit == 'pcs' || unit == 'porsi')) {
                          current = 1.0;
                        } else {
                          current += (unit == 'pcs' || unit == 'porsi')
                              ? 1.0
                              : 0.1;
                        }
                        quantityController.text =
                            (unit == 'pcs' || unit == 'porsi')
                            ? current.toStringAsFixed(0)
                            : current.toStringAsFixed(1);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: Colors.blueGrey),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final quantity =
                    double.tryParse(quantityController.text) ?? 0.0;
                if (quantity > 0) {
                  Provider.of<OrderProvider>(
                    context,
                    listen: false,
                  ).updateItemQuantity(item.menuId, quantity);
                  Navigator.pop(context);
                } else {
                  CustomNotification.show(
                    context,
                    'Kuantitas tidak boleh 0',
                    backgroundColor: Colors.red,
                    icon: Icons.error,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
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
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      if (orderProvider.cart.isEmpty) {
        CustomNotification.show(
          context,
          'Keranjang kosong. Tambahkan menu terlebih dahulu.',
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
        return;
      }

      int? customerId = await _saveCustomerData();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            order: model_order.Order(
              id: orderProvider.editingOrderId,
              totalAmount: orderProvider.totalAmount,
              customerId: customerId,
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
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Dismissible(
                        key: ValueKey(item.menuId),
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
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          onTap: () => _showEditQuantityDialog(context, item),
                          leading: SizedBox(
                            width: 60,
                            height: 60,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  menu.image != null && menu.image!.isNotEmpty
                                  ? Image.file(
                                      File(menu.image!),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/placeholder.png',
                                              fit: BoxFit.cover,
                                            );
                                          },
                                    )
                                  : Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          title: Text(
                            item.menuName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.quantity.toStringAsFixed(1)} ${menu.weightUnit ?? 'pcs'} x Rp ${_formatCurrency(item.price)}',
                            style: TextStyle(color: Colors.blueGrey.shade700),
                          ),
                          trailing: Text(
                            'Rp ${_formatCurrency(item.price * item.quantity)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal,
                            ),
                          ),
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
                              color: Colors.blueGrey,
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(orderProvider.totalAmount)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _customerNameController,
                          decoration: InputDecoration(
                            labelText: 'Nama Pelanggan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.person_search,
                                color: Colors.blueGrey,
                              ),
                              onPressed: () {
                                _showCustomerSelectionDialog(
                                  context,
                                  customerProvider,
                                );
                              },
                            ),
                          ),
                          validator: (value) => value!.isEmpty
                              ? 'Nama pelanggan wajib diisi.'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _guestCountController,
                              decoration: const InputDecoration(
                                labelText: 'Jumlah Tamu',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tableNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor Meja',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _saveOrder(context),
                              icon: const Icon(
                                FontAwesomeIcons.solidFloppyDisk,
                                size: 20,
                              ),
                              label: const Text(
                                'Simpan',
                                style: TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
