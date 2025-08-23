import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_kasir_seafood/models/category.dart' as model_category;
import 'package:aplikasi_kasir_seafood/models/menu.dart' as model_menu;
import 'package:aplikasi_kasir_seafood/providers/category_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/menu_provider.dart';
import 'package:aplikasi_kasir_seafood/providers/order_provider.dart';
import 'package:aplikasi_kasir_seafood/widgets/custom_app_bar.dart';
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
  model_category.Category? _selectedCategory;
  bool _isGridView = true;

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
    return Scaffold(
      appBar: const CustomAppBar(title: 'Pemesanan'),
      drawer: const CustomDrawer(),
      body: Consumer2<CategoryProvider, MenuProvider>(
        builder: (context, categoryProvider, menuProvider, child) {
          if (categoryProvider.isLoading || menuProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<model_menu.Menu> allMenus = menuProvider.menus;

          // Filter dan sortir menu
          List<model_menu.Menu> filteredMenus = allMenus.where((menu) {
            final matchCategory =
                _selectedCategory == null ||
                menu.categoryId == _selectedCategory!.id;
            final matchQuery = menu.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            return matchCategory && matchQuery;
          }).toList();

          if (_sortOrder == 'az') {
            filteredMenus.sort((a, b) => a.name.compareTo(b.name));
          } else {
            filteredMenus.sort((a, b) => b.name.compareTo(a.name));
          }

          return Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
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
                          IconButton(
                            icon: Icon(
                              _isGridView ? Icons.view_list : Icons.grid_view,
                            ),
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Semua'),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                            ),
                            ...categoryProvider.categories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: ChoiceChip(
                                  label: Text(category.name!),
                                  selected:
                                      _selectedCategory?.id == category.id,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedCategory = selected
                                          ? category
                                          : null;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16.0),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 5.0,
                                mainAxisSpacing: 5.0,
                                childAspectRatio: 0.7,
                              ),
                          itemCount: filteredMenus.length,
                          itemBuilder: (context, index) {
                            final menu = filteredMenus[index];
                            return _buildMenuItemCard(context, menu);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filteredMenus.length,
                          itemBuilder: (context, index) {
                            final menu = filteredMenus[index];
                            return _buildMenuItemListTile(context, menu);
                          },
                        ),
                ),
                _buildCartView(context),
              ],
            ),
          );
        },
      ),
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
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemListTile(BuildContext context, model_menu.Menu menu) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          height: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: menu.image != null && menu.image!.isNotEmpty
                ? Image.file(File(menu.image!), fit: BoxFit.cover)
                : Image.asset('assets/placeholder.png', fit: BoxFit.cover),
          ),
        ),
        title: Text(
          menu.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Rp ${_formatCurrency(menu.priceSell)}'),
        onTap: () => _showQuantityDialog(context, menu),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context, model_menu.Menu menu) {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );
    final String unit = menu.weightUnit ?? 'pcs';
    double price = menu.priceSell;

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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Input Quantity ${menu.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Harga per $unit: Rp ${_formatCurrency(price)}'),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Tombol minus
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      int current = int.tryParse(quantityController.text) ?? 1;
                      if (current > 1) {
                        current--;
                        quantityController.text = current.toString();
                      }
                    },
                  ),
                  // TextField
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  // Tombol plus
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () {
                      int current = int.tryParse(quantityController.text) ?? 1;
                      current++;
                      quantityController.text = current.toString();
                    },
                  ),
                ],
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
