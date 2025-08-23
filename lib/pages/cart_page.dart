import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/models/customer.dart' as model_customer;
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/customer_provider.dart';
import 'package:aplikasi_kasir_seafood/pages/active_orders_page.dart';
import 'package:aplikasi_kasir_seafood/pages/payment_page.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_notification.dart';
import 'package:aplikasi_kasir_seafood/models/order.dart' as model_order;

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

  void _saveOrder(BuildContext context, {bool isPaid = false}) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      int? customerId = _selectedCustomer?.id;
      if (customerId == null && _customerNameController.text.isNotEmpty) {
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
      } else if (customerId != null) {
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

    final latestOrder = orderProvider.cart.isNotEmpty
        ? orderProvider.cart.first
        : null;

    if (latestOrder != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            order: model_order.Order(
              id: latestOrder.orderId,
              totalAmount: orderProvider.totalAmount,
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
                        onTap: () => Provider.of<OrderProvider>(
                          context,
                          listen: false,
                        ).updateItemQuantity(item.menuId, 1),
                        title: Text(menu.name),
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
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Catatan (opsional)',
                        ),
                        maxLines: 2,
                      ),
                      TextFormField(
                        controller: _guestCountController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Tamu (opsional)',
                        ),
                        keyboardType: TextInputType.number,
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
