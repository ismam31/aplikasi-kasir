import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/providers/category_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_drawer.dart';
import 'package:aplikasi_kasir_seafood/pages/cart_page.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = 'az';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Metode untuk format angka
  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CategoryProvider, MenuProvider>(
      builder: (context, categoryProvider, menuProvider, child) {
        if (categoryProvider.isLoading || menuProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final List<model_category.Category> categories =
            categoryProvider.categories;
        final List<model_menu.Menu> allMenus = menuProvider.menus;

        return DefaultTabController(
          length: categories.length,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.blue.shade800,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              title: const Text(
                'Pemesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottom: TabBar(
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: categories.map((category) {
                  return Tab(text: category.name);
                }).toList(),
              ),
            ),
            drawer: const CustomDrawer(),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            // border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Cari menu...',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _sortOrder,

                        items: const [
                          DropdownMenuItem(value: 'az', child: Text('A-Z')),
                          DropdownMenuItem(value: 'za', child: Text('Z-A')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortOrder = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: categories.map((category) {
                      List<model_menu.Menu> menusInCategory = allMenus
                          .where((menu) => menu.categoryId == category.id)
                          .where(
                            (menu) => menu.name.toLowerCase().contains(
                              _searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                      if (_sortOrder == 'az') {
                        menusInCategory.sort(
                          (a, b) => a.name.compareTo(b.name),
                        );
                      } else {
                        menusInCategory.sort(
                          (a, b) => b.name.compareTo(a.name),
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(16.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.0,
                              mainAxisSpacing: 16.0,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: menusInCategory.length,
                        itemBuilder: (context, index) {
                          final menu = menusInCategory[index];
                          return _buildMenuItemCard(context, menu);
                        },
                      );
                    }).toList(),
                  ),
                ),
                _buildCartView(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItemCard(BuildContext context, model_menu.Menu menu) {
    return InkWell(
      onTap: () {
        _showQuantityDialog(context, menu);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: menu.image != null && menu.image!.isNotEmpty
                    ? Image.file(File(menu.image!), fit: BoxFit.cover)
                    : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    menu.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(menu.priceSell)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, model_menu.Menu menu) {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    final String unit = menu.weightUnit ?? 'pcs';
    double price = menu.priceSell;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambahkan ${menu.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Harga per $unit: Rp ${_formatCurrency(price)}'),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kuantitas ($unit)',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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
                  ).addItemToCart(menu: menu, quantity: quantity);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kuantitas tidak boleh 0')),
                  );
                }
              },
              child: const Text('Tambahkan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCartView(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  Text(
                    'Rp ${_formatCurrency(orderProvider.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: orderProvider.cart.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CartPage(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Lihat Keranjang & Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
